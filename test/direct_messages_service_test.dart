import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_credentials.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_models.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_service.dart';
import 'package:verdant_flutter/generated/verdant/models.pb.dart'
    as verdant_models;
import 'package:verdant_flutter/generated/verdant/ws.pb.dart' as verdant_ws;

void main() {
  test('protobuf READY entitlements hydrate direct messages data', () {
    final data = directMessagesDataFromReady(
      verdant_ws.Ready(
        userStatus: 'online',
        entitlementsJson: jsonEncode({
          'imageUploads': true,
          'memberListBanner': true,
          'officialSubscriptionActive': true,
          'maxUploadBytes': 5242880,
        }),
      ),
      networkId: 'official',
      currentUserId: '42',
      currentUserName: 'Joshy',
      currentUserInitials: 'JO',
    );

    expect(data.entitlements.imageUploads, isTrue);
    expect(data.entitlements.memberListBanner, isTrue);
    expect(data.entitlements.officialSubscriptionActive, isTrue);
    expect(data.entitlements.maxUploadBytes, 5242880);
  });

  test('protobuf READY hidden DM preferences hydrate as scoped ids', () {
    final data = directMessagesDataFromReady(
      verdant_ws.Ready(
        userStatus: 'online',
        preferencesJson: jsonEncode({
          'hiddenDmIds': [
            'dm-avery',
            'official/dm-should-stay-local',
            'dm/poison',
          ],
        }),
      ),
      networkId: 'official',
      currentUserId: '42',
      currentUserName: 'Joshy',
      currentUserInitials: 'JO',
    );

    expect(data.hiddenChannelIds, {'official/dm-avery'});
  });

  test('JSON READY entitlements hydrate direct messages data', () {
    final data = directMessagesDataFromReadyJson(
      {
        'userStatus': 'online',
        'entitlements': {
          'imageUploads': true,
          'memberListBanner': false,
          'animatedAvatar': true,
        },
      },
      networkId: 'official',
      currentUserId: '42',
      currentUserName: 'Joshy',
      currentUserInitials: 'JO',
    );

    expect(data.entitlements.imageUploads, isTrue);
    expect(data.entitlements.memberListBanner, isFalse);
    expect(data.entitlements.animatedAvatar, isTrue);
  });

  test('JSON READY hidden DM preferences hydrate as scoped ids', () {
    final data = directMessagesDataFromReadyJson(
      {
        'userStatus': 'online',
        'preferences': {
          'hiddenDmIds': [
            'dm-avery',
            'official/dm-should-stay-local',
            'dm/poison',
          ],
        },
      },
      networkId: 'official',
      currentUserId: '42',
      currentUserName: 'Joshy',
      currentUserInitials: 'JO',
    );

    expect(data.hiddenChannelIds, {'official/dm-avery'});
  });

  test(
    'READY falls back to instance capabilities for self-host entitlements',
    () {
      final data = directMessagesDataFromReady(
        verdant_ws.Ready(
          userStatus: 'online',
          entitlementsJson: jsonEncode({}),
          instanceJson: jsonEncode({
            'capabilities': {
              'imageUploads': true,
              'fileSharing': true,
              'messageAttachments': true,
              'animatedAvatar': true,
              'animatedBanner': true,
              'memberListBanner': true,
              'maxUploadBytes': 26214400,
            },
          }),
        ),
        networkId: 'official',
        currentUserId: '42',
        currentUserName: 'Joshy',
        currentUserInitials: 'JO',
      );

      expect(data.entitlements.imageUploads, isTrue);
      expect(data.entitlements.fileSharing, isTrue);
      expect(data.entitlements.messageAttachments, isTrue);
      expect(data.entitlements.animatedAvatar, isTrue);
      expect(data.entitlements.animatedBanner, isTrue);
      expect(data.entitlements.memberListBanner, isTrue);
      expect(data.entitlements.maxUploadBytes, 26214400);
    },
  );

  test(
    'loads full direct message history with the default page size',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final apiOrigin = 'http://127.0.0.1:${server.port}';
      final requestedUris = <Uri>[];
      final credentialStore = _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: apiOrigin,
      );

      final serverSubscription = server.listen((request) async {
        requestedUris.add(request.uri);
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/api/channels/dm-avery/messages') {
          request.response.write(
            jsonEncode([
              _messageJson(
                id: 'message-newer',
                authorId: '42',
                content: 'newer dm message',
                createdAt: '2026-06-03T22:02:00Z',
              ),
              _messageJson(
                id: 'message-older',
                authorId: '181',
                content: 'older dm message',
                createdAt: '2026-06-03T22:01:00Z',
              ),
            ]),
          );
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write(jsonEncode({'error': 'not found'}));
        }
        await request.response.close();
      });
      addTearDown(() async {
        await serverSubscription.cancel();
        await server.close(force: true);
      });

      final service = VerdantDirectMessagesService(
        apiOrigin: apiOrigin,
        credentialStore: credentialStore,
        timeout: const Duration(seconds: 2),
      );
      addTearDown(service.close);

      final messages = await service.loadConversationMessages(
        conversation: const DmConversationPreviewSeed(
          channelId: 'official/dm-avery',
          localChannelId: 'dm-avery',
          networkId: 'official',
          displayName: 'Avery',
          initials: 'AV',
          status: 'Online',
          lastMessage: 'Preview',
        ),
        currentUserId: '42',
      );

      expect(requestedUris.single.queryParameters['limit'], '50');
      expect(messages.messages.map((message) => message.body), [
        'older dm message',
        'newer dm message',
      ]);
    },
  );

  test('deletes direct messages through the scoped channel route', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final apiOrigin = 'http://127.0.0.1:${server.port}';
    final requestedUris = <Uri>[];
    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: apiOrigin,
    );

    final serverSubscription = server.listen((request) async {
      requestedUris.add(request.uri);
      request.response.headers.contentType = ContentType.json;
      expect(request.method, 'DELETE');
      expect(request.uri.path, '/api/channels/dm-avery/messages/message-1');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access-secret',
      );
      request.response.write(jsonEncode({'success': true}));
      await request.response.close();
    });
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });

    final service = VerdantDirectMessagesService(
      apiOrigin: apiOrigin,
      credentialStore: credentialStore,
      timeout: const Duration(seconds: 2),
    );
    addTearDown(service.close);
    final networkId = networkIdFromApiOrigin(apiOrigin);

    await service.deleteChannelMessage(
      channelId: '$networkId/dm-avery',
      messageId: '$networkId/message-1',
    );

    expect(requestedUris.single.query, isEmpty);
  });

  test(
    'loads backend hidden direct message preferences as scoped ids',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final apiOrigin = 'http://127.0.0.1:${server.port}';
      final credentialStore = _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: apiOrigin,
      );
      final networkId = networkIdFromApiOrigin(apiOrigin);
      final requestedUris = <Uri>[];

      final serverSubscription = server.listen((request) async {
        requestedUris.add(request.uri);
        request.response.headers.contentType = ContentType.json;
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/users/me');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        request.response.write(
          jsonEncode({
            'id': '42',
            'username': 'boji',
            'preferences': {
              'hiddenDmIds': [
                'dm-avery',
                '$networkId/dm-should-stay-local-only',
                'bad/id/value',
              ],
            },
          }),
        );
        await request.response.close();
      });
      addTearDown(() async {
        await serverSubscription.cancel();
        await server.close(force: true);
      });

      final service = VerdantDirectMessagesService(
        apiOrigin: apiOrigin,
        credentialStore: credentialStore,
        timeout: const Duration(seconds: 2),
      );
      addTearDown(service.close);

      final hidden = await service.loadHiddenChannelIds();

      expect(hidden, {'$networkId/dm-avery'});
      expect(requestedUris.single.query, isEmpty);
    },
  );

  test('rejects missing backend hidden direct message preferences', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final apiOrigin = 'http://127.0.0.1:${server.port}';
    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: apiOrigin,
    );

    final serverSubscription = server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/users/me');
      request.response.write(jsonEncode({'id': '42', 'username': 'boji'}));
      await request.response.close();
    });
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });

    final service = VerdantDirectMessagesService(
      apiOrigin: apiOrigin,
      credentialStore: credentialStore,
      timeout: const Duration(seconds: 2),
    );
    addTearDown(service.close);

    await expectLater(
      service.loadHiddenChannelIds(),
      throwsA(isA<DirectMessagesException>()),
    );
  });

  test(
    'saves backend hidden direct message preferences as local ids only',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final apiOrigin = 'http://127.0.0.1:${server.port}';
      final credentialStore = _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: apiOrigin,
      );
      final networkId = networkIdFromApiOrigin(apiOrigin);
      final otherNetworkId = networkIdFromApiOrigin('https://api.other.test');
      Map<String, Object?>? capturedBody;

      final serverSubscription = server.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        expect(request.method, 'PATCH');
        expect(request.uri.path, '/api/users/me/preferences');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        capturedBody =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, Object?>;
        request.response.write(jsonEncode({'preferences': capturedBody}));
        await request.response.close();
      });
      addTearDown(() async {
        await serverSubscription.cancel();
        await server.close(force: true);
      });

      final service = VerdantDirectMessagesService(
        apiOrigin: apiOrigin,
        credentialStore: credentialStore,
        timeout: const Duration(seconds: 2),
      );
      addTearDown(service.close);

      await service.saveHiddenChannelIds(
        channelIds: {
          '$networkId/dm-avery',
          '$otherNetworkId/dm-other',
          '$networkId/dm/poison',
          'raw-dm',
        },
      );

      expect(capturedBody, {
        'hiddenDmIds': ['dm-avery'],
      });
    },
  );

  test(
    'rejects mismatched scoped direct message delete routes before egress',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final apiOrigin = 'http://127.0.0.1:${server.port}';
      var requestCount = 0;
      final credentialStore = _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: apiOrigin,
      );

      final serverSubscription = server.listen((request) async {
        requestCount += 1;
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      });
      addTearDown(() async {
        await serverSubscription.cancel();
        await server.close(force: true);
      });

      final service = VerdantDirectMessagesService(
        apiOrigin: apiOrigin,
        credentialStore: credentialStore,
        timeout: const Duration(seconds: 2),
      );
      addTearDown(service.close);
      final networkId = networkIdFromApiOrigin(apiOrigin);
      final otherNetworkId = networkIdFromApiOrigin('https://api.other.test');

      await expectLater(
        service.deleteChannelMessage(
          channelId: '$otherNetworkId/dm-avery',
          messageId: '$networkId/message-1',
        ),
        throwsA(
          isA<DirectMessagesException>().having(
            (error) => error.message,
            'message',
            'Invalid message route',
          ),
        ),
      );

      await expectLater(
        service.deleteChannelMessage(
          channelId: '$networkId/dm-avery',
          messageId: '$otherNetworkId/message-1',
        ),
        throwsA(
          isA<DirectMessagesException>().having(
            (error) => error.message,
            'message',
            'Invalid message route',
          ),
        ),
      );

      expect(requestCount, 0);
    },
  );

  test(
    'loads direct message lists over REST without opening a snapshot websocket',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final apiOrigin = 'http://127.0.0.1:${server.port}';
      final requestedUris = <Uri>[];
      var websocketAttempts = 0;
      final credentialStore = _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: apiOrigin,
      );
      final serverSubscription = server.listen((request) async {
        if (request.uri.path == '/ws') {
          websocketAttempts += 1;
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
          return;
        }

        requestedUris.add(request.uri);
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/api/users/me/relationships') {
          request.response.write(
            jsonEncode([
              {
                'userId': '181051381515448320',
                'type': 1,
                'user': {
                  'id': '181051381515448320',
                  'username': 'Joshy',
                  'displayName': 'Joshy',
                  'status': 'online',
                },
              },
            ]),
          );
        } else if (request.uri.path == '/api/dms') {
          request.response.write(
            jsonEncode([
              {
                'id': '181215028619407360',
                'participants': [
                  {'id': '42', 'username': 'boji'},
                  {
                    'id': '181051381515448320',
                    'username': 'Joshy',
                    'displayName': 'Joshy',
                    'status': 'online',
                  },
                ],
                'lastMessageAt': '2026-06-03T22:00:00Z',
              },
            ]),
          );
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write(jsonEncode({'error': 'not found'}));
        }
        await request.response.close();
      });
      addTearDown(() async {
        await serverSubscription.cancel();
        await server.close(force: true);
      });

      final service = VerdantDirectMessagesService(
        apiOrigin: apiOrigin,
        credentialStore: credentialStore,
        timeout: const Duration(seconds: 2),
      );
      addTearDown(service.close);

      final snapshot = await service.loadDirectMessages(
        currentUserId: '42',
        currentUserName: 'boji',
        currentUserInitials: 'BO',
      );

      expect(snapshot.friends.single.localUserId, '181051381515448320');
      expect(snapshot.conversations.single.channelId, contains('181215'));
      expect(requestedUris.map((uri) => uri.path), [
        '/api/users/me/relationships',
        '/api/dms',
      ]);
      expect(websocketAttempts, 0);
      expect(credentialStore.clearCount, 0);
    },
  );

  test('loads hidden DM preferences from REST bootstrap snapshot', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final apiOrigin = 'http://127.0.0.1:${server.port}';
    final requestedUris = <Uri>[];
    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: apiOrigin,
    );
    final networkId = networkIdFromApiOrigin(apiOrigin);

    final serverSubscription = server.listen((request) async {
      requestedUris.add(request.uri);
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/api/users/me/relationships') {
        request.response.write(jsonEncode([]));
      } else if (request.uri.path == '/api/dms') {
        request.response.write(
          jsonEncode({
            'dmChannels': [
              {
                'id': '181215028619407360',
                'participants': [
                  {'id': '42', 'username': 'boji'},
                  {
                    'id': '181051381515448320',
                    'username': 'Joshy',
                    'displayName': 'Joshy',
                    'status': 'online',
                  },
                ],
                'lastMessageAt': '2026-06-03T22:00:00Z',
              },
            ],
            'hiddenDmIds': [
              '181215028619407360',
              '$networkId/dm-should-stay-local-only',
              'bad/id/value',
            ],
          }),
        );
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(jsonEncode({'error': 'not found'}));
      }
      await request.response.close();
    });
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });

    final service = VerdantDirectMessagesService(
      apiOrigin: apiOrigin,
      credentialStore: credentialStore,
      timeout: const Duration(seconds: 2),
    );
    addTearDown(service.close);

    final snapshot = await service.loadDirectMessages(
      currentUserId: '42',
      currentUserName: 'boji',
      currentUserInitials: 'BO',
    );

    expect(snapshot.conversations.single.channelId, contains('181215'));
    expect(snapshot.hiddenChannelIds, {'$networkId/181215028619407360'});
    expect(requestedUris.map((uri) => uri.path), [
      '/api/users/me/relationships',
      '/api/dms',
    ]);
  });

  test('loads older direct message history with a before cursor', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final apiOrigin = 'http://127.0.0.1:${server.port}';
    final requestedUris = <Uri>[];
    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: apiOrigin,
    );

    final serverSubscription = server.listen((request) async {
      requestedUris.add(request.uri);
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode([
          _messageJson(
            id: 'message-older',
            authorId: '181',
            content: 'older dm message',
            createdAt: '2026-06-03T22:01:00Z',
          ),
        ]),
      );
      await request.response.close();
    });
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });

    final service = VerdantDirectMessagesService(
      apiOrigin: apiOrigin,
      credentialStore: credentialStore,
      timeout: const Duration(seconds: 2),
    );
    addTearDown(service.close);

    await service.loadConversationMessages(
      conversation: const DmConversationPreviewSeed(
        channelId: 'official/181215028619407360',
        localChannelId: '181215028619407360',
        networkId: 'official',
        displayName: 'Avery',
        initials: 'AV',
        status: 'Online',
        lastMessage: 'Preview',
      ),
      currentUserId: '42',
      beforeMessageId: 'official/181215028619407361',
    );

    expect(requestedUris.single.queryParameters['limit'], '50');
    expect(
      requestedUris.single.queryParameters['before'],
      '181215028619407361',
    );
  });

  test(
    'queues live commands while websocket READY is still handshaking',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final apiOrigin = 'http://127.0.0.1:${server.port}';
      final credentialStore = _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: apiOrigin,
      );
      final sentMessage = Completer<verdant_ws.ClientMessageSend>();

      final serverSubscription = server.listen((request) async {
        if (request.uri.path != '/ws') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }
        final socket = await WebSocketTransformer.upgrade(request);
        await for (final frame in socket) {
          final message = verdant_ws.WsMessage.fromBuffer(
            Uint8List.fromList(List<int>.from(frame as List<int>)),
          );
          if (message.whichPayload() == verdant_ws.WsMessage_Payload.identify) {
            await Future<void>.delayed(const Duration(milliseconds: 40));
            socket.add(
              Uint8List.fromList(
                verdant_ws.WsMessage(ready: verdant_ws.Ready()).writeToBuffer(),
              ),
            );
            continue;
          }
          if (message.whichPayload() ==
              verdant_ws.WsMessage_Payload.clientMessageSend) {
            sentMessage.complete(message.clientMessageSend);
          }
        }
      });
      addTearDown(() async {
        await serverSubscription.cancel();
        await server.close(force: true);
      });

      final service = VerdantDirectMessagesService(
        apiOrigin: apiOrigin,
        credentialStore: credentialStore,
        timeout: const Duration(seconds: 2),
      );
      addTearDown(service.close);
      final subscription = service
          .connectRealtime(
            currentUserId: '42',
            currentUserName: 'Joshy',
            currentUserInitials: 'JO',
            currentUserStatus: 'online',
          )
          .listen((_) {});
      addTearDown(subscription.cancel);

      await service.sendChannelMessage(channelId: '321', content: 'hello');

      final message = await sentMessage.future.timeout(
        const Duration(seconds: 2),
      );
      expect(message.channelId, '321');
      expect(message.content, 'hello');
    },
  );

  test('identifies realtime with the selected current user status', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final apiOrigin = 'http://127.0.0.1:${server.port}';
    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: apiOrigin,
    );
    final identified = Completer<verdant_ws.Identify>();

    final serverSubscription = server.listen((request) async {
      if (request.uri.path != '/ws') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      await for (final frame in socket) {
        final message = verdant_ws.WsMessage.fromBuffer(
          Uint8List.fromList(List<int>.from(frame as List<int>)),
        );
        if (message.whichPayload() == verdant_ws.WsMessage_Payload.identify) {
          identified.complete(message.identify);
          socket.add(
            Uint8List.fromList(
              verdant_ws.WsMessage(ready: verdant_ws.Ready()).writeToBuffer(),
            ),
          );
          break;
        }
      }
    });
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });

    final service = VerdantDirectMessagesService(
      apiOrigin: apiOrigin,
      credentialStore: credentialStore,
      timeout: const Duration(seconds: 2),
    );
    addTearDown(service.close);
    final subscription = service
        .connectRealtime(
          currentUserId: '42',
          currentUserName: 'Joshy',
          currentUserInitials: 'JO',
          currentUserStatus: 'idle',
        )
        .listen((_) {});
    addTearDown(subscription.cancel);

    final identify = await identified.future.timeout(
      const Duration(seconds: 2),
    );
    expect(identify.initialStatus, verdant_models.UserStatus.USER_STATUS_IDLE);
  });

  test(
    'keeps the realtime event stream alive and reconnects after websocket close',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final apiOrigin = 'http://127.0.0.1:${server.port}';
      final credentialStore = _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: apiOrigin,
      );
      final snapshots = <DirectMessagesSnapshotEvent>[];
      final secondReady = Completer<void>();
      final secondSnapshot = Completer<void>();
      var identifyCount = 0;

      final serverSubscription = server.listen((request) async {
        if (request.uri.path != '/ws') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }
        final socket = await WebSocketTransformer.upgrade(request);
        await for (final frame in socket) {
          final message = verdant_ws.WsMessage.fromBuffer(
            Uint8List.fromList(List<int>.from(frame as List<int>)),
          );
          if (message.whichPayload() == verdant_ws.WsMessage_Payload.identify) {
            identifyCount += 1;
            socket.add(
              Uint8List.fromList(
                verdant_ws.WsMessage(ready: verdant_ws.Ready()).writeToBuffer(),
              ),
            );
            if (identifyCount == 1) {
              await socket.close();
            } else if (!secondReady.isCompleted) {
              secondReady.complete();
            }
            break;
          }
        }
      });
      addTearDown(() async {
        await serverSubscription.cancel();
        await server.close(force: true);
      });

      final service = VerdantDirectMessagesService(
        apiOrigin: apiOrigin,
        credentialStore: credentialStore,
        timeout: const Duration(seconds: 2),
      );
      addTearDown(service.close);
      final subscription = service
          .connectRealtime(
            currentUserId: '42',
            currentUserName: 'Joshy',
            currentUserInitials: 'JO',
            currentUserStatus: 'online',
          )
          .listen((event) {
            if (event is DirectMessagesSnapshotEvent) {
              snapshots.add(event);
              if (snapshots.length == 2 && !secondSnapshot.isCompleted) {
                secondSnapshot.complete();
              }
            }
          });
      addTearDown(subscription.cancel);

      await secondReady.future.timeout(const Duration(seconds: 2));
      await secondSnapshot.future.timeout(const Duration(seconds: 2));

      expect(identifyCount, 2);
      expect(snapshots.length, 2);
    },
  );

  test('sends protobuf ping and accepts protobuf pong heartbeats', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final apiOrigin = 'http://127.0.0.1:${server.port}';
    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: apiOrigin,
    );
    final pingReceived = Completer<void>();

    final serverSubscription = server.listen((request) async {
      if (request.uri.path != '/ws') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      await for (final frame in socket) {
        final message = verdant_ws.WsMessage.fromBuffer(
          Uint8List.fromList(List<int>.from(frame as List<int>)),
        );
        if (message.whichPayload() == verdant_ws.WsMessage_Payload.identify) {
          socket.add(
            Uint8List.fromList(
              verdant_ws.WsMessage(
                ready: verdant_ws.Ready(sessionId: 'session-1'),
              ).writeToBuffer(),
            ),
          );
          continue;
        }
        if (message.whichPayload() == verdant_ws.WsMessage_Payload.ping) {
          if (!pingReceived.isCompleted) {
            pingReceived.complete();
          }
          socket.add(
            Uint8List.fromList(
              verdant_ws.WsMessage(pong: verdant_ws.Pong()).writeToBuffer(),
            ),
          );
        }
      }
    });
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });

    final service = VerdantDirectMessagesService(
      apiOrigin: apiOrigin,
      credentialStore: credentialStore,
      timeout: const Duration(seconds: 2),
      heartbeatInterval: const Duration(milliseconds: 20),
      pongTimeout: const Duration(milliseconds: 100),
    );
    addTearDown(service.close);
    final subscription = service
        .connectRealtime(
          currentUserId: '42',
          currentUserName: 'Joshy',
          currentUserInitials: 'JO',
          currentUserStatus: 'online',
        )
        .listen((_) {});
    addTearDown(subscription.cancel);

    await pingReceived.future.timeout(const Duration(seconds: 2));
  });

  test('starts protobuf heartbeats only after READY', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final apiOrigin = 'http://127.0.0.1:${server.port}';
    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: apiOrigin,
    );
    final pingAfterReady = Completer<void>();
    var readySent = false;
    var pingBeforeReady = false;

    final serverSubscription = server.listen((request) async {
      if (request.uri.path != '/ws') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      await for (final frame in socket) {
        final message = verdant_ws.WsMessage.fromBuffer(
          Uint8List.fromList(List<int>.from(frame as List<int>)),
        );
        if (message.whichPayload() == verdant_ws.WsMessage_Payload.identify) {
          await Future<void>.delayed(const Duration(milliseconds: 80));
          readySent = true;
          socket.add(
            Uint8List.fromList(
              verdant_ws.WsMessage(
                ready: verdant_ws.Ready(sessionId: 'session-1'),
              ).writeToBuffer(),
            ),
          );
          continue;
        }
        if (message.whichPayload() == verdant_ws.WsMessage_Payload.ping) {
          if (!readySent) {
            pingBeforeReady = true;
          } else if (!pingAfterReady.isCompleted) {
            pingAfterReady.complete();
          }
          socket.add(
            Uint8List.fromList(
              verdant_ws.WsMessage(pong: verdant_ws.Pong()).writeToBuffer(),
            ),
          );
        }
      }
    });
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });

    final service = VerdantDirectMessagesService(
      apiOrigin: apiOrigin,
      credentialStore: credentialStore,
      timeout: const Duration(seconds: 2),
      heartbeatInterval: const Duration(milliseconds: 20),
      pongTimeout: const Duration(milliseconds: 100),
    );
    addTearDown(service.close);
    final subscription = service
        .connectRealtime(
          currentUserId: '42',
          currentUserName: 'Joshy',
          currentUserInitials: 'JO',
          currentUserStatus: 'online',
        )
        .listen((_) {});
    addTearDown(subscription.cancel);

    await pingAfterReady.future.timeout(const Duration(seconds: 2));

    expect(pingBeforeReady, isFalse);
  });

  test('reconnects after missed pong and resumes from last READY', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final apiOrigin = 'http://127.0.0.1:${server.port}';
    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: apiOrigin,
    );
    final secondIdentify = Completer<verdant_ws.Identify>();
    var identifyCount = 0;

    final serverSubscription = server.listen((request) async {
      if (request.uri.path != '/ws') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      await for (final frame in socket) {
        final message = verdant_ws.WsMessage.fromBuffer(
          Uint8List.fromList(List<int>.from(frame as List<int>)),
        );
        if (message.whichPayload() == verdant_ws.WsMessage_Payload.identify) {
          identifyCount += 1;
          if (identifyCount == 2 && !secondIdentify.isCompleted) {
            secondIdentify.complete(message.identify);
          }
          socket.add(
            Uint8List.fromList(
              verdant_ws.WsMessage(
                ready: verdant_ws.Ready(sessionId: 'session-$identifyCount'),
              ).writeToBuffer(),
            ),
          );
          if (identifyCount == 1) {
            socket.add(
              Uint8List.fromList(
                verdant_ws.WsMessage(
                  readyDelta: verdant_ws.ReadyDelta(
                    sessionId: 'session-delta-1',
                  ),
                ).writeToBuffer(),
              ),
            );
          }
        }
      }
    });
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });

    final service = VerdantDirectMessagesService(
      apiOrigin: apiOrigin,
      credentialStore: credentialStore,
      timeout: const Duration(seconds: 2),
      heartbeatInterval: const Duration(milliseconds: 20),
      pongTimeout: const Duration(milliseconds: 40),
      minReconnectDelay: Duration.zero,
    );
    addTearDown(service.close);
    final subscription = service
        .connectRealtime(
          currentUserId: '42',
          currentUserName: 'Joshy',
          currentUserInitials: 'JO',
          currentUserStatus: 'online',
        )
        .listen((_) {});
    addTearDown(subscription.cancel);

    final identify = await secondIdentify.future.timeout(
      const Duration(seconds: 2),
    );
    expect(identify.resumeSessionId, 'session-delta-1');
    expect(identify.lastReadyAt, isNotEmpty);
  });

  test('uses server draining reconnect delay for planned reconnects', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final apiOrigin = 'http://127.0.0.1:${server.port}';
    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: apiOrigin,
    );
    final reconnectStopwatch = Stopwatch();
    final reconnected = Completer<Duration>();
    var identifyCount = 0;

    final serverSubscription = server.listen((request) async {
      if (request.uri.path != '/ws') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      await for (final frame in socket) {
        final message = verdant_ws.WsMessage.fromBuffer(
          Uint8List.fromList(List<int>.from(frame as List<int>)),
        );
        if (message.whichPayload() != verdant_ws.WsMessage_Payload.identify) {
          continue;
        }
        identifyCount += 1;
        if (identifyCount == 1) {
          socket.add(
            Uint8List.fromList(
              verdant_ws.WsMessage(ready: verdant_ws.Ready()).writeToBuffer(),
            ),
          );
          socket.add(
            jsonEncode({
              'op': 'SERVER_DRAINING',
              'd': {'reconnectAfterMs': 120},
            }),
          );
          reconnectStopwatch.start();
          await socket.close(1001, 'Server draining');
          break;
        }
        if (!reconnected.isCompleted) {
          reconnected.complete(reconnectStopwatch.elapsed);
        }
        socket.add(
          Uint8List.fromList(
            verdant_ws.WsMessage(ready: verdant_ws.Ready()).writeToBuffer(),
          ),
        );
      }
    });
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });

    final service = VerdantDirectMessagesService(
      apiOrigin: apiOrigin,
      credentialStore: credentialStore,
      timeout: const Duration(seconds: 2),
      minReconnectDelay: const Duration(milliseconds: 250),
    );
    addTearDown(service.close);
    final subscription = service
        .connectRealtime(
          currentUserId: '42',
          currentUserName: 'Joshy',
          currentUserInitials: 'JO',
          currentUserStatus: 'online',
        )
        .listen((_) {});
    addTearDown(subscription.cancel);

    final elapsed = await reconnected.future.timeout(
      const Duration(seconds: 2),
    );
    expect(elapsed.inMilliseconds, greaterThanOrEqualTo(90));
    expect(elapsed.inMilliseconds, lessThan(240));
  });

  test(
    'refreshes credentials and reconnects live websocket after invalid token close',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final apiOrigin = 'http://127.0.0.1:${server.port}';
      final identifyTokens = <String>[];
      final freshReady = Completer<void>();
      final credentialStore = _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'expired-access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: apiOrigin,
      );

      final serverSubscription = server.listen((request) async {
        if (request.uri.path == '/ws') {
          final socket = await WebSocketTransformer.upgrade(request);
          await for (final frame in socket) {
            final message = verdant_ws.WsMessage.fromBuffer(
              Uint8List.fromList(List<int>.from(frame as List<int>)),
            );
            if (message.whichPayload() !=
                verdant_ws.WsMessage_Payload.identify) {
              continue;
            }
            final token = message.identify.token;
            identifyTokens.add(token);
            if (token == 'expired-access-secret') {
              await socket.close(4004, 'Invalid token');
              break;
            }
            socket.add(
              Uint8List.fromList(
                verdant_ws.WsMessage(ready: verdant_ws.Ready()).writeToBuffer(),
              ),
            );
            if (!freshReady.isCompleted) {
              freshReady.complete();
            }
          }
          return;
        }

        final bytes = await request.fold<List<int>>(
          <int>[],
          (buffer, chunk) => buffer..addAll(chunk),
        );
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/api/auth/refresh') {
          expect(jsonDecode(utf8.decode(bytes)), {
            'sessionToken': 'session-secret',
          });
          request.response.write(
            jsonEncode({'accessToken': 'fresh-access-secret'}),
          );
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write(jsonEncode({'error': 'not found'}));
        }
        await request.response.close();
      });
      addTearDown(() async {
        await serverSubscription.cancel();
        await server.close(force: true);
      });

      final service = VerdantDirectMessagesService(
        apiOrigin: apiOrigin,
        credentialStore: credentialStore,
        timeout: const Duration(seconds: 2),
      );
      addTearDown(service.close);
      final subscription = service
          .connectRealtime(
            currentUserId: '42',
            currentUserName: 'Joshy',
            currentUserInitials: 'JO',
            currentUserStatus: 'online',
          )
          .listen((_) {});
      addTearDown(subscription.cancel);

      await freshReady.future.timeout(const Duration(seconds: 2));

      expect(identifyTokens, ['expired-access-secret', 'fresh-access-secret']);
      expect(credentialStore.credentials.accessToken, 'fresh-access-secret');
      expect(credentialStore.clearCount, 0);
    },
  );

  test(
    'records sanitized websocket close code and reason diagnostics',
    () async {
      final previousDebugPrint = debugPrint;
      final diagnostics = <String>[];
      final closeDiagnostic = Completer<void>();
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          diagnostics.add(message);
          if (message.contains('protobuf.live.closed') &&
              !closeDiagnostic.isCompleted) {
            closeDiagnostic.complete();
          }
        }
      };
      addTearDown(() {
        debugPrint = previousDebugPrint;
      });

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final apiOrigin = 'http://127.0.0.1:${server.port}';
      final credentialStore = _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: apiOrigin,
      );
      final serverSubscription = server.listen((request) async {
        if (request.uri.path != '/ws') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }
        final socket = await WebSocketTransformer.upgrade(request);
        await for (final frame in socket) {
          final message = verdant_ws.WsMessage.fromBuffer(
            Uint8List.fromList(List<int>.from(frame as List<int>)),
          );
          if (message.whichPayload() != verdant_ws.WsMessage_Payload.identify) {
            continue;
          }
          socket.add(
            Uint8List.fromList(
              verdant_ws.WsMessage(ready: verdant_ws.Ready()).writeToBuffer(),
            ),
          );
          await socket.close(
            4008,
            'Rate limited accessToken=access-secret sessionToken=session-secret',
          );
          break;
        }
      });
      addTearDown(() async {
        await serverSubscription.cancel();
        await server.close(force: true);
      });

      final service = VerdantDirectMessagesService(
        apiOrigin: apiOrigin,
        credentialStore: credentialStore,
        timeout: const Duration(seconds: 2),
      );
      addTearDown(service.close);
      final subscription = service
          .connectRealtime(
            currentUserId: '42',
            currentUserName: 'Joshy',
            currentUserInitials: 'JO',
            currentUserStatus: 'online',
          )
          .listen((_) {});
      addTearDown(subscription.cancel);

      await closeDiagnostic.future.timeout(const Duration(seconds: 2));

      final rendered = diagnostics.join('\n');
      expect(rendered, contains('protobuf.live.closed'));
      expect(rendered, contains('closeCode: 4008'));
      expect(rendered, contains('closeReason: redacted'));
      expect(rendered, isNot(contains('access-secret')));
      expect(rendered, isNot(contains('session-secret')));
    },
  );

  test(
    'sends focus, channel messages, and reactions over the live protobuf websocket',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final apiOrigin = 'http://127.0.0.1:${server.port}';
      final networkId = networkIdFromApiOrigin(apiOrigin);
      final credentialStore = _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: apiOrigin,
      );
      final received = <verdant_ws.WsMessage>[];
      final commandFrames = <verdant_ws.WsMessage>[];
      final allCommandsReceived = Completer<void>();
      final reactionEcho = Completer<DirectMessagesReactionAddEvent>();

      final serverSubscription = server.listen((request) async {
        if (request.uri.path != '/ws') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }
        final socket = await WebSocketTransformer.upgrade(request);
        await for (final frame in socket) {
          final message = verdant_ws.WsMessage.fromBuffer(
            Uint8List.fromList(List<int>.from(frame as List<int>)),
          );
          received.add(message);
          if (message.whichPayload() == verdant_ws.WsMessage_Payload.identify) {
            socket.add(
              Uint8List.fromList(
                verdant_ws.WsMessage(ready: verdant_ws.Ready()).writeToBuffer(),
              ),
            );
            continue;
          }
          commandFrames.add(message);
          if (message.whichPayload() ==
              verdant_ws.WsMessage_Payload.clientReactionAdd) {
            socket.add(
              Uint8List.fromList(
                verdant_ws.WsMessage(
                  reactionAdd: verdant_ws.ReactionAdd(
                    channelId: message.clientReactionAdd.channelId,
                    messageId: message.clientReactionAdd.messageId,
                    userId: '42',
                    emoji: message.clientReactionAdd.emoji,
                    emojiId: message.clientReactionAdd.emojiId,
                  ),
                ).writeToBuffer(),
              ),
            );
          }
          if (commandFrames.length == 6 && !allCommandsReceived.isCompleted) {
            allCommandsReceived.complete();
          }
        }
      });
      addTearDown(() async {
        await serverSubscription.cancel();
        await server.close(force: true);
      });

      final service = VerdantDirectMessagesService(
        apiOrigin: apiOrigin,
        credentialStore: credentialStore,
        timeout: const Duration(seconds: 2),
      );
      addTearDown(service.close);

      final ready = Completer<void>();
      final subscription = service
          .connectRealtime(
            currentUserId: '42',
            currentUserName: 'Joshy',
            currentUserInitials: 'JO',
            currentUserStatus: 'online',
          )
          .listen((event) {
            if (event is DirectMessagesSnapshotEvent && !ready.isCompleted) {
              ready.complete();
            }
            if (event is DirectMessagesReactionAddEvent &&
                !reactionEcho.isCompleted) {
              reactionEcho.complete(event);
            }
          });
      addTearDown(subscription.cancel);

      await service.focusServer(serverId: '123');
      await service.focusChannel(channelId: '321');
      await ready.future.timeout(const Duration(seconds: 2));
      await service.sendChannelMessage(
        channelId: '321',
        content: ' <b>Hello from Flutter</b> ',
      );
      await service.sendTypingStart(channelId: '321');
      await service.addReaction(
        channelId: '321',
        messageId: '654',
        emoji: '\u{1F600}',
        emojiId: 'emoji-1',
      );
      await service.removeReaction(
        channelId: '321',
        messageId: '654',
        emoji: '\u{1F600}',
      );
      await allCommandsReceived.future.timeout(const Duration(seconds: 2));
      final echoedReaction = await reactionEcho.future.timeout(
        const Duration(seconds: 2),
      );

      expect(
        received.first.whichPayload(),
        verdant_ws.WsMessage_Payload.identify,
      );
      expect(commandFrames.map((frame) => frame.whichPayload()), [
        verdant_ws.WsMessage_Payload.clientFocusServer,
        verdant_ws.WsMessage_Payload.clientFocusChannel,
        verdant_ws.WsMessage_Payload.clientMessageSend,
        verdant_ws.WsMessage_Payload.clientTypingStart,
        verdant_ws.WsMessage_Payload.clientReactionAdd,
        verdant_ws.WsMessage_Payload.clientReactionRemove,
      ]);
      expect(commandFrames[0].clientFocusServer.serverId, '123');
      expect(commandFrames[1].clientFocusChannel.channelId, '321');
      expect(commandFrames[2].clientMessageSend.channelId, '321');
      expect(commandFrames[2].clientMessageSend.content, 'Hello from Flutter');
      expect(commandFrames[3].clientTypingStart.channelId, '321');
      expect(commandFrames[4].clientReactionAdd.messageId, '654');
      expect(commandFrames[4].clientReactionAdd.emojiId, 'emoji-1');
      expect(commandFrames[5].clientReactionRemove.emoji, '\u{1F600}');
      expect(echoedReaction.channelId, '$networkId/321');
      expect(echoedReaction.messageId, '$networkId/654');
      expect(echoedReaction.localUserId, '42');
    },
  );

  test('decodes protobuf hydration and mutation realtime events', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final apiOrigin = 'http://127.0.0.1:${server.port}';
    final networkId = networkIdFromApiOrigin(apiOrigin);
    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: apiOrigin,
    );
    final decoded = <DirectMessagesRealtimeEvent>[];
    final done = Completer<void>();

    final serverSubscription = server.listen((request) async {
      if (request.uri.path != '/ws') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      await for (final frame in socket) {
        final message = verdant_ws.WsMessage.fromBuffer(
          Uint8List.fromList(List<int>.from(frame as List<int>)),
        );
        if (message.whichPayload() != verdant_ws.WsMessage_Payload.identify) {
          continue;
        }
        socket.add(
          Uint8List.fromList(
            verdant_ws.WsMessage(ready: verdant_ws.Ready()).writeToBuffer(),
          ),
        );
        socket.add(
          Uint8List.fromList(
            verdant_ws.WsMessage(
              batch: verdant_ws.Batch(
                messages: [
                  verdant_ws.WsMessage(
                    messageUpdate: verdant_ws.MessageUpdate(
                      message: _protoMessage(
                        id: 'm-1',
                        channelId: '321',
                        authorId: '42',
                        content: 'edited',
                      ),
                    ),
                  ),
                  verdant_ws.WsMessage(
                    messageDelete: verdant_ws.MessageDelete(
                      id: 'm-2',
                      channelId: '321',
                    ),
                  ),
                  verdant_ws.WsMessage(
                    channelUnreadSignal: verdant_ws.ChannelUnreadSignal(
                      channelId: '654',
                      messageId: 'm-3',
                      authorId: '181',
                      mentionsCurrentUser: true,
                      dm: false,
                    ),
                  ),
                  verdant_ws.WsMessage(
                    channelActivityUpdate: verdant_ws.ChannelActivityUpdate(
                      channelId: '321',
                      userId: '181',
                      displayName: 'Avery',
                      avatarUrl: 'https://cdn.example/avatar.webp',
                    ),
                  ),
                  verdant_ws.WsMessage(
                    typingStart: verdant_ws.TypingStart(
                      channelId: '321',
                      userId: '181',
                    ),
                  ),
                  verdant_ws.WsMessage(
                    channelCreate: verdant_ws.ChannelCreate(
                      channel: verdant_models.Channel(
                        id: '777',
                        serverId: '123',
                        name: 'new-room',
                        type:
                            verdant_models.ChannelType.CHANNEL_TYPE_SERVER_TEXT,
                      ),
                    ),
                  ),
                  verdant_ws.WsMessage(
                    channelUpdate: verdant_ws.ChannelUpdate(
                      channel: verdant_models.Channel(
                        id: '654',
                        serverId: '123',
                        name: 'renamed-voice',
                        type: verdant_models
                            .ChannelType
                            .CHANNEL_TYPE_SERVER_VOICE,
                      ),
                    ),
                  ),
                  verdant_ws.WsMessage(
                    channelDelete: verdant_ws.ChannelDelete(
                      channelId: '555',
                      serverId: '123',
                    ),
                  ),
                  verdant_ws.WsMessage(
                    serverDelete: verdant_ws.ServerDelete(serverId: '123'),
                  ),
                  verdant_ws.WsMessage(
                    memberJoin: verdant_ws.MemberJoin(
                      serverId: '123',
                      userId: '222',
                      displayName: 'New User',
                      avatarUrl: 'https://cdn.example/new-user.webp',
                    ),
                  ),
                  verdant_ws.WsMessage(
                    memberRoleUpdate: verdant_ws.MemberRoleUpdate(
                      serverId: '123',
                      userId: '181',
                      roleIds: ['role-1', 'role-2'],
                    ),
                  ),
                  verdant_ws.WsMessage(
                    memberRemove: verdant_ws.MemberRemove(
                      serverId: '123',
                      userId: '333',
                    ),
                  ),
                  verdant_ws.WsMessage(
                    relationshipAdd: verdant_ws.RelationshipAdd(
                      relationship: verdant_models.Relationship(
                        userId: '181',
                        type: verdant_models
                            .RelationshipType
                            .RELATIONSHIP_TYPE_FRIEND,
                        user: verdant_models.RelationshipUser(
                          id: '181',
                          username: 'avery',
                          status: 'online',
                        ),
                      ),
                    ),
                  ),
                  verdant_ws.WsMessage(
                    dmChannelCreate: verdant_ws.DmChannelCreate(
                      dmChannel: verdant_models.DmChannel(
                        id: 'dm-181',
                        participants: [
                          verdant_models.DmParticipant(
                            id: '42',
                            username: 'Joshy',
                            status: 'online',
                          ),
                          verdant_models.DmParticipant(
                            id: '181',
                            username: 'avery',
                            displayName: 'Avery',
                            status: 'online',
                          ),
                        ],
                      ),
                    ),
                  ),
                  verdant_ws.WsMessage(
                    relationshipRemove: verdant_ws.RelationshipRemove(
                      userId: '181',
                    ),
                  ),
                ],
              ),
            ).writeToBuffer(),
          ),
        );
      }
    });
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });

    final service = VerdantDirectMessagesService(
      apiOrigin: apiOrigin,
      credentialStore: credentialStore,
      timeout: const Duration(seconds: 2),
    );
    addTearDown(service.close);

    final subscription = service
        .connectRealtime(
          currentUserId: '42',
          currentUserName: 'Joshy',
          currentUserInitials: 'JO',
          currentUserStatus: 'online',
        )
        .listen((event) {
          decoded.add(event);
          if (event is DirectMessagesRelationshipRemoveEvent &&
              !done.isCompleted) {
            done.complete();
          }
        });
    addTearDown(subscription.cancel);

    await done.future.timeout(const Duration(seconds: 2));

    expect(decoded.whereType<DirectMessagesMessageUpdateEvent>(), hasLength(1));
    expect(
      decoded.whereType<DirectMessagesMessageUpdateEvent>().single.message.body,
      'edited',
    );
    expect(
      decoded.whereType<DirectMessagesMessageDeleteEvent>().single.messageId,
      '$networkId/m-2',
    );
    expect(
      decoded.whereType<DirectMessagesChannelUnreadEvent>().single.channelId,
      '$networkId/654',
    );
    expect(
      decoded
          .whereType<DirectMessagesChannelActivityEvent>()
          .single
          .localUserId,
      '181',
    );
    expect(decoded.whereType<DirectMessagesTypingStartEvent>(), hasLength(1));
    expect(
      decoded
          .whereType<DirectMessagesServerChannelUpsertEvent>()
          .first
          .channel
          .name,
      'new-room',
    );
    expect(
      decoded
          .whereType<DirectMessagesServerChannelDeleteEvent>()
          .single
          .channelId,
      '$networkId/555',
    );
    expect(
      decoded.whereType<DirectMessagesServerDeleteEvent>().single.serverId,
      '$networkId/123',
    );
    expect(
      decoded
          .whereType<DirectMessagesServerMemberUpsertEvent>()
          .single
          .member
          .name,
      'New User',
    );
    expect(
      decoded
          .whereType<DirectMessagesServerMemberUpsertEvent>()
          .single
          .member
          .status,
      'Online',
    );
    expect(
      decoded
          .whereType<DirectMessagesServerMemberUpsertEvent>()
          .single
          .member
          .isActive,
      isTrue,
    );
    expect(
      decoded
          .whereType<DirectMessagesServerMemberRoleUpdateEvent>()
          .single
          .roleIds,
      ['role-1', 'role-2'],
    );
    expect(
      decoded.whereType<DirectMessagesServerMemberRemoveEvent>().single.userId,
      '$networkId/333',
    );
    expect(
      decoded
          .whereType<DirectMessagesRelationshipUpsertEvent>()
          .single
          .friend
          .id,
      '$networkId/181',
    );
    expect(
      decoded
          .whereType<DirectMessagesConversationUpsertEvent>()
          .single
          .conversation
          .channelId,
      '$networkId/dm-181',
    );
  });

  test('decodes JSON presence batches from focus server responses', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final apiOrigin = 'http://127.0.0.1:${server.port}';
    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: apiOrigin,
    );
    final presence = Completer<DirectMessagesPresenceUpdateEvent>();

    final serverSubscription = server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      await for (final frame in socket) {
        final message = verdant_ws.WsMessage.fromBuffer(
          Uint8List.fromList(List<int>.from(frame as List<int>)),
        );
        if (message.whichPayload() != verdant_ws.WsMessage_Payload.identify) {
          continue;
        }
        socket.add(
          Uint8List.fromList(
            verdant_ws.WsMessage(ready: verdant_ws.Ready()).writeToBuffer(),
          ),
        );
        socket.add(
          jsonEncode({
            'op': 'PRESENCE_BATCH',
            'd': {
              'serverId': '123',
              'presences': [
                {'userId': '181', 'status': 'idle'},
              ],
            },
          }),
        );
      }
    });
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });

    final service = VerdantDirectMessagesService(
      apiOrigin: apiOrigin,
      credentialStore: credentialStore,
      timeout: const Duration(seconds: 2),
    );
    addTearDown(service.close);
    final subscription = service
        .connectRealtime(
          currentUserId: '42',
          currentUserName: 'Joshy',
          currentUserInitials: 'JO',
          currentUserStatus: 'online',
        )
        .listen((event) {
          if (event is DirectMessagesPresenceUpdateEvent &&
              !presence.isCompleted) {
            presence.complete(event);
          }
        });
    addTearDown(subscription.cancel);

    final event = await presence.future.timeout(const Duration(seconds: 2));

    expect(event.localUserId, '181');
    expect(event.status, 'Idle');
  });

  test('decodes JSON bot presence updates from bot gateway events', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final apiOrigin = 'http://127.0.0.1:${server.port}';
    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: apiOrigin,
    );
    final presence = Completer<DirectMessagesBotPresenceUpdateEvent>();

    final serverSubscription = server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      await for (final frame in socket) {
        final message = verdant_ws.WsMessage.fromBuffer(
          Uint8List.fromList(List<int>.from(frame as List<int>)),
        );
        if (message.whichPayload() != verdant_ws.WsMessage_Payload.identify) {
          continue;
        }
        socket.add(
          Uint8List.fromList(
            verdant_ws.WsMessage(ready: verdant_ws.Ready()).writeToBuffer(),
          ),
        );
        socket.add(
          jsonEncode({
            'op': 'BOT_PRESENCE_UPDATE',
            'd': {'botId': 'bot-1', 'serverId': '123', 'status': 'online'},
          }),
        );
      }
    });
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });

    final service = VerdantDirectMessagesService(
      apiOrigin: apiOrigin,
      credentialStore: credentialStore,
      timeout: const Duration(seconds: 2),
    );
    addTearDown(service.close);
    final subscription = service
        .connectRealtime(
          currentUserId: '42',
          currentUserName: 'Joshy',
          currentUserInitials: 'JO',
          currentUserStatus: 'online',
        )
        .listen((event) {
          if (event is DirectMessagesBotPresenceUpdateEvent &&
              !presence.isCompleted) {
            presence.complete(event);
          }
        });
    addTearDown(subscription.cancel);

    final event = await presence.future.timeout(const Duration(seconds: 2));

    expect(event.localBotId, 'bot-1');
    expect(event.serverId, '${networkIdFromApiOrigin(apiOrigin)}/123');
    expect(event.status, 'Online');
  });
}

