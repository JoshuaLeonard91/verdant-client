import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../generated/verdant/models.pb.dart' as verdant_models;
import '../../../generated/verdant/ws.pb.dart' as verdant_ws;
import '../../../app/client_version.dart';
import '../../auth/auth_diagnostics.dart';
import '../../auth/auth_credentials.dart';
import '../../auth/auth_models.dart';
import '../../auth/auth_service.dart';
import '../../auth/transport_security.dart';
import '../../../shared/verdant_input_sanitizer.dart';
import '../shared/chat_timestamp_format.dart';
import '../shared/workspace_entitlements.dart';
import '../shared/workspace_credential_refresher.dart';
import '../shared/workspace_message_mutation_repository.dart';
import '../workspace_local_id.dart';
import '../workspace_seed.dart';
import 'direct_messages_models.dart';
part 'direct_messages_service_mappers.dart';

abstract interface class DirectMessagesRepository {
  Future<DirectMessagesWorkspaceData> loadDirectMessages({
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
  });

  Future<Set<String>> loadHiddenChannelIds();

  Future<void> saveHiddenChannelIds({required Set<String> channelIds});

  Future<void> sendFriendRequest({required String username});

  Future<void> acceptFriendRequest({required String localUserId});

  Future<void> removeRelationship({required String localUserId});

  Future<DmConversationPreviewSeed> openDirectMessage({
    required String localUserId,
    required String currentUserId,
  });

  Future<DmConversationMessages> loadConversationMessages({
    required DmConversationPreviewSeed conversation,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  });

  Stream<DirectMessagesRealtimeEvent> connectRealtime({
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
    required String currentUserStatus,
  });
}

abstract interface class WorkspaceRealtimeCommandSink {
  Future<void> focusServer({required String serverId});

  Future<void> focusChannel({String? channelId});

  Future<void> sendChannelMessage({
    required String channelId,
    required String content,
  });

  Future<void> sendTypingStart({required String channelId});

  Future<void> updatePresenceStatus({required String status, bool afk = false});

  Future<void> addReaction({
    required String channelId,
    required String messageId,
    required String emoji,
    String? emojiId,
  });

  Future<void> removeReaction({
    required String channelId,
    required String messageId,
    required String emoji,
  });
}

final class DirectMessagesException implements Exception {
  const DirectMessagesException(
    this.message, {
    this.canRefreshCredentials = false,
  });

  final String message;
  final bool canRefreshCredentials;

  @override
  String toString() => message;
}

final class _PendingLiveFrame {
  _PendingLiveFrame({required this.frame, required this.diagnosticEvent});

  final verdant_ws.WsMessage frame;
  final String diagnosticEvent;
  final Completer<void> completer = Completer<void>();
}

