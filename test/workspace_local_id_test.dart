import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_credentials.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_models.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_service.dart';
import 'package:verdant_flutter/features/workspace/workspace_local_id.dart';

void main() {
  group('safeWorkspaceLocalId', () {
    test('keeps unscoped local ids and strips allowed scoped prefixes', () {
      expect(safeWorkspaceLocalId('12345'), '12345');
      expect(
        safeWorkspaceLocalId('official/12345', allowScopedPrefix: true),
        '12345',
      );
    });

    test(
      'rejects path separators, controls, whitespace, and encoded controls',
      () {
        for (final value in [
          '',
          ' ',
          'official/12345',
          '12/345',
          r'12\345',
          '12 345',
          '12\u0000345',
          '12\u001f345',
          '12\u007f345',
          '12%00345',
          '12%1f345',
          '12%2f345',
          '12%5c345',
          '12%7f345',
        ]) {
          expect(() => safeWorkspaceLocalId(value), throwsFormatException);
        }
      },
    );
  });

  group('scopedWorkspaceId', () {
    test('scopes local ids and accepts matching two-part scoped ids', () {
      expect(scopedWorkspaceId('official', '12345'), 'official/12345');
      expect(
        scopedWorkspaceId('official', ' official/12345 '),
        'official/12345',
      );
    });

    test('rejects malformed scoped ids instead of preserving them', () {
      for (final value in [
        '',
        'official/one/two',
        'other/12345',
        'official/',
        'official/12%2f345',
        '12/345',
      ]) {
        expect(
          () => scopedWorkspaceId('official', value),
          throwsFormatException,
        );
      }
    });
  });

  group('HttpDirectMessagesService local id validation', () {
    test(
      'rejects unsafe relationship and channel ids before credentials',
      () async {
        final store = _RecordingCredentialStore();
        final service = HttpDirectMessagesService(
          apiOrigin: officialApiOrigin,
          credentialStore: store,
        );
        const unsafeId = '123%00456';

        await expectLater(
          service.acceptFriendRequest(localUserId: unsafeId),
          throwsA(isA<DirectMessagesException>()),
        );
        await expectLater(
          service.removeRelationship(localUserId: unsafeId),
          throwsA(isA<DirectMessagesException>()),
        );
        await expectLater(
          service.openDirectMessage(
            localUserId: unsafeId,
            currentUserId: 'current-user',
          ),
          throwsA(isA<DirectMessagesException>()),
        );
        await expectLater(
          service.loadConversationMessages(
            conversation: const DmConversationPreviewSeed(
              channelId: 'official/123%00456',
              localChannelId: unsafeId,
              networkId: 'official',
              displayName: 'Unsafe',
              initials: 'UN',
              status: 'Offline',
              lastMessage: 'No messages yet',
            ),
            currentUserId: 'current-user',
          ),
          throwsA(isA<DirectMessagesException>()),
        );

        expect(store.readCount, 0);
        service.close();
      },
    );

    test(
      'drops malformed REST rows without failing the whole snapshot',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final requests = server.listen((request) async {
          request.response.headers.contentType = ContentType.json;
          switch (request.uri.path) {
            case '/api/users/me/relationships':
              request.response.write(
                jsonEncode([
                  {
                    'userId': '181051381515448321',
                    'type': 1,
                    'user': {
                      'id': '181051381515448321',
                      'username': 'Avery',
                      'status': 'online',
                    },
                  },
                  {
                    'userId': 'other-network/poison',
                    'type': 1,
                    'user': {
                      'id': 'other-network/poison',
                      'username': 'Poison',
                    },
                  },
                ]),
              );
            case '/api/dms':
              request.response.write(
                jsonEncode([
                  {
                    'id': 'dm-avery',
                    'participants': [
                      {'id': '42', 'username': 'boji'},
                      {
                        'id': '181051381515448321',
                        'username': 'Avery',
                        'status': 'online',
                      },
                    ],
                  },
                  {
                    'id': 'other-network/dm-poison',
                    'participants': [
                      {'id': '42', 'username': 'boji'},
                      {'id': 'other-network/poison', 'username': 'Poison'},
                    ],
                  },
                ]),
              );
            default:
              request.response.statusCode = HttpStatus.notFound;
              request.response.write(jsonEncode({'error': 'not found'}));
          }
          await request.response.close();
        });
        addTearDown(() async {
          await requests.cancel();
          await server.close(force: true);
        });

        final apiOrigin = 'http://127.0.0.1:${server.port}';
        final networkId = networkIdFromApiOrigin(apiOrigin);
        final service = HttpDirectMessagesService(
          apiOrigin: apiOrigin,
          credentialStore: _StaticCredentialStore(apiOrigin),
        );
        addTearDown(service.close);

        final snapshot = await service.loadDirectMessages(
          currentUserId: '42',
          currentUserName: 'boji',
          currentUserInitials: 'BO',
        );

        expect(snapshot.friends.map((friend) => friend.id), [
          '$networkId/181051381515448321',
        ]);
        expect(
          snapshot.conversations.map((conversation) => conversation.channelId),
          ['$networkId/dm-avery'],
        );
      },
    );
  });
}

final class _RecordingCredentialStore implements AuthCredentialStore {
  var readCount = 0;

  @override
  Future<void> clear(String apiOrigin) async {}

  @override
  Future<bool> contains(String apiOrigin) async => false;

  @override
  Future<AuthCredentialBundle?> read(String apiOrigin) async {
    readCount += 1;
    return null;
  }

  @override
  Future<void> save(AuthCredentialBundle credentials) async {}
}

final class _StaticCredentialStore implements AuthCredentialStore {
  const _StaticCredentialStore(this.apiOrigin);

  final String apiOrigin;

  @override
  Future<void> clear(String apiOrigin) async {}

  @override
  Future<bool> contains(String apiOrigin) async => true;

  @override
  Future<AuthCredentialBundle?> read(String apiOrigin) async {
    return AuthCredentialBundle(
      apiOrigin: this.apiOrigin,
      accessToken: 'test-access-token',
      sessionToken: 'test-session-token',
      user: const VerdantUser(
        id: '42',
        username: 'boji',
        email: 'boji@example.com',
        status: 'online',
        usernameSet: true,
        emailVerified: true,
        totpEnabled: false,
      ),
    );
  }

  @override
  Future<void> save(AuthCredentialBundle credentials) async {}
}
