import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_credentials.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_content_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_notifications.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';

final _testWebpBytes = base64Decode(
  'UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AA/vuUAAA=',
);

void main() {
  test('parses invite preview server banner media fields', () {
    final preview = ServerInvitePreview.fromJson({
      'code': 'abc123',
      'server': {
        'id': '123',
        'name': 'Verdant',
        'owner_id': 'owner',
        'icon_url': 'https://media.verdant.chat/server-icons/123.webp',
        'banner_url': 'https://media.verdant.chat/server-banners/123.webp',
        'banner_crop': {'x': 0.1, 'y': 0.2, 'width': 0.8, 'height': 0.6},
        'voiceBitrate': 64000,
        'bannerOffsetY': 50,
        'memberCount': 3,
        'large': false,
        'createdAt': '',
        'updatedAt': '',
      },
      'inviterUsername': 'Josh',
      'isMember': false,
    });

    expect(preview.server.iconUrl, contains('/server-icons/123.webp'));
    expect(preview.server.bannerUrl, contains('/server-banners/123.webp'));
    expect(preview.server.bannerCrop?.x, 0.1);
    expect(preview.server.bannerCrop?.y, 0.2);
  });

  test(
    'refreshes a stale access token and retries server loads without expiring the session',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final apiOrigin = 'http://127.0.0.1:${server.port}';
      final requests = <String>[];
      final credentialStore = _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'expired-access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: apiOrigin,
      );
      final serverSubscription = server.listen((request) async {
        final bytes = await request.fold<List<int>>(
          <int>[],
          (buffer, chunk) => buffer..addAll(chunk),
        );
        requests.add('${request.method} ${request.uri.path}');
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/api/auth/refresh') {
          expect(request.method, 'POST');
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            isNull,
          );
          expect(jsonDecode(utf8.decode(bytes)), {
            'sessionToken': 'session-secret',
          });
          request.response.write(
            jsonEncode({'accessToken': 'fresh-access-secret'}),
          );
        } else if (request.uri.path == '/api/servers' &&
            request.headers.value(HttpHeaders.authorizationHeader) ==
                'Bearer expired-access-secret') {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write(jsonEncode({'error': 'access expired'}));
        } else if (request.uri.path == '/api/servers' &&
            request.headers.value(HttpHeaders.authorizationHeader) ==
                'Bearer fresh-access-secret') {
          request.response.write(
            jsonEncode({
              'servers': [_serverJson(id: '123', name: 'Actual Verdant')],
              'serverOrder': ['123'],
              'favoriteOrder': [],
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

      final service = ServerSettingsService(
        apiOrigin: apiOrigin,
        credentialStore: credentialStore,
      );
      addTearDown(service.close);

      final servers = await service.listServers();

      expect(servers.single.id, '123');
      expect(requests, [
        'GET /api/servers',
        'POST /api/auth/refresh',
        'GET /api/servers',
      ]);
      expect(credentialStore.credentials.accessToken, 'fresh-access-secret');
      expect(credentialStore.clearCount, 0);
    },
  );

  test(
    'public metadata failures fall back without clearing credentials',
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
      final serverSubscription = server.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path.endsWith('/layout')) {
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            'Bearer access-secret',
          );
          request.response.write(jsonEncode({'channels': <Object?>[]}));
        } else if (request.uri.path == '/api/instance') {
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            isNull,
          );
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write(jsonEncode({'error': 'instance unavailable'}));
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

      final service = ServerSettingsService(
        apiOrigin: apiOrigin,
        credentialStore: credentialStore,
      );
      addTearDown(service.close);

      final settings = await service.loadServerSettings(
        _serverFrom(id: '123', name: 'Actual Verdant'),
      );

      expect(
        safeServerMediaUri(
          '$apiOrigin/server-icons/123/icon.webp',
          policy: settings.mediaPolicy,
        ),
        isNotNull,
      );
      expect(await credentialStore.contains(apiOrigin), isTrue);
      expect(credentialStore.clearCount, 0);
    },
  );

  test(
    'loads server workspace bootstrap in one authenticated request',
    () async {
      final requests = <String>[];
      late _JsonExchange exchange;
      exchange = await _JsonExchange.start((request, body) {
        requests.add('${request.method} ${request.uri.path}');
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/servers/123/workspace');
        expect(request.uri.queryParameters['messageLimit'], '50');
        expect(request.uri.queryParameters['includeActivity'], 'true');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        return {
          'version': 1,
          'server': _serverJson(id: '123', name: 'Actual Verdant'),
          'layout': {
            'channels': [
              {
                'id': '321',
                'name': 'general',
                'type': 0,
                'topic': null,
                'readOnly': false,
                'slowmodeSeconds': 0,
              },
            ],
          },
          'roles': [
            {
              'id': 'role-1',
              'name': '@everyone',
              'permissions': '1',
              'position': 0,
            },
          ],
          'members': [
            {
              'userId': '42',
              'username': 'josh',
              'displayName': 'Josh',
              'status': 'online',
              'joinedAt': '2026-06-01T10:00:00Z',
              'roleIds': ['role-1'],
            },
          ],
          'feeds': <Object?>[],
          'bots': <Object?>[],
          'emojis': [
            {
              'id': 'emoji-1',
              'serverId': '123',
              'name': 'verdant',
              'url': '${exchange.origin}/emojis/emoji-1.webp',
              'createdBy': '42',
              'createdAt': '2026-06-01T10:00:00Z',
            },
          ],
          'stickers': <Object?>[],
          'invites': <Object?>[],
          'auditEvents': <Object?>[],
          'currentUser': {
            'id': '42',
            'username': 'josh',
            'displayName': 'Josh',
            'status': 'online',
            'avatarUrl': '${exchange.origin}/avatars/42.webp',
          },
          'activeChannelId': '321',
          'messages': [
            {
              'id': 'message-1',
              'authorId': '42',
              'content': 'hello',
              'createdAt': '2026-06-01T10:00:00Z',
              'author': {'username': 'josh', 'displayName': 'Josh'},
              'reactions': <Object?>[],
            },
          ],
          'activity': {
            'available': true,
            'members': [
              {
                'userId': '42',
                'username': 'josh',
                'displayName': 'Josh',
                'status': 'online',
                'joinedAt': '2026-06-01T10:00:00Z',
                'roleIds': ['role-1'],
              },
            ],
          },
          'instance': {
            'apiUrl': exchange.origin,
            'publicUrl': exchange.origin,
            'cdnUrl': null,
            'capabilities': <String, Object?>{},
          },
        };
      });
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final bootstrap = await service.loadServerWorkspaceBootstrap(
        _serverFrom(id: '123', name: 'Fallback'),
        currentUserId: '42',
      );

      expect(requests, ['GET /api/servers/123/workspace']);
      expect(bootstrap, isNotNull);
      expect(bootstrap!.settings.server.name, 'Actual Verdant');
      expect(bootstrap.settings.channels.single.id, '321');
      expect(bootstrap.settings.emojis.single.title, ':verdant:');
      expect(bootstrap.settings.emojis.single.avatarUrl, contains('/emojis/'));
      expect(bootstrap.settings.members.single.userId, '42');
      expect(bootstrap.currentUserMedia?.id, '42');
      expect(bootstrap.activeChannelId, '321');
      expect(bootstrap.messages.single.body, 'hello');
      expect(bootstrap.messages.single.isOwnMessage, isTrue);
      expect(bootstrap.activity.available, isTrue);
      expect(bootstrap.activity.members.single.username, 'josh');
    },
  );

  test(
    'fills missing workspace bootstrap emojis from the server emoji endpoint',
    () async {
      final requests = <String>[];
      late _JsonExchange exchange;
      exchange = await _JsonExchange.start((request, body) {
        requests.add('${request.method} ${request.uri.path}');
        expect(request.method, 'GET');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        if (request.uri.path == '/api/servers/123/emojis') {
          return [
            {
              'id': 'emoji-1',
              'serverId': '123',
              'name': 'smokoko',
              'url': '${exchange.origin}/emojis/emoji-1.webp',
            },
          ];
        }

        expect(request.uri.path, '/api/servers/123/workspace');
        return {
          'version': 1,
          'server': _serverJson(id: '123', name: 'Actual Verdant'),
          'layout': {
            'channels': [
              {
                'id': '321',
                'name': 'general',
                'type': 0,
                'topic': null,
                'readOnly': false,
                'slowmodeSeconds': 0,
              },
            ],
          },
          'roles': <Object?>[],
          'members': <Object?>[],
          'feeds': <Object?>[],
          'bots': <Object?>[],
          'stickers': <Object?>[],
          'invites': <Object?>[],
          'currentUser': {
            'id': '42',
            'username': 'josh',
            'displayName': 'Josh',
            'status': 'online',
          },
          'activeChannelId': '321',
          'messages': [
            {
              'id': 'message-1',
              'authorId': '42',
              'content': ':smokoko:',
              'createdAt': '2026-06-01T10:00:00Z',
              'author': {'username': 'josh', 'displayName': 'Josh'},
              'reactions': <Object?>[],
            },
          ],
          'activity': {'available': true, 'members': <Object?>[]},
          'instance': {
            'apiUrl': exchange.origin,
            'publicUrl': exchange.origin,
            'cdnUrl': exchange.origin,
            'capabilities': <String, Object?>{},
          },
        };
      }, requestCount: 2);
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final bootstrap = await service.loadServerWorkspaceBootstrap(
        _serverFrom(id: '123', name: 'Fallback'),
        currentUserId: '42',
      );

      expect(requests, [
        'GET /api/servers/123/workspace',
        'GET /api/servers/123/emojis',
      ]);
      expect(bootstrap, isNotNull);
      expect(bootstrap!.settings.emojis, hasLength(1));
      expect(bootstrap.settings.emojis.single.title, ':smokoko:');
      expect(bootstrap.messages.single.body, ':smokoko:');
    },
  );

  test(
    'fills empty workspace bootstrap emojis from the server emoji endpoint',
    () async {
      final requests = <String>[];
      late _JsonExchange exchange;
      exchange = await _JsonExchange.start((request, body) {
        requests.add('${request.method} ${request.uri.path}');
        expect(request.method, 'GET');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        if (request.uri.path == '/api/servers/123/emojis') {
          return [
            {
              'id': 'emoji-1',
              'serverId': '123',
              'name': 'smokoko',
              'url': '${exchange.origin}/emojis/emoji-1.webp',
            },
          ];
        }

        expect(request.uri.path, '/api/servers/123/workspace');
        return {
          'version': 1,
          'server': _serverJson(id: '123', name: 'Actual Verdant'),
          'layout': {
            'channels': [
              {
                'id': '321',
                'name': 'general',
                'type': 0,
                'topic': null,
                'readOnly': false,
                'slowmodeSeconds': 0,
              },
            ],
          },
          'roles': <Object?>[],
          'members': <Object?>[],
          'feeds': <Object?>[],
          'bots': <Object?>[],
          'emojis': <Object?>[],
          'stickers': <Object?>[],
          'invites': <Object?>[],
          'currentUser': {
            'id': '42',
            'username': 'josh',
            'displayName': 'Josh',
            'status': 'online',
          },
          'activeChannelId': '321',
          'messages': [
            {
              'id': 'message-1',
              'authorId': '42',
              'content': ':smokoko:',
              'createdAt': '2026-06-01T10:00:00Z',
              'author': {'username': 'josh', 'displayName': 'Josh'},
              'reactions': [
                {'emoji': ':smokoko:', 'emojiId': 'emoji-1', 'count': 1},
              ],
            },
          ],
          'activity': {'available': true, 'members': <Object?>[]},
          'instance': {
            'apiUrl': exchange.origin,
            'publicUrl': exchange.origin,
            'cdnUrl': exchange.origin,
            'capabilities': <String, Object?>{},
          },
        };
      }, requestCount: 2);
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final bootstrap = await service.loadServerWorkspaceBootstrap(
        _serverFrom(id: '123', name: 'Fallback'),
        currentUserId: '42',
      );

      expect(requests, [
        'GET /api/servers/123/workspace',
        'GET /api/servers/123/emojis',
      ]);
      expect(bootstrap, isNotNull);
      expect(bootstrap!.settings.emojis, hasLength(1));
      expect(bootstrap.settings.emojis.single.title, ':smokoko:');
      expect(bootstrap.messages.single.reactions.single.emojiId, 'emoji-1');
    },
  );

  test('server workspace bootstrap returns null for old backends', () async {
    final exchange = await _JsonExchange.start((request, body) {
      request.response.statusCode = HttpStatus.notFound;
      return {'error': 'not found'};
    });
    addTearDown(exchange.close);
    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);

    final bootstrap = await service.loadServerWorkspaceBootstrap(
      _serverFrom(id: '123', name: 'Fallback'),
      currentUserId: '42',
    );

    expect(bootstrap, isNull);
  });

  test(
    'loads active server emojis during normal workspace settings hydration',
    () async {
      final requestedPaths = <String>[];
      late _JsonExchange exchange;
      exchange = await _JsonExchange.start((request, body) async {
        requestedPaths.add(request.uri.path);
        if (request.uri.path == '/api/instance') {
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            isNull,
          );
          return {
            'apiUrl': exchange.origin,
            'publicUrl': exchange.origin,
            'cdnUrl': exchange.origin,
            'capabilities': <String, Object?>{},
          };
        }

        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        if (request.uri.path.endsWith('/layout')) {
          return {'channels': <Object?>[]};
        }
        if (request.uri.path.endsWith('/emojis')) {
          return [
            {
              'id': 'emoji-1',
              'serverId': '123',
              'name': 'smokoko',
              'url': '${exchange.origin}/emojis/emoji-1.webp',
            },
          ];
        }
        return <Object?>[];
      }, requestCount: 8);
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final settings = await service.loadServerSettings(
        _serverFrom(id: '123', name: 'Actual Verdant'),
      );

      expect(requestedPaths, contains('/api/servers/123/emojis'));
      expect(settings.emojis, hasLength(1));
      expect(settings.emojis.single.title, ':smokoko:');
      expect(
        settings.emojis.single.avatarUrl,
        contains('/emojis/emoji-1.webp'),
      );
    },
  );

  test('retries one rate-limited GET without clearing credentials', () async {
    var attempts = 0;
    final exchange = await _JsonExchange.start((request, body) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/channels/321/messages');
      expect(request.uri.queryParameters['limit'], '50');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access-secret',
      );
      attempts += 1;
      if (attempts == 1) {
        request.response.statusCode = HttpStatus.tooManyRequests;
        request.response.headers.set(HttpHeaders.retryAfterHeader, '0');
        return {'error': 'Too many requests'};
      }
      return [
        {
          'id': 'message-1',
          'authorId': '42',
          'content': 'Server hello',
          'createdAt': '2026-06-01T10:00:00Z',
          'author': {'displayName': 'Joshy', 'bannerBaseColor': '#2EC4B6'},
          'reactions': <Object?>[],
        },
      ];
    }, requestCount: 2);
    addTearDown(exchange.close);

    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: exchange.origin,
    );
    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: credentialStore,
    );
    addTearDown(service.close);

    final messages = await service.loadChannelMessages(
      channelId: '321',
      currentUserId: '42',
    );

    expect(attempts, 2);
    expect(messages.single.body, 'Server hello');
    expect(messages.single.authorBannerBaseColor, const Color(0xFF2EC4B6));
    expect(credentialStore.clearCount, 0);
  });

  test('paces server hydration requests when configured', () async {
    final requestedAt = <DateTime>[];
    final requestedPaths = <String>[];
    final exchange = await _JsonExchange.start((request, body) async {
      requestedAt.add(DateTime.now());
      requestedPaths.add(request.uri.path);
      if (request.uri.path == '/api/instance') {
        expect(request.headers.value(HttpHeaders.authorizationHeader), isNull);
        return {
          'apiUrl': '${request.uri.scheme}://${request.headers.host}',
          'registration': 'public',
        };
      }

      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access-secret',
      );
      if (request.uri.path.endsWith('/layout')) {
        return {'channels': <Object?>[]};
      }
      return <String, Object?>{'items': <Object?>[]};
    }, requestCount: 8);
    addTearDown(exchange.close);

    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
      minRequestInterval: const Duration(milliseconds: 35),
    );
    addTearDown(service.close);

    await service.loadServerSettings(
      _serverFrom(id: '123', name: 'Actual Verdant'),
    );

    expect(requestedPaths, [
      '/api/servers/123/layout',
      '/api/instance',
      '/api/servers/123/roles',
      '/api/servers/123/members',
      '/api/servers/123/feeds',
      '/api/servers/123/bots',
      '/api/servers/123/emojis',
      '/api/servers/123/stickers',
    ]);
    final requestGaps = [
      for (var index = 1; index < requestedAt.length; index += 1)
        requestedAt[index].difference(requestedAt[index - 1]).inMilliseconds,
    ];
    expect(requestGaps, everyElement(greaterThanOrEqualTo(20)));
  });

  test(
    'refreshes rotated credentials before retrying channel message loads',
    () async {
      final requests = <String>[];
      final exchange = await _JsonExchange.start((request, body) async {
        requests.add('${request.method} ${request.uri.path}');
        if (request.uri.path == '/api/auth/refresh') {
          expect(request.method, 'POST');
          expect(body, {'sessionToken': 'stale-session-secret'});
          return {
            'accessToken': 'fresh-access-secret',
            'sessionToken': 'rotated-session-secret',
          };
        }

        expect(request.method, 'GET');
        expect(request.uri.path, '/api/channels/321/messages');
        expect(request.uri.queryParameters['limit'], '50');
        if (request.headers.value(HttpHeaders.authorizationHeader) ==
            'Bearer expired-access-secret') {
          request.response.statusCode = HttpStatus.unauthorized;
          return {'error': 'access expired'};
        }
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer fresh-access-secret',
        );
        return [
          {
            'id': 'message-1',
            'authorId': '42',
            'content': 'Server hello after refresh',
            'createdAt': '2026-06-01T10:00:00Z',
            'author': {'displayName': 'Joshy'},
            'reactions': <Object?>[],
          },
        ];
      }, requestCount: 3);
      addTearDown(exchange.close);

      final credentialStore = _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'expired-access-secret',
          sessionToken: 'stale-session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      );
      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: credentialStore,
      );
      addTearDown(service.close);

      final messages = await service.loadChannelMessages(
        channelId: '321',
        currentUserId: '42',
      );

      expect(messages.single.body, 'Server hello after refresh');
      expect(requests, [
        'GET /api/channels/321/messages',
        'POST /api/auth/refresh',
        'GET /api/channels/321/messages',
      ]);
      expect(credentialStore.credentials.accessToken, 'fresh-access-secret');
      expect(
        credentialStore.credentials.sessionToken,
        'rotated-session-secret',
      );
      expect(credentialStore.clearCount, 0);
    },
  );

  test('loads older channel messages with a before cursor', () async {
    final requestedUris = <Uri>[];
    final exchange = await _JsonExchange.start((request, body) async {
      requestedUris.add(request.uri);
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/channels/321/messages');
      return [
        {
          'id': 'message-older',
          'authorId': '181',
          'content': 'Older server hello',
          'createdAt': '2026-06-01T09:00:00Z',
          'author': {'displayName': 'Avery'},
          'reactions': <Object?>[],
        },
      ];
    });
    addTearDown(exchange.close);

    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: exchange.origin,
    );
    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: credentialStore,
    );
    addTearDown(service.close);
    final networkId = networkIdFromApiOrigin(exchange.origin);

    await service.loadChannelMessages(
      channelId: '321',
      currentUserId: '42',
      beforeMessageId: '$networkId/181215028619407361',
    );

    expect(requestedUris.single.queryParameters['limit'], '50');
    expect(
      requestedUris.single.queryParameters['before'],
      '181215028619407361',
    );
  });

  test('message reads reject mismatched scoped routes before egress', () async {
    final exchange = await _JsonExchange.start((request, body) async {
      fail('Unexpected backend request for mismatched message read route');
    });
    addTearDown(exchange.close);
    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);
    final networkId = networkIdFromApiOrigin(exchange.origin);
    final otherNetworkId = networkIdFromApiOrigin('https://api.other.test');

    await expectLater(
      service.loadChannelMessages(
        channelId: '$otherNetworkId/321',
        currentUserId: '42',
      ),
      throwsA(
        isA<ServerSettingsException>().having(
          (error) => error.message,
          'message',
          'Channel route did not match network',
        ),
      ),
    );

    await expectLater(
      service.loadChannelMessages(
        channelId: '$networkId/321',
        currentUserId: '42',
        beforeMessageId: '$otherNetworkId/181215028619407361',
      ),
      throwsA(
        isA<ServerSettingsException>().having(
          (error) => error.message,
          'message',
          'Message route did not match network',
        ),
      ),
    );
  });

  test('deletes channel messages through a scoped backend route', () async {
    final requestedUris = <Uri>[];
    final exchange = await _JsonExchange.start((request, body) async {
      requestedUris.add(request.uri);
      expect(request.method, 'DELETE');
      expect(request.uri.path, '/api/channels/321/messages/181215028619407361');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access-secret',
      );
      return {'success': true};
    });
    addTearDown(exchange.close);

    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: exchange.origin,
    );
    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: credentialStore,
    );
    addTearDown(service.close);
    final networkId = networkIdFromApiOrigin(exchange.origin);

    await service.deleteChannelMessage(
      channelId: '321',
      messageId: '$networkId/181215028619407361',
    );

    expect(requestedUris.single.query, isEmpty);
  });

  test(
    'deleteChannelMessage rejects mismatched scoped routes before egress',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        fail('Unexpected backend request for mismatched message delete route');
      });
      addTearDown(exchange.close);
      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);
      final networkId = networkIdFromApiOrigin(exchange.origin);
      final otherNetworkId = networkIdFromApiOrigin('https://api.other.test');

      await expectLater(
        service.deleteChannelMessage(
          channelId: '$otherNetworkId/321',
          messageId: '$networkId/181215028619407361',
        ),
        throwsA(
          isA<ServerSettingsException>().having(
            (error) => error.message,
            'message',
            'Channel route did not match network',
          ),
        ),
      );

      await expectLater(
        service.deleteChannelMessage(
          channelId: '$networkId/321',
          messageId: '$otherNetworkId/181215028619407361',
        ),
        throwsA(
          isA<ServerSettingsException>().having(
            (error) => error.message,
            'message',
            'Message route did not match network',
          ),
        ),
      );
    },
  );

  test(
    'moderation actions route through scoped server and member ids',
    () async {
      final requests = <String>[];
      final bodies = <Object?>[];
      final exchange = await _JsonExchange.start((request, body) async {
        requests.add('${request.method} ${request.uri.path}');
        bodies.add(body);
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        switch (requests.length) {
          case 1:
            expect(request.method, 'POST');
            expect(request.uri.path, '/api/servers/123/members/456/kick');
            expect(body, {'reason': 'spam'});
            return {'success': true};
          case 2:
            expect(request.method, 'POST');
            expect(request.uri.path, '/api/servers/123/bans/456');
            expect(body, {'reason': null});
            return {'success': true};
          default:
            expect(request.method, 'DELETE');
            expect(request.uri.path, '/api/servers/123/bans/456');
            expect(body, isNull);
            return {'success': true};
        }
      }, requestCount: 3);
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);
      final networkId = networkIdFromApiOrigin(exchange.origin);

      await service.kickMember(
        serverId: '$networkId/123',
        userId: '$networkId/456',
        reason: '  spam  ',
      );
      await service.banMember(
        serverId: '$networkId/123',
        userId: '$networkId/456',
      );
      await service.unbanMember(
        serverId: '$networkId/123',
        userId: '$networkId/456',
      );

      expect(requests, [
        'POST /api/servers/123/members/456/kick',
        'POST /api/servers/123/bans/456',
        'DELETE /api/servers/123/bans/456',
      ]);
      expect(bodies.last, isNull);
    },
  );

  test('moderation actions reject cross-network ids before egress', () async {
    final exchange = await _JsonExchange.start((request, body) async {
      fail('Unexpected backend request for mismatched moderation route');
    });
    addTearDown(exchange.close);
    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);
    final networkId = networkIdFromApiOrigin(exchange.origin);
    final otherNetworkId = networkIdFromApiOrigin('https://api.other.test');

    await expectLater(
      service.kickMember(
        serverId: '$networkId/123',
        userId: '$otherNetworkId/456',
      ),
      throwsA(
        isA<ServerSettingsException>().having(
          (error) => error.message,
          'message',
          'Member route did not match network',
        ),
      ),
    );

    await expectLater(
      service.banMember(
        serverId: '$otherNetworkId/123',
        userId: '$networkId/456',
      ),
      throwsA(
        isA<ServerSettingsException>().having(
          (error) => error.message,
          'message',
          'Server route did not match network',
        ),
      ),
    );
  });

  test('lists banned users with scoped ids and redacted object text', () async {
    final exchange = await _JsonExchange.start((request, body) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/servers/123/bans');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access-secret',
      );
      return [
        {
          'userId': '456',
          'username': 'spammer',
          'avatarUrl': 'https://cdn.example.com/avatars/spammer.webp',
          'bannedBy': '42',
          'reason': 'link spam',
          'createdAt': '2026-06-10T12:00:00Z',
          'accessToken': 'must-not-leak',
          'sessionToken': 'must-not-leak',
        },
      ];
    });
    addTearDown(exchange.close);

    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);
    final networkId = networkIdFromApiOrigin(exchange.origin);

    final bans = await service.listBans(serverId: '$networkId/123');

    expect(bans.single.userId, '$networkId/456');
    expect(bans.single.username, 'spammer');
    expect(bans.single.reason, 'link spam');
    expect(bans.single.actorId, '$networkId/42');
    expect(bans.single.toString(), isNot(contains('must-not-leak')));
  });

  test(
    'loads audit events with scoped cursor and richer event fields',
    () async {
      final requestedUris = <Uri>[];
      final exchange = await _JsonExchange.start((request, body) async {
        requestedUris.add(request.uri);
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/servers/123/audit-log');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        return {
          'entries': [
            {
              'id': '900',
              'actorId': '42',
              'actorUsername': 'Moderator',
              'actorAvatar': 'https://cdn.example.com/avatars/mod.webp',
              'action': 'BAN_MEMBER',
              'targetType': 'user',
              'targetId': '456',
              'metadata': {'reason': 'spam'},
              'createdAt': '2026-06-10T12:00:00Z',
              'bearer': 'must-not-leak',
            },
          ],
          'hasMore': true,
        };
      });
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);
      final networkId = networkIdFromApiOrigin(exchange.origin);

      final page = await service.listAuditEvents(
        serverId: '$networkId/123',
        beforeEventId: '$networkId/901',
      );

      expect(requestedUris.single.queryParameters, {
        'limit': '50',
        'before': '901',
      });
      expect(page.hasMore, isTrue);
      expect(page.entries.single.id, '$networkId/900');
      expect(page.entries.single.actorId, '$networkId/42');
      expect(page.entries.single.targetId, '$networkId/456');
      expect(page.entries.single.action, 'BAN_MEMBER');
      expect(page.entries.single.reason, 'spam');
      expect(page.entries.single.toString(), isNot(contains('must-not-leak')));
    },
  );

  test(
    'bot and emoji admin routes are scoped and token text is not logged',
    () async {
      final emojiFile = await File(
        '${Directory.systemTemp.path}/verdant-emoji-upload.webp',
      ).writeAsBytes(_testWebpBytes);
      addTearDown(() async {
        if (await emojiFile.exists()) {
          await emojiFile.delete();
        }
      });
      final requests = <String>[];
      final bodies = <Object?>[];
      final exchange = await _JsonExchange.start((request, body) async {
        requests.add('${request.method} ${request.uri.path}');
        bodies.add(body);
        switch (requests.length) {
          case 1:
            expect(request.uri.path, '/api/servers/123/bots');
            expect(body, {
              'name': 'Deploy Bot',
              'description': 'release helper',
              'avatarPreset': 'verdant',
              'bannerPreset': 'aurora',
            });
            return {
              'id': '700',
              'name': 'Deploy Bot',
              'description': 'release helper',
              'status': 'offline',
            };
          case 2:
            expect(request.uri.path, '/api/servers/123/bots/700');
            expect(body, {'name': 'Deploy Helper'});
            return {
              'id': '700',
              'name': 'Deploy Helper',
              'description': 'release helper',
              'status': 'offline',
            };
          case 3:
            expect(request.uri.path, '/api/servers/123/bots/700/tokens');
            expect(body, {
              'name': 'deploy',
              'scopes': ['announcements:write'],
            });
            return {
              'tokenId': '900',
              'token': 'bot-token-must-not-leak',
              'name': 'deploy',
              'scopes': ['announcements:write'],
            };
          case 4:
            expect(request.uri.path, '/api/servers/123/emojis');
            expect(
              request.headers.contentType?.mimeType,
              'multipart/form-data',
            );
            final raw = utf8.decode(body! as Uint8List, allowMalformed: true);
            expect(raw, contains('name="name"'));
            expect(raw, contains('wave_upload'));
            expect(raw, contains('name="file"'));
            expect(raw, contains('filename="verdant-emoji-upload.webp"'));
            return {
              'id': '320',
              'serverId': '123',
              'name': 'wave_upload',
              'url': 'https://cdn.example.com/emojis/wave-upload.webp',
            };
          case 5:
            expect(request.uri.path, '/api/servers/123/emojis/321');
            expect(body, {'name': 'wave'});
            return {
              'id': '321',
              'serverId': '123',
              'name': 'wave',
              'url': 'https://cdn.example.com/emojis/wave.webp',
            };
          case 6:
            expect(request.uri.path, '/api/servers/123/emojis/321');
            expect(body, isNull);
            return {'success': true};
          default:
            expect(request.uri.path, '/api/servers/123/bots/700');
            expect(body, isNull);
            return {'success': true};
        }
      }, requestCount: 7);
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);
      final networkId = networkIdFromApiOrigin(exchange.origin);

      final created = await service.createBot(
        serverId: '$networkId/123',
        patch: const ServerBotPatch(
          name: ' Deploy Bot ',
          description: ' release helper ',
          avatarPreset: 'verdant',
          bannerPreset: 'aurora',
        ),
      );
      final updated = await service.updateBot(
        serverId: '$networkId/123',
        botId: '$networkId/700',
        patch: const ServerBotPatch(name: 'Deploy Helper'),
      );
      final token = await service.generateBotToken(
        serverId: '$networkId/123',
        botId: '$networkId/700',
        patch: const BotTokenPatch(
          name: 'deploy',
          scopes: ['announcements:write'],
        ),
      );
      final uploadedEmoji = await service.uploadEmoji(
        serverId: '$networkId/123',
        name: ' wave_upload ',
        upload: ServerSettingsUpload(
          path: emojiFile.path,
          fileName: 'verdant-emoji-upload.webp',
        ),
      );
      final emoji = await service.renameEmoji(
        serverId: '$networkId/123',
        emojiId: '$networkId/321',
        name: ' wave ',
      );
      await service.deleteEmoji(
        serverId: '$networkId/123',
        emojiId: '$networkId/321',
      );
      await service.deleteBot(
        serverId: '$networkId/123',
        botId: '$networkId/700',
      );

      expect(created.id, '700');
      expect(updated.title, 'Deploy Helper');
      expect(token.token, 'bot-token-must-not-leak');
      expect(token.toString(), isNot(contains('bot-token-must-not-leak')));
      expect(uploadedEmoji.title, ':wave_upload:');
      expect(emoji.title, ':wave:');
      expect(requests, [
        'POST /api/servers/123/bots',
        'PATCH /api/servers/123/bots/700',
        'POST /api/servers/123/bots/700/tokens',
        'POST /api/servers/123/emojis',
        'PATCH /api/servers/123/emojis/321',
        'DELETE /api/servers/123/emojis/321',
        'DELETE /api/servers/123/bots/700',
      ]);
    },
  );

  test('emoji admin rejects invalid names before HTTP egress', () async {
    var calledBackend = false;
    final exchange = await _JsonExchange.start((request, body) {
      calledBackend = true;
      return <String, Object?>{'unexpected': true};
    });
    addTearDown(exchange.close);

    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);
    final networkId = networkIdFromApiOrigin(exchange.origin);

    await expectLater(
      service.uploadEmoji(
        serverId: '$networkId/123',
        name: 'bad name',
        upload: const ServerSettingsUpload(
          path: 'missing.webp',
          fileName: 'missing.webp',
        ),
      ),
      throwsA(
        isA<ServerSettingsException>().having(
          (error) => error.message,
          'message',
          'Use 2-32 letters, numbers, or underscores.',
        ),
      ),
    );
    await expectLater(
      service.renameEmoji(
        serverId: '$networkId/123',
        emojiId: '$networkId/321',
        name: 'x',
      ),
      throwsA(
        isA<ServerSettingsException>().having(
          (error) => error.message,
          'message',
          'Use 2-32 letters, numbers, or underscores.',
        ),
      ),
    );
    expect(calledBackend, isFalse);
  });

  test('createServer sanitizes the submitted server name', () async {
    final exchange = await _JsonExchange.start((request, body) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/servers');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access-secret',
      );
      expect(body, {'name': 'Verdant Server'});
      request.response.statusCode = HttpStatus.created;
      return _serverJson(id: 'created', name: 'Verdant Server');
    });
    final credentialStore = _MemoryCredentialStore(
      const AuthCredentialBundle(
        apiOrigin: 'http://127.0.0.1',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
      ),
      overrideApiOrigin: exchange.origin,
    );
    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: credentialStore,
    );
    addTearDown(service.close);
    addTearDown(exchange.close);

    final created = await service.createServer(
      name: ' <b>Verdant\u202e Server</b>\u200b ',
    );

    expect(created.id, 'created');
    expect(created.name, 'Verdant Server');
  });

  test(
    'updateChannel rejects mismatched scoped channel routes before egress',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        fail('Unexpected backend request for mismatched channel route');
      });
      addTearDown(exchange.close);
      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      await expectLater(
        service.updateChannel(
          channelId: 'origin:https%3A%2F%2Fother.example/321',
          patch: const ChannelSettingsPatch(name: 'announcements'),
        ),
        throwsA(
          isA<ServerSettingsException>().having(
            (error) => error.message,
            'message',
            'Channel route did not match network',
          ),
        ),
      );
    },
  );

  test(
    'creates, revokes, and leaves through server invite endpoints',
    () async {
      final requests = <String>[];
      final exchange = await _JsonExchange.start((request, body) async {
        requests.add('${request.method} ${request.uri.path}');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        switch ('${request.method} ${request.uri.path}') {
          case 'POST /api/servers/123/invites':
            expect(body, {'maxUses': 5, 'expiresIn': 3600});
            request.response.statusCode = HttpStatus.created;
            return {
              'code': 'abc123',
              'inviterUsername': 'Joshy',
              'uses': 0,
              'maxUses': 5,
              'expiresAt': '2026-06-06T10:00:00Z',
              'createdAt': '2026-06-05T10:00:00Z',
            };
          case 'DELETE /api/servers/123/invites/abc123':
            expect(body, isNull);
            return {'ok': true};
          case 'DELETE /api/servers/123/leave':
            expect(body, isNull);
            return {'ok': true};
        }
        fail('Unexpected request ${request.method} ${request.uri.path}');
      }, requestCount: 3);
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final invite = await service.createInvite(
        serverId: '123',
        maxUses: 5,
        expiresIn: const Duration(hours: 1),
      );
      await service.revokeInvite(serverId: '123', code: 'abc123');
      await service.leaveServer(serverId: '123');

      expect(invite.inviteCode, 'abc123');
      expect(invite.inviterUsername, 'Joshy');
      expect(invite.inviteUses, 0);
      expect(invite.inviteMaxUses, 5);
      expect(requests, [
        'POST /api/servers/123/invites',
        'DELETE /api/servers/123/invites/abc123',
        'DELETE /api/servers/123/leave',
      ]);
    },
  );

  test(
    'server invite routes reject mismatched scoped servers before egress',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        fail('Unexpected backend request for mismatched server invite route');
      });
      addTearDown(exchange.close);
      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);
      final otherNetworkId = networkIdFromApiOrigin('https://api.other.test');

      await expectLater(
        service.createInvite(serverId: '$otherNetworkId/123'),
        throwsA(
          isA<ServerSettingsException>().having(
            (error) => error.message,
            'message',
            'Server route did not match network',
          ),
        ),
      );
      await expectLater(
        service.revokeInvite(serverId: '$otherNetworkId/123', code: 'abc123'),
        throwsA(
          isA<ServerSettingsException>().having(
            (error) => error.message,
            'message',
            'Server route did not match network',
          ),
        ),
      );
      await expectLater(
        service.leaveServer(serverId: '$otherNetworkId/123'),
        throwsA(
          isA<ServerSettingsException>().having(
            (error) => error.message,
            'message',
            'Server route did not match network',
          ),
        ),
      );
    },
  );

  test(
    'loads real server overview data with backend banner crop fields',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/servers');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        expect(body, isNull);

        return {
          'servers': [
            _serverJson(
              id: '123',
              name: 'Actual Verdant',
              iconUrl: 'https://media.verdant.chat/server-icons/123/icon.webp',
              bannerUrl:
                  'https://media.verdant.chat/server-banners/123/banner.webp',
              bannerCrop: {
                'x': 12.34567,
                'y': 4.321,
                'width': 70.25,
                'height': 24.75,
              },
              memberCount: 42,
            ),
          ],
          'serverOrder': ['123'],
          'favoriteOrder': [],
        };
      });
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final servers = await service.listServers();

      expect(servers, hasLength(1));
      expect(servers.single.id, '123');
      expect(servers.single.name, 'Actual Verdant');
      expect(servers.single.iconUrl, contains('/server-icons/123/'));
      expect(servers.single.bannerUrl, contains('/server-banners/123/'));
      expect(
        servers.single.bannerCrop,
        const BannerCrop(x: 12.3457, y: 4.321, width: 70.25, height: 24.75),
      );
      expect(servers.single.memberCount, 42);
    },
  );

  test(
    'saves banner crop through the backend crop endpoint without logging tokens',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        expect(request.method, 'PATCH');
        expect(request.uri.path, '/api/servers/123/banner/crop');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        expect(body, {
          'bannerCrop': {'x': 5.5, 'y': 10.25, 'width': 80.0, 'height': 45.0},
        });

        return _serverJson(
          id: '123',
          name: 'Actual Verdant',
          bannerUrl: 'https://media.verdant.chat/server-banners/123/new.webp',
          bannerCrop: {'x': 5.5, 'y': 10.25, 'width': 80.0, 'height': 45.0},
        );
      });
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final updated = await service.updateBannerCrop(
        serverId: '123',
        crop: const BannerCrop(x: 5.5, y: 10.25, width: 80, height: 45),
      );

      expect(
        updated.bannerCrop,
        const BannerCrop(x: 5.5, y: 10.25, width: 80, height: 45),
      );
      expect(service.toString(), isNot(contains('access-secret')));
      expect(service.toString(), isNot(contains('session-secret')));
    },
  );

  test(
    'updates server overview fields through the backend patch endpoint',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        expect(request.method, 'PATCH');
        expect(request.uri.path, '/api/servers/123');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        expect(body, {'name': 'Renamed Verdant', 'welcomeChannelId': null});

        return _serverJson(id: '123', name: 'Renamed Verdant');
      });
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final updated = await service.updateServer(
        serverId: '123',
        patch: const ServerSettingsPatch(
          name: 'Renamed Verdant',
          welcomeChannelId: null,
        ),
      );

      expect(updated.name, 'Renamed Verdant');
      expect(updated.welcomeChannelId, '321');
    },
  );

  test('uploads and removes server media through backend endpoints', () async {
    final temp = await Directory.systemTemp.createTemp('verdant_media_test');
    addTearDown(() => temp.delete(recursive: true));
    final icon = File('${temp.path}${Platform.pathSeparator}icon.png');
    final banner = File('${temp.path}${Platform.pathSeparator}banner.webp');
    await icon.writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]);
    await banner.writeAsBytes([
      0x52,
      0x49,
      0x46,
      0x46,
      0x01,
      0x00,
      0x00,
      0x00,
      0x57,
      0x45,
      0x42,
      0x50,
    ]);
    final seen = <String>[];
    final exchange = await _JsonExchange.start((request, body) async {
      seen.add('${request.method} ${request.uri.path}');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access-secret',
      );

      if (request.method == 'POST') {
        expect(body, isA<Uint8List>());
        expect(request.headers.contentType?.mimeType, 'multipart/form-data');
        final raw = utf8.decode(body! as Uint8List, allowMalformed: true);
        expect(raw, contains('name="file"'));
        expect(raw, contains('Content-Disposition: form-data'));
        if (request.uri.path.endsWith('/icon')) {
          expect(raw, contains('filename="icon.png"'));
          return _serverJson(
            id: '123',
            name: 'Actual Verdant',
            iconUrl: 'https://media.verdant.chat/server-icons/123/icon.webp',
          );
        }
        expect(raw, contains('filename="banner.webp"'));
        return _serverJson(
          id: '123',
          name: 'Actual Verdant',
          bannerUrl:
              'https://media.verdant.chat/server-banners/123/banner.webp',
        );
      }

      expect(body, isNull);
      if (request.uri.path.endsWith('/icon')) {
        return _serverJson(id: '123', name: 'Actual Verdant', iconUrl: null);
      }
      return _serverJson(id: '123', name: 'Actual Verdant', bannerUrl: null);
    }, requestCount: 4);
    addTearDown(exchange.close);

    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);

    final uploadedIcon = await service.uploadServerIcon(
      serverId: '123',
      upload: ServerSettingsUpload(path: icon.path, fileName: 'icon.png'),
    );
    final removedIcon = await service.deleteServerIcon(serverId: '123');
    final uploadedBanner = await service.uploadServerBanner(
      serverId: '123',
      upload: ServerSettingsUpload(path: banner.path, fileName: 'banner.webp'),
    );
    final removedBanner = await service.deleteServerBanner(serverId: '123');

    expect(uploadedIcon.iconUrl, contains('/server-icons/123/'));
    expect(removedIcon.iconUrl, isNull);
    expect(uploadedBanner.bannerUrl, contains('/server-banners/123/'));
    expect(removedBanner.bannerUrl, isNull);
    expect(seen, [
      'POST /api/servers/123/icon',
      'DELETE /api/servers/123/icon',
      'POST /api/servers/123/banner',
      'DELETE /api/servers/123/banner',
    ]);
  });

  test('uploads, positions, and removes member-list banner media', () async {
    final banner = await File(
      '${Directory.systemTemp.path}/member-banner.webp',
    ).writeAsBytes(_testWebpBytes);
    addTearDown(() async {
      if (await banner.exists()) {
        await banner.delete();
      }
    });

    final seen = <String>[];
    final exchange = await _JsonExchange.start((request, body) async {
      seen.add('${request.method} ${request.uri.path}');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access-secret',
      );
      if (request.method == 'POST') {
        expect(request.uri.path, '/api/users/me/member-list-banner');
        expect(request.headers.contentType?.mimeType, 'multipart/form-data');
        final raw = utf8.decode(body! as Uint8List, allowMalformed: true);
        expect(raw, contains('name="file"'));
        expect(raw, contains('filename="member-banner.webp"'));
        return {
          'memberListBannerUrl':
              'https://media.verdant.chat/member-list-banners/42/banner.webp',
          'memberListBannerCrop': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
        };
      }
      if (request.method == 'PATCH') {
        expect(request.uri.path, '/api/users/me/member-list-banner/crop');
        final decoded = body! as Map<String, Object?>;
        expect(decoded['bannerCrop'], {
          'x': 12.0,
          'y': 6.0,
          'width': 70.0,
          'height': 42.0,
        });
        return {
          'memberListBannerCrop': {'x': 12, 'y': 6, 'width': 70, 'height': 42},
        };
      }
      expect(request.method, 'DELETE');
      expect(request.uri.path, '/api/users/me/member-list-banner');
      expect(body, isNull);
      return {'memberListBannerUrl': null, 'memberListBannerCrop': null};
    }, requestCount: 3);
    addTearDown(exchange.close);

    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);

    final uploaded = await service.uploadMemberListBanner(
      upload: ServerSettingsUpload(
        path: banner.path,
        fileName: 'member-banner.webp',
      ),
    );
    final positioned = await service.updateMemberListBannerCrop(
      crop: const BannerCrop(x: 12, y: 6, width: 70, height: 42),
    );
    final removed = await service.deleteMemberListBanner();

    expect(uploaded.memberListBannerUrl, contains('/member-list-banners/42/'));
    expect(positioned.memberListBannerCrop?.width, 70);
    expect(removed.memberListBannerUrl, isNull);
    expect(removed.memberListBannerCrop, isNull);
    expect(seen, [
      'POST /api/users/me/member-list-banner',
      'PATCH /api/users/me/member-list-banner/crop',
      'DELETE /api/users/me/member-list-banner',
    ]);
  });

  test('uploads avatar and manages profile banner media', () async {
    final avatar = await File(
      '${Directory.systemTemp.path}/profile-avatar.webp',
    ).writeAsBytes(_testWebpBytes);
    final banner = await File(
      '${Directory.systemTemp.path}/profile-banner.webp',
    ).writeAsBytes(_testWebpBytes);
    addTearDown(() async {
      if (await avatar.exists()) {
        await avatar.delete();
      }
      if (await banner.exists()) {
        await banner.delete();
      }
    });

    final seen = <String>[];
    final exchange = await _JsonExchange.start((request, body) async {
      seen.add('${request.method} ${request.uri.path}');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access-secret',
      );
      if (request.method == 'POST' &&
          request.uri.path == '/api/users/me/avatar') {
        expect(request.headers.contentType?.mimeType, 'multipart/form-data');
        final raw = utf8.decode(body! as Uint8List, allowMalformed: true);
        expect(raw, contains('name="file"'));
        expect(raw, contains('filename="profile-avatar.webp"'));
        return {'avatarUrl': 'https://media.verdant.chat/avatars/42/a.webp'};
      }
      if (request.method == 'DELETE' &&
          request.uri.path == '/api/users/me/avatar') {
        expect(body, isNull);
        return {'avatarUrl': null};
      }
      if (request.method == 'POST' &&
          request.uri.path == '/api/users/me/banner') {
        expect(request.headers.contentType?.mimeType, 'multipart/form-data');
        final raw = utf8.decode(body! as Uint8List, allowMalformed: true);
        expect(raw, contains('name="file"'));
        expect(raw, contains('filename="profile-banner.webp"'));
        return {
          'bannerUrl': 'https://media.verdant.chat/profile-banners/42/b.webp',
          'bannerCrop': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
        };
      }
      if (request.method == 'PATCH' &&
          request.uri.path == '/api/users/me/banner/crop') {
        final decoded = body! as Map<String, Object?>;
        expect(decoded['bannerCrop'], {
          'x': 4.0,
          'y': 8.0,
          'width': 82.0,
          'height': 46.0,
        });
        return {
          'bannerUrl': 'https://media.verdant.chat/profile-banners/42/b.webp',
          'bannerCrop': {'x': 4, 'y': 8, 'width': 82, 'height': 46},
        };
      }
      expect(request.method, 'DELETE');
      expect(request.uri.path, '/api/users/me/banner');
      expect(body, isNull);
      return {'bannerUrl': null, 'bannerCrop': null};
    }, requestCount: 5);
    addTearDown(exchange.close);

    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);

    final uploadedAvatar = await service.uploadUserAvatar(
      upload: ServerSettingsUpload(
        path: avatar.path,
        fileName: 'profile-avatar.webp',
      ),
    );
    final removedAvatar = await service.deleteUserAvatar();
    final uploadedBanner = await service.uploadUserProfileBanner(
      upload: ServerSettingsUpload(
        path: banner.path,
        fileName: 'profile-banner.webp',
      ),
    );
    final positionedBanner = await service.updateUserProfileBannerCrop(
      crop: const BannerCrop(x: 4, y: 8, width: 82, height: 46),
    );
    final removedBanner = await service.deleteUserProfileBanner();

    expect(uploadedAvatar.avatarUrl, contains('/avatars/42/'));
    expect(removedAvatar.avatarUrl, isNull);
    expect(uploadedBanner.bannerUrl, contains('/profile-banners/42/'));
    expect(positionedBanner.bannerCrop?.width, 82);
    expect(removedBanner.bannerUrl, isNull);
    expect(removedBanner.bannerCrop, isNull);
    expect(seen, [
      'POST /api/users/me/avatar',
      'DELETE /api/users/me/avatar',
      'POST /api/users/me/banner',
      'PATCH /api/users/me/banner/crop',
      'DELETE /api/users/me/banner',
    ]);
  });

  test('keeps profile and member-list banners separate for members', () async {
    final exchange = await _JsonExchange.start((request, body) async {
      if (request.uri.path == '/api/instance') {
        expect(request.headers.value(HttpHeaders.authorizationHeader), isNull);
        return {
          'apiUrl': '${request.uri.scheme}://${request.headers.host}',
          'publicUrl': 'https://example.com',
          'cdnUrl': 'https://cdn.example.com/media',
          'registration': 'public',
          'capabilities': {
            'imageUploads': true,
            'fileSharing': false,
            'messageAttachments': false,
            'voiceChat': true,
            'videoStreaming': false,
            'crossServerEmoji': false,
            'animatedAvatar': false,
            'animatedBanner': false,
            'memberListBanner': true,
            'maxUploadBytes': 64,
            'maxVoiceBitrate': 96000,
          },
        };
      }

      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access-secret',
      );
      if (request.uri.path.endsWith('/layout')) {
        return {'channels': <Object?>[]};
      }
      if (request.uri.path.endsWith('/roles')) {
        return [
          {
            'id': 'purple',
            'name': 'Purple',
            'permissions': '0',
            'color': '#7CFFDE',
            'position': 2,
            'colorOnly': true,
            'showAsSection': false,
            'colorPriority': 12,
          },
          {
            'id': 'owner',
            'name': 'Owner',
            'permissions': '1024',
            'color': '#C1B3FF',
            'position': 1,
            'colorOnly': false,
            'showAsSection': true,
            'colorPriority': 7,
          },
        ];
      }
      if (request.uri.path.endsWith('/members')) {
        return [
          {
            'userId': '42',
            'username': 'Joshy',
            'displayName': 'Joshy',
            'avatarUrl': 'https://cdn.example.com/media/avatars/joshy.webp',
            'bannerUrl':
                'https://cdn.example.com/media/profile-banners/joshy.webp',
            'bannerCrop': {'x': 8, 'y': 12, 'width': 84, 'height': 60},
            'memberListBannerUrl':
                'https://cdn.example.com/media/member-list-banners/joshy.webp',
            'memberListBannerCrop': {
              'x': 18,
              'y': 4,
              'width': 66,
              'height': 44,
            },
            'status': 'idle',
            'joinedAt': '2026-06-01T10:00:00Z',
            'roleIds': ['purple', 'owner'],
          },
        ];
      }
      if (request.uri.path.endsWith('/feeds')) {
        return [
          {
            'id': 'feed-1',
            'serverId': '123',
            'name': 'Announcements',
            'description': 'Server news',
            'position': 0,
            'publishRoleIds': ['owner'],
            'visibleRoleIds': null,
          },
        ];
      }
      if (request.uri.path.endsWith('/audit-log')) {
        return {'entries': <Object?>[]};
      }
      return <Object?>[];
    }, requestCount: 8);
    addTearDown(exchange.close);

    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);

    final settings = await service.loadServerSettings(
      _serverFrom(id: '123', name: 'Actual Verdant'),
    );

    expect(settings.members.single.avatarUrl, contains('/avatars/joshy.webp'));
    final purpleRole = settings.roles.firstWhere((role) => role.id == 'purple');
    final ownerRole = settings.roles.firstWhere((role) => role.id == 'owner');
    expect(purpleRole.colorOnly, isTrue);
    expect(purpleRole.colorPriority, 12);
    expect(ownerRole.showAsSection, isTrue);
    expect(ownerRole.colorPriority, 7);
    expect(
      settings.members.single.bannerUrl,
      contains('/profile-banners/joshy.webp'),
    );
    expect(
      settings.members.single.memberListBannerUrl,
      contains('/member-list-banners/joshy.webp'),
    );
    expect(settings.members.single.bannerCrop?.x, 8);
    expect(settings.members.single.memberListBannerCrop?.width, 66);
    expect(settings.feeds.single.title, 'Announcements');
    expect(settings.feeds.single.publishRoleIds, ['owner']);

    final workspace = WorkspaceSeed.fromSettingsData(
      settings,
      currentUserId: '42',
      currentUserName: 'Joshy',
      currentUserInitials: 'JO',
    );
    expect(workspace.members.single.role, 'Owner');
    expect(workspace.members.single.nameColorName, 'Purple');
    expect(workspace.members.single.roleIds, ['purple', 'owner']);
    expect(
      workspace.members.single.bannerUrl,
      contains('/profile-banners/joshy.webp'),
    );
    expect(
      workspace.members.single.memberListBannerUrl,
      contains('/member-list-banners/joshy.webp'),
    );
    expect(workspace.members.single.bannerCrop?.y, 12);
    expect(workspace.members.single.memberListBannerCrop?.height, 44);
  });

  test(
    'creates and updates server roles through the existing role routes',
    () async {
      final seen = <String>[];
      final bodies = <Object?>[];
      final exchange = await _JsonExchange.start((request, body) async {
        seen.add('${request.method} ${request.uri.path}');
        bodies.add(body);
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );

        if (request.method == 'POST' &&
            request.uri.path == '/api/servers/server-1/roles') {
          expect(body, {
            'name': 'New Role',
            'colorOnly': false,
            'showAsSection': true,
            'permissions': '32',
          });
          return {
            'id': 'role-1',
            'name': 'New Role',
            'permissions': '32',
            'color': null,
            'position': 3,
            'colorOnly': false,
            'showAsSection': true,
            'colorPriority': 3,
          };
        }

        expect(request.method, 'PATCH');
        expect(request.uri.path, '/api/servers/server-1/roles/role-1');
        expect(body, {
          'name': 'Moderators',
          'color': '#22c55e',
          'permissions': '0',
          'colorOnly': false,
          'showAsSection': false,
          'colorPriority': 9,
        });
        return {
          'id': 'role-1',
          'name': 'Moderators',
          'permissions': '0',
          'color': '#22c55e',
          'position': 3,
          'colorOnly': false,
          'showAsSection': false,
          'colorPriority': 9,
        };
      }, requestCount: 2);
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final created = await service.createRole(
        serverId: 'server-1',
        patch: const ServerRolePatch(
          name: 'New Role',
          permissions: 32,
          colorOnly: false,
          showAsSection: true,
        ),
      );
      final updated = await service.updateRole(
        serverId: 'server-1',
        roleId: 'role-1',
        patch: const ServerRolePatch(
          name: 'Moderators',
          color: '#22c55e',
          permissions: 0,
          colorOnly: false,
          showAsSection: false,
          colorPriority: 9,
        ),
      );

      expect(created.id, 'role-1');
      expect(created.showAsSection, isTrue);
      expect(updated.title, 'Moderators');
      expect(updated.colorOnly, isFalse);
      expect(updated.colorPriority, 9);
      expect(seen, [
        'POST /api/servers/server-1/roles',
        'PATCH /api/servers/server-1/roles/role-1',
      ]);
      expect(bodies, hasLength(2));
    },
  );

  test('sets own name color through the member name color endpoint', () async {
    final seen = <String>[];
    final bodies = <Map<String, Object?>>[];
    final exchange = await _JsonExchange.start((request, body) async {
      seen.add('${request.method} ${request.uri.path}');
      bodies.add(body == null ? const {} : body as Map<String, Object?>);
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access-secret',
      );
      return {
        'success': true,
        'roleIds': ['access', 'mint'],
      };
    });
    addTearDown(exchange.close);

    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);

    final roleIds = await service.setOwnNameColor(
      serverId: '${networkIdFromApiOrigin(exchange.origin)}/server-1',
      roleId: '${networkIdFromApiOrigin(exchange.origin)}/mint',
    );

    expect(roleIds, ['access', 'mint']);
    expect(seen, ['PATCH /api/servers/server-1/members/@me/name-color']);
    expect(bodies.single, {'roleId': 'mint'});
  });

  test(
    'creates, updates, and deletes feeds through scoped backend routes',
    () async {
      final seen = <String>[];
      final bodies = <Map<String, Object?>>[];
      final exchange = await _JsonExchange.start((request, body) async {
        seen.add('${request.method} ${request.uri.path}');
        if (body is Map<String, Object?>) {
          bodies.add(body);
        }
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        switch ('${request.method} ${request.uri.path}') {
          case 'POST /api/servers/server-1/feeds':
            expect(body, {
              'name': 'Patch Notes',
              'description': 'Release notes',
              'icon': 'PN',
              'publishRoleIds': ['publisher'],
              'visibleRoleIds': null,
            });
            request.response.statusCode = HttpStatus.created;
            return {
              'id': 'feed-1',
              'serverId': 'server-1',
              'name': 'Patch Notes',
              'description': 'Release notes',
              'icon': 'PN',
              'position': 0,
              'publishRoleIds': ['publisher'],
              'visibleRoleIds': null,
              'createdAt': '2026-06-10T10:00:00Z',
            };
          case 'PATCH /api/servers/server-1/feeds/feed-1':
            expect(body, {
              'name': 'Deploy Notes',
              'description': null,
              'icon': null,
              'publishRoleIds': null,
              'visibleRoleIds': ['member'],
            });
            return {
              'id': 'feed-1',
              'serverId': 'server-1',
              'name': 'Deploy Notes',
              'description': null,
              'icon': null,
              'position': 0,
              'publishRoleIds': null,
              'visibleRoleIds': ['member'],
              'createdAt': '2026-06-10T10:00:00Z',
            };
          case 'DELETE /api/servers/server-1/feeds/feed-1':
            expect(body, isNull);
            return {'success': true};
        }
        fail('Unexpected request ${request.method} ${request.uri.path}');
      }, requestCount: 3);
      addTearDown(exchange.close);

      final networkId = networkIdFromApiOrigin(exchange.origin);
      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final created = await service.createFeed(
        serverId: '$networkId/server-1',
        patch: ServerFeedPatch(
          name: 'Patch Notes',
          description: 'Release notes',
          icon: 'PN',
          publishRoleIds: ['$networkId/publisher'],
          visibleRoleIds: const <String>[],
        ),
      );
      final updated = await service.updateFeed(
        serverId: '$networkId/server-1',
        feedId: '$networkId/feed-1',
        patch: ServerFeedPatch(
          name: 'Deploy Notes',
          description: null,
          icon: null,
          publishRoleIds: const <String>[],
          visibleRoleIds: ['$networkId/member'],
        ),
      );
      await service.deleteFeed(
        serverId: '$networkId/server-1',
        feedId: 'feed-1',
      );

      expect(created.id, 'feed-1');
      expect(created.feedIcon, 'PN');
      expect(created.publishRoleIds, ['publisher']);
      expect(created.visibleRoleIds, isEmpty);
      expect(updated.title, 'Deploy Notes');
      expect(updated.visibleRoleIds, ['member']);
      expect(seen, [
        'POST /api/servers/server-1/feeds',
        'PATCH /api/servers/server-1/feeds/feed-1',
        'DELETE /api/servers/server-1/feeds/feed-1',
      ]);
      expect(bodies, hasLength(2));
    },
  );

  test(
    'rejects mismatched scoped feed role routes before HTTP egress',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        fail('feed write should fail before HTTP egress');
      });
      addTearDown(exchange.close);
      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);
      final networkId = networkIdFromApiOrigin(exchange.origin);
      final otherNetworkId = networkIdFromApiOrigin('https://api.other.test');

      await expectLater(
        service.createFeed(
          serverId: '$networkId/server-1',
          patch: ServerFeedPatch(
            name: 'Bad Route',
            publishRoleIds: ['$otherNetworkId/publisher'],
          ),
        ),
        throwsA(
          isA<ServerSettingsException>().having(
            (error) => error.message,
            'message',
            contains('Feed role route did not match network'),
          ),
        ),
      );
    },
  );

  test(
    'loads, creates, updates, and deletes feed announcements through scoped backend routes',
    () async {
      final seen = <String>[];
      final bodies = <Map<String, Object?>>[];
      final exchange = await _JsonExchange.start((request, body) async {
        seen.add('${request.method} ${request.uri}');
        if (body is Map<String, Object?>) {
          bodies.add(body);
        }
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        switch ('${request.method} ${request.uri.path}') {
          case 'GET /api/feeds/feed-1/announcements':
            expect(request.uri.queryParameters['limit'], '25');
            return [
              {
                'id': 'ann-2',
                'feedId': 'feed-1',
                'serverId': 'server-1',
                'content': {
                  'title': 'Latest persisted',
                  'color': '#1ee3b6',
                  'sections': [
                    {'type': 'divider'},
                  ],
                },
                'postedBy': 'user-1',
                'botId': null,
                'createdAt': '2026-06-12T10:00:00Z',
                'updatedAt': null,
              },
            ];
          case 'POST /api/feeds/feed-1/announcements':
            expect(body, {
              'title': 'Publish me',
              'color': '#1ee3b6',
              'sections': [
                {
                  'type': 'button',
                  'label': 'Read notes',
                  'action': {
                    'type': 'externalUrl',
                    'url': 'https://verdant.chat',
                  },
                },
                {
                  'type': 'video',
                  'url': 'https://www.youtube.com/watch?v=k1_ODDevbY8',
                  'videoId': 'k1_ODDevbY8',
                },
              ],
            });
            request.response.statusCode = HttpStatus.created;
            return {
              'id': 'ann-3',
              'feedId': 'feed-1',
              'serverId': 'server-1',
              'content': body,
              'postedBy': 'user-1',
              'botId': null,
              'createdAt': '2026-06-12T10:01:00Z',
              'updatedAt': null,
            };
          case 'PATCH /api/feeds/feed-1/announcements/ann-3':
            expect(body, {'title': 'Updated', 'color': '#1ee3b6'});
            return {
              'id': 'ann-3',
              'feedId': 'feed-1',
              'serverId': 'server-1',
              'content': body,
              'postedBy': 'user-1',
              'botId': null,
              'createdAt': '2026-06-12T10:01:00Z',
              'updatedAt': '2026-06-12T10:02:00Z',
            };
          case 'DELETE /api/feeds/feed-1/announcements/ann-3':
            expect(body, isNull);
            return {'success': true};
        }
        fail('Unexpected request ${request.method} ${request.uri}');
      }, requestCount: 4);
      addTearDown(exchange.close);

      final networkId = networkIdFromApiOrigin(exchange.origin);
      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final listed = await service.listFeedAnnouncements(
        serverId: '$networkId/server-1',
        feedId: '$networkId/feed-1',
      );
      final created = await service.createFeedAnnouncement(
        serverId: '$networkId/server-1',
        feedId: '$networkId/feed-1',
        draft: const FeedAnnouncementDraft(
          title: 'Publish me',
          color: '#1ee3b6',
          sections: [
            FeedAnnouncementButtonSection(
              label: 'Read notes',
              url: 'https://verdant.chat',
            ),
            FeedAnnouncementYouTubeSection(
              url: 'https://www.youtube.com/watch?v=k1_ODDevbY8',
            ),
          ],
        ),
      );
      final updated = await service.updateFeedAnnouncement(
        serverId: '$networkId/server-1',
        feedId: '$networkId/feed-1',
        announcementId: '$networkId/ann-3',
        draft: const FeedAnnouncementDraft(title: 'Updated', color: '#1ee3b6'),
      );
      await service.deleteFeedAnnouncement(
        serverId: '$networkId/server-1',
        feedId: '$networkId/feed-1',
        announcementId: 'ann-3',
      );

      expect(listed.single.id, 'ann-2');
      expect(listed.single.draft.title, 'Latest persisted');
      expect(created.id, 'ann-3');
      expect(created.draft.sections, hasLength(2));
      expect(updated.updatedAt, '2026-06-12T10:02:00Z');
      expect(seen, [
        'GET /api/feeds/feed-1/announcements?limit=25',
        'POST /api/feeds/feed-1/announcements',
        'PATCH /api/feeds/feed-1/announcements/ann-3',
        'DELETE /api/feeds/feed-1/announcements/ann-3',
      ]);
      expect(bodies, hasLength(2));
    },
  );

  test(
    'rejects mismatched scoped feed announcement routes before HTTP egress',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        fail('announcement read should fail before HTTP egress');
      });
      addTearDown(exchange.close);
      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);
      final networkId = networkIdFromApiOrigin(exchange.origin);
      final otherNetworkId = networkIdFromApiOrigin('https://api.other.test');

      await expectLater(
        service.listFeedAnnouncements(
          serverId: '$networkId/server-1',
          feedId: '$otherNetworkId/feed-1',
        ),
        throwsA(
          isA<ServerSettingsException>().having(
            (error) => error.message,
            'message',
            contains('Feed route did not match network'),
          ),
        ),
      );
    },
  );

  test('rejects mismatched scoped role writes before HTTP egress', () async {
    final exchange = await _JsonExchange.start((request, body) async {
      fail('role write should fail before HTTP egress');
    });
    addTearDown(exchange.close);
    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);
    final otherNetworkId = networkIdFromApiOrigin('https://api.other.test');

    await expectLater(
      service.updateRole(
        serverId: '${networkIdFromApiOrigin(exchange.origin)}/server-1',
        roleId: '$otherNetworkId/role-1',
        patch: const ServerRolePatch(name: 'Bad Route'),
      ),
      throwsA(
        isA<ServerSettingsException>().having(
          (error) => error.message,
          'message',
          contains('Role route did not match network'),
        ),
      ),
    );
  });

  test('loads server settings media policy from instance metadata', () async {
    final exchange = await _JsonExchange.start((request, body) async {
      if (request.uri.path == '/api/instance') {
        expect(request.headers.value(HttpHeaders.authorizationHeader), isNull);
        return {
          'apiUrl': '${request.uri.scheme}://${request.headers.host}',
          'publicUrl': 'https://example.com',
          'cdnUrl': 'https://cdn.example.com/media',
          'registration': 'public',
          'capabilities': {
            'imageUploads': true,
            'fileSharing': false,
            'messageAttachments': false,
            'voiceChat': true,
            'videoStreaming': false,
            'crossServerEmoji': false,
            'animatedAvatar': false,
            'animatedBanner': false,
            'memberListBanner': true,
            'maxUploadBytes': 64,
            'maxVoiceBitrate': 96000,
          },
        };
      }

      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access-secret',
      );
      if (request.uri.path.endsWith('/layout')) {
        return {'channels': <Object?>[]};
      }
      if (request.uri.path.endsWith('/audit-log')) {
        return {'entries': <Object?>[]};
      }
      return <String, Object?>{'items': <Object?>[]};
    }, requestCount: 8);
    addTearDown(exchange.close);

    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);

    final settings = await service.loadServerSettings(
      _serverFrom(id: '123', name: 'Actual Verdant'),
    );

    expect(
      safeServerMediaUri(
        'https://cdn.example.com/media/server-icons/123/icon.webp',
        policy: settings.mediaPolicy,
      ),
      isNotNull,
    );
    expect(
      safeServerMediaUri(
        'https://evil.example/server-icons/123/icon.webp',
        policy: settings.mediaPolicy,
      ),
      isNull,
    );
    expect(settings.entitlements.imageUploads, isTrue);
    expect(settings.entitlements.memberListBanner, isTrue);
    expect(settings.entitlements.maxUploadBytes, 64);
    expect(settings.entitlements.maxVoiceBitrate, 96000);
  });

  test(
    'loads visible server bots during normal workspace settings hydration',
    () async {
      final requestedPaths = <String>[];
      final exchange = await _JsonExchange.start((request, body) async {
        requestedPaths.add(request.uri.path);
        if (request.uri.path == '/api/instance') {
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            isNull,
          );
          return {'apiUrl': '${request.uri.scheme}://${request.headers.host}'};
        }

        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        if (request.uri.path.endsWith('/layout')) {
          return {'channels': <Object?>[]};
        }
        if (request.uri.path.endsWith('/bots')) {
          return [
            {
              'id': 'bot-1',
              'name': 'Verdant Bot',
              'description': 'Publishes feed smoke tests',
              'status': 'online',
              'bot': true,
              'roleIds': ['bot-role'],
              'avatarUrl': 'https://cdn.example.com/media/bot-avatars/bot.webp',
              'bannerUrl': 'https://cdn.example.com/media/bot-banners/bot.webp',
            },
          ];
        }
        return <Object?>[];
      }, requestCount: 8);
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final settings = await service.loadServerSettings(
        _serverFrom(id: '123', name: 'Actual Verdant'),
      );
      final workspace = WorkspaceSeed.fromSettingsData(
        settings,
        currentUserId: '42',
        currentUserName: 'Joshy',
        currentUserInitials: 'JO',
      );

      expect(requestedPaths, contains('/api/servers/123/bots'));
      expect(settings.bots.single.title, 'Verdant Bot');
      expect(settings.bots.single.trailing, 'online');
      final bot = workspace.members.singleWhere((member) => member.isBot);
      expect(bot.name, 'Verdant Bot');
      expect(bot.status, 'online');
      expect(bot.isActive, isTrue);
      expect(bot.avatarUrl, contains('/bot-avatars/bot.webp'));
    },
  );

  test(
    'workspace seed enriches sparse current member media from auth user',
    () {
      final settings = ServerSettingsData(
        networkId: 'official',
        server: _serverFrom(id: 'server-1', name: 'Verdant'),
        channels: <ServerSettingsChannelSeed>[],
        emojis: <ServerSettingsListItemSeed>[],
        invites: <ServerSettingsListItemSeed>[],
        roles: <ServerSettingsListItemSeed>[],
        members: [
          ServerSettingsListItemSeed(
            userId: '42',
            title: 'Joshy',
            subtitle: 'idle - joined Jun 1',
            trailing: '1 role',
          ),
          ServerSettingsListItemSeed(
            userId: '84',
            title: 'Avery',
            subtitle: 'online - joined Jun 1',
            trailing: '1 role',
          ),
        ],
        auditEvents: <ServerSettingsListItemSeed>[],
        feeds: <ServerSettingsListItemSeed>[],
        bots: <ServerSettingsListItemSeed>[],
      );

      final workspace = WorkspaceSeed.fromSettingsData(
        settings,
        currentUserId: '42',
        currentUserName: 'Joshy',
        currentUserInitials: 'JO',
        currentUserAvatarUrl:
            'https://cdn.example.com/media/avatars/joshy.webp',
        currentUserBannerUrl:
            'https://cdn.example.com/media/banners/joshy.webp',
        currentUserMemberListBannerUrl:
            'https://cdn.example.com/media/member-list-banners/joshy.webp',
      );

      expect(workspace.members[0].avatarUrl, contains('/avatars/joshy.webp'));
      expect(workspace.members[0].bannerUrl, contains('/banners/joshy.webp'));
      expect(
        workspace.members[0].memberListBannerUrl,
        contains('/member-list-banners/joshy.webp'),
      );
      expect(workspace.members[1].avatarUrl, isNull);
      expect(workspace.members[1].bannerUrl, isNull);
      expect(workspace.members[1].memberListBannerUrl, isNull);
    },
  );

  test(
    'loads current user media from the authenticated profile endpoint',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/users/me');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        return {
          'id': '42',
          'avatarUrl': 'https://cdn.example.com/media/avatars/joshy.webp',
          'bannerUrl': 'https://cdn.example.com/media/banners/joshy.webp',
          'bannerCrop': {'x': 12, 'y': 8, 'width': 82, 'height': 58},
          'memberListBannerUrl':
              'https://cdn.example.com/media/member-list-banners/joshy.webp',
          'memberListBannerCrop': {'x': 6, 'y': 4, 'width': 70, 'height': 42},
        };
      }, requestCount: 1);
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final media = await service.loadCurrentUserMedia();

      expect(media?.id, '42');
      expect(media?.avatarUrl, contains('/avatars/joshy.webp'));
      expect(media?.bannerUrl, contains('/banners/joshy.webp'));
      expect(media?.bannerCrop?.x, 12);
      expect(
        media?.memberListBannerUrl,
        contains('/member-list-banners/joshy.webp'),
      );
      expect(media?.memberListBannerCrop?.height, 42);
    },
  );

  test(
    'updates current user profile fields through the authenticated profile endpoint',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        expect(request.method, 'PATCH');
        expect(request.uri.path, '/api/users/me');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        expect(body, {'displayName': 'Joshua', 'bio': null});
        return {
          'id': '42',
          'username': 'josh',
          'displayName': 'Joshua',
          'bio': null,
          'email': 'josh@example.com',
          'status': 'online',
          'usernameSet': true,
          'emailVerified': true,
          'totpEnabled': false,
        };
      });
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final updated = await service.updateCurrentUserProfile(
        patch: const UserProfilePatch(displayName: 'Joshua', bio: null),
      );

      expect(updated.displayName, 'Joshua');
      expect(updated.bio, isNull);
    },
  );

  test(
    'changes current user password through the authenticated profile endpoint',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        expect(request.method, 'PATCH');
        expect(request.uri.path, '/api/users/me');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        expect(body, {
          'currentPassword': 'old password',
          'password': 'new password',
        });
        return {
          'id': '42',
          'username': 'josh',
          'email': 'josh@example.com',
          'status': 'online',
          'usernameSet': true,
          'emailVerified': true,
          'totpEnabled': false,
        };
      });
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final updated = await service.changeCurrentUserPassword(
        currentPassword: 'old password',
        newPassword: 'new password',
      );

      expect(updated.id, '42');
    },
  );

  test(
    'starts and confirms current user email changes through the authenticated account endpoints',
    () async {
      var step = 0;
      final exchange = await _JsonExchange.start((request, body) async {
        step += 1;
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        if (step == 1) {
          expect(request.method, 'POST');
          expect(request.uri.path, '/api/users/me/change-email');
          expect(body, {
            'currentEmail': 'josh@example.com',
            'newEmail': 'new@example.com',
            'currentPassword': 'current password',
          });
          return {'codeSent': true, 'has2fa': true};
        }
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/users/me/change-email/confirm');
        expect(body, {'code': '123456'});
        return {'ok': true};
      }, requestCount: 2);
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final started = await service.startCurrentUserEmailChange(
        currentEmail: 'josh@example.com',
        newEmail: 'new@example.com',
        currentPassword: 'current password',
      );
      await service.confirmCurrentUserEmailChange(code: '123456');

      expect(started.codeSent, isTrue);
      expect(started.has2fa, isTrue);
    },
  );

  test(
    'manages two factor authentication through authenticated account endpoints',
    () async {
      var step = 0;
      final exchange = await _JsonExchange.start((request, body) async {
        step += 1;
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        switch (step) {
          case 1:
            expect(request.method, 'GET');
            expect(request.uri.path, '/api/2fa/status');
            expect(body, isNull);
            return {
              'enabled': false,
              'enabledAt': null,
              'remainingBackupCodes': 0,
            };
          case 2:
            expect(request.method, 'POST');
            expect(request.uri.path, '/api/2fa/setup');
            expect(body, {'currentPassword': 'current password'});
            return {
              'secret': 'otpauth-secret-not-logged',
              'qrDataUrl': 'data:image/png;base64,abc',
            };
          case 3:
            expect(request.method, 'POST');
            expect(request.uri.path, '/api/2fa/verify-setup');
            expect(body, {'code': '123456'});
            return {
              'enabled': true,
              'backupCodes': ['backup-1', 'backup-2'],
            };
          case 4:
            expect(request.method, 'POST');
            expect(request.uri.path, '/api/2fa/backup-codes/regenerate');
            expect(body, {
              'currentPassword': 'current password',
              'totpCode': '234567',
            });
            return {
              'backupCodes': ['backup-3', 'backup-4'],
            };
          default:
            expect(request.method, 'POST');
            expect(request.uri.path, '/api/2fa/disable');
            expect(body, {
              'currentPassword': 'current password',
              'code': '345678',
            });
            return {'ok': true};
        }
      }, requestCount: 5);
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final status = await service.loadTwoFactorStatus();
      final setup = await service.startTwoFactorSetup(
        currentPassword: 'current password',
      );
      final verified = await service.verifyTwoFactorSetup(code: '123456');
      final regenerated = await service.regenerateTwoFactorBackupCodes(
        currentPassword: 'current password',
        totpCode: '234567',
      );
      await service.disableTwoFactor(
        currentPassword: 'current password',
        code: '345678',
      );

      expect(status.enabled, isFalse);
      expect(setup.qrDataUrl, startsWith('data:image/png'));
      expect(verified.enabled, isTrue);
      expect(verified.backupCodes, ['backup-1', 'backup-2']);
      expect(regenerated.backupCodes, ['backup-3', 'backup-4']);
    },
  );

  test(
    'loads active channel members with avatar and member-list banner media',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/channels/321/activity');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        final recentMessageAt = DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 5))
            .toIso8601String();
        return [
          {
            'userId': '42',
            'username': 'joshy',
            'displayName': 'Joshy',
            'avatarUrl': 'https://cdn.example.com/media/avatars/joshy.webp',
            'bannerUrl':
                'https://cdn.example.com/media/profile-banners/joshy.webp',
            'bannerCrop': {'x': 8, 'y': 12, 'width': 84, 'height': 60},
            'memberListBannerUrl':
                'https://cdn.example.com/media/member-list-banners/joshy.webp',
            'memberListBannerCrop': {
              'x': 18,
              'y': 4,
              'width': 66,
              'height': 44,
            },
            'status': 'idle',
            'joinedAt': '2026-06-01T10:00:00Z',
            'roleIds': ['purple', 'owner'],
            'lastMessageAt': '2026-06-03T12:00:00Z',
          },
          {
            'userId': '43',
            'username': 'avery',
            'displayName': 'Avery',
            'status': 'online',
            'joinedAt': '2026-06-01T10:00:00Z',
            'roleIds': ['member'],
            'lastMessageAt': recentMessageAt,
          },
        ];
      }, requestCount: 1);
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final members = await service.loadChannelActivity(channelId: '321');

      final joshy = members.firstWhere((member) => member.name == 'Joshy');
      final avery = members.firstWhere((member) => member.name == 'Avery');

      expect(joshy.id, startsWith('origin:'));
      expect(joshy.id, endsWith('/42'));
      expect(joshy.avatarUrl, contains('/avatars/joshy.webp'));
      expect(joshy.bannerUrl, contains('/profile-banners/joshy.webp'));
      expect(
        joshy.memberListBannerUrl,
        contains('/member-list-banners/joshy.webp'),
      );
      expect(joshy.bannerCrop?.x, 8);
      expect(joshy.memberListBannerCrop?.width, 66);
      expect(joshy.lastMessageAt, '2026-06-03T12:00:00Z');
      expect(joshy.isActive, isFalse);
      expect(avery.lastMessageAt, isNotNull);
      expect(avery.isActive, isTrue);
    },
  );

  test(
    'channel activity rejects mismatched scoped channels before egress',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        fail('Unexpected backend request for mismatched activity route');
      });
      addTearDown(exchange.close);
      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);
      final otherNetworkId = networkIdFromApiOrigin('https://api.other.test');

      await expectLater(
        service.loadChannelActivity(channelId: '$otherNetworkId/321'),
        throwsA(
          isA<ServerSettingsException>().having(
            (error) => error.message,
            'message',
            'Channel route did not match network',
          ),
        ),
      );
    },
  );

  test(
    'routes user session listing and revocation to the selected backend',
    () async {
      final requests = <String>[];
      final exchange = await _JsonExchange.start((request, body) async {
        requests.add('${request.method} ${request.uri.path}');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        switch (requests.length) {
          case 1:
            expect(request.method, 'GET');
            expect(request.uri.path, '/api/users/me/sessions');
            expect(body, isNull);
            return [
              {
                'id': 'session-2',
                'isCurrent': false,
                'device': 'Chrome on Windows',
                'city': 'Tampa',
                'country': 'US',
                'createdAt': '2026-06-10T10:00:00Z',
                'lastRefreshAt': '2026-06-15T12:00:00Z',
                'accessToken': 'must-not-leak',
                'sessionToken': 'must-not-leak',
              },
              {
                'id': 'session-1',
                'isCurrent': true,
                'device': 'Verdant Desktop',
                'createdAt': '2026-06-11T10:00:00Z',
                'lastRefreshAt': '2026-06-14T12:00:00Z',
              },
            ];
          case 2:
            expect(request.method, 'DELETE');
            expect(request.uri.path, '/api/users/me/sessions/session-2');
            expect(body, isNull);
            return {'ok': true};
          default:
            expect(request.method, 'POST');
            expect(request.uri.path, '/api/users/me/sessions/revoke-all');
            expect(body, isNull);
            return {'ok': true};
        }
      }, requestCount: 3);
      addTearDown(exchange.close);

      final service = ServerSettingsService(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(
          const AuthCredentialBundle(
            apiOrigin: 'http://127.0.0.1',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          overrideApiOrigin: exchange.origin,
        ),
      );
      addTearDown(service.close);

      final sessions = await service.listSessions();
      await service.revokeSession(sessionId: 'session-2');
      await service.revokeAllOtherSessions();

      expect(sessions.map((session) => session.id), ['session-1', 'session-2']);
      expect(sessions.first.isCurrent, isTrue);
      expect(sessions.last.locationLabel, 'Tampa, US');
      expect(sessions.last.toString(), isNot(contains('must-not-leak')));
      expect(requests, [
        'GET /api/users/me/sessions',
        'DELETE /api/users/me/sessions/session-2',
        'POST /api/users/me/sessions/revoke-all',
      ]);
    },
  );

  test('user media and session routes reject mismatched scoped ids', () async {
    final exchange = await _JsonExchange.start((request, body) async {
      fail('Unexpected backend request for mismatched user settings route');
    });
    addTearDown(exchange.close);
    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);
    final otherNetworkId = networkIdFromApiOrigin('https://api.other.test');

    await expectLater(
      service.loadUserMedia(localUserId: '$otherNetworkId/42'),
      throwsA(
        isA<ServerSettingsException>().having(
          (error) => error.message,
          'message',
          'User route did not match network',
        ),
      ),
    );
    await expectLater(
      service.revokeSession(sessionId: '$otherNetworkId/session-2'),
      throwsA(
        isA<ServerSettingsException>().having(
          (error) => error.message,
          'message',
          'Session route did not match network',
        ),
      ),
    );
  });

  test('routes notification preferences to the selected backend', () async {
    final requests = <String>[];
    final bodies = <Object?>[];
    final exchange = await _JsonExchange.start((request, body) async {
      requests.add('${request.method} ${request.uri.path}');
      bodies.add(body);
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer access-secret',
      );
      switch (requests.length) {
        case 1:
          expect(request.method, 'GET');
          expect(request.uri.path, '/api/users/me/notifications');
          expect(body, isNull);
          return [
            {
              'targetType': 'global',
              'targetId': '0',
              'muted': false,
              'desktopEnabled': true,
              'token': 'must-not-leak',
              'bearer': 'must-not-leak',
            },
          ];
        default:
          expect(request.method, 'PUT');
          expect(request.uri.path, '/api/users/me/notifications');
          expect(body, {
            'targetType': 'global',
            'targetId': '0',
            'muted': true,
            'desktopEnabled': false,
          });
          return {'ok': true};
      }
    }, requestCount: 2);
    addTearDown(exchange.close);

    final service = ServerSettingsService(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(
        const AuthCredentialBundle(
          apiOrigin: 'http://127.0.0.1',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
        overrideApiOrigin: exchange.origin,
      ),
    );
    addTearDown(service.close);

    final preferences = await service.listNotificationPreferences();
    await service.saveNotificationPreference(
      preference: UserSettingsNotificationPreference.globalDefault.copyWith(
        muted: true,
        desktopEnabled: false,
      ),
    );

    expect(preferences, hasLength(1));
    expect(
      preferences.single.targetType,
      UserSettingsNotificationTargetType.global,
    );
    expect(preferences.single.toString(), isNot(contains('must-not-leak')));
    expect(requests, [
      'GET /api/users/me/notifications',
      'PUT /api/users/me/notifications',
    ]);
    expect(bodies.last, {
      'targetType': 'global',
      'targetId': '0',
      'muted': true,
      'desktopEnabled': false,
    });
  });
}