verdant_models.Message _protoMessage({
  required String id,
  required String channelId,
  required String authorId,
  required String content,
}) {
  return verdant_models.Message(
    id: id,
    channelId: channelId,
    authorId: authorId,
    author: verdant_models.MessageAuthor(
      id: authorId,
      username: authorId == '42' ? 'Joshy' : 'Avery',
      displayName: authorId == '42' ? 'Joshy' : 'Avery',
    ),
    content: content,
    createdAt: '2026-06-03T22:00:00Z',
    updatedAt: '2026-06-03T22:00:00Z',
  );
}

Map<String, Object?> _messageJson({
  required String id,
  required String authorId,
  required String content,
  required String createdAt,
}) {
  return {
    'id': id,
    'authorId': authorId,
    'content': content,
    'createdAt': createdAt,
    'author': {
      'id': authorId,
      'username': authorId == '42' ? 'Joshy' : 'Avery',
      'displayName': authorId == '42' ? 'Joshy' : 'Avery',
    },
  };
}

final class _MemoryCredentialStore implements AuthCredentialStore {
  _MemoryCredentialStore(this.credentials, {required this.overrideApiOrigin});

  AuthCredentialBundle credentials;
  final String overrideApiOrigin;
  var clearCount = 0;

  @override
  Future<void> clear(String apiOrigin) async {
    clearCount += 1;
  }

  @override
  Future<bool> contains(String apiOrigin) async => true;

  @override
  Future<AuthCredentialBundle?> read(String apiOrigin) async {
    if (normalizeBackendApiOrigin(apiOrigin) !=
        normalizeBackendApiOrigin(overrideApiOrigin)) {
      return null;
    }
    return AuthCredentialBundle(
      apiOrigin: overrideApiOrigin,
      accessToken: credentials.accessToken,
      sessionToken: credentials.sessionToken,
      user: credentials.user,
    );
  }

  @override
  Future<void> save(AuthCredentialBundle credentials) async {
    this.credentials = credentials;
  }
}