final class VerdantDirectMessagesService
    implements
        DirectMessagesRepository,
        WorkspaceRealtimeCommandSink,
        WorkspaceMessageMutationRepository {
  VerdantDirectMessagesService({
    required String apiOrigin,
    required AuthCredentialStore credentialStore,
    AuthService? authService,
    Duration timeout = const Duration(seconds: 15),
    this.heartbeatInterval = const Duration(seconds: 10),
    this.pongTimeout = const Duration(seconds: 5),
    this.minReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 30),
    WebSocketChannel Function(Uri uri)? connectWebSocket,
    CertificatePinningPolicy? certificatePinningPolicy,
  }) : _actions = HttpDirectMessagesService(
         apiOrigin: apiOrigin,
         credentialStore: credentialStore,
         authService: authService,
         certificatePinningPolicy: certificatePinningPolicy,
         timeout: timeout,
       ),
       _credentialRefresher = WorkspaceCredentialRefresher(
         apiOrigin: apiOrigin,
         credentialStore: credentialStore,
         authService: authService,
         certificatePinningPolicy: certificatePinningPolicy,
         timeout: timeout,
       ),
       _connectWebSocket =
           connectWebSocket ??
           (certificatePinningPolicy ??
                   CertificatePinningPolicy.fromEnvironment())
               .connectWebSocket,
       apiOrigin = normalizeBackendApiOrigin(apiOrigin),
       timeout = timeout;

  final String apiOrigin;
  final Duration timeout;
  final Duration heartbeatInterval;
  final Duration pongTimeout;
  final Duration minReconnectDelay;
  final Duration maxReconnectDelay;
  final WebSocketChannel Function(Uri uri) _connectWebSocket;
  final HttpDirectMessagesService _actions;
  final WorkspaceCredentialRefresher _credentialRefresher;
  WebSocketChannel? _liveChannel;
  Completer<void>? _liveReady;
  var _liveGeneration = 0;
  final List<_PendingLiveFrame> _pendingLiveFrames = <_PendingLiveFrame>[];
  String? _desiredFocusedServerId;
  String? _sentFocusedServerId;
  String? _desiredFocusedChannelId;
  String? _sentFocusedChannelId;
  var _hasDesiredFocusedChannel = false;
  String? _lastRealtimeSessionId;
  String? _lastRealtimeReadyAt;
  String _livePreferredStatus = 'online';

  String get networkId => networkIdFromApiOrigin(apiOrigin);

  @override
  Future<DirectMessagesWorkspaceData> loadDirectMessages({
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
  }) async {
    _recordDiagnostic('rest.load.start', {
      'networkId': networkId,
      'apiOrigin': apiOrigin,
    });
    try {
      final data = await _actions.loadDirectMessages(
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserInitials: currentUserInitials,
      );
      _recordDiagnostic('rest.load.success', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'relationshipCount': data.friends.length,
        'dmChannelCount': data.conversations.length,
      });
      return data;
    } catch (error) {
      _recordDiagnostic('rest.load.failure', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'reason': error is DirectMessagesException
            ? error.message
            : 'Realtime session failed',
      });
      rethrow;
    }
  }

  @override
  Future<Set<String>> loadHiddenChannelIds() {
    return _actions.loadHiddenChannelIds();
  }

  @override
  Future<void> saveHiddenChannelIds({required Set<String> channelIds}) {
    return _actions.saveHiddenChannelIds(channelIds: channelIds);
  }

  @override
  Future<void> sendFriendRequest({required String username}) {
    return _actions.sendFriendRequest(username: username);
  }

  @override
  Future<void> acceptFriendRequest({required String localUserId}) {
    return _actions.acceptFriendRequest(localUserId: localUserId);
  }

  @override
  Future<void> removeRelationship({required String localUserId}) {
    return _actions.removeRelationship(localUserId: localUserId);
  }

  @override
  Future<DmConversationPreviewSeed> openDirectMessage({
    required String localUserId,
    required String currentUserId,
  }) {
    return _actions.openDirectMessage(
      localUserId: localUserId,
      currentUserId: currentUserId,
    );
  }

  @override
  Future<DmConversationMessages> loadConversationMessages({
    required DmConversationPreviewSeed conversation,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) {
    return _actions.loadConversationMessages(
      conversation: conversation,
      currentUserId: currentUserId,
      limit: limit,
      beforeMessageId: beforeMessageId,
    );
  }

  @override
  Future<void> deleteChannelMessage({
    required String channelId,
    required String messageId,
  }) {
    return _actions.deleteChannelMessage(
      channelId: channelId,
      messageId: messageId,
    );
  }

  @override
  Stream<DirectMessagesRealtimeEvent> connectRealtime({
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
    required String currentUserStatus,
  }) {
    _livePreferredStatus = _normalizeStatus(currentUserStatus).toLowerCase();
    final controller = StreamController<DirectMessagesRealtimeEvent>();
    var canceled = false;
    Future<void> Function()? closeActiveSocket;
    final firstReady = Completer<void>();
    Completer<void>? pendingInitialReady = firstReady;
    unawaited(firstReady.future.catchError((_) {}));
    _liveReady = firstReady;

    controller.onListen = () async {
      var refreshCredentialsBeforeNextAttempt = false;
      var reconnectAttempt = 0;
      while (!canceled && !controller.isClosed) {
        WebSocketChannel? channel;
        StreamSubscription<Object?>? subscription;
        Timer? heartbeatTimer;
        Timer? pongTimer;
        final ready = pendingInitialReady ?? Completer<void>();
        pendingInitialReady = null;
        unawaited(ready.future.catchError((_) {}));
        final socketDone = Completer<void>();
        var closed = false;
        int? closeCode;
        String? closeReason;
        Duration? plannedReconnectDelay;
        var awaitingPong = false;
        final generation = ++_liveGeneration;

        void stopHeartbeat() {
          heartbeatTimer?.cancel();
          heartbeatTimer = null;
          pongTimer?.cancel();
          pongTimer = null;
          awaitingPong = false;
        }

        Future<void> closeSocket([int? statusCode]) async {
          if (closed) {
            return;
          }
          closed = true;
          stopHeartbeat();
          if (_liveGeneration == generation &&
              _liveChannel == channel &&
              _liveReady == ready) {
            _liveChannel = null;
            _liveReady = null;
            _sentFocusedServerId = null;
            _sentFocusedChannelId = null;
          } else if (_liveGeneration == generation &&
              _liveChannel == null &&
              _liveReady == ready) {
            _liveReady = null;
          }
          if (!ready.isCompleted) {
            ready.completeError(
              DirectMessagesException(
                'Realtime session closed before READY',
                canRefreshCredentials: _isRefreshableRealtimeClose(
                  closeCode,
                  closeReason,
                ),
              ),
            );
          }
          await subscription?.cancel();
          await channel?.sink.close(_clientWebSocketCloseCode(statusCode));
          if (!socketDone.isCompleted) {
            socketDone.complete();
          }
        }

        void markPong() {
          if (!awaitingPong) {
            return;
          }
          awaitingPong = false;
          pongTimer?.cancel();
          pongTimer = null;
          _recordDiagnostic('protobuf.live.pong', {
            'networkId': networkId,
            'apiOrigin': apiOrigin,
          });
        }

        void startHeartbeat() {
          stopHeartbeat();
          heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
            if (closed ||
                canceled ||
                _liveGeneration != generation ||
                _liveChannel != channel ||
                channel == null) {
              stopHeartbeat();
              return;
            }
            if (awaitingPong) {
              _recordDiagnostic('protobuf.live.pong_timeout', {
                'networkId': networkId,
                'apiOrigin': apiOrigin,
              });
              unawaited(closeSocket(ws_status.goingAway));
              return;
            }
            try {
              channel.sink.add(
                Uint8List.fromList(
                  verdant_ws.WsMessage(ping: verdant_ws.Ping()).writeToBuffer(),
                ),
              );
              awaitingPong = true;
              pongTimer?.cancel();
              pongTimer = Timer(pongTimeout, () {
                if (awaitingPong && !closed && !canceled) {
                  _recordDiagnostic('protobuf.live.pong_timeout', {
                    'networkId': networkId,
                    'apiOrigin': apiOrigin,
                  });
                  unawaited(closeSocket(ws_status.goingAway));
                }
              });
              _recordDiagnostic('protobuf.live.ping', {
                'networkId': networkId,
                'apiOrigin': apiOrigin,
              });
            } catch (_) {
              unawaited(closeSocket(ws_status.goingAway));
            }
          });
        }

        closeActiveSocket = closeSocket;

        try {
          var credentials = await _readCredentials();
          if (refreshCredentialsBeforeNextAttempt) {
            credentials = await _refreshCredentials(credentials);
            refreshCredentialsBeforeNextAttempt = false;
          }
          final socket = _connectWebSocket(_webSocketUri());
          channel = socket;
          _liveChannel = socket;
          _liveReady = ready;
          _sentFocusedServerId = null;
          _sentFocusedChannelId = null;
          subscription = socket.stream.cast<Object?>().listen(
            (message) {
              try {
                final pong = _isRealtimePongFrame(message);
                if (pong) {
                  markPong();
                }
                final drainDelay = _plannedReconnectDelayFromFrame(message);
                if (drainDelay != null) {
                  plannedReconnectDelay = drainDelay;
                  _recordDiagnostic('protobuf.live.server_draining', {
                    'networkId': networkId,
                    'apiOrigin': apiOrigin,
                    'delayMs': drainDelay.inMilliseconds,
                  });
                }
                _rememberRealtimeResumeFromFrame(message);
                for (final event in _decodeRealtimeFrame(
                  message,
                  currentUserId: currentUserId,
                  currentUserName: currentUserName,
                  currentUserInitials: currentUserInitials,
                )) {
                  if (event is DirectMessagesSnapshotEvent &&
                      !ready.isCompleted) {
                    ready.complete();
                    startHeartbeat();
                    unawaited(_flushPendingFocus());
                    _flushPendingLiveFrames();
                  }
                  controller.add(event);
                }
              } on DirectMessagesException catch (error, stackTrace) {
                controller.addError(error, stackTrace);
              } catch (error, stackTrace) {
                controller.addError(
                  const DirectMessagesException('Realtime message was invalid'),
                  stackTrace,
                );
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!socketDone.isCompleted) {
                socketDone.complete();
              }
              controller.addError(
                const DirectMessagesException('Realtime session failed'),
                stackTrace,
              );
            },
            onDone: () {
              closeCode = socket.closeCode;
              closeReason = _safeWebSocketCloseReason(socket.closeReason);
              if (!controller.isClosed) {
                _recordDiagnostic('protobuf.live.closed', {
                  'networkId': networkId,
                  'apiOrigin': apiOrigin,
                  'closeCode': closeCode,
                  'closeReason': closeReason,
                });
              }
              if (!ready.isCompleted) {
                ready.completeError(
                  DirectMessagesException(
                    'Realtime session closed before READY',
                    canRefreshCredentials: _isRefreshableRealtimeClose(
                      closeCode,
                      closeReason,
                    ),
                  ),
                );
              }
              if (!socketDone.isCompleted) {
                socketDone.complete();
              }
            },
          );

          await socket.ready.timeout(
            timeout,
            onTimeout: () => throw const DirectMessagesException(
              'Realtime connection timed out',
            ),
          );
          final identify = verdant_ws.WsMessage(
            identify: _liveIdentify(credentials.accessToken),
          );
          socket.sink.add(Uint8List.fromList(identify.writeToBuffer()));
          _recordDiagnostic('protobuf.live.connected', {
            'networkId': networkId,
            'apiOrigin': apiOrigin,
          });

          await socketDone.future;
          refreshCredentialsBeforeNextAttempt = _isRefreshableRealtimeClose(
            closeCode,
            closeReason,
          );
        } on DirectMessagesException catch (error, stackTrace) {
          if (error.canRefreshCredentials) {
            refreshCredentialsBeforeNextAttempt = true;
          } else if (!controller.isClosed && !canceled) {
            controller.addError(error, stackTrace);
          }
        } catch (error, stackTrace) {
          if (!controller.isClosed && !canceled) {
            controller.addError(
              const DirectMessagesException('Realtime session failed'),
              stackTrace,
            );
          }
        } finally {
          await closeSocket(ws_status.goingAway);
        }

        if (!canceled && !controller.isClosed) {
          final delay = _liveReconnectDelay(
            reconnectAttempt,
            plannedDelay: plannedReconnectDelay,
          );
          reconnectAttempt += 1;
          await Future<void>.delayed(delay);
        }
      }
    };
    controller.onCancel = () async {
      canceled = true;
      _liveGeneration += 1;
      _failPendingLiveFrames(
        const DirectMessagesException('Realtime session closed'),
      );
      await closeActiveSocket?.call();
    };
    return controller.stream;
  }

  verdant_ws.Identify _liveIdentify(String accessToken) {
    final identify = verdant_ws.Identify(
      token: accessToken,
      clientVersion: verdantClientVersion,
      initialStatus: _statusToProto(_livePreferredStatus),
      afk: false,
    );
    final sessionId = _lastRealtimeSessionId;
    final readyAt = _lastRealtimeReadyAt;
    if (sessionId != null && readyAt != null) {
      identify.resumeSessionId = sessionId;
      identify.lastReadyAt = readyAt;
    }
    return identify;
  }

  @override
  Future<void> focusServer({required String serverId}) async {
    _desiredFocusedServerId = _safeCommandLocalId(networkId, serverId);
    await _flushPendingFocus();
  }

  @override
  Future<void> focusChannel({String? channelId}) async {
    _hasDesiredFocusedChannel = true;
    _desiredFocusedChannelId = channelId == null
        ? null
        : _safeCommandLocalId(networkId, channelId);
    await _flushPendingFocus();
  }

  @override
  Future<void> sendChannelMessage({
    required String channelId,
    required String content,
  }) async {
    final localChannelId = _safeCommandLocalId(networkId, channelId);
    final sanitized = sanitizeSearchInput(content, maxLength: 4000);
    if (sanitized.isEmpty) {
      throw const DirectMessagesException('Enter a message');
    }
    await _sendLiveFrame(
      verdant_ws.WsMessage(
        clientMessageSend: verdant_ws.ClientMessageSend(
          channelId: localChannelId,
          content: sanitized,
          nonce: _messageNonce(),
        ),
      ),
      diagnosticEvent: 'protobuf.command.message_send',
    );
  }

  @override
  Future<void> sendTypingStart({required String channelId}) async {
    final localChannelId = _safeCommandLocalId(networkId, channelId);
    await _sendLiveFrame(
      verdant_ws.WsMessage(
        clientTypingStart: verdant_ws.ClientTypingStart(
          channelId: localChannelId,
        ),
      ),
      diagnosticEvent: 'protobuf.command.typing_start',
    );
  }

  @override
  Future<void> updatePresenceStatus({
    required String status,
    bool afk = false,
  }) async {
    if (!afk) {
      _livePreferredStatus = _normalizeStatus(status).toLowerCase();
    }
    await _sendLiveFrame(
      verdant_ws.WsMessage(
        clientPresenceUpdate: verdant_ws.ClientPresenceUpdate(
          status: _statusToProto(status),
          afk: afk,
        ),
      ),
      diagnosticEvent: 'protobuf.command.presence_update',
    );
  }

  @override
  Future<void> addReaction({
    required String channelId,
    required String messageId,
    required String emoji,
    String? emojiId,
  }) async {
    final localChannelId = _safeCommandLocalId(networkId, channelId);
    final localMessageId = _safeCommandLocalId(networkId, messageId);
    final safeEmoji = _safeReactionEmoji(emoji);
    final safeEmojiId = emojiId == null
        ? null
        : _safeCommandLocalId(networkId, emojiId);
    await _sendLiveFrame(
      verdant_ws.WsMessage(
        clientReactionAdd: verdant_ws.ClientReactionAdd(
          channelId: localChannelId,
          messageId: localMessageId,
          emoji: safeEmoji,
          emojiId: safeEmojiId,
        ),
      ),
      diagnosticEvent: 'protobuf.command.reaction_add',
    );
  }

  @override
  Future<void> removeReaction({
    required String channelId,
    required String messageId,
    required String emoji,
  }) async {
    final localChannelId = _safeCommandLocalId(networkId, channelId);
    final localMessageId = _safeCommandLocalId(networkId, messageId);
    final safeEmoji = _safeReactionEmoji(emoji);
    await _sendLiveFrame(
      verdant_ws.WsMessage(
        clientReactionRemove: verdant_ws.ClientReactionRemove(
          channelId: localChannelId,
          messageId: localMessageId,
          emoji: safeEmoji,
        ),
      ),
      diagnosticEvent: 'protobuf.command.reaction_remove',
    );
  }

  Future<void> _sendLiveFrame(
    verdant_ws.WsMessage frame, {
    required String diagnosticEvent,
  }) async {
    final pending = _PendingLiveFrame(
      frame: frame,
      diagnosticEvent: diagnosticEvent,
    );
    _pendingLiveFrames.add(pending);
    _flushPendingLiveFrames();
    try {
      await pending.completer.future.timeout(
        timeout,
        onTimeout: () =>
            throw const DirectMessagesException('Realtime is reconnecting'),
      );
    } on DirectMessagesException {
      _pendingLiveFrames.remove(pending);
      rethrow;
    } catch (_) {
      _pendingLiveFrames.remove(pending);
      throw const DirectMessagesException('Realtime is reconnecting');
    }
  }

  void _flushPendingLiveFrames() {
    final ready = _liveReady;
    final channel = _liveChannel;
    if (ready == null ||
        channel == null ||
        !ready.isCompleted ||
        _pendingLiveFrames.isEmpty) {
      return;
    }
    final pending = List<_PendingLiveFrame>.of(_pendingLiveFrames);
    _pendingLiveFrames.clear();
    for (final item in pending) {
      if (item.completer.isCompleted) {
        continue;
      }
      try {
        channel.sink.add(Uint8List.fromList(item.frame.writeToBuffer()));
        _recordDiagnostic(item.diagnosticEvent, {
          'networkId': networkId,
          'apiOrigin': apiOrigin,
        });
        item.completer.complete();
      } catch (error, stackTrace) {
        item.completer.completeError(
          const DirectMessagesException('Realtime is reconnecting'),
          stackTrace,
        );
      }
    }
  }

  void _failPendingLiveFrames(DirectMessagesException error) {
    final pending = List<_PendingLiveFrame>.of(_pendingLiveFrames);
    _pendingLiveFrames.clear();
    for (final item in pending) {
      if (!item.completer.isCompleted) {
        item.completer.completeError(error);
      }
    }
  }

  Future<void> _flushPendingFocus() async {
    final channel = _liveChannel;
    final ready = _liveReady;
    if (channel == null || ready == null || !ready.isCompleted) {
      return;
    }

    final desiredServerId = _desiredFocusedServerId;
    if (desiredServerId != null && desiredServerId != _sentFocusedServerId) {
      channel.sink.add(
        Uint8List.fromList(
          verdant_ws.WsMessage(
            clientFocusServer: verdant_ws.ClientFocusServer(
              serverId: desiredServerId,
            ),
          ).writeToBuffer(),
        ),
      );
      _sentFocusedServerId = desiredServerId;
      _recordDiagnostic('protobuf.command.focus_server', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
      });
    }

    final desiredChannelId = _desiredFocusedChannelId;
    if (_hasDesiredFocusedChannel &&
        desiredChannelId != _sentFocusedChannelId) {
      channel.sink.add(
        Uint8List.fromList(
          verdant_ws.WsMessage(
            clientFocusChannel: desiredChannelId == null
                ? verdant_ws.ClientFocusChannel()
                : verdant_ws.ClientFocusChannel(channelId: desiredChannelId),
          ).writeToBuffer(),
        ),
      );
      _sentFocusedChannelId = desiredChannelId;
      _recordDiagnostic('protobuf.command.focus_channel', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'hasChannel': desiredChannelId != null,
      });
    }
  }

  void close() {
    _actions.close();
    _credentialRefresher.close();
  }

  Future<AuthCredentialBundle> _readCredentials() async {
    try {
      return await _credentialRefresher.readCredentials();
    } on WorkspaceCredentialRefreshException catch (error) {
      throw DirectMessagesException(error.message);
    }
  }

  Future<AuthCredentialBundle> _refreshCredentials(
    AuthCredentialBundle credentials,
  ) async {
    try {
      return await _credentialRefresher.refresh(credentials);
    } on WorkspaceCredentialRefreshException catch (error) {
      throw DirectMessagesException(error.message);
    }
  }

  Iterable<DirectMessagesRealtimeEvent> _decodeRealtimeFrame(
    Object? message, {
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
  }) sync* {
    if (message is String) {
      final decoded = jsonDecode(message);
      if (decoded is! Map) {
        throw const DirectMessagesException('Realtime text frame was invalid');
      }
      yield* _eventsFromJsonEnvelope(
        Map<String, Object?>.from(decoded),
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserInitials: currentUserInitials,
      );
      return;
    }
    if (message is! List<int>) {
      throw const DirectMessagesException('Realtime response was not protobuf');
    }

    final decoded = verdant_ws.WsMessage.fromBuffer(message);
    yield* _eventsFromProtoEnvelope(
      decoded,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      currentUserInitials: currentUserInitials,
    );
  }

  bool _isRealtimePongFrame(Object? message) {
    try {
      if (message is String) {
        final decoded = jsonDecode(message);
        return decoded is Map && decoded['op'] == 'PONG';
      }
      if (message is List<int>) {
        final decoded = verdant_ws.WsMessage.fromBuffer(message);
        return decoded.whichPayload() == verdant_ws.WsMessage_Payload.pong;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  Duration? _plannedReconnectDelayFromFrame(Object? message) {
    try {
      if (message is! String) {
        return null;
      }
      final decoded = jsonDecode(message);
      if (decoded is! Map || decoded['op'] != 'SERVER_DRAINING') {
        return null;
      }
      final data = decoded['d'];
      final delay = data is Map ? data['reconnectAfterMs'] : null;
      if (delay is int && delay >= 0) {
        return Duration(milliseconds: delay);
      }
      if (delay is num && delay >= 0) {
        return Duration(milliseconds: delay.round());
      }
      return Duration.zero;
    } catch (_) {
      return null;
    }
  }

  void _rememberRealtimeResumeFromFrame(Object? message) {
    try {
      String? sessionId;
      if (message is String) {
        final decoded = jsonDecode(message);
        if (decoded is Map &&
            (decoded['op'] == 'READY' || decoded['op'] == 'READY_DELTA')) {
          final data = decoded['d'];
          if (data is Map) {
            sessionId = _nullableString(data['sessionId']);
          }
        }
      } else if (message is List<int>) {
        final decoded = verdant_ws.WsMessage.fromBuffer(message);
        switch (decoded.whichPayload()) {
          case verdant_ws.WsMessage_Payload.ready:
            sessionId = _nullableString(decoded.ready.sessionId);
          case verdant_ws.WsMessage_Payload.readyDelta:
            sessionId = _nullableString(decoded.readyDelta.sessionId);
          default:
            break;
        }
      }
      if (sessionId == null || sessionId.isEmpty) {
        return;
      }
      _lastRealtimeSessionId = sessionId;
      _lastRealtimeReadyAt = DateTime.now().toUtc().toIso8601String();
    } catch (_) {
      return;
    }
  }

  Iterable<DirectMessagesRealtimeEvent> _eventsFromProtoEnvelope(
    verdant_ws.WsMessage envelope, {
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
  }) sync* {
    switch (envelope.whichPayload()) {
      case verdant_ws.WsMessage_Payload.ready:
        yield DirectMessagesSnapshotEvent(
          directMessagesDataFromReady(
            envelope.ready,
            networkId: networkId,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
            currentUserInitials: currentUserInitials,
          ),
        );
      case verdant_ws.WsMessage_Payload.readyDelta:
        for (final presence in envelope.readyDelta.presences) {
          final localUserId = _safeInboundLocalId(
            presence.userId,
            fallback: '',
            networkId: networkId,
          );
          if (localUserId == null) {
            continue;
          }
          yield DirectMessagesPresenceUpdateEvent(
            localUserId: localUserId,
            status: _normalizeStatus(
              _stringValue(presence.status, fallback: 'offline'),
            ),
          );
        }
      case verdant_ws.WsMessage_Payload.messageCreate:
        final message = envelope.messageCreate.message;
        final channelId = _safeScopedIdOrNull(networkId, message.channelId);
        final mappedMessage = _messageFromProtoOrNull(
          message,
          networkId: networkId,
          currentUserId: currentUserId,
        );
        if (channelId == null || mappedMessage == null) {
          return;
        }
        yield DirectMessagesMessageCreateEvent(
          channelId: channelId,
          message: mappedMessage,
        );
      case verdant_ws.WsMessage_Payload.messageUpdate:
        final message = envelope.messageUpdate.message;
        final channelId = _safeScopedIdOrNull(networkId, message.channelId);
        final mappedMessage = _messageFromProtoOrNull(
          message,
          networkId: networkId,
          currentUserId: currentUserId,
        );
        if (channelId == null || mappedMessage == null) {
          return;
        }
        yield DirectMessagesMessageUpdateEvent(
          channelId: channelId,
          message: mappedMessage,
        );
      case verdant_ws.WsMessage_Payload.messageDelete:
        final event = _messageDeleteEventFromProtoOrNull(
          envelope.messageDelete,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case verdant_ws.WsMessage_Payload.channelUnreadSignal:
        final event = _channelUnreadEventFromProtoOrNull(
          envelope.channelUnreadSignal,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case verdant_ws.WsMessage_Payload.channelActivityUpdate:
        final event = _channelActivityEventFromProtoOrNull(
          envelope.channelActivityUpdate,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case verdant_ws.WsMessage_Payload.typingStart:
        final event = _typingStartEventFromProtoOrNull(
          envelope.typingStart,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case verdant_ws.WsMessage_Payload.channelCreate:
        final event = _serverChannelUpsertEventFromProtoOrNull(
          envelope.channelCreate.channel,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case verdant_ws.WsMessage_Payload.channelUpdate:
        final event = _serverChannelUpsertEventFromProtoOrNull(
          envelope.channelUpdate.channel,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case verdant_ws.WsMessage_Payload.channelDelete:
        final event = _serverChannelDeleteEventFromProtoOrNull(
          envelope.channelDelete,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case verdant_ws.WsMessage_Payload.serverDelete:
        final event = _serverDeleteEventFromProtoOrNull(
          envelope.serverDelete,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case verdant_ws.WsMessage_Payload.memberJoin:
        final event = _serverMemberUpsertEventFromProtoOrNull(
          envelope.memberJoin,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case verdant_ws.WsMessage_Payload.memberRemove:
        final event = _serverMemberRemoveEventFromProtoOrNull(
          envelope.memberRemove,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case verdant_ws.WsMessage_Payload.memberRoleUpdate:
        final event = _serverMemberRoleUpdateEventFromProtoOrNull(
          envelope.memberRoleUpdate,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case verdant_ws.WsMessage_Payload.reactionAdd:
        final reaction = envelope.reactionAdd;
        final event = _reactionAddEventFromProtoOrNull(
          reaction,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case verdant_ws.WsMessage_Payload.reactionRemove:
        final reaction = envelope.reactionRemove;
        final event = _reactionRemoveEventFromProtoOrNull(
          reaction,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case verdant_ws.WsMessage_Payload.presenceUpdate:
        final localUserId = _safeInboundLocalId(
          envelope.presenceUpdate.userId,
          fallback: '',
          networkId: networkId,
        );
        if (localUserId == null) {
          return;
        }
        yield DirectMessagesPresenceUpdateEvent(
          localUserId: localUserId,
          status: _statusFromProto(envelope.presenceUpdate.status),
        );
      case verdant_ws.WsMessage_Payload.userProfileUpdate:
        final localUserId = _safeInboundLocalId(
          envelope.userProfileUpdate.userId,
          fallback: '',
          networkId: networkId,
        );
        if (localUserId == null) {
          return;
        }
        yield DirectMessagesUserProfileUpdateEvent(
          localUserId: localUserId,
          displayName: envelope.userProfileUpdate.hasDisplayName()
              ? _nullableString(envelope.userProfileUpdate.displayName)
              : workspaceEventUnset,
          avatarUrl: envelope.userProfileUpdate.hasAvatarUrl()
              ? _nullableString(envelope.userProfileUpdate.avatarUrl)
              : workspaceEventUnset,
          bannerUrl: envelope.userProfileUpdate.hasBannerUrl()
              ? _nullableString(envelope.userProfileUpdate.bannerUrl)
              : workspaceEventUnset,
          bannerBaseColor: envelope.userProfileUpdate.hasBannerBaseColor()
              ? _nullableString(envelope.userProfileUpdate.bannerBaseColor)
              : workspaceEventUnset,
          bio: envelope.userProfileUpdate.hasBio()
              ? _nullableString(envelope.userProfileUpdate.bio)
              : workspaceEventUnset,
        );
      case verdant_ws.WsMessage_Payload.relationshipAdd:
        final friend = _friendFromProtoRelationshipOrNull(
          envelope.relationshipAdd.relationship,
          networkId,
        );
        if (friend != null) {
          yield DirectMessagesRelationshipUpsertEvent(friend);
        }
      case verdant_ws.WsMessage_Payload.relationshipRemove:
        final localUserId = _safeInboundLocalId(
          envelope.relationshipRemove.userId,
          fallback: '',
          networkId: networkId,
        );
        if (localUserId != null) {
          yield DirectMessagesRelationshipRemoveEvent(localUserId: localUserId);
        }
      case verdant_ws.WsMessage_Payload.dmChannelCreate:
        final conversation = _conversationFromProtoDmChannelOrNull(
          envelope.dmChannelCreate.dmChannel,
          networkId: networkId,
          currentUserId: currentUserId,
        );
        if (conversation != null) {
          yield DirectMessagesConversationUpsertEvent(conversation);
        }
      case verdant_ws.WsMessage_Payload.batch:
        for (final nested in envelope.batch.messages) {
          yield* _eventsFromProtoEnvelope(
            nested,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
            currentUserInitials: currentUserInitials,
          );
        }
      case verdant_ws.WsMessage_Payload.wsError:
        throw _directMessagesWsError(envelope.wsError);
      default:
        return;
    }
  }

  Iterable<DirectMessagesRealtimeEvent> _eventsFromJsonEnvelope(
    Map<String, Object?> envelope, {
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
  }) sync* {
    final op = _nullableString(envelope['op']);
    if (op == null) {
      return;
    }
    final data = _mapValue(envelope['d']);
    switch (op) {
      case 'READY':
        if (data != null) {
          yield DirectMessagesSnapshotEvent(
            directMessagesDataFromReadyJson(
              data,
              networkId: networkId,
              currentUserId: currentUserId,
              currentUserName: currentUserName,
              currentUserInitials: currentUserInitials,
            ),
          );
        }
      case 'READY_DELTA':
        final rawPresences = data?['presences'];
        final presences = rawPresences is List
            ? rawPresences
            : const <Object?>[];
        for (final item in presences) {
          final presence = _mapValue(item);
          if (presence == null) {
            continue;
          }
          final localUserId = _safeInboundLocalId(
            presence['userId'],
            fallback: '',
            networkId: networkId,
          );
          if (localUserId == null) {
            continue;
          }
          yield DirectMessagesPresenceUpdateEvent(
            localUserId: localUserId,
            status: _normalizeStatus(
              _stringValue(presence['status'], fallback: 'offline'),
            ),
          );
        }
      case 'MESSAGE_CREATE':
        final messageJson = _mapValue(data?['message']) ?? data;
        if (messageJson == null) {
          return;
        }
        final localChannelId = _safeInboundLocalId(
          messageJson['channelId'],
          fallback: _stringValue(messageJson['channel_id'], fallback: ''),
          networkId: networkId,
        );
        final mappedMessage = _messageFromJsonOrNull(
          messageJson,
          networkId: networkId,
          currentUserId: currentUserId,
        );
        if (localChannelId == null || mappedMessage == null) {
          return;
        }
        yield DirectMessagesMessageCreateEvent(
          channelId: scopedWorkspaceId(networkId, localChannelId),
          message: mappedMessage,
        );
      case 'MESSAGE_UPDATE':
        final messageJson = _mapValue(data?['message']) ?? data;
        if (messageJson == null) {
          return;
        }
        final localChannelId = _safeInboundLocalId(
          messageJson['channelId'],
          fallback: _stringValue(messageJson['channel_id'], fallback: ''),
          networkId: networkId,
        );
        final mappedMessage = _messageFromJsonOrNull(
          messageJson,
          networkId: networkId,
          currentUserId: currentUserId,
        );
        if (localChannelId == null || mappedMessage == null) {
          return;
        }
        yield DirectMessagesMessageUpdateEvent(
          channelId: scopedWorkspaceId(networkId, localChannelId),
          message: mappedMessage,
        );
      case 'MESSAGE_DELETE':
        if (data == null) {
          return;
        }
        final event = _messageDeleteEventFromJsonOrNull(
          data,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case 'CHANNEL_UNREAD_SIGNAL':
        if (data == null) {
          return;
        }
        final event = _channelUnreadEventFromJsonOrNull(
          data,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case 'CHANNEL_ACTIVITY_UPDATE':
        if (data == null) {
          return;
        }
        final event = _channelActivityEventFromJsonOrNull(
          data,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case 'TYPING_START':
        if (data == null) {
          return;
        }
        final event = _typingStartEventFromJsonOrNull(
          data,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case 'CHANNEL_CREATE':
      case 'CHANNEL_UPDATE':
        final channelJson = _mapValue(data?['channel']) ?? data;
        if (channelJson == null) {
          return;
        }
        final event = _serverChannelUpsertEventFromJsonOrNull(
          channelJson,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case 'CHANNEL_DELETE':
        if (data == null) {
          return;
        }
        final event = _serverChannelDeleteEventFromJsonOrNull(
          data,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case 'SERVER_DELETE':
        if (data == null) {
          return;
        }
        final event = _serverDeleteEventFromJsonOrNull(
          data,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case 'MEMBER_JOIN':
        if (data == null) {
          return;
        }
        final event = _serverMemberUpsertEventFromJsonOrNull(
          data,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case 'MEMBER_REMOVE':
        if (data == null) {
          return;
        }
        final event = _serverMemberRemoveEventFromJsonOrNull(
          data,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case 'MEMBER_ROLE_UPDATE':
        if (data == null) {
          return;
        }
        final event = _serverMemberRoleUpdateEventFromJsonOrNull(
          data,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case 'REACTION_ADD':
        if (data == null) {
          return;
        }
        final event = _reactionAddEventFromJsonOrNull(
          data,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case 'REACTION_REMOVE':
        if (data == null) {
          return;
        }
        final event = _reactionRemoveEventFromJsonOrNull(
          data,
          networkId: networkId,
        );
        if (event != null) {
          yield event;
        }
      case 'PRESENCE_UPDATE':
        if (data == null) {
          return;
        }
        final localUserId = _safeInboundLocalId(
          data['userId'],
          fallback: '',
          networkId: networkId,
        );
        if (localUserId == null) {
          return;
        }
        yield DirectMessagesPresenceUpdateEvent(
          localUserId: localUserId,
          status: _normalizeStatus(
            _stringValue(data['status'], fallback: 'offline'),
          ),
        );
      case 'BOT_PRESENCE_UPDATE':
        if (data == null) {
          return;
        }
        final localBotId = _safeInboundLocalId(
          data['botId'],
          fallback: _stringValue(data['bot_id'], fallback: ''),
          networkId: networkId,
        );
        final localServerId = _safeInboundLocalId(
          data['serverId'],
          fallback: _stringValue(data['server_id'], fallback: ''),
          networkId: networkId,
        );
        if (localBotId == null || localServerId == null) {
          return;
        }
        yield DirectMessagesBotPresenceUpdateEvent(
          localBotId: localBotId,
          serverId: scopedWorkspaceId(networkId, localServerId),
          status: _normalizeStatus(
            _stringValue(data['status'], fallback: 'offline'),
          ),
        );
      case 'USER_PROFILE_UPDATE':
        if (data == null) {
          return;
        }
        final localUserId = _safeInboundLocalId(
          data['userId'],
          fallback: _stringValue(data['user_id'], fallback: ''),
          networkId: networkId,
        );
        if (localUserId == null) {
          return;
        }
        yield DirectMessagesUserProfileUpdateEvent(
          localUserId: localUserId,
          displayName: data.containsKey('displayName')
              ? _nullableString(data['displayName'])
              : workspaceEventUnset,
          avatarUrl: data.containsKey('avatarUrl')
              ? _nullableString(data['avatarUrl'])
              : workspaceEventUnset,
          bannerUrl: data.containsKey('bannerUrl')
              ? _nullableString(data['bannerUrl'])
              : workspaceEventUnset,
          bannerBaseColor: data.containsKey('bannerBaseColor')
              ? _nullableString(data['bannerBaseColor'])
              : workspaceEventUnset,
          bio: data.containsKey('bio')
              ? _nullableString(data['bio'])
              : workspaceEventUnset,
        );
      case 'PRESENCE_BATCH':
        final rawPresences = data?['presences'];
        final presences = rawPresences is List
            ? rawPresences
            : const <Object?>[];
        for (final item in presences) {
          final presence = _mapValue(item);
          if (presence == null) {
            continue;
          }
          final localUserId = _safeInboundLocalId(
            presence['userId'],
            fallback: _stringValue(presence['user_id'], fallback: ''),
            networkId: networkId,
          );
          if (localUserId == null) {
            continue;
          }
          yield DirectMessagesPresenceUpdateEvent(
            localUserId: localUserId,
            status: _normalizeStatus(
              _stringValue(presence['status'], fallback: 'offline'),
            ),
          );
        }
      case 'RELATIONSHIP_ADD':
        if (data == null) {
          return;
        }
        final friend = _friendFromRelationshipOrNull(data, networkId);
        if (friend != null) {
          yield DirectMessagesRelationshipUpsertEvent(friend);
        }
      case 'RELATIONSHIP_REMOVE':
        if (data == null) {
          return;
        }
        final localUserId = _safeInboundLocalId(
          data['userId'],
          fallback: _stringValue(data['user_id'], fallback: ''),
          networkId: networkId,
        );
        if (localUserId != null) {
          yield DirectMessagesRelationshipRemoveEvent(localUserId: localUserId);
        }
      case 'DM_CHANNEL_CREATE':
        if (data == null) {
          return;
        }
        final conversation = _conversationFromDmChannelOrNull(
          data,
          networkId: networkId,
          currentUserId: currentUserId,
        );
        if (conversation != null) {
          yield DirectMessagesConversationUpsertEvent(conversation);
        }
      case 'WS_ERROR':
        final message =
            _nullableString(data?['error']) ?? 'Realtime session failed';
        throw DirectMessagesException(
          message,
          canRefreshCredentials: _isRefreshableRealtimeError(message),
        );
      default:
        return;
    }
  }

  String _nonSecretRealtimeError(verdant_ws.WsError error) {
    final message = error.error.trim();
    if (message.isNotEmpty) {
      return message;
    }
    final code = error.code.trim();
    return code.isEmpty ? 'Realtime session failed' : code;
  }

  DirectMessagesException _directMessagesWsError(verdant_ws.WsError error) {
    final message = _nonSecretRealtimeError(error);
    return DirectMessagesException(
      message,
      canRefreshCredentials: _isRefreshableRealtimeError(message),
    );
  }

  bool _isRefreshableRealtimeClose(int? closeCode, String? closeReason) {
    return closeCode == 4004 || _isRefreshableRealtimeError(closeReason);
  }

  bool _isRefreshableRealtimeError(String? message) {
    final normalized = message?.trim().toLowerCase();
    return normalized == 'invalid token' ||
        normalized == 'authentication required' ||
        normalized == 'authentication timeout';
  }

  Duration _liveReconnectDelay(int attempt, {Duration? plannedDelay}) {
    if (plannedDelay != null) {
      return plannedDelay <= const Duration(seconds: 5)
          ? plannedDelay
          : const Duration(seconds: 5);
    }
    final boundedAttempt = attempt < 0 ? 0 : (attempt > 5 ? 5 : attempt);
    final multiplier = 1 << boundedAttempt;
    final delay = minReconnectDelay * multiplier;
    return delay <= maxReconnectDelay ? delay : maxReconnectDelay;
  }

  int _clientWebSocketCloseCode(int? statusCode) {
    final code = statusCode ?? ws_status.normalClosure;
    if (code == ws_status.normalClosure || (code >= 3000 && code <= 4999)) {
      return code;
    }
    return ws_status.normalClosure;
  }

  String _safeWebSocketCloseReason(String? reason) {
    final trimmed = reason?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '';
    }
    const allowedReasons = {
      'Account banned',
      'Authentication required',
      'Authentication timeout',
      'Client outdated',
      'Database unavailable',
      'Email verification required',
      'Invalid token',
      'Payload too large',
      'Rate limit exceeded',
      'Server draining',
      'Server restarting',
      'Slow client',
      'Too many IDENTIFY requests',
      'Too many connections',
      'User not found',
    };
    return allowedReasons.contains(trimmed) ? trimmed : 'redacted';
  }

  Uri _webSocketUri() {
    final uri = Uri.parse(apiOrigin);
    final scheme = switch (uri.scheme) {
      'https' => 'wss',
      'http' => 'ws',
      _ => throw const DirectMessagesException('Invalid realtime origin'),
    };
    return uri.replace(scheme: scheme, path: '/ws');
  }

  void _recordDiagnostic(String event, Map<String, Object?> fields) {
    debugPrint('verdant.dm $event ${sanitizeAuthDiagnosticFields(fields)}');
  }

  @override
  String toString() {
    return 'VerdantDirectMessagesService(apiOrigin: $apiOrigin, token: redacted)';
  }
}

final class HttpDirectMessagesService
    implements DirectMessagesRepository, WorkspaceMessageMutationRepository {
  HttpDirectMessagesService({
    required String apiOrigin,
    required this.credentialStore,
    AuthService? authService,
    HttpClient? httpClient,
    CertificatePinningPolicy? certificatePinningPolicy,
    this.timeout = const Duration(seconds: 15),
    this.maxResponseBytes = 1024 * 1024,
  }) : _certificatePinningPolicy =
           certificatePinningPolicy ??
           CertificatePinningPolicy.fromEnvironment(),
       _httpClient =
           httpClient ??
           (certificatePinningPolicy ??
                   CertificatePinningPolicy.fromEnvironment())
               .createHttpClient(),
       _credentialRefresher = WorkspaceCredentialRefresher(
         apiOrigin: apiOrigin,
         credentialStore: credentialStore,
         authService: authService,
         certificatePinningPolicy: certificatePinningPolicy,
         timeout: timeout,
       ),
       apiOrigin = normalizeBackendApiOrigin(apiOrigin);

  final String apiOrigin;
  final AuthCredentialStore credentialStore;
  final HttpClient _httpClient;
  final CertificatePinningPolicy _certificatePinningPolicy;
  final WorkspaceCredentialRefresher _credentialRefresher;
  final Duration timeout;
  final int maxResponseBytes;

  String get networkId => networkIdFromApiOrigin(apiOrigin);

  @override
  Future<DirectMessagesWorkspaceData> loadDirectMessages({
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
  }) async {
    final results = await Future.wait<Object?>([
      _jsonRequest('GET', '/api/users/me/relationships'),
      _jsonRequest('GET', '/api/dms?includePreferences=true'),
    ]);
    final relationships = results[0];
    final dmResponse = results[1];
    if (relationships is! List) {
      throw const DirectMessagesException('Relationship response was invalid');
    }
    final dmBootstrap = _directMessagesBootstrapFromRest(dmResponse, networkId);
    if (dmBootstrap == null) {
      throw const DirectMessagesException('DM response was invalid');
    }

    final friends = [
      for (final item in relationships)
        if (_mapValue(item) case final map?)
          ?_friendFromRelationshipOrNull(map, networkId),
    ]..sort(_sortFriends);

    final conversations = [
      for (final item in dmBootstrap.channels)
        if (_mapValue(item) case final map?)
          ?_conversationFromDmChannelOrNull(
            map,
            networkId: networkId,
            currentUserId: currentUserId,
          ),
    ]..sort(_sortConversations);

    return DirectMessagesWorkspaceData(
      networkId: networkId,
      currentUserName: currentUserName,
      currentUserInitials: currentUserInitials,
      conversations: conversations,
      friends: friends,
      hiddenChannelIds: dmBootstrap.hiddenChannelIds,
    );
  }

  @override
  Future<Set<String>> loadHiddenChannelIds() async {
    _recordDiagnostic('hidden_prefs.load.start', {
      'networkId': networkId,
      'apiOrigin': apiOrigin,
    });
    try {
      final decoded = await _jsonRequest('GET', '/api/users/me');
      final map = _mapValue(decoded);
      if (map == null) {
        _recordDiagnostic('hidden_prefs.load.failure', {
          'networkId': networkId,
          'apiOrigin': apiOrigin,
          'reason': 'invalid_user_response',
        });
        throw const DirectMessagesException('User response was invalid');
      }
      if (!map.containsKey('preferences')) {
        _recordDiagnostic('hidden_prefs.load.failure', {
          'networkId': networkId,
          'apiOrigin': apiOrigin,
          'reason': 'preferences_missing',
        });
        throw const DirectMessagesException(
          'Direct message preferences are unavailable',
        );
      }
      final preferences = _mapValue(map['preferences']);
      if (preferences == null) {
        _recordDiagnostic('hidden_prefs.load.failure', {
          'networkId': networkId,
          'apiOrigin': apiOrigin,
          'reason': 'preferences_invalid',
        });
        throw const DirectMessagesException(
          'Direct message preferences were invalid',
        );
      }
      final rawHidden = preferences['hiddenDmIds'];
      if (rawHidden is! List) {
        _recordDiagnostic('hidden_prefs.load.success', {
          'networkId': networkId,
          'apiOrigin': apiOrigin,
          'hiddenCount': 0,
          'fieldPresent': preferences.containsKey('hiddenDmIds'),
        });
        return {};
      }
      final hidden = {
        for (final item in rawHidden)
          if (item is String)
            if (_safeHiddenDmLocalIdOrNull(item) case final localId?)
              scopedWorkspaceId(networkId, localId),
      };
      _recordDiagnostic('hidden_prefs.load.success', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'hiddenCount': hidden.length,
        'rawCount': rawHidden.length,
        'fieldPresent': true,
      });
      return hidden;
    } catch (error) {
      if (error is! DirectMessagesException) {
        _recordDiagnostic('hidden_prefs.load.failure', {
          'networkId': networkId,
          'apiOrigin': apiOrigin,
          'reason': 'unexpected',
          'errorType': error.runtimeType.toString(),
        });
      }
      rethrow;
    }
  }

  @override
  Future<void> saveHiddenChannelIds({required Set<String> channelIds}) async {
    final localIds = <String>{};
    for (final channelId in channelIds) {
      final localId = _safeHiddenDmScopedLocalIdOrNull(networkId, channelId);
      if (localId != null) {
        localIds.add(localId);
      }
    }
    final sortedLocalIds = localIds.toList(growable: false)..sort();
    _recordDiagnostic('hidden_prefs.save.start', {
      'networkId': networkId,
      'apiOrigin': apiOrigin,
      'hiddenCount': sortedLocalIds.length,
      'inputCount': channelIds.length,
    });
    try {
      await _jsonRequest(
        'PATCH',
        '/api/users/me/preferences',
        body: {'hiddenDmIds': sortedLocalIds},
      );
      _recordDiagnostic('hidden_prefs.save.success', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'hiddenCount': sortedLocalIds.length,
      });
    } catch (error) {
      _recordDiagnostic('hidden_prefs.save.failure', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'hiddenCount': sortedLocalIds.length,
        'reason': error is DirectMessagesException
            ? error.message
            : 'unexpected',
        'errorType': error.runtimeType.toString(),
      });
      rethrow;
    }
  }

  @override
  Future<void> sendFriendRequest({required String username}) async {
    final trimmed = sanitizeUsernameInput(username);
    if (trimmed.isEmpty) {
      throw const DirectMessagesException('Enter a username');
    }
    await _jsonRequest(
      'POST',
      '/api/users/me/relationships',
      body: {'username': trimmed},
    );
  }

  @override
  Future<void> acceptFriendRequest({required String localUserId}) async {
    final id = _safeLocalId(localUserId);
    await _jsonRequest(
      'PATCH',
      '/api/users/me/relationships/${Uri.encodeComponent(id)}',
      body: {'type': 1},
    );
  }

  @override
  Future<void> removeRelationship({required String localUserId}) async {
    final id = _safeLocalId(localUserId);
    await _jsonRequest(
      'DELETE',
      '/api/users/me/relationships/${Uri.encodeComponent(id)}',
    );
  }

  @override
  Future<DmConversationPreviewSeed> openDirectMessage({
    required String localUserId,
    required String currentUserId,
  }) async {
    final id = _safeLocalId(localUserId);
    final decoded = await _jsonRequest(
      'POST',
      '/api/dms',
      body: {
        'recipientIds': [id],
      },
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const DirectMessagesException('DM response was invalid');
    }
    return _conversationFromDmChannel(
      map,
      networkId: networkId,
      currentUserId: currentUserId,
    );
  }

  @override
  Future<DmConversationMessages> loadConversationMessages({
    required DmConversationPreviewSeed conversation,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    final id = _safeLocalId(conversation.localChannelId);
    final before = beforeMessageId == null
        ? null
        : safeWorkspaceLocalId(beforeMessageId, allowScopedPrefix: true);
    final safeLimit = limit.clamp(1, 50).toInt();
    final stopwatch = Stopwatch()..start();
    try {
      final query = <String, String>{'limit': safeLimit.toString()};
      if (before != null) {
        query['before'] = before;
      }
      final queryString = Uri(queryParameters: query).query;
      final decoded = await _jsonRequest(
        'GET',
        '/api/channels/${Uri.encodeComponent(id)}/messages?$queryString',
      );
      if (decoded is! List) {
        throw const DirectMessagesException('Message response was invalid');
      }
      final rows = <({int index, Map<String, Object?> map})>[];
      for (var index = 0; index < decoded.length; index += 1) {
        final map = _mapValue(decoded[index]);
        if (map != null) {
          rows.add((index: index, map: map));
        }
      }
      rows.sort(_messageRowOldestFirst);
      final messages = [
        for (final row in rows)
          _messageFromJson(
            row.map,
            networkId: networkId,
            currentUserId: currentUserId,
          ),
      ];
      _recordDiagnostic('messages.load.success', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'channelId': conversation.channelId,
        'localChannelId': id,
        'limit': safeLimit,
        'hasBefore': before != null,
        'messageCount': messages.length,
        'ms': stopwatch.elapsedMilliseconds,
      });
      return DmConversationMessages(
        channelId: conversation.channelId,
        messages: messages,
      );
    } catch (error) {
      _recordDiagnostic('messages.load.failure', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'channelId': conversation.channelId,
        'localChannelId': id,
        'limit': safeLimit,
        'hasBefore': before != null,
        'reason': error is DirectMessagesException
            ? error.message
            : 'Message history failed',
        'ms': stopwatch.elapsedMilliseconds,
      });
      rethrow;
    }
  }

  @override
  Future<void> deleteChannelMessage({
    required String channelId,
    required String messageId,
  }) async {
    final channel = _safeMessageRouteLocalId(networkId, channelId);
    final message = _safeMessageRouteLocalId(networkId, messageId);
    await _jsonRequest(
      'DELETE',
      '/api/channels/${Uri.encodeComponent(channel)}/messages/${Uri.encodeComponent(message)}',
    );
  }

  @override
  Stream<DirectMessagesRealtimeEvent> connectRealtime({
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
    required String currentUserStatus,
  }) {
    return const Stream.empty();
  }

  void close() {
    _httpClient.close(force: true);
    _credentialRefresher.close();
  }

  Future<Object?> _jsonRequest(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    var credentials = await _readCredentials();
    for (var attempt = 0; attempt < 2; attempt += 1) {
      final request = await _openRequest(method, path, credentials);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(timeout);
      _certificatePinningPolicy.verifyResponseCertificate(
        apiOrigin: apiOrigin,
        response: response,
      );
      final decoded = await _decodeJsonResponse(response);
      if (response.statusCode == HttpStatus.unauthorized && attempt == 0) {
        credentials = await _refreshCredentials(credentials);
        continue;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DirectMessagesException(
          _errorMessage(response.statusCode, decoded, 'Request failed'),
        );
      }
      return decoded;
    }
    throw const DirectMessagesException('Request failed');
  }

  Future<HttpClientRequest> _openRequest(
    String method,
    String path,
    AuthCredentialBundle credentials,
  ) async {
    _assertApiPath(path);

    await _certificatePinningPolicy.verifyPinnedHost(
      httpClient: _httpClient,
      apiOrigin: apiOrigin,
      timeout: timeout,
    );
    final request = await _httpClient
        .openUrl(method, Uri.parse('$apiOrigin$path'))
        .timeout(timeout);
    request.followRedirects = false;
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${credentials.accessToken}',
    );
    request.headers.set(HttpHeaders.userAgentHeader, verdantFlutterUserAgent);
    request.headers.set('X-Client-Version', verdantClientVersion);
    return request;
  }

  Future<AuthCredentialBundle> _readCredentials() async {
    try {
      return await _credentialRefresher.readCredentials();
    } on WorkspaceCredentialRefreshException catch (error) {
      throw DirectMessagesException(error.message);
    }
  }

  Future<AuthCredentialBundle> _refreshCredentials(
    AuthCredentialBundle credentials,
  ) async {
    try {
      return await _credentialRefresher.refresh(credentials);
    } on WorkspaceCredentialRefreshException catch (error) {
      throw DirectMessagesException(error.message);
    }
  }

  void _recordDiagnostic(String event, Map<String, Object?> fields) {
    debugPrint('verdant.dm $event ${sanitizeAuthDiagnosticFields(fields)}');
  }

  Future<Object?> _decodeJsonResponse(HttpClientResponse response) async {
    final buffer = StringBuffer();
    var length = 0;
    await for (final chunk in utf8.decoder.bind(response)) {
      length += chunk.length;
      if (length > maxResponseBytes) {
        throw const DirectMessagesException('Server response was too large');
      }
      buffer.write(chunk);
    }

    final text = buffer.toString();
    if (text.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(text);
    } on FormatException {
      if (response.statusCode >= 400) {
        return {'error': text.trim()};
      }
      throw const DirectMessagesException('Invalid server response');
    }
  }

  String _errorMessage(int statusCode, Object? decoded, String fallback) {
    if (decoded is Map<String, Object?>) {
      final error = decoded['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return switch (statusCode) {
      401 => 'Sign in again to continue',
      403 => 'You do not have permission to view relationships',
      404 => 'Relationship was not found',
      429 => 'Too many requests. Try again shortly.',
      _ => fallback,
    };
  }

  void _assertApiPath(String path) {
    final uri = Uri.tryParse(path);
    if (uri == null ||
        !path.startsWith('/api/') ||
        uri.hasScheme ||
        uri.host.isNotEmpty ||
        uri.hasFragment ||
        path.contains('\\') ||
        path.contains('\u0000')) {
      throw const DirectMessagesException('Invalid API path');
    }
  }

  @override
  String toString() {
    return 'HttpDirectMessagesService(apiOrigin: $apiOrigin, token: redacted)';
  }
}

String? _safeHiddenDmLocalIdOrNull(String value) {
  try {
    final id = safeWorkspaceLocalId(value);
    if (id.length > 160) {
      return null;
    }
    return id;
  } on FormatException {
    return null;
  }
}

String? _safeHiddenDmScopedLocalIdOrNull(String networkId, String value) {
  if (!isSafeScopedWorkspaceId(value, networkId: networkId)) {
    return null;
  }
  final slash = value.indexOf('/');
  if (slash <= 0 || slash == value.length - 1) {
    return null;
  }
  return _safeHiddenDmLocalIdOrNull(value.substring(slash + 1));
}