Map<String, Object?> _serverJson({
  required String id,
  required String name,
  String? iconUrl,
  String? bannerUrl,
  Map<String, Object?>? bannerCrop,
  int memberCount = 2,
}) {
  return {
    'id': id,
    'name': name,
    'ownerId': '42',
    'iconUrl': iconUrl,
    'description': null,
    'voiceBitrate': 64000,
    'welcomeChannelId': '321',
    'announceChannelId': null,
    'bannerUrl': bannerUrl,
    'bannerCrop': bannerCrop,
    'accentColor': '#13eab3',
    'bannerOffsetY': 50,
    'memberCount': memberCount,
    'large': false,
    'createdAt': '2026-06-01T10:00:00Z',
    'updatedAt': '2026-06-01T10:00:00Z',
  };
}

ServerSettingsServer _serverFrom({required String id, required String name}) {
  return ServerSettingsServer.fromJson(_serverJson(id: id, name: name));
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
    );
  }

  @override
  Future<void> save(AuthCredentialBundle credentials) async {
    this.credentials = credentials;
  }
}

final class _JsonExchange {
  _JsonExchange._(this._server, this.origin);

  final HttpServer _server;
  final String origin;

  static Future<_JsonExchange> start(
    FutureOr<Object?> Function(HttpRequest request, Object? body) handler, {
    int requestCount = 1,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final origin = 'http://127.0.0.1:${server.port}';
    unawaited(_handle(server, handler, requestCount));
    return _JsonExchange._(server, origin);
  }

  static Future<void> _handle(
    HttpServer server,
    FutureOr<Object?> Function(HttpRequest request, Object? body) handler,
    int requestCount,
  ) async {
    var handled = 0;
    await for (final request in server) {
      final bytes = await request.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      final body = _requestBody(request, Uint8List.fromList(bytes));
      try {
        final payload = await handler(request, body);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(payload));
      } finally {
        await request.response.close();
      }
      handled += 1;
      if (handled >= requestCount) {
        break;
      }
    }
  }

  static Object? _requestBody(HttpRequest request, Uint8List bytes) {
    if (bytes.isEmpty) {
      return null;
    }
    if (request.headers.contentType?.mimeType == 'application/json') {
      return jsonDecode(utf8.decode(bytes));
    }
    return bytes;
  }

  Future<void> close() => _server.close(force: true);
}
