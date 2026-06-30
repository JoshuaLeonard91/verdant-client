import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_diagnostics.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_models.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_preferences.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_service.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';
import 'package:verdant_flutter/features/workspace/shared/workspace_message_mutation_repository.dart';
import 'package:verdant_flutter/features/workspace/workspace_controller.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';
import 'package:verdant_flutter/generated/verdant/models.pb.dart'
    as verdant_models;
import 'package:verdant_flutter/generated/verdant/ws.pb.dart' as verdant_ws;

void main() {
  test('loads real server workspace data after authentication', () async {
    final repository = _FakeServerSettingsRepository(
      data: ServerSettingsData(
        networkId: 'official',
        server: const ServerSettingsServer(
          id: '123',
          name: 'Actual Verdant',
          ownerId: '42',
          iconUrl: 'https://media.verdant.chat/server-icons/123/icon.webp',
          description: 'Real backend server',
          voiceBitrate: 64000,
          welcomeChannelId: '321',
          announceChannelId: null,
          bannerUrl:
              'https://media.verdant.chat/server-banners/123/banner.webp',
          bannerCrop: BannerCrop(x: 10, y: 20, width: 80, height: 45),
          accentColor: '#13eab3',
          bannerOffsetY: 50,
          memberCount: 42,
          large: false,
          createdAt: '2026-06-01T10:00:00Z',
          updatedAt: '2026-06-01T10:00:00Z',
        ),
        channels: const [
          ServerSettingsChannelSeed(id: '321', name: 'general'),
          ServerSettingsChannelSeed(id: '654', name: 'announcements'),
        ],
        emojis: const [
          ServerSettingsListItemSeed(
            title: ':verdant:',
            subtitle: 'Created by boji',
          ),
        ],
        invites: const [],
        roles: const [
          ServerSettingsListItemSeed(
            title: 'Admin',
            subtitle: '8 permissions',
            trailing: '#13eab3',
          ),
        ],
        members: const [
          ServerSettingsListItemSeed(
            title: 'boji',
            subtitle: 'Joined 2026-06-01',
            trailing: 'Owner',
            userId: '42',
          ),
        ],
        auditEvents: const [
          ServerSettingsListItemSeed(
            title: 'boji updated server settings',
            subtitle: '2026-06-01T11:00:00Z',
          ),
        ],
        feeds: const [],
        bots: const [],
      ),
      currentUserMedia: const ServerSettingsCurrentUserMedia(
        id: '42',
        avatarUrl: 'https://media.verdant.chat/avatars/boji.webp',
        bannerUrl: 'https://media.verdant.chat/banners/boji.webp',
        memberListBannerUrl:
            'https://media.verdant.chat/member-list-banners/boji.webp',
      ),
      activeChannelMembers: const [
        MemberSeed(
          id: 'official/42',
          name: 'boji',
          status: 'idle',
          initials: 'BO',
          role: '2 roles',
          avatarUrl: 'https://media.verdant.chat/avatars/boji.webp',
          bannerUrl: 'https://media.verdant.chat/banners/boji.webp',
          memberListBannerUrl:
              'https://media.verdant.chat/member-list-banners/boji.webp',
        ),
      ],
    );
    final controller = WorkspaceController(
      session: _session,
      repository: repository,
      directMessagesRepository: _FakeDirectMessagesRepository(),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(repository.listServersCalled, isTrue);
    expect(repository.loadedServerId, '123');
    expect(controller.state.isLoading, isFalse);
    expect(controller.state.activeServer?.name, 'Actual Verdant');
    expect(
      controller.state.settings?.channels.map((channel) => channel.name),
      contains('general'),
    );
    expect(controller.state.settings?.roles.single.title, 'Admin');
    expect(controller.state.activeChannelId, '321');
    expect(repository.loadedActivityChannelId, '321');
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.hasChannelActivityData, isTrue);
    expect(
      controller.state.activeChannelMembers.single.avatarUrl,
      contains('/avatars/boji.webp'),
    );
    expect(
      controller.state.activeChannelMembers.single.memberListBannerUrl,
      contains('/member-list-banners/boji.webp'),
    );
    expect(controller.state.serverMessages.single.body, 'Server hello');
    expect(
      controller.state.settings?.members.single.avatarUrl,
      contains('/avatars/boji.webp'),
    );
    expect(
      controller.state.settings?.members.single.bannerUrl,
      contains('/banners/boji.webp'),
    );
    expect(
      controller.state.settings?.members.single.memberListBannerUrl,
      contains('/member-list-banners/boji.webp'),
    );
    expect(
      controller.state.serverMessages.map((message) => message.body),
      isNot(contains('Fake chat message 1 for scroll and rebuild profiling.')),
    );
    expect(controller.state.directMessages?.friends, isEmpty);
    expect(controller.toString(), isNot(contains('access-secret')));
  });

  test(
    'initial server load does not wait for channel activity hydration',
    () async {
      final activityCompleter = Completer<List<MemberSeed>>();
      final repository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        channelActivityFuture: activityCompleter.future,
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
      );
      addTearDown(controller.dispose);

      unawaited(controller.load());
      await Future<void>.delayed(Duration.zero);

      expect(repository.loadedActivityChannelId, '321');
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isChannelActivityLoading, isTrue);
      expect(controller.state.serverMessages, isNotEmpty);
      expect(controller.state.activeChannelMembers, isEmpty);

      activityCompleter.complete([
        const MemberSeed(
          id: 'official/84',
          name: 'Kai',
          initials: 'KA',
          role: 'Member',
          status: 'online',
          avatarUrl: null,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isChannelActivityLoading, isFalse);
      expect(controller.state.activeChannelMembers.single.name, 'Kai');
    },
  );

  test(
    'federated access filter constrains initial active workspace servers',
    () async {
      final allowed = _server(id: 'allowed-server', name: 'Allowed Verdant');
      final unrelated = _server(
        id: 'unrelated-server',
        name: 'Unrelated Verdant',
      );
      final diagnostics = _RecordingDiagnostics();
      final repository = _FakeServerSettingsRepository(
        data: _settings(allowed),
        servers: [unrelated, allowed],
      );
      final controller = WorkspaceController(
        session: AuthSession.authenticated(
          apiOrigin: 'https://api-test.pryzmapp.com',
          user: _session.user,
          hasSessionToken: false,
          credentialKind: AuthCredentialKind.federatedClient,
        ),
        repository: repository,
        initialServerId: unrelated.id,
        serverAccessFilter: () async => {allowed.id},
        diagnostics: diagnostics,
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.servers.map((server) => server.id), [allowed.id]);
      expect(controller.state.activeServer?.id, allowed.id);
      expect(repository.loadedServerId, allowed.id);
      final payload = diagnostics
          .payloadsFor('workspace.servers.access_filter.result')
          .single;
      expect(payload['listedServerCount'], 2);
      expect(payload['allowedServerCount'], 1);
      expect(payload['filteredServerCount'], 1);
    },
  );

  test(
    'keeps username setup state from live current-user data after restore',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        currentUserMedia: const ServerSettingsCurrentUserMedia(
          id: '42',
          username: 'user_42',
          email: 'boji@example.com',
          usernameSet: false,
          emailVerified: true,
          totpEnabled: false,
        ),
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.currentUser?.username, 'user_42');
      expect(controller.state.currentUser?.usernameSet, isFalse);
      expect(controller.state.currentUserMedia?.usernameSet, isFalse);
      expect(repository.loadedMessageCurrentUserIds, ['42']);
    },
  );

  test(
    'selects the first text channel when layout starts with a category',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(
              id: 'category-chat',
              name: 'Chat',
              type: 1,
            ),
            ServerSettingsChannelSeed(id: '321', name: 'general'),
            ServerSettingsChannelSeed(
              id: 'voice-general',
              name: 'Voice',
              type: 3,
            ),
          ],
        ),
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.activeChannelId, '321');
      expect(repository.loadedActivityChannelId, '321');
      expect(repository.loadedMessageChannelIds, ['321']);
      expect(controller.state.serverMessages.single.id, '321/message-1');
    },
  );

  test('treats empty initial channel history as loaded', () async {
    final repository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
      messageBatches: [const []],
    );
    final controller = WorkspaceController(
      session: _session,
      repository: repository,
      directMessagesRepository: _FakeDirectMessagesRepository(),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(repository.loadedMessageChannelIds, ['321']);
    expect(controller.state.activeChannelId, '321');
    expect(controller.state.serverMessages, isEmpty);
    expect(controller.state.serverMessagesError, isNull);
  });

  test('does not poll repeated empty startup batches', () async {
    final repository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
      messageBatches: [const [], const [], const []],
    );
    final controller = WorkspaceController(
      session: _session,
      repository: repository,
      directMessagesRepository: _FakeDirectMessagesRepository(),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(repository.loadedMessageChannelIds, ['321']);
    expect(controller.state.activeChannelId, '321');
    expect(controller.state.serverMessages, isEmpty);
    expect(controller.state.serverMessagesError, isNull);
  });

  test(
    'retries transient startup message failures before leaving the chat empty',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        messageFailuresBeforeSuccess: 1,
        messages: const [
          MessageSeed(
            id: '321/message-after-transient-failure',
            authorId: '42',
            author: 'boji',
            body: 'Loaded after transient startup failure',
            initials: 'BO',
            time: '10:02 AM',
            isOwnMessage: true,
          ),
        ],
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(repository.loadedMessageChannelIds, ['321', '321']);
      expect(controller.state.activeChannelId, '321');
      expect(
        controller.state.serverMessages.single.body,
        contains('transient startup failure'),
      );
      expect(controller.state.serverMessagesError, isNull);
    },
  );

  test(
    'uses backend current user identity when the saved session snapshot is stale',
    () async {
      final staleSession = AuthSession.authenticated(
        apiOrigin: 'https://api.verdant.chat',
        user: VerdantUser(
          id: '176495712701775872',
          username: 'old-user',
          email: 'old-user@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      );
      final diagnostics = _RecordingDiagnostics();
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final repository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          members: const [
            ServerSettingsListItemSeed(
              title: 'Joshy',
              subtitle: 'Online - joined 2026-06-01',
              trailing: '2 roles',
              userId: '181051381515448320',
            ),
          ],
        ),
        currentUserMedia: const ServerSettingsCurrentUserMedia(
          id: '181051381515448320',
          username: 'joshy',
          displayName: 'Joshy',
          avatarUrl: 'https://media.verdant.chat/avatars/joshy.webp',
          status: 'online',
        ),
      );
      final controller = WorkspaceController(
        session: staleSession,
        repository: repository,
        directMessagesRepository: directMessagesRepository,
        diagnostics: diagnostics,
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.currentUser?.id, '181051381515448320');
      expect(repository.loadedMessageCurrentUserIds, ['181051381515448320']);
      expect(directMessagesRepository.loadedCurrentUserIds, isEmpty);
      expect(
        controller.state.serverMessages.single.authorId,
        '181051381515448320',
      );
      expect(controller.state.serverMessages.single.isOwnMessage, isTrue);
      expect(
        diagnostics.payloadsFor('workspace.current_user.reconciled').single,
        isNot(containsPair('userId', '181051381515448320')),
      );
      expect(
        diagnostics.payloadsFor('workspace.current_user.reconciled').single,
        isNot(containsPair('oldUserId', '176495712701775872')),
      );
    },
  );

  test(
    'surfaces startup message hydration failures without expiring the workspace',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        messageFailuresBeforeSuccess: 10,
      );
      final diagnostics = _RecordingDiagnostics();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
        diagnostics: diagnostics,
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.error, isNull);
      expect(controller.state.isAuthExpired, isFalse);
      expect(controller.state.activeServer?.id, '123');
      expect(controller.state.activeChannelId, '321');
      expect(controller.state.serverMessages, isEmpty);
      expect(
        controller.state.serverMessagesError,
        'Message transport unavailable',
      );
      expect(repository.loadedMessageChannelIds, ['321', '321', '321', '321']);
      expect(
        diagnostics.payloadsFor('workspace.messages.load.result').last,
        containsPair('status', 'failed'),
      );
      expect(
        diagnostics.payloadsFor('workspace.messages.load.result').last,
        containsPair('errorKind', 'transport'),
      );
      expect(
        diagnostics.payloadsFor('workspace.messages.load.result').last.values,
        isNot(contains(contains('secret'))),
      );
      expect(
        diagnostics
            .payloadsFor('workspace.messages.load.start')
            .map((payload) => payload['attempt']),
        [1, 2, 3, 4],
      );
      expect(
        diagnostics.payloadsFor('workspace.messages.load.start').last,
        containsPair('mode', 'startup'),
      );
    },
  );

  test(
    'sending a server message uses realtime websocket command sink',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        currentUserMedia: const ServerSettingsCurrentUserMedia(
          id: '42',
          username: 'boji',
          displayName: 'boji',
        ),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: directMessagesRepository,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.sendServerMessage(' <b>Hello from Flutter</b> ');

      expect(directMessagesRepository.sentMessageChannelIds, ['321']);
      expect(directMessagesRepository.sentMessageContents, [
        'Hello from Flutter',
      ]);
      directMessagesRepository.emit(
        const DirectMessagesMessageCreateEvent(
          channelId: 'official/321',
          message: MessageSeed(
            id: 'official/sent-1',
            authorId: 'official/42',
            author: 'boji',
            body: 'Hello from Flutter',
            initials: 'BO',
            time: '10:01 AM',
            isOwnMessage: true,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.serverMessages.last.body, 'Hello from Flutter');
      expect(controller.state.serverMessages.last.isOwnMessage, isTrue);

      await controller.setServerReaction(
        messageId: 'official/sent-1',
        emoji: '😀',
        selected: true,
      );
      await controller.setServerReaction(
        messageId: 'official/sent-1',
        emoji: '😀',
        selected: false,
      );

      expect(directMessagesRepository.addedReactionMessageIds, [
        'official/sent-1',
      ]);
      expect(directMessagesRepository.removedReactionMessageIds, [
        'official/sent-1',
      ]);
    },
  );

  test(
    'deleting a server message removes it through the backend route',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        currentUserMedia: const ServerSettingsCurrentUserMedia(
          id: '42',
          username: 'boji',
          displayName: 'boji',
        ),
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      final message = controller.state.serverMessages.single;

      await controller.deleteServerMessage(message);

      expect(repository.deletedMessageChannelIds, ['321']);
      expect(repository.deletedMessageIds, [message.id]);
      expect(controller.state.serverMessages, isEmpty);
      expect(controller.state.serverMessagesError, isNull);
    },
  );

  test(
    'server message delete failures leave the message visible and report the backend error',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        currentUserMedia: const ServerSettingsCurrentUserMedia(
          id: '42',
          username: 'boji',
          displayName: 'boji',
        ),
      )..messageDeleteFailure = const ServerSettingsException('Delete denied');
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      final message = controller.state.serverMessages.single;

      await controller.deleteServerMessage(message);

      expect(controller.state.serverMessages.single.id, message.id);
      expect(controller.state.serverMessagesError, 'Delete denied');
    },
  );

  test('sending a direct message uses the active DM realtime route', () async {
    final repository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
      currentUserMedia: const ServerSettingsCurrentUserMedia(
        id: '42',
        username: 'boji',
        displayName: 'boji',
      ),
    );
    final directMessagesRepository = _FakeDirectMessagesRepository();
    final controller = WorkspaceController(
      session: _session,
      repository: repository,
      directMessagesRepository: directMessagesRepository,
    );
    addTearDown(controller.dispose);

    await controller.load();
    final conversation = directMessagesRepository.data.conversations.single;
    await controller.openDirectMessageConversation(conversation);

    await controller.sendDirectMessage(' <b>Hello from DM</b> ');

    expect(directMessagesRepository.sentMessageChannelIds, [
      '${_session.networkId}/dm-avery',
    ]);
    expect(directMessagesRepository.sentMessageContents, ['Hello from DM']);
  });

  test(
    'sending a direct message refreshes the active DM thread without an echo',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        currentUserMedia: const ServerSettingsCurrentUserMedia(
          id: '42',
          username: 'boji',
          displayName: 'boji',
        ),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..conversationMessageBatches = const [
          [
            MessageSeed(
              id: 'official/dm-message-0',
              authorId: 'official/181051381515448321',
              author: 'Avery',
              body: 'Older hello from Avery',
              initials: 'AV',
              time: '10:20 AM',
            ),
          ],
          [
            MessageSeed(
              id: 'official/dm-message-0',
              authorId: 'official/181051381515448321',
              author: 'Avery',
              body: 'Older hello from Avery',
              initials: 'AV',
              time: '10:20 AM',
            ),
            MessageSeed(
              id: 'official/dm-message-sent',
              authorId: 'official/42',
              author: 'boji',
              body: 'Hello from DM',
              initials: 'BO',
              time: '10:24 AM',
              isOwnMessage: true,
            ),
          ],
        ];
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: directMessagesRepository,
      );
      addTearDown(controller.dispose);

      await controller.load();
      final conversation = directMessagesRepository.data.conversations.single;
      await controller.openDirectMessageConversation(conversation);

      await controller.sendDirectMessage('Hello from DM');

      expect(directMessagesRepository.sentMessageChannelIds, [
        '${_session.networkId}/dm-avery',
      ]);
      expect(directMessagesRepository.loadedConversationChannelIds, [
        '${_session.networkId}/dm-avery',
        '${_session.networkId}/dm-avery',
      ]);
      expect(
        controller.state.dmMessages?.messages.map((message) => message.body),
        contains('Hello from DM'),
      );
      expect(controller.state.dmMessagesError, isNull);
    },
  );

  test(
    'deleting a direct message removes it through the DM channel route',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        currentUserMedia: const ServerSettingsCurrentUserMedia(
          id: '42',
          username: 'boji',
          displayName: 'boji',
        ),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: directMessagesRepository,
      );
      addTearDown(controller.dispose);

      await controller.load();
      final conversation = directMessagesRepository.data.conversations.single;
      await controller.openDirectMessageConversation(conversation);
      final message = controller.state.dmMessages!.messages.first;

      await controller.deleteDirectMessage(message);

      expect(directMessagesRepository.deletedMessageChannelIds, [
        '${_session.networkId}/dm-avery',
      ]);
      expect(directMessagesRepository.deletedMessageIds, [message.id]);
      expect(
        controller.state.dmMessages!.messages.map((item) => item.id),
        isNot(contains(message.id)),
      );
      expect(controller.state.dmMessagesError, isNull);
    },
  );

  test(
    'server load and channel switching focus the realtime websocket route',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
            ServerSettingsChannelSeed(id: '654', name: 'bot-test'),
          ],
        ),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: directMessagesRepository,
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(directMessagesRepository.focusedServerIds, ['123']);
      expect(directMessagesRepository.focusedChannelIds, ['321']);

      await controller.selectTextChannel('654');

      expect(directMessagesRepository.focusedServerIds, ['123']);
      expect(directMessagesRepository.focusedChannelIds, ['321', '654']);
    },
  );

  test(
    'accepting a server invite refocuses the realtime websocket route',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
            ServerSettingsChannelSeed(id: '654', name: 'bot-test'),
          ],
        ),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: directMessagesRepository,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.acceptServerInvite('fresh-invite');

      expect(directMessagesRepository.focusedServerIds, ['123', '123']);
      expect(directMessagesRepository.focusedChannelIds, ['321', '321']);
      expect(controller.state.activeServer?.id, '123');
      expect(controller.state.activeChannelId, '321');
    },
  );

  test(
    'accepting a server invite resolves before slow activity hydration',
    () async {
      final repository = _SlowActivityServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
            ServerSettingsChannelSeed(id: '654', name: 'bot-test'),
          ],
        ),
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      var joined = false;
      final joinFuture = controller.acceptServerInvite('fresh-invite').then((
        _,
      ) {
        joined = true;
      });
      for (var attempt = 0; attempt < 5; attempt += 1) {
        await pumpEventQueue();
        if (repository.activityLoadCount >= 2) {
          break;
        }
      }

      expect(repository.activityLoadCount, 2);
      expect(joined, isTrue);
      expect(controller.state.activeServer?.id, '123');
      expect(controller.state.activeChannelId, '321');
      expect(controller.state.isChannelActivityLoading, isTrue);
      expect(controller.state.activeChannelMembers, isEmpty);

      repository.completeActivity(const [
        MemberSeed(
          id: 'official/181',
          name: 'Avery',
          status: 'Online',
          initials: 'AV',
        ),
      ]);
      await joinFuture;
      await pumpEventQueue();

      expect(controller.state.isChannelActivityLoading, isFalse);
      expect(controller.state.activeChannelMembers.single.name, 'Avery');
    },
  );

  test(
    'channel switching commits messages before slow members hydrate',
    () async {
      final repository = _SlowChannelServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
            ServerSettingsChannelSeed(id: '654', name: 'bot-test'),
          ],
        ),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: directMessagesRepository,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await pumpEventQueue();
      final switchFuture = controller.selectTextChannel('654');
      await pumpEventQueue();

      expect(controller.state.activeChannelId, '321');
      expect(controller.state.pendingChannelId, '654');
      expect(controller.state.isChannelTransitionLoading, isTrue);
      expect(controller.state.isServerMessagesLoading, isFalse);
      expect(controller.state.isChannelActivityLoading, isFalse);
      expect(controller.state.serverMessages.single.id, '321/message-1');

      repository.completeMessages(const [
        MessageSeed(
          id: 'official/m-654',
          authorId: 'official/42',
          author: 'Joshy',
          body: 'new channel loaded',
          initials: 'JO',
          time: '10:30 AM',
        ),
      ]);
      await pumpEventQueue();
      expect(controller.state.activeChannelId, '654');
      expect(controller.state.pendingChannelId, isNull);
      expect(controller.state.isChannelTransitionLoading, isFalse);
      expect(controller.state.isChannelActivityLoading, isTrue);
      expect(controller.state.serverMessages.single.id, 'official/m-654');
      expect(controller.state.activeChannelMembers, isEmpty);

      repository.completeActivity(const [
        MemberSeed(
          id: 'official/181',
          name: 'Avery',
          status: 'Online',
          initials: 'AV',
        ),
      ]);
      await switchFuture;

      expect(controller.state.activeChannelId, '654');
      expect(controller.state.pendingChannelId, isNull);
      expect(controller.state.isChannelTransitionLoading, isFalse);
      await pumpEventQueue();
      expect(controller.state.isChannelActivityLoading, isFalse);
      expect(controller.state.serverMessages.single.id, 'official/m-654');
      expect(controller.state.activeChannelMembers.single.name, 'Avery');
    },
  );

  test(
    'duplicate pending channel selections reuse the in-flight hydration',
    () async {
      final repository = _SlowChannelServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
            ServerSettingsChannelSeed(id: '654', name: 'bot-test'),
          ],
        ),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: directMessagesRepository,
      );
      addTearDown(controller.dispose);

      await controller.load();
      final firstSwitch = controller.selectTextChannel('654');
      await pumpEventQueue();
      final duplicateSwitch = controller.selectTextChannel('654');
      await pumpEventQueue();

      expect(repository.messageLoadCount, 2);
      expect(repository.activityLoadCount, 2);
      expect(directMessagesRepository.focusedChannelIds, ['321', '654']);

      repository.completeMessages(const [
        MessageSeed(
          id: 'official/m-654',
          authorId: 'official/42',
          author: 'Joshy',
          body: 'new channel loaded',
          initials: 'JO',
          time: '10:30 AM',
        ),
      ]);
      repository.completeActivity(const []);
      await firstSwitch;
      await duplicateSwitch;

      expect(controller.state.activeChannelId, '654');
      expect(controller.state.serverMessages.single.id, 'official/m-654');
    },
  );

  test(
    'switching back to a hydrated channel uses cached messages and activity',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
            ServerSettingsChannelSeed(id: '654', name: 'bot-test'),
          ],
        ),
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await pumpEventQueue();
      await controller.selectTextChannel('654');
      await controller.selectTextChannel('321');

      expect(repository.loadedMessageChannelIds, ['321', '654']);
      expect(repository.loadedActivityChannelIds, ['321', '654']);
      expect(controller.state.activeChannelId, '321');
      expect(controller.state.serverMessages.single.id, '321/message-1');
    },
  );

  test(
    'announcement feed selection clears chat state until a text channel is selected',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
            ServerSettingsChannelSeed(id: '654', name: 'bot-test'),
          ],
        ),
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.activeChannelId, '321');
      expect(controller.state.activeFeedId, isNull);
      expect(controller.state.serverMessages, isNotEmpty);

      controller.selectAnnouncementFeed('feed-1');

      expect(controller.state.activeFeedId, 'feed-1');
      expect(controller.state.activeChannelId, isNull);
      expect(controller.state.pendingChannelId, isNull);
      expect(controller.state.activeChannelMembers, isEmpty);
      expect(controller.state.activeTypingMembers, isEmpty);
      expect(controller.state.serverMessages, isEmpty);
      expect(controller.state.serverMessagesError, isNull);

      await controller.selectTextChannel('654');

      expect(controller.state.activeFeedId, isNull);
      expect(controller.state.activeChannelId, '654');
      expect(controller.state.serverMessages.single.id, '654/message-1');
    },
  );

  test('enriches sparse active channel rows with known member media', () async {
    final session = AuthSession.authenticated(
      apiOrigin: 'https://api.verdant.chat',
      user: const VerdantUser(
        id: '42',
        username: 'joshy',
        displayName: 'Joshy',
        email: 'joshy@example.com',
        avatarUrl: 'https://media.verdant.chat/avatars/joshy.webp',
        bannerUrl: 'https://media.verdant.chat/banners/joshy.webp',
        memberListBannerUrl:
            'https://media.verdant.chat/member-list-banners/joshy.webp',
        status: 'idle',
        usernameSet: true,
        emailVerified: true,
        totpEnabled: false,
      ),
    );
    final repository = _FakeServerSettingsRepository(
      data: _settings(
        _server(id: '123', name: 'Actual Verdant'),
        members: const [
          ServerSettingsListItemSeed(
            title: 'Joshy',
            subtitle: 'Idle - joined 2026-06-01',
            trailing: '2 roles',
            userId: '42',
          ),
        ],
      ),
      activeChannelMembers: const [
        MemberSeed(
          id: 'official/42',
          name: 'Joshy',
          status: 'idle',
          initials: 'JO',
          role: '2 roles',
        ),
      ],
    );
    final controller = WorkspaceController(
      session: session,
      repository: repository,
      directMessagesRepository: _FakeDirectMessagesRepository(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    await pumpEventQueue();

    expect(controller.state.hasChannelActivityData, isTrue);
    expect(
      controller.state.activeChannelMembers.single.avatarUrl,
      contains('/avatars/joshy.webp'),
    );
    expect(
      controller.state.activeChannelMembers.single.bannerUrl,
      contains('/banners/joshy.webp'),
    );
    expect(
      controller.state.activeChannelMembers.single.memberListBannerUrl,
      contains('/member-list-banners/joshy.webp'),
    );
  });

  test(
    'defers sparse active channel profile media until popover prepare',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          members: const [
            ServerSettingsListItemSeed(
              title: 'Joshy',
              subtitle: 'Idle - joined 2026-06-01',
              trailing: '2 roles',
              userId: '42',
            ),
          ],
        ),
        activeChannelMembers: const [
          MemberSeed(
            id: 'official/42',
            name: 'Joshy',
            status: 'idle',
            initials: 'JO',
            role: '2 roles',
          ),
        ],
        userMediaById: const {
          '42': ServerSettingsCurrentUserMedia(
            id: '42',
            username: 'joshy_perm',
            displayName: 'Joshy Live',
            status: 'dnd',
            avatarUrl: 'https://media.verdant.chat/avatars/joshy.webp',
            bannerUrl: 'https://media.verdant.chat/banners/joshy.webp',
            memberListBannerUrl:
                'https://media.verdant.chat/member-list-banners/joshy.webp',
          ),
        },
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await pumpEventQueue();

      expect(repository.loadedUserMediaIds, isEmpty);
      expect(controller.state.activeChannelMembers.single.name, 'Joshy');
      expect(controller.state.activeChannelMembers.single.username, isNull);
      expect(controller.state.activeChannelMembers.single.status, 'idle');
      expect(controller.state.activeChannelMembers.single.avatarUrl, isNull);
      expect(controller.state.activeChannelMembers.single.bannerUrl, isNull);
      expect(
        controller.state.activeChannelMembers.single.memberListBannerUrl,
        isNull,
      );

      final prepared = await controller.prepareMemberProfile(
        controller.state.activeChannelMembers.single,
      );

      expect(repository.loadedUserMediaIds, ['42']);
      expect(prepared.name, 'Joshy Live');
      expect(prepared.username, 'joshy_perm');
      expect(prepared.status, 'dnd');
      expect(prepared.avatarUrl, contains('/avatars/joshy.webp'));
      expect(prepared.bannerUrl, contains('/banners/joshy.webp'));
      expect(
        prepared.memberListBannerUrl,
        contains('/member-list-banners/joshy.webp'),
      );
    },
  );

  test(
    'enriches sparse active channel rows from message author media',
    () async {
      final repository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          members: const [
            ServerSettingsListItemSeed(
              title: 'Joshy',
              subtitle: 'Idle - joined 2026-06-01',
              trailing: '2 roles',
              userId: '42',
            ),
          ],
        ),
        activeChannelMembers: const [
          MemberSeed(
            id: 'official/42',
            name: 'Joshy',
            status: 'idle',
            initials: 'JO',
            role: '2 roles',
          ),
        ],
        messages: const [
          MessageSeed(
            id: '321/message-1',
            authorId: '42',
            author: 'Joshy',
            body: 'Recent activity',
            initials: 'JO',
            time: '10:00 AM',
            avatarUrl: 'https://media.verdant.chat/avatars/from-message.webp',
            isOwnMessage: true,
          ),
        ],
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await pumpEventQueue();

      expect(
        controller.state.activeChannelMembers.single.avatarUrl,
        contains('/avatars/from-message.webp'),
      );
    },
  );

  test('activity enrichment does not bulk-load profile media', () async {
    final diagnostics = _RecordingDiagnostics();
    final repository = _FakeServerSettingsRepository(
      data: _settings(
        _server(id: '123', name: 'Actual Verdant'),
        members: const [
          ServerSettingsListItemSeed(
            title: 'Joshy',
            subtitle: 'Idle - joined 2026-06-01',
            trailing: '2 roles',
            userId: '42',
          ),
        ],
      ),
      activeChannelMembers: const [
        MemberSeed(
          id: 'official/42',
          name: 'Joshy',
          status: 'idle',
          initials: 'JO',
          role: '2 roles',
        ),
      ],
      throwUserMediaSecret: true,
    );
    final controller = WorkspaceController(
      session: _session,
      repository: repository,
      directMessagesRepository: _FakeDirectMessagesRepository(),
      diagnostics: diagnostics,
    );
    addTearDown(controller.dispose);

    await controller.load();
    await pumpEventQueue();

    expect(repository.loadedUserMediaIds, isEmpty);
    expect(diagnostics.events, contains('workspace.activity.enrich.result'));
    expect(
      diagnostics.events,
      isNot(contains('workspace.activity.profile_media.result')),
    );
    expect(diagnostics.rendered, isNot(contains('access-secret')));
    expect(diagnostics.rendered, isNot(contains('session-secret')));
    expect(diagnostics.rendered, isNot(contains('Bearer')));
  });

  test('selects a different server through scoped rail state', () async {
    final first = _server(id: '123', name: 'Actual Verdant');
    final second = _server(id: '456', name: 'Second Verdant');
    final repository = _MultiServerSettingsRepository(
      dataByServerId: {
        first.id: _settings(first),
        second.id: _settings(second),
      },
    );
    final controller = WorkspaceController(
      session: _session,
      repository: repository,
      directMessagesRepository: _FakeDirectMessagesRepository(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    await controller.selectServer(second);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.activeServer?.id, '456');
    expect(controller.state.settings?.server.name, 'Second Verdant');
    expect(repository.loadedServerIds, ['123', '456']);
    expect(
      controller.toString(),
      contains('networkId: ${networkIdFromApiOrigin(officialApiOrigin)}'),
    );
    expect(controller.toString(), isNot(contains('access-secret')));
  });

  test('server rail switching uses workspace batch messages', () async {
    final first = _server(id: '123', name: 'Actual Verdant');
    final second = _server(id: '456', name: 'Second Verdant');
    final diagnostics = _RecordingDiagnostics();
    final repository = _BatchMultiServerSettingsRepository(
      dataByServerId: {
        first.id: _settings(first),
        second.id: _settings(
          second,
          channels: const [
            ServerSettingsChannelSeed(id: '654', name: 'general'),
          ],
        ),
      },
    );
    final controller = WorkspaceController(
      session: _session,
      repository: repository,
      directMessagesRepository: _FakeDirectMessagesRepository(),
      diagnostics: diagnostics,
    );
    addTearDown(controller.dispose);

    await controller.load();
    await pumpEventQueue();
    await controller.selectServer(second);

    expect(controller.state.activeServer?.id, second.id);
    expect(controller.state.serverMessages.single.id, '654/batch-message-1');
    expect(repository.loadedWorkspaceServerIds, [first.id, second.id]);
    expect(repository.loadedMessageChannelIds, isEmpty);
    expect(
      diagnostics.payloadsFor('workspace.messages.load.result').last,
      containsPair('source', 'cache'),
    );
  });

  test(
    'switching back to a hydrated server reuses cached workspace data',
    () async {
      final first = _server(id: '123', name: 'Actual Verdant');
      final second = _server(id: '456', name: 'Second Verdant');
      final repository = _MultiServerSettingsRepository(
        dataByServerId: {
          first.id: _settings(first),
          second.id: _settings(
            second,
            channels: const [
              ServerSettingsChannelSeed(id: '654', name: 'general'),
            ],
          ),
        },
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await pumpEventQueue();
      await controller.selectServer(second);
      await controller.selectServer(first);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isServerMessagesLoading, isFalse);
      expect(controller.state.isChannelActivityLoading, isFalse);
      expect(controller.state.activeServer?.id, first.id);
      expect(controller.state.settings?.server.id, first.id);
      expect(repository.loadedServerIds, [first.id, second.id]);
      expect(repository.loadedMessageChannelIds, ['321', '654']);
    },
  );

  test('server catalog mutations survive cached workspace replay', () async {
    final first = _server(id: '123', name: 'Actual Verdant');
    final second = _server(id: '456', name: 'Second Verdant');
    const originalEmoji = ServerSettingsListItemSeed(
      id: 'emoji-old',
      title: ':old:',
      subtitle: 'old emoji',
      avatarUrl: 'https://cdn.pryzmapp.com/emojis/old.webp',
    );
    const updatedEmoji = ServerSettingsListItemSeed(
      id: 'emoji-new',
      title: ':new:',
      subtitle: 'new emoji',
      avatarUrl: 'https://cdn.pryzmapp.com/emojis/new.webp',
    );
    const originalSticker = ServerSettingsListItemSeed(
      id: 'sticker-old',
      title: ':oldsticker:',
      subtitle: 'old sticker',
      avatarUrl: 'https://cdn.pryzmapp.com/stickers/old.webp',
    );
    const updatedSticker = ServerSettingsListItemSeed(
      id: 'sticker-new',
      title: ':newsticker:',
      subtitle: 'new sticker',
      avatarUrl: 'https://cdn.pryzmapp.com/stickers/new.webp',
    );
    final repository = _MultiServerSettingsRepository(
      dataByServerId: {
        first.id: _settings(
          first,
          emojis: const [originalEmoji],
          stickers: const [originalSticker],
        ),
        second.id: _settings(
          second,
          channels: const [
            ServerSettingsChannelSeed(id: '654', name: 'general'),
          ],
        ),
      },
    );
    final controller = WorkspaceController(
      session: _session,
      repository: repository,
      directMessagesRepository: _FakeDirectMessagesRepository(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    await pumpEventQueue();

    controller.updateCachedEmojis(const [updatedEmoji]);
    controller.updateCachedStickers(const [updatedSticker]);
    await controller.selectServer(second);
    await controller.selectServer(first);

    expect(controller.state.activeServer?.id, first.id);
    expect(controller.state.settings?.emojis, const [updatedEmoji]);
    expect(controller.state.settings?.stickers, const [updatedSticker]);
    expect(repository.loadedServerIds, [first.id, second.id]);
  });

  test(
    'server catalog mutations survive deferred activity snapshot replay',
    () async {
      final first = _server(id: '123', name: 'Actual Verdant');
      final second = _server(id: '456', name: 'Second Verdant');
      final activityCompleter = Completer<List<MemberSeed>>();
      const updatedEmoji = ServerSettingsListItemSeed(
        id: 'emoji-new',
        title: ':new:',
        subtitle: 'new emoji',
        avatarUrl: 'https://cdn.pryzmapp.com/emojis/new.webp',
      );
      const updatedSticker = ServerSettingsListItemSeed(
        id: 'sticker-new',
        title: ':newsticker:',
        subtitle: 'new sticker',
        avatarUrl: 'https://cdn.pryzmapp.com/stickers/new.webp',
      );
      final repository = _MultiServerSettingsRepository(
        dataByServerId: {
          first.id: _settings(
            first,
            emojis: const [
              ServerSettingsListItemSeed(
                id: 'emoji-old',
                title: ':old:',
                subtitle: 'old emoji',
              ),
            ],
            stickers: const [
              ServerSettingsListItemSeed(
                id: 'sticker-old',
                title: ':oldsticker:',
                subtitle: 'old sticker',
              ),
            ],
          ),
          second.id: _settings(
            second,
            channels: const [
              ServerSettingsChannelSeed(id: '654', name: 'general'),
            ],
          ),
        },
        activityByChannelId: {'321': activityCompleter.future},
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await Future<void>.delayed(Duration.zero);

      controller.updateCachedEmojis(const [updatedEmoji]);
      controller.updateCachedStickers(const [updatedSticker]);
      activityCompleter.complete(const []);
      await pumpEventQueue();
      await controller.selectServer(second);
      await controller.selectServer(first);

      expect(controller.state.activeServer?.id, first.id);
      expect(controller.state.settings?.emojis, const [updatedEmoji]);
      expect(controller.state.settings?.stickers, const [updatedSticker]);
      expect(repository.loadedServerIds, [first.id, second.id]);
    },
  );

  test(
    'server access denial during selection removes stale rail server',
    () async {
      final first = _server(id: '123', name: 'Actual Verdant');
      final removed = _server(id: '456', name: 'Removed Verdant');
      final diagnostics = _RecordingDiagnostics();
      final repository = _ServerAccessDeniedOnSelectRepository(
        deniedServerId: removed.id,
        dataByServerId: {
          first.id: _settings(first),
          removed.id: _settings(removed),
        },
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
        diagnostics: diagnostics,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.selectServer(removed);

      expect(controller.state.servers.map((server) => server.id), [first.id]);
      expect(controller.state.activeServer?.id, first.id);
      expect(controller.state.settings?.server.id, first.id);
      expect(controller.state.error, isNull);
      expect(controller.state.serverMessagesError, isNull);
      expect(controller.state.isAuthExpired, isFalse);
      expect(
        diagnostics.events,
        contains('workspace.server.select.access_denied'),
      );
      expect(diagnostics.events, contains('workspace.server.remove.apply'));
    },
  );

  test(
    'server rail switching keeps the loaded workspace during hydration',
    () async {
      final first = _server(id: '123', name: 'Actual Verdant');
      final second = _server(id: '456', name: 'Second Verdant');
      final repository = _SlowServerSwitchRepository(
        dataByServerId: {
          first.id: _settings(first),
          second.id: _settings(second),
        },
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      final switching = controller.selectServer(second);
      await pumpEventQueue();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isServerMessagesLoading, isTrue);
      expect(controller.state.isChannelActivityLoading, isTrue);
      expect(controller.state.activeServer?.id, first.id);
      expect(controller.state.settings?.server.id, first.id);

      repository.completeServerLoad(second.id);
      await switching;

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isServerMessagesLoading, isFalse);
      expect(controller.state.isChannelActivityLoading, isTrue);
      expect(controller.state.activeServer?.id, second.id);
      expect(controller.state.settings?.server.id, second.id);

      await pumpEventQueue();

      expect(controller.state.isChannelActivityLoading, isFalse);
      expect(controller.state.activeServer?.id, second.id);
      expect(controller.state.settings?.server.id, second.id);
    },
  );

  test('server rail switching ignores repeat taps during hydration', () async {
    final first = _server(id: '123', name: 'Actual Verdant');
    final second = _server(id: '456', name: 'Second Verdant');
    final diagnostics = _RecordingDiagnostics();
    final repository = _SlowServerSwitchRepository(
      dataByServerId: {
        first.id: _settings(first),
        second.id: _settings(second),
      },
    );
    final controller = WorkspaceController(
      session: _session,
      repository: repository,
      directMessagesRepository: _FakeDirectMessagesRepository(),
      diagnostics: diagnostics,
    );
    addTearDown(controller.dispose);

    await controller.load();
    final firstSwitch = controller.selectServer(second);
    await pumpEventQueue();
    var repeatTapCompleted = false;
    final secondSwitch = controller.selectServer(second);
    unawaited(secondSwitch.then((_) => repeatTapCompleted = true));
    await pumpEventQueue();

    expect(controller.state.activeServer?.id, first.id);
    expect(repository.loadedServerIds, [first.id, second.id]);
    expect(
      diagnostics.payloadsFor('workspace.server.select.busy_ignore').single,
      containsPair('serverId', second.id),
    );
    expect(repeatTapCompleted, isTrue);

    repository.completeServerLoad(second.id);
    await firstSwitch;

    expect(controller.state.activeServer?.id, second.id);
    expect(controller.state.settings?.server.id, second.id);
    expect(repository.loadedServerIds, [first.id, second.id]);
  });

  test(
    'server rail switching waits for the minimum dwell before committing',
    () async {
      final first = _server(id: '123', name: 'Actual Verdant');
      final second = _server(id: '456', name: 'Second Verdant');
      final dwellCompleter = Completer<void>();
      final dwellDurations = <Duration>[];
      final repository = _MultiServerSettingsRepository(
        dataByServerId: {
          first.id: _settings(first),
          second.id: _settings(second),
        },
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
        serverSelectionMinimumDwell: const Duration(milliseconds: 1500),
        serverSelectionDelay: (duration) {
          dwellDurations.add(duration);
          return dwellCompleter.future;
        },
      );
      addTearDown(controller.dispose);

      await controller.load();
      final switching = controller.selectServer(second);
      await pumpEventQueue();

      expect(controller.state.activeServer?.id, first.id);
      expect(controller.state.settings?.server.id, first.id);
      expect(controller.state.isServerMessagesLoading, isTrue);
      expect(dwellDurations, [const Duration(milliseconds: 1500)]);

      dwellCompleter.complete();
      await switching;

      expect(controller.state.activeServer?.id, second.id);
      expect(controller.state.settings?.server.id, second.id);
      expect(controller.state.isServerMessagesLoading, isFalse);
    },
  );

  test('server rail switching records end-to-end timing diagnostics', () async {
    final first = _server(id: '123', name: 'Actual Verdant');
    final second = _server(id: '456', name: 'Second Verdant');
    final diagnostics = _RecordingDiagnostics();
    final repository = _MultiServerSettingsRepository(
      dataByServerId: {
        first.id: _settings(first),
        second.id: _settings(second),
      },
    );
    final controller = WorkspaceController(
      session: _session,
      repository: repository,
      directMessagesRepository: _FakeDirectMessagesRepository(),
      diagnostics: diagnostics,
    );
    addTearDown(controller.dispose);

    await controller.load();
    await controller.selectServer(second);

    expect(
      diagnostics.payloadsFor('workspace.messages.load.start').last,
      containsPair('mode', 'server_select'),
    );
    final payload = diagnostics
        .payloadsFor('workspace.server.select.result')
        .last;
    expect(payload, containsPair('networkId', _session.networkId));
    expect(payload, containsPair('serverId', second.id));
    expect(payload, containsPair('status', 'ok'));
    expect(payload, containsPair('keepLoadedWorkspace', true));
    expect(payload, containsPair('source', 'fanout'));
    expect(payload, containsPair('messageStatus', 'ok'));
    expect(payload, containsPair('activityDeferred', true));
    expect(payload['settingsMs'], isA<int>());
    expect(payload['messagesMs'], isA<int>());
    expect(payload['dwellMs'], isA<int>());
    expect(payload['totalMs'], isA<int>());
    expect(payload['messageCount'], 1);
  });

  test(
    'server rail switching treats empty channel history as loaded',
    () async {
      final first = _server(id: '123', name: 'Actual Verdant');
      final second = _server(id: '456', name: 'Quiet Verdant');
      final repository = _QuietServerSwitchRepository(
        quietChannelId: 'quiet-general',
        dataByServerId: {
          first.id: _settings(first),
          second.id: _settings(
            second,
            channels: const [
              ServerSettingsChannelSeed(id: 'quiet-general', name: 'general'),
            ],
          ),
        },
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.selectServer(second);

      expect(controller.state.activeServer?.id, second.id);
      expect(controller.state.serverMessages, isEmpty);
      expect(controller.state.serverMessagesError, isNull);
      expect(repository.loadedMessageChannelIds, ['321', 'quiet-general']);
    },
  );

  test('server rail switching ignores overlapping server loads', () async {
    final first = _server(id: '123', name: 'Actual Verdant');
    final second = _server(id: '456', name: 'Second Verdant');
    final third = _server(id: '789', name: 'Third Verdant');
    final diagnostics = _RecordingDiagnostics();
    final repository = _SlowServerSwitchRepository(
      dataByServerId: {
        first.id: _settings(first),
        second.id: _settings(second),
        third.id: _settings(third),
      },
    );
    final controller = WorkspaceController(
      session: _session,
      repository: repository,
      directMessagesRepository: _FakeDirectMessagesRepository(),
      diagnostics: diagnostics,
    );
    addTearDown(controller.dispose);

    await controller.load();
    final switchingToSecond = controller.selectServer(second);
    await pumpEventQueue();
    var ignoredSwitchCompleted = false;
    final switchingToThird = controller.selectServer(third);
    unawaited(switchingToThird.then((_) => ignoredSwitchCompleted = true));
    await pumpEventQueue();

    expect(controller.state.activeServer?.id, first.id);
    expect(repository.loadedServerIds, [first.id, second.id]);
    expect(
      diagnostics.payloadsFor('workspace.server.select.busy_ignore').single,
      containsPair('reason', 'pending_selection'),
    );
    expect(ignoredSwitchCompleted, isTrue);

    repository.completeServerLoad(second.id);
    await switchingToSecond;

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.activeServer?.id, second.id);
    expect(controller.state.settings?.server.id, second.id);
    expect(repository.loadedServerIds, [first.id, second.id]);
  });

  test(
    'server rail switching cancels a pending load when reselecting visible server',
    () async {
      final first = _server(id: '123', name: 'Actual Verdant');
      final second = _server(id: '456', name: 'Second Verdant');
      final repository = _SlowServerSwitchRepository(
        dataByServerId: {
          first.id: _settings(first),
          second.id: _settings(second),
        },
      );
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      final switchingToSecond = controller.selectServer(second);
      await pumpEventQueue();

      expect(controller.state.activeServer?.id, first.id);
      expect(controller.state.settings?.server.id, first.id);
      expect(controller.state.isServerMessagesLoading, isTrue);

      await controller.selectServer(first);
      repository.completeServerLoad(second.id);
      await switchingToSecond;

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isServerMessagesLoading, isFalse);
      expect(controller.state.isChannelActivityLoading, isFalse);
      expect(controller.state.activeServer?.id, first.id);
      expect(controller.state.settings?.server.id, first.id);
      expect(repository.loadedServerIds, [first.id, second.id]);
    },
  );

  test(
    'channel switching keeps the session for non-auth message load failures',
    () async {
      final repository = _FailingMessageServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final diagnostics = _RecordingDiagnostics();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: directMessagesRepository,
        diagnostics: diagnostics,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.selectTextChannel('654');

      expect(controller.state.error, isNull);
      expect(controller.state.activeChannelId, '321');
      expect(controller.state.pendingChannelId, isNull);
      expect(controller.state.isChannelTransitionLoading, isFalse);
      expect(controller.state.isServerMessagesLoading, isFalse);
      expect(
        controller.state.serverMessagesError,
        'Message index timed out; sign in state unknown.',
      );
      expect(controller.state.settings, isNotNull);
      expect(controller.state.directMessages, isNotNull);
      expect(directMessagesRepository.loadCount, 0);
      expect(
        diagnostics.payloadsFor('workspace.messages.load.result').last,
        containsPair('errorKind', 'transport'),
      );
      expect(
        controller.toString(),
        contains('networkId: ${networkIdFromApiOrigin(officialApiOrigin)}'),
      );
      expect(controller.toString(), isNot(contains('access-secret')));
    },
  );

  test(
    'channel switching exits to auth state after a real message auth rejection',
    () async {
      final repository = _AuthExpiredMessageServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final diagnostics = _RecordingDiagnostics();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: directMessagesRepository,
        diagnostics: diagnostics,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.selectTextChannel('654');

      expect(controller.state.error, 'Sign in again to continue');
      expect(controller.state.isAuthExpired, isTrue);
      expect(controller.state.activeChannelId, '321');
      expect(controller.state.pendingChannelId, isNull);
      expect(controller.state.isChannelTransitionLoading, isFalse);
      expect(controller.state.serverMessagesError, 'Sign in again to continue');
      expect(
        diagnostics.payloadsFor('workspace.messages.load.result').last,
        containsPair('errorKind', 'auth'),
      );
    },
  );

  test(
    'channel access rejection removes the server when membership is gone',
    () async {
      final repository = _MembershipLostServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
            ServerSettingsChannelSeed(id: '654', name: 'bot-test'),
          ],
        ),
      );
      final diagnostics = _RecordingDiagnostics();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
        diagnostics: diagnostics,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.selectTextChannel('654');

      expect(repository.listServersCount, 2);
      expect(controller.state.servers, isEmpty);
      expect(controller.state.activeServer, isNull);
      expect(controller.state.settings, isNull);
      expect(controller.state.activeChannelId, isNull);
      expect(controller.state.serverMessages, isEmpty);
      expect(
        controller.state.error,
        'You no longer have access to this server',
      );
      expect(
        diagnostics.payloadsFor('workspace.server.membership_reconcile.result'),
        contains(containsPair('status', 'removed')),
      );
    },
  );

  test(
    'server was not found channel rejection removes the server when membership is gone',
    () async {
      final repository = _MembershipLostServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
            ServerSettingsChannelSeed(id: '654', name: 'bot-test'),
          ],
        ),
        messageLoadError: 'Server was not found',
      );
      final diagnostics = _RecordingDiagnostics();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
        diagnostics: diagnostics,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.selectTextChannel('654');

      expect(repository.listServersCount, 2);
      expect(controller.state.servers, isEmpty);
      expect(controller.state.activeServer, isNull);
      expect(controller.state.settings, isNull);
      expect(controller.state.activeChannelId, isNull);
      expect(controller.state.serverMessages, isEmpty);
      expect(
        controller.state.error,
        'You no longer have access to this server',
      );
      expect(
        diagnostics.payloadsFor('workspace.server.membership_reconcile.result'),
        contains(containsPair('status', 'removed')),
      );
    },
  );

  test(
    'server was not found load rejection reconciles stale active server',
    () async {
      final repository = _LoadAccessDeniedOnRefreshRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
          ],
        ),
      );
      final diagnostics = _RecordingDiagnostics();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: _FakeDirectMessagesRepository(),
        diagnostics: diagnostics,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.refresh();

      expect(repository.listServersCount, 3);
      expect(controller.state.servers, isEmpty);
      expect(controller.state.activeServer, isNull);
      expect(controller.state.settings, isNull);
      expect(controller.state.activeChannelId, isNull);
      expect(controller.state.serverMessages, isEmpty);
      expect(
        controller.state.error,
        'You no longer have access to this server',
      );
      expect(
        diagnostics.payloadsFor('workspace.server.membership_reconcile.result'),
        contains(containsPair('status', 'removed')),
      );
    },
  );

  test(
    'send access rejection removes the server when membership is gone',
    () async {
      final repository = _MembershipLostServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..sendChannelMessageFailure = const DirectMessagesException(
          "That channel doesn't exist or you don't have access",
        );
      final diagnostics = _RecordingDiagnostics();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: directMessagesRepository,
        diagnostics: diagnostics,
      );
      addTearDown(controller.dispose);

      await controller.load();
      repository.membershipLost = true;
      await controller.sendServerMessage('still here?');

      expect(repository.listServersCount, 2);
      expect(controller.state.servers, isEmpty);
      expect(controller.state.activeServer, isNull);
      expect(controller.state.settings, isNull);
      expect(controller.state.activeChannelId, isNull);
      expect(controller.state.serverMessages, isEmpty);
      expect(
        controller.state.error,
        'You no longer have access to this server',
      );
      expect(
        diagnostics.payloadsFor('workspace.server.membership_reconcile.result'),
        contains(containsPair('status', 'removed')),
      );
    },
  );

  test(
    'channel visibility delete removes the server when membership is gone',
    () async {
      final repository = _MembershipLostServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
            ServerSettingsChannelSeed(id: '654', name: 'bot-test'),
          ],
        ),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final diagnostics = _RecordingDiagnostics();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: directMessagesRepository,
        diagnostics: diagnostics,
      );
      addTearDown(controller.dispose);

      await controller.load();
      repository.membershipLost = true;
      directMessagesRepository.emit(
        DirectMessagesServerChannelDeleteEvent(
          channelId: '${_session.networkId}/321',
          serverId: '${_session.networkId}/123',
        ),
      );
      await pumpEventQueue();

      expect(repository.listServersCount, 2);
      expect(controller.state.servers, isEmpty);
      expect(controller.state.activeServer, isNull);
      expect(controller.state.settings, isNull);
      expect(controller.state.activeChannelId, isNull);
      expect(controller.state.serverMessages, isEmpty);
      expect(
        controller.state.error,
        'You no longer have access to this server',
      );
      expect(
        diagnostics.payloadsFor('workspace.server.membership_reconcile.result'),
        contains(containsPair('status', 'removed')),
      );
    },
  );

  test('server removal selects fallback server without retry state', () async {
    final repository = _MultiServerSettingsRepository(
      dataByServerId: {
        '123': _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
            ServerSettingsChannelSeed(id: '654', name: 'bot-test'),
          ],
        ),
        '999': _settings(
          _server(id: '999', name: 'Fallback Verdant'),
          channels: const [ServerSettingsChannelSeed(id: '777', name: 'home')],
        ),
      },
    );
    final directMessagesRepository = _FakeDirectMessagesRepository();
    final diagnostics = _RecordingDiagnostics();
    final controller = WorkspaceController(
      session: _session,
      repository: repository,
      directMessagesRepository: directMessagesRepository,
      diagnostics: diagnostics,
    );
    addTearDown(controller.dispose);

    await controller.load();
    directMessagesRepository.emit(
      DirectMessagesServerDeleteEvent(serverId: '${_session.networkId}/123'),
    );
    await pumpEventQueue();

    expect(controller.state.error, isNull);
    expect(controller.state.isLoading, isFalse);
    expect(controller.state.isChannelTransitionLoading, isFalse);
    expect(controller.state.isServerMessagesLoading, isFalse);
    expect(controller.state.servers.map((server) => server.id), ['999']);
    expect(controller.state.activeServer?.id, '999');
    expect(controller.state.settings?.server.id, '999');
    expect(controller.state.activeChannelId, '777');
    expect(controller.state.serverMessagesError, isNull);
    expect(
      diagnostics.payloadsFor('workspace.server.remove.fallback.result'),
      contains(containsPair('status', 'ok')),
    );
  });

  test(
    'refreshes direct messages from repository without server member fakes',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final directMessagesPreferences = DirectMessagesPreferences.memory();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: directMessagesPreferences,
      );
      addTearDown(controller.dispose);

      await controller.load();
      directMessagesRepository.data = directMessagesRepository.data.copyWith(
        friends: [
          ...directMessagesRepository.data.friends,
          const FriendPreviewSeed(
            id: 'official/user-morgan',
            localUserId: 'user-morgan',
            networkId: 'official',
            displayName: 'Morgan',
            initials: 'MO',
            status: 'Pending',
            detail: 'Incoming request',
            kind: FriendRelationshipKind.pendingIncoming,
          ),
        ],
      );
      await controller.refreshDirectMessages();

      expect(directMessagesRepository.loadCount, 1);
      expect(
        controller.state.directMessages?.friends.map(
          (friend) => friend.displayName,
        ),
        containsAll(['Avery', 'Morgan']),
      );
      expect(
        controller.state.directMessages?.friends.map(
          (friend) => friend.displayName,
        ),
        isNot(contains('User 181051381515448320')),
      );
    },
  );

  test(
    'opens a hydrated direct message and loads its message history',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final directMessagesPreferences = DirectMessagesPreferences.memory();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: directMessagesPreferences,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.refreshDirectMessages();
      await controller.openDirectMessageConversation(
        directMessagesRepository.data.conversations.single,
      );

      expect(
        controller.state.activeDmConversation?.channelId,
        '${_session.networkId}/dm-avery',
      );
      expect(controller.state.isDmMessagesLoading, isFalse);
      expect(
        controller.state.dmMessages?.messages.map((message) => message.body),
        ['Older hello from Avery', 'Hello from Avery'],
      );
      expect(
        controller.state.directMessages?.conversations.single.lastMessage,
        'Hello from Avery',
      );
      expect(
        directMessagesRepository.loadedConversationChannelIds,
        contains('${_session.networkId}/dm-avery'),
      );

      await controller.closeDirectMessageConversation(
        directMessagesRepository.data.conversations.single,
      );

      expect(controller.state.activeDmConversation, isNull);
      expect(controller.state.dmMessages, isNull);
      expect(controller.state.directMessages?.conversations, isEmpty);
      expect(directMessagesRepository.savedHiddenChannelIds.last, {
        '${_session.networkId}/dm-avery',
      });

      final relaunched = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: directMessagesPreferences,
      );
      addTearDown(relaunched.dispose);
      await relaunched.load();

      expect(relaunched.state.directMessages?.conversations, isEmpty);

      await relaunched.openDirectMessage(
        directMessagesRepository.data.friends.single.localUserId,
      );

      expect(
        relaunched.state.directMessages?.conversations.single.channelId,
        '${_session.networkId}/dm-avery',
      );
    },
  );

  test('serializes hidden DM saves so the latest closed state wins', () async {
    final serverRepository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
    );
    final directMessagesRepository = _FakeDirectMessagesRepository();
    directMessagesRepository
      ..data = directMessagesRepository.data.copyWith(
        hiddenChannelIds: {'${_session.networkId}/dm-avery'},
      )
      ..saveHiddenChannelIdsDelay = (channelIds) {
        return channelIds.isEmpty
            ? const Duration(milliseconds: 30)
            : const Duration(milliseconds: 1);
      };
    final controller = WorkspaceController(
      session: _session,
      repository: serverRepository,
      directMessagesRepository: directMessagesRepository,
      directMessagesPreferences: DirectMessagesPreferences.memory(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    await controller.refreshDirectMessages();

    final conversation = directMessagesRepository.data.conversations.single;
    expect(controller.state.directMessages?.conversations, isEmpty);

    await controller.openDirectMessageConversation(conversation);
    await controller.closeDirectMessageConversation(conversation);
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(directMessagesRepository.requestedHiddenChannelIds, [
      isEmpty,
      {'${_session.networkId}/dm-avery'},
    ]);
    expect(directMessagesRepository.hiddenChannelIds, {
      '${_session.networkId}/dm-avery',
    });
  });

  test(
    'pending hidden DM saves ignore stale realtime hidden preference snapshots',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..saveHiddenChannelIdsDelay = (_) => const Duration(milliseconds: 30);
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.refreshDirectMessages();

      final conversation = directMessagesRepository.data.conversations.single;
      final close = controller.closeDirectMessageConversation(conversation);
      await pumpEventQueue();
      directMessagesRepository.emit(
        DirectMessagesSnapshotEvent(
          directMessagesRepository.data.copyWith(
            hiddenChannelIds: const <String>{},
          ),
        ),
      );
      await pumpEventQueue();

      expect(controller.state.directMessages?.conversations, isEmpty);

      await close;

      expect(controller.state.directMessages?.conversations, isEmpty);
      expect(directMessagesRepository.hiddenChannelIds, {
        '${_session.networkId}/dm-avery',
      });
    },
  );

  test(
    'stale direct message refresh snapshots do not override a later close save',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.refreshDirectMessages();

      final staleRefresh = Completer<DirectMessagesWorkspaceData>();
      directMessagesRepository.loadDirectMessagesCompleter = staleRefresh;
      final refresh = controller.refreshDirectMessages();
      await pumpEventQueue();

      final conversation = directMessagesRepository.data.conversations.single;
      await controller.closeDirectMessageConversation(conversation);

      staleRefresh.complete(
        directMessagesRepository.data.copyWith(
          hiddenChannelIds: const <String>{},
        ),
      );
      await refresh;

      expect(controller.state.directMessages?.conversations, isEmpty);
      expect(directMessagesRepository.hiddenChannelIds, {
        '${_session.networkId}/dm-avery',
      });
    },
  );

  test(
    'backend hidden direct message preferences ignore stale local cache',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final preferences = DirectMessagesPreferences.memory();
      await preferences.saveHiddenChannelIds(
        networkId: _session.networkId,
        userId: '42',
        channelIds: {'${_session.networkId}/dm-avery'},
      );
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: preferences,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.refreshDirectMessages();

      expect(
        controller.state.directMessages?.conversations.single.channelId,
        '${_session.networkId}/dm-avery',
      );
      expect(
        await preferences.loadHiddenChannelIds(
          networkId: _session.networkId,
          userId: '42',
        ),
        {'${_session.networkId}/dm-avery'},
      );
    },
  );

  test(
    'backend hidden direct message preferences hydrate the sidebar filter',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..hiddenChannelIds = {'${_session.networkId}/dm-avery'};
      final preferences = DirectMessagesPreferences.memory();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: preferences,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.refreshDirectMessages();

      expect(controller.state.directMessages?.conversations, isEmpty);
    },
  );

  test(
    'backend hidden direct message preference load failure only blocks conversations',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..loadHiddenChannelIdsFailure = const DirectMessagesException(
          'Direct message preferences are unavailable',
        );
      final preferences = DirectMessagesPreferences.memory();
      await preferences.saveHiddenChannelIds(
        networkId: _session.networkId,
        userId: '42',
        channelIds: {'${_session.networkId}/dm-avery'},
      );
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: preferences,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.refreshDirectMessages();

      expect(controller.state.directMessages?.conversations, isEmpty);
      expect(
        controller.state.directMessages?.friends.map(
          (friend) => friend.displayName,
        ),
        contains('Avery'),
      );
      expect(directMessagesRepository.loadCount, 1);
    },
  );

  test(
    'first direct message refresh stays pending until backend preferences load',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final hiddenPreferences = Completer<Set<String>>();
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..loadHiddenChannelIdsCompleter = hiddenPreferences;
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      final refresh = controller.refreshDirectMessages();
      await pumpEventQueue();

      expect(controller.state.directMessages?.hasHydrated, isFalse);
      expect(controller.state.directMessages?.isRefreshing, isTrue);
      expect(controller.state.directMessages?.friends, isEmpty);
      expect(controller.state.directMessages?.conversations, isEmpty);

      hiddenPreferences.complete(const {});
      await refresh;

      expect(controller.state.directMessages?.hasHydrated, isTrue);
      expect(
        controller.state.directMessages?.friends.map(
          (friend) => friend.displayName,
        ),
        contains('Avery'),
      );
      expect(
        controller.state.directMessages?.conversations.map(
          (conversation) => conversation.displayName,
        ),
        contains('Avery'),
      );
    },
  );

  test(
    'first direct message refresh uses bootstrap hidden preferences',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..data = _FakeDirectMessagesRepository().data.copyWith(
          hiddenChannelIds: {'${_session.networkId}/dm-avery'},
        )
        ..loadHiddenChannelIdsFailure = const DirectMessagesException(
          'separate preference fetch should not run',
        );
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.refreshDirectMessages();

      expect(controller.state.directMessages?.hasHydrated, isTrue);
      expect(controller.state.directMessages?.conversations, isEmpty);
      expect(
        controller.state.directMessages?.friends.map(
          (friend) => friend.displayName,
        ),
        contains('Avery'),
      );
      expect(directMessagesRepository.loadHiddenCount, 0);
      expect(directMessagesRepository.loadCount, 1);
    },
  );

  test('realtime READY hidden preferences filter direct messages', () async {
    final serverRepository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
    );
    final directMessagesRepository = _FakeDirectMessagesRepository()
      ..loadHiddenChannelIdsFailure = const DirectMessagesException(
        'separate preference fetch should not run',
      );
    final controller = WorkspaceController(
      session: _session,
      repository: serverRepository,
      directMessagesRepository: directMessagesRepository,
      directMessagesPreferences: DirectMessagesPreferences.memory(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    directMessagesRepository.emit(
      DirectMessagesSnapshotEvent(
        directMessagesRepository.data.copyWith(
          hiddenChannelIds: {'${_session.networkId}/dm-avery'},
        ),
      ),
    );
    await pumpEventQueue();

    expect(controller.state.directMessages?.conversations, isEmpty);
    expect(
      controller.state.directMessages?.friends.map(
        (friend) => friend.displayName,
      ),
      contains('Avery'),
    );
    expect(directMessagesRepository.loadHiddenCount, 0);
  });

  test(
    'concurrent direct message refresh waits for backend hidden preferences',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final hiddenPreferences = Completer<Set<String>>();
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..loadHiddenChannelIdsCompleter = hiddenPreferences;
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      final firstRefresh = controller.refreshDirectMessages();
      await pumpEventQueue();

      var secondRefreshCompleted = false;
      final secondRefresh = controller.refreshDirectMessages().then((_) {
        secondRefreshCompleted = true;
      });
      await pumpEventQueue();

      expect(secondRefreshCompleted, isFalse);
      expect(controller.state.directMessages?.conversations, isEmpty);

      hiddenPreferences.complete({'${_session.networkId}/dm-avery'});
      await Future.wait([firstRefresh, secondRefresh]);

      expect(controller.state.directMessages?.conversations, isEmpty);
      expect(directMessagesRepository.loadCount, 2);
    },
  );

  test(
    'keeps hydrated direct messages when a refresh snapshot fails',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.refreshDirectMessages();
      directMessagesRepository.failNextLoad = true;
      await controller.refreshDirectMessages();

      expect(
        controller.state.directMessages?.conversations.single.channelId,
        '${_session.networkId}/dm-avery',
      );
      expect(controller.state.directMessages?.error, 'DM snapshot failed');
    },
  );

  test(
    'stale realtime snapshots do not close the active direct message',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      final conversation = directMessagesRepository.data.conversations.single;
      await controller.openDirectMessageConversation(conversation);

      directMessagesRepository.emit(
        DirectMessagesSnapshotEvent(
          DirectMessagesWorkspaceData.empty(
            networkId: 'official',
            currentUserName: 'boji',
            currentUserInitials: 'BO',
          ),
        ),
      );
      await pumpEventQueue();

      expect(
        controller.state.activeDmConversation?.channelId,
        '${_session.networkId}/dm-avery',
      );
      expect(
        controller.state.dmMessages?.messages.map((message) => message.body),
        ['Older hello from Avery', 'Hello from Avery'],
      );
    },
  );

  test('loads older direct messages before the oldest hydrated row', () async {
    final serverRepository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
    );
    final directMessagesRepository = _FakeDirectMessagesRepository()
      ..initialConversationMessageCount = 50;
    final controller = WorkspaceController(
      session: _session,
      repository: serverRepository,
      directMessagesRepository: directMessagesRepository,
      directMessagesPreferences: DirectMessagesPreferences.memory(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    await controller.openDirectMessageConversation(
      directMessagesRepository.data.conversations.single,
    );
    await controller.loadOlderDirectMessages();

    expect(
      directMessagesRepository.loadedConversationBeforeIds.last,
      '${_session.networkId}/dm-message-0',
    );
    expect(controller.state.hasMoreDmMessages, isFalse);
    expect(
      controller.state.dmMessages?.messages.first.body,
      startsWith('Oldest'),
    );
    expect(controller.state.dmMessages?.messages, hasLength(51));
  });

  test('loads older server messages before the oldest hydrated row', () async {
    final initialMessages = [
      for (var index = 0; index < 50; index += 1)
        MessageSeed(
          id: 'official/server-message-$index',
          authorId: 'official/42',
          author: 'boji',
          body: 'Initial server message $index',
          initials: 'BO',
          time: '10:$index AM',
          isOwnMessage: true,
        ),
    ];
    final olderMessages = [
      const MessageSeed(
        id: 'official/server-message-older',
        authorId: 'official/181',
        author: 'Avery',
        body: 'Older server message',
        initials: 'AV',
        time: '9:59 AM',
        isOwnMessage: false,
      ),
    ];
    final repository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
      messageBatches: [initialMessages, olderMessages],
    );
    final controller = WorkspaceController(
      session: _session,
      repository: repository,
      directMessagesRepository: _FakeDirectMessagesRepository(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    await controller.loadOlderServerMessages();

    expect(repository.loadedMessageBeforeIds.last, 'official/server-message-0');
    expect(controller.state.hasMoreServerMessages, isFalse);
    expect(controller.state.serverMessages.first.body, 'Older server message');
    expect(controller.state.serverMessages, hasLength(51));
  });

  test('applies live direct message and presence websocket events', () async {
    final serverRepository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
    );
    final directMessagesRepository = _FakeDirectMessagesRepository();
    final controller = WorkspaceController(
      session: _session,
      repository: serverRepository,
      directMessagesRepository: directMessagesRepository,
      directMessagesPreferences: DirectMessagesPreferences.memory(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    final conversation = directMessagesRepository.data.conversations.single;
    await controller.closeDirectMessageConversation(conversation);

    directMessagesRepository.emit(
      const DirectMessagesPresenceUpdateEvent(
        localUserId: '181051381515448321',
        status: 'idle',
      ),
    );
    directMessagesRepository.emit(
      DirectMessagesMessageCreateEvent(
        channelId: conversation.channelId,
        message: const MessageSeed(
          id: 'official/message-live',
          authorId: 'official/181051381515448321',
          author: 'Avery',
          body: 'Live websocket hello',
          initials: 'AV',
          time: '2026-06-02 12:30',
          isOwnMessage: false,
          reactions: [],
        ),
      ),
    );
    await pumpEventQueue();

    expect(controller.state.directMessages?.conversations, isEmpty);
    expect(directMessagesRepository.savedHiddenChannelIds.last, {
      '${_session.networkId}/dm-avery',
    });
    await controller.openDirectMessageConversation(conversation);
    expect(controller.state.directMessages?.conversations, hasLength(1));
    expect(
      controller.state.directMessages?.conversations.single.status,
      'Idle',
    );
    expect(
      controller.state.directMessages?.conversations.single.lastMessage,
      'Live websocket hello',
    );
    directMessagesRepository.emit(
      const DirectMessagesMessageCreateEvent(
        channelId: 'dm-avery',
        message: MessageSeed(
          id: 'official/message-live-raw-dm-channel',
          authorId: 'official/181051381515448321',
          author: 'Avery',
          body: 'Raw DM channel was scoped to active network',
          initials: 'AV',
          time: '2026-06-02 12:30',
          isOwnMessage: false,
          reactions: [],
        ),
      ),
    );
    await pumpEventQueue();

    expect(
      controller.state.directMessages?.conversations.single.channelId,
      '${_session.networkId}/dm-avery',
    );
    expect(
      controller.state.directMessages?.conversations.single.lastMessage,
      'Raw DM channel was scoped to active network',
    );
    expect(directMessagesRepository.savedHiddenChannelIds.last, isEmpty);

    directMessagesRepository.emit(
      DirectMessagesMessageCreateEvent(
        channelId: conversation.channelId,
        message: const MessageSeed(
          id: 'official/message-live-2',
          authorId: 'official/42',
          author: 'boji',
          body: 'Own live reply',
          initials: 'BO',
          time: '2026-06-02 12:31',
          isOwnMessage: true,
          reactions: [],
        ),
      ),
    );
    directMessagesRepository.emit(
      const DirectMessagesPresenceUpdateEvent(localUserId: '42', status: 'dnd'),
    );
    await pumpEventQueue();

    expect(
      controller.state.dmMessages?.messages.map((message) => message.body),
      containsAll(['Live websocket hello', 'Own live reply']),
    );
    expect(controller.state.directMessages?.currentUserStatus, 'Busy');
  });

  test('applies live server channel message websocket events', () async {
    final serverRepository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
    );
    final directMessagesRepository = _FakeDirectMessagesRepository();
    final controller = WorkspaceController(
      session: _session,
      repository: serverRepository,
      directMessagesRepository: directMessagesRepository,
      directMessagesPreferences: DirectMessagesPreferences.memory(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    directMessagesRepository.emit(
      const DirectMessagesMessageCreateEvent(
        channelId: 'official/321',
        message: MessageSeed(
          id: 'official/message-live-server',
          authorId: 'official/181051381515448321',
          author: 'Avery',
          body: 'Server broadcast arrived',
          initials: 'AV',
          time: '2026-06-02 12:33',
          isOwnMessage: false,
          reactions: [],
        ),
      ),
    );
    await pumpEventQueue();

    expect(
      controller.state.serverMessages.map((message) => message.body),
      contains('Server broadcast arrived'),
    );
    expect(controller.state.directMessages?.conversations, isEmpty);

    directMessagesRepository.emit(
      const DirectMessagesMessageCreateEvent(
        channelId: '321',
        message: MessageSeed(
          id: 'official/message-live-server-raw-channel',
          authorId: 'official/181051381515448321',
          author: 'Avery',
          body: 'Raw channel was scoped to active network',
          initials: 'AV',
          time: '2026-06-02 12:34',
          isOwnMessage: false,
          reactions: [],
        ),
      ),
    );
    await pumpEventQueue();

    expect(
      controller.state.serverMessages.map((message) => message.body),
      contains('Raw channel was scoped to active network'),
    );

    directMessagesRepository.emit(
      const DirectMessagesMessageCreateEvent(
        channelId: 'origin:https%3A%2F%2Fapi-test.pryzmapp.com/321',
        message: MessageSeed(
          id: 'origin:https%3A%2F%2Fapi-test.pryzmapp.com/message-other-network',
          authorId:
              'origin:https%3A%2F%2Fapi-test.pryzmapp.com/181051381515448321',
          author: 'Avery',
          body: 'Other network message must not render here',
          initials: 'AV',
          time: '2026-06-02 12:35',
          isOwnMessage: false,
          reactions: [],
        ),
      ),
    );
    await pumpEventQueue();

    expect(
      controller.state.serverMessages.map((message) => message.body),
      isNot(contains('Other network message must not render here')),
    );
    expect(controller.state.directMessages?.conversations, isEmpty);

    directMessagesRepository.emit(
      const DirectMessagesReactionAddEvent(
        channelId: 'official/321',
        messageId: 'official/message-live-server',
        localUserId: '42',
        emoji: '😀',
      ),
    );
    await pumpEventQueue();

    expect(
      controller.state.serverMessages
          .firstWhere((message) => message.id == 'official/message-live-server')
          .reactions
          .single
          .reactedByCurrentUser,
      isTrue,
    );

    directMessagesRepository.emit(
      const DirectMessagesReactionRemoveEvent(
        channelId: 'official/321',
        messageId: 'official/message-live-server',
        localUserId: '42',
        emoji: '😀',
      ),
    );
    await pumpEventQueue();

    expect(
      controller.state.serverMessages
          .firstWhere((message) => message.id == 'official/message-live-server')
          .reactions,
      isEmpty,
    );
  });

  test('applies live server presence and typing websocket events', () async {
    final serverRepository = _FakeServerSettingsRepository(
      data: _settings(
        _server(id: '123', name: 'Actual Verdant'),
        members: const [
          ServerSettingsListItemSeed(
            title: 'Avery',
            subtitle: 'Offline',
            trailing: 'Member',
            userId: '181051381515448321',
          ),
        ],
      ),
      activeChannelMembers: const [
        MemberSeed(
          id: 'official/181051381515448321',
          name: 'Avery',
          status: 'Offline',
          initials: 'AV',
          role: 'Member',
        ),
      ],
    );
    final directMessagesRepository = _FakeDirectMessagesRepository();
    final controller = WorkspaceController(
      session: _session,
      repository: serverRepository,
      directMessagesRepository: directMessagesRepository,
      directMessagesPreferences: DirectMessagesPreferences.memory(),
    );
    addTearDown(controller.dispose);

    await controller.load();

    directMessagesRepository.emit(
      const DirectMessagesPresenceUpdateEvent(
        localUserId: '181051381515448321',
        status: 'online',
      ),
    );
    directMessagesRepository.emit(
      const DirectMessagesTypingStartEvent(
        channelId: 'official/321',
        localUserId: '181051381515448321',
      ),
    );
    await pumpEventQueue();

    expect(controller.state.activeChannelMembers.single.status, 'Online');
    expect(controller.state.activeChannelMembers.single.isActive, isTrue);
    expect(controller.state.settings?.members.single.subtitle, 'Online');
    expect(
      controller.state.activeTypingMembers.map((member) => member.name),
      contains('Avery'),
    );
  });

  test(
    'applies live bot presence websocket events to workspace members',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          bots: const [
            ServerSettingsListItemSeed(
              id: 'bot-1',
              title: 'Verdant Bot',
              subtitle: 'Publishes feed smoke tests',
              trailing: 'offline',
            ),
          ],
        ),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      var seed = WorkspaceSeed.fromSettingsData(
        controller.state.settings!,
        currentUserId: '42',
        currentUserName: 'Joshy',
        currentUserInitials: 'JO',
      );
      expect(
        seed.members.singleWhere((member) => member.isBot).isActive,
        isFalse,
      );

      directMessagesRepository.emit(
        const DirectMessagesBotPresenceUpdateEvent(
          localBotId: 'bot-1',
          serverId: 'official/123',
          status: 'online',
        ),
      );
      await pumpEventQueue();

      expect(controller.state.settings?.bots.single.trailing, 'Online');
      seed = WorkspaceSeed.fromSettingsData(
        controller.state.settings!,
        currentUserId: '42',
        currentUserName: 'Joshy',
        currentUserInitials: 'JO',
      );
      final bot = seed.members.singleWhere((member) => member.isBot);
      expect(bot.name, 'Verdant Bot');
      expect(bot.status, 'Online');
      expect(bot.isActive, isTrue);
    },
  );

  test('applies live server profile updates to member state', () async {
    final serverRepository = _FakeServerSettingsRepository(
      data: _settings(
        _server(id: '123', name: 'Actual Verdant'),
        members: const [
          ServerSettingsListItemSeed(
            title: 'Avery',
            subtitle: 'Offline',
            trailing: 'Member',
            userId: '181051381515448321',
          ),
        ],
      ),
      activeChannelMembers: const [
        MemberSeed(
          id: 'official/181051381515448321',
          name: 'Avery',
          status: 'Offline',
          initials: 'AV',
          role: 'Member',
        ),
      ],
    );
    final directMessagesRepository = _FakeDirectMessagesRepository();
    final controller = WorkspaceController(
      session: _session,
      repository: serverRepository,
      directMessagesRepository: directMessagesRepository,
      directMessagesPreferences: DirectMessagesPreferences.memory(),
    );
    addTearDown(controller.dispose);

    await controller.load();

    directMessagesRepository.emit(
      const DirectMessagesUserProfileUpdateEvent(
        localUserId: '181051381515448321',
        displayName: 'Avery Live',
        bannerBaseColor: '#2EC4B6',
      ),
    );
    await pumpEventQueue();

    expect(controller.state.activeChannelMembers.single.name, 'Avery Live');
    expect(
      controller.state.activeChannelMembers.single.bannerBaseColor,
      const Color(0xFF2EC4B6),
    );
    expect(controller.state.settings?.members.single.title, 'Avery Live');
    expect(
      controller.state.settings?.members.single.bannerBaseColor,
      const Color(0xFF2EC4B6),
    );
  });

  test('refreshCurrentUserProfile avoids a full workspace reload', () async {
    final serverRepository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
      currentUserMedia: const ServerSettingsCurrentUserMedia(
        id: '181051381515448320',
        username: 'joshy',
        displayName: 'Joshy',
        email: 'joshy@example.com',
        avatarUrl: null,
        bannerUrl: null,
        bannerBaseColor: Color(0xFF2EC4B6),
        status: 'online',
        bio: null,
        usernameSet: true,
        emailVerified: true,
        totpEnabled: false,
      ),
    );
    final directMessagesRepository = _FakeDirectMessagesRepository();
    final controller = WorkspaceController(
      session: _session,
      repository: serverRepository,
      directMessagesRepository: directMessagesRepository,
      directMessagesPreferences: DirectMessagesPreferences.memory(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(serverRepository.listServersCount, 1);

    await controller.refreshCurrentUserProfile();

    expect(serverRepository.listServersCount, 1);
    expect(serverRepository.currentUserMediaLoadCount, 2);
    expect(controller.state.currentUser!.bannerBaseColor, '#2EC4B6');
  });

  test(
    'sends server typing through the realtime websocket command sink',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.sendServerTypingStart();
      await controller.sendServerTypingStart();

      expect(directMessagesRepository.sentTypingChannelIds, ['321']);
    },
  );

  test(
    'manual current-user status uses realtime command and updates workspace',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          members: const [
            ServerSettingsListItemSeed(
              title: 'boji',
              subtitle: 'Online',
              trailing: 'Member',
              userId: '42',
            ),
          ],
        ),
        activeChannelMembers: const [
          MemberSeed(
            id: 'official/42',
            name: 'boji',
            status: 'Online',
            initials: 'BO',
            role: 'Member',
          ),
        ],
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await pumpEventQueue();
      await controller.updateCurrentUserStatus('idle');

      expect(directMessagesRepository.updatedPresenceStatuses, ['idle']);
      expect(directMessagesRepository.connectedStatuses, ['online']);
      expect(controller.state.currentUser?.status, 'idle');
      expect(controller.state.activeChannelMembers.single.status, 'Idle');
      expect(controller.state.settings?.members.single.subtitle, 'Idle');
    },
  );

  test(
    'does not identify realtime as offline from stale REST profile status',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          members: const [
            ServerSettingsListItemSeed(
              title: 'boji',
              subtitle: 'Offline',
              trailing: 'Member',
              userId: '42',
            ),
          ],
        ),
        currentUserMedia: const ServerSettingsCurrentUserMedia(
          id: '42',
          status: 'offline',
        ),
        activeChannelMembers: const [
          MemberSeed(
            id: 'official/42',
            name: 'boji',
            status: 'Offline',
            initials: 'BO',
            role: 'Member',
          ),
        ],
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(directMessagesRepository.connectedStatuses, ['online']);
      expect(controller.state.currentUser?.status, 'online');
      expect(controller.state.directMessages?.currentUserStatus, 'Online');
    },
  );

  test(
    'explicit invisible status still reconnects realtime as offline',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..presenceReconnectingFailuresRemaining = 1;
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.updateCurrentUserStatus('offline');

      expect(directMessagesRepository.connectedStatuses, ['online', 'offline']);
      expect(directMessagesRepository.updatedPresenceStatuses, [
        'offline',
        'offline',
      ]);
      expect(controller.state.currentUser?.status, 'offline');
      expect(controller.state.directMessages?.currentUserStatus, 'Offline');
    },
  );

  test(
    'restores selected current-user status after restart when profile is stale offline',
    () async {
      final preferences = DirectMessagesPreferences.memory();
      final firstRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        currentUserMedia: const ServerSettingsCurrentUserMedia(
          id: '42',
          status: 'offline',
        ),
      );
      final firstRealtimeRepository = _FakeDirectMessagesRepository();
      final offlineSession = AuthSession.authenticated(
        apiOrigin: 'https://api.verdant.chat',
        user: _session.user.copyWith(status: 'offline'),
      );
      final firstController = WorkspaceController(
        session: offlineSession,
        repository: firstRepository,
        directMessagesRepository: firstRealtimeRepository,
        directMessagesPreferences: preferences,
      );

      await firstController.load();
      await firstController.updateCurrentUserStatus('idle');
      firstController.dispose();

      final restartedRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        currentUserMedia: const ServerSettingsCurrentUserMedia(
          id: '42',
          status: 'offline',
        ),
      );
      final restartedRealtimeRepository = _FakeDirectMessagesRepository();
      final restartedController = WorkspaceController(
        session: offlineSession,
        repository: restartedRepository,
        directMessagesRepository: restartedRealtimeRepository,
        directMessagesPreferences: preferences,
      );
      addTearDown(restartedController.dispose);

      await restartedController.load();

      expect(restartedRealtimeRepository.connectedStatuses, ['idle']);
      expect(restartedController.state.currentUser?.status, 'idle');
      expect(
        restartedController.state.directMessages?.currentUserStatus,
        'Idle',
      );
    },
  );

  test(
    'defaults stale offline session and profile status to online without a saved preference',
    () async {
      final offlineSession = AuthSession.authenticated(
        apiOrigin: 'https://api.verdant.chat',
        user: _session.user.copyWith(status: 'offline'),
      );
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        currentUserMedia: const ServerSettingsCurrentUserMedia(
          id: '42',
          status: 'offline',
        ),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: offlineSession,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(directMessagesRepository.connectedStatuses, ['online']);
      expect(controller.state.currentUser?.status, 'online');
      expect(controller.state.directMessages?.currentUserStatus, 'Online');
    },
  );

  test('restores explicitly selected invisible status after restart', () async {
    final preferences = DirectMessagesPreferences.memory();
    final firstRepository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
    );
    final firstRealtimeRepository = _FakeDirectMessagesRepository();
    final firstController = WorkspaceController(
      session: _session,
      repository: firstRepository,
      directMessagesRepository: firstRealtimeRepository,
      directMessagesPreferences: preferences,
    );

    await firstController.load();
    await firstController.updateCurrentUserStatus('offline');
    firstController.dispose();

    final restartedRepository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
    );
    final restartedRealtimeRepository = _FakeDirectMessagesRepository();
    final restartedController = WorkspaceController(
      session: _session,
      repository: restartedRepository,
      directMessagesRepository: restartedRealtimeRepository,
      directMessagesPreferences: preferences,
    );
    addTearDown(restartedController.dispose);

    await restartedController.load();

    expect(restartedRealtimeRepository.connectedStatuses, ['offline']);
    expect(restartedController.state.currentUser?.status, 'offline');
    expect(
      restartedController.state.directMessages?.currentUserStatus,
      'Offline',
    );
  });

  test(
    'keeps selected current user status when realtime is reconnecting',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        activeChannelMembers: const [
          MemberSeed(
            id: 'official/42',
            name: 'boji',
            status: 'Online',
            initials: 'BO',
            role: 'Member',
          ),
        ],
      );
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..presenceReconnectingFailuresRemaining = 1;
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.updateCurrentUserStatus('idle');

      expect(directMessagesRepository.connectedStatuses, ['online', 'idle']);
      expect(directMessagesRepository.updatedPresenceStatuses, [
        'idle',
        'idle',
      ]);
      expect(controller.state.currentUser?.status, 'idle');
      expect(controller.state.directMessages?.currentUserStatus, 'Idle');
    },
  );

  test(
    'does not mark current user channel-active until message activity arrives',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        activeChannelMembers: const [
          MemberSeed(
            id: 'official/42',
            name: 'boji',
            status: 'Online',
            initials: 'BO',
            isActive: false,
          ),
        ],
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      directMessagesRepository.emit(
        const DirectMessagesPresenceUpdateEvent(
          localUserId: '42',
          status: 'online',
        ),
      );
      await controller.sendServerTypingStart();
      await pumpEventQueue();

      expect(controller.state.activeChannelMembers.single.isActive, isFalse);

      directMessagesRepository.emit(
        const DirectMessagesChannelActivityEvent(
          channelId: 'official/321',
          localUserId: '42',
          displayName: 'boji',
        ),
      );
      await pumpEventQueue();

      expect(controller.state.activeChannelMembers.single.isActive, isTrue);
    },
  );

  test('reconnects realtime commands after the live stream closes', () async {
    final serverRepository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
    );
    final directMessagesRepository = _FakeDirectMessagesRepository();
    final controller = WorkspaceController(
      session: _session,
      repository: serverRepository,
      directMessagesRepository: directMessagesRepository,
      directMessagesPreferences: DirectMessagesPreferences.memory(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(directMessagesRepository.connectCount, 1);

    await directMessagesRepository.closeRealtime();
    await pumpEventQueue();
    await controller.sendServerMessage('after reconnect');

    expect(directMessagesRepository.connectCount, 2);
    expect(
      directMessagesRepository.sentMessageContents.last,
      'after reconnect',
    );
    expect(controller.state.serverMessagesError, isNull);
  });

  test(
    'refreshing direct messages preserves the active realtime session',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.refreshDirectMessages();
      await controller.refreshDirectMessages();

      expect(directMessagesRepository.loadCount, 2);
      expect(directMessagesRepository.connectCount, 1);
    },
  );

  test(
    'retries commands during realtime READY churn without expiring the session',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..sendFailuresRemaining = 1;
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.sendServerMessage('after ready churn');

      expect(directMessagesRepository.connectCount, 2);
      expect(directMessagesRepository.sentMessageContents, [
        'after ready churn',
      ]);
      expect(controller.state.serverMessagesError, isNull);
      expect(controller.state.isAuthExpired, isFalse);
      expect(controller.toString(), isNot(contains('access-secret')));
      expect(controller.toString(), isNot(contains('session-secret')));
    },
  );

  test(
    'keeps retrying commands through reconnect and token refresh churn',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..sendFailuresRemaining = 2;
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.sendServerMessage('after token refresh churn');

      expect(directMessagesRepository.connectCount, 3);
      expect(directMessagesRepository.sentMessageContents, [
        'after token refresh churn',
      ]);
      expect(controller.state.serverMessagesError, isNull);
      expect(controller.state.isAuthExpired, isFalse);
    },
  );

  test(
    'forces a fresh realtime session for retryable command setup failures',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..sendNotReadyFailuresRemaining = 1;
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.sendServerMessage('after not ready');

      expect(directMessagesRepository.connectCount, 2);
      expect(directMessagesRepository.sentMessageContents, ['after not ready']);
      expect(controller.state.serverMessagesError, isNull);
      expect(controller.state.isAuthExpired, isFalse);
    },
  );

  test(
    'keeps the session when commands hit a reconnecting realtime transport',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository()
        ..sendReconnectingFailuresRemaining = 1;
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.sendServerMessage('after reconnecting');

      expect(directMessagesRepository.connectCount, 2);
      expect(directMessagesRepository.sentMessageContents, [
        'after reconnecting',
      ]);
      expect(controller.state.serverMessagesError, isNull);
      expect(controller.state.isAuthExpired, isFalse);
    },
  );

  test(
    'applies live server hydration updates for messages activity and unread',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
            ServerSettingsChannelSeed(id: '654', name: 'bot-test'),
          ],
        ),
        activeChannelMembers: const [
          MemberSeed(
            id: 'official/181',
            name: 'Avery',
            status: 'Offline',
            initials: 'AV',
            isActive: false,
          ),
        ],
        messages: const [
          MessageSeed(
            id: 'official/message-live-server',
            authorId: 'official/181',
            author: 'Avery',
            body: 'before edit',
            initials: 'AV',
            time: '2026-06-02 12:33',
            isOwnMessage: false,
            reactions: [],
          ),
          MessageSeed(
            id: 'official/message-delete-me',
            authorId: 'official/181',
            author: 'Avery',
            body: 'delete me',
            initials: 'AV',
            time: '2026-06-02 12:34',
            isOwnMessage: false,
            reactions: [],
          ),
        ],
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      directMessagesRepository.emit(
        const DirectMessagesMessageUpdateEvent(
          channelId: 'official/321',
          message: MessageSeed(
            id: 'official/message-live-server',
            authorId: 'official/181',
            author: 'Avery',
            body: 'after edit',
            initials: 'AV',
            time: '2026-06-02 12:35',
          ),
        ),
      );
      directMessagesRepository.emit(
        const DirectMessagesMessageDeleteEvent(
          channelId: 'official/321',
          messageId: 'official/message-delete-me',
        ),
      );
      directMessagesRepository.emit(
        const DirectMessagesChannelActivityEvent(
          channelId: 'official/321',
          localUserId: '181',
          displayName: 'Avery Updated',
          avatarUrl: 'https://cdn.example/avatar.webp',
        ),
      );
      directMessagesRepository.emit(
        const DirectMessagesChannelUnreadEvent(
          channelId: 'origin:https%3A%2F%2Fapi-test.pryzmapp.com/654',
          messageId:
              'origin:https%3A%2F%2Fapi-test.pryzmapp.com/message-other-network',
          localAuthorId: '181',
          mentionsCurrentUser: true,
          isDirectMessage: false,
        ),
      );
      await pumpEventQueue();
      final unchangedUnreadChannel = controller.state.settings!.channels
          .firstWhere((channel) => channel.id == '654');
      expect(unchangedUnreadChannel.unread, isFalse);
      expect(unchangedUnreadChannel.mentionCount, 0);

      directMessagesRepository.emit(
        const DirectMessagesChannelUnreadEvent(
          channelId: 'official/654',
          messageId: 'official/message-other-channel',
          localAuthorId: '181',
          mentionsCurrentUser: true,
          isDirectMessage: false,
        ),
      );
      await pumpEventQueue();

      expect(
        controller.state.serverMessages
            .firstWhere(
              (message) => message.id == 'official/message-live-server',
            )
            .body,
        'after edit',
      );
      expect(
        controller.state.serverMessages.where(
          (message) => message.id == 'official/message-delete-me',
        ),
        isEmpty,
      );
      expect(
        controller.state.activeChannelMembers.single.name,
        'Avery Updated',
      );
      expect(controller.state.activeChannelMembers.single.isActive, isTrue);
      final unreadChannel = controller.state.settings!.channels.firstWhere(
        (channel) => channel.id == '654',
      );
      expect(unreadChannel.unread, isTrue);
      expect(unreadChannel.mentionCount, 1);
    },
  );

  test('applies live server channel and member hydration updates', () async {
    final serverRepository = _FakeServerSettingsRepository(
      data: _settings(
        _server(id: '123', name: 'Actual Verdant'),
        channels: const [
          ServerSettingsChannelSeed(id: '321', name: 'general'),
          ServerSettingsChannelSeed(id: '654', name: 'bot-test'),
        ],
      ),
      activeChannelMembers: const [
        MemberSeed(
          id: 'official/181',
          name: 'Avery',
          status: 'Offline',
          initials: 'AV',
          role: 'Member',
          isActive: false,
        ),
        MemberSeed(
          id: 'official/333',
          name: 'Leaving User',
          status: 'Online',
          initials: 'LU',
        ),
      ],
    );
    final directMessagesRepository = _FakeDirectMessagesRepository();
    final controller = WorkspaceController(
      session: _session,
      repository: serverRepository,
      directMessagesRepository: directMessagesRepository,
      directMessagesPreferences: DirectMessagesPreferences.memory(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    directMessagesRepository.emit(
      const DirectMessagesServerChannelUpsertEvent(
        channel: ChannelSeed(id: 'official/777', name: 'new-room'),
      ),
    );
    directMessagesRepository.emit(
      const DirectMessagesServerChannelUpsertEvent(
        channel: ChannelSeed(
          id: 'official/654',
          name: 'renamed-voice',
          type: 3,
        ),
      ),
    );
    directMessagesRepository.emit(
      const DirectMessagesServerChannelDeleteEvent(
        channelId: 'origin:https%3A%2F%2Fapi-test.pryzmapp.com/321',
      ),
    );
    await pumpEventQueue();
    expect(
      controller.state.settings?.channels.map((channel) => channel.name),
      contains('general'),
    );
    directMessagesRepository.emit(
      const DirectMessagesServerChannelDeleteEvent(channelId: 'official/321'),
    );
    directMessagesRepository.emit(
      const DirectMessagesServerMemberUpsertEvent(
        member: MemberSeed(
          id: 'official/222',
          name: 'New User',
          status: 'Online',
          initials: 'NU',
          avatarUrl: 'https://cdn.example/new-user.webp',
        ),
      ),
    );
    directMessagesRepository.emit(
      const DirectMessagesServerMemberUpsertEvent(
        member: MemberSeed(
          id: 'official/181',
          name: 'Avery Live',
          username: 'avery_perm',
          status: 'dnd',
          initials: 'AL',
          avatarUrl: 'https://cdn.example/avery-live.webp',
          bannerUrl: 'https://cdn.example/avery-banner.webp',
          memberListBannerUrl: 'https://cdn.example/avery-list-banner.webp',
        ),
      ),
    );
    directMessagesRepository.emit(
      const DirectMessagesServerMemberRoleUpdateEvent(
        userId: 'official/181',
        roleIds: ['role-1', 'role-2'],
      ),
    );
    directMessagesRepository.emit(
      const DirectMessagesServerMemberRemoveEvent(userId: 'official/333'),
    );
    await pumpEventQueue();

    expect(
      controller.state.settings?.channels.map((channel) => channel.name),
      containsAll(['new-room', 'renamed-voice']),
    );
    expect(
      controller.state.settings?.channels.map((channel) => channel.name),
      isNot(contains('general')),
    );
    expect(
      controller.state.activeChannelMembers.map((member) => member.name),
      isNot(contains('New User')),
    );
    expect(
      controller.state.settings?.members.map((member) => member.title),
      containsAll(['New User', 'Avery Live']),
    );
    final settingsNewUser = controller.state.settings!.members.firstWhere(
      (member) => member.userId == '222',
    );
    expect(settingsNewUser.id, '${_session.networkId}/222');
    expect(settingsNewUser.avatarUrl, contains('/new-user.webp'));
    directMessagesRepository.emit(
      const DirectMessagesChannelActivityEvent(
        channelId: 'official/777',
        localUserId: '222',
      ),
    );
    await pumpEventQueue();
    final activeNewUser = controller.state.activeChannelMembers.firstWhere(
      (member) => member.id?.endsWith('/222') ?? false,
    );
    expect(activeNewUser.name, 'New User');
    expect(activeNewUser.status, 'Online');
    expect(activeNewUser.avatarUrl, contains('/new-user.webp'));
    final settingsAvery = controller.state.settings!.members.firstWhere(
      (member) => member.userId == '181',
    );
    expect(settingsAvery.username, 'avery_perm');
    expect(settingsAvery.avatarUrl, contains('/avery-live.webp'));
    expect(settingsAvery.bannerUrl, contains('/avery-banner.webp'));
    expect(
      settingsAvery.memberListBannerUrl,
      contains('/avery-list-banner.webp'),
    );
    expect(
      controller.state.activeChannelMembers
          .firstWhere((member) => member.id?.endsWith('/181') ?? false)
          .role,
      '2 roles',
    );
    final updatedAvery = controller.state.activeChannelMembers.firstWhere(
      (member) => member.id?.endsWith('/181') ?? false,
    );
    expect(updatedAvery.name, 'Avery Live');
    expect(updatedAvery.username, 'avery_perm');
    expect(updatedAvery.status, 'dnd');
    expect(updatedAvery.avatarUrl, contains('/avery-live.webp'));
    expect(updatedAvery.bannerUrl, contains('/avery-banner.webp'));
    expect(
      updatedAvery.memberListBannerUrl,
      contains('/avery-list-banner.webp'),
    );
    expect(
      controller.state.activeChannelMembers.map((member) => member.id),
      isNot(contains('official/333')),
    );
  });

  test('server delete realtime ejects the server from the rail', () async {
    final serverRepository = _FakeServerSettingsRepository(
      data: _settings(
        _server(id: '123', name: 'Actual Verdant'),
        members: const [
          ServerSettingsListItemSeed(
            title: 'boji',
            subtitle: 'Online',
            userId: '42',
            trailing: 'Owner',
          ),
        ],
      ),
    );
    final directMessagesRepository = _FakeDirectMessagesRepository();
    final controller = WorkspaceController(
      session: _session,
      repository: serverRepository,
      directMessagesRepository: directMessagesRepository,
    );
    addTearDown(controller.dispose);

    await controller.load();

    directMessagesRepository.emit(
      const DirectMessagesServerDeleteEvent(serverId: 'other-network/123'),
    );
    await pumpEventQueue();

    expect(controller.state.activeServer?.id, '123');

    directMessagesRepository.emit(
      const DirectMessagesServerDeleteEvent(serverId: 'official/123'),
    );
    await pumpEventQueue();

    expect(controller.state.servers.map((server) => server.id), isEmpty);
    expect(controller.state.activeServer, isNull);
    expect(controller.state.settings, isNull);
    expect(controller.state.activeChannelId, isNull);
    expect(controller.state.serverMessages, isEmpty);
    expect(controller.state.activeChannelMembers, isEmpty);
  });

  test(
    'current user member remove realtime ejects the active server',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          members: const [
            ServerSettingsListItemSeed(
              title: 'boji',
              subtitle: 'Online',
              userId: '42',
              trailing: 'Owner',
            ),
          ],
        ),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
      );
      addTearDown(controller.dispose);

      await controller.load();

      directMessagesRepository.emit(
        const DirectMessagesServerMemberRemoveEvent(
          serverId: 'official/123',
          userId: 'official/42',
        ),
      );
      await pumpEventQueue();

      expect(controller.state.servers.map((server) => server.id), isEmpty);
      expect(controller.state.activeServer, isNull);
      expect(controller.state.settings, isNull);
      expect(controller.state.activeChannelId, isNull);
      expect(controller.state.serverMessages, isEmpty);
      expect(controller.state.activeChannelMembers, isEmpty);
    },
  );

  test(
    'server member remove prunes settings, active members, and typing rows',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          members: const [
            ServerSettingsListItemSeed(
              title: 'boji',
              subtitle: 'Online',
              userId: '42',
              trailing: 'Owner',
            ),
            ServerSettingsListItemSeed(
              title: 'Avery',
              subtitle: 'Online',
              userId: '333',
              trailing: 'Member',
            ),
          ],
        ),
        activeChannelMembers: const [
          MemberSeed(
            id: 'official/333',
            name: 'Avery',
            status: 'Online',
            initials: 'AV',
            role: 'Member',
          ),
        ],
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
      );
      addTearDown(controller.dispose);

      await controller.load();
      directMessagesRepository.emit(
        const DirectMessagesTypingStartEvent(
          channelId: 'official/321',
          localUserId: '333',
        ),
      );
      await pumpEventQueue();
      expect(controller.state.activeTypingMembers, isNotEmpty);

      directMessagesRepository.emit(
        const DirectMessagesServerMemberRemoveEvent(
          serverId: 'official/123',
          userId: 'official/333',
        ),
      );
      await pumpEventQueue();

      expect(
        controller.state.settings?.members.map((member) => member.userId),
        isNot(contains('333')),
      );
      expect(
        controller.state.activeChannelMembers.map((member) => member.id),
        isNot(contains('official/333')),
      );
      expect(
        controller.state.activeTypingMembers.map((member) => member.id),
        isNot(contains('official/333')),
      );
    },
  );

  test('current user member remove ejects the server from the rail', () async {
    final serverRepository = _FakeServerSettingsRepository(
      data: _settings(
        _server(id: '123', name: 'Actual Verdant'),
        members: const [
          ServerSettingsListItemSeed(
            title: 'boji',
            subtitle: 'Online',
            userId: '42',
            trailing: 'Owner',
          ),
        ],
      ),
    );
    final directMessagesRepository = _FakeDirectMessagesRepository();
    final controller = WorkspaceController(
      session: _session,
      repository: serverRepository,
      directMessagesRepository: directMessagesRepository,
    );
    addTearDown(controller.dispose);

    await controller.load();

    directMessagesRepository.emit(
      const DirectMessagesServerMemberRemoveEvent(
        serverId: 'official/123',
        userId: 'official/42',
      ),
    );
    await pumpEventQueue();

    expect(controller.state.servers.map((server) => server.id), isEmpty);
    expect(controller.state.activeServer, isNull);
    expect(controller.state.settings, isNull);
    expect(controller.state.activeChannelId, isNull);
    expect(controller.state.serverMessages, isEmpty);
    expect(controller.state.activeChannelMembers, isEmpty);
  });

  test(
    'realtime access error reconciles and removes stale rail server',
    () async {
      final repository = _MembershipLostServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Removed Verdant'),
          channels: const [
            ServerSettingsChannelSeed(id: '321', name: 'general'),
          ],
        ),
        fallbackData: _settings(
          _server(id: '999', name: 'Fallback Verdant'),
          channels: const [ServerSettingsChannelSeed(id: '777', name: 'home')],
        ),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final diagnostics = _RecordingDiagnostics();
      final controller = WorkspaceController(
        session: _session,
        repository: repository,
        directMessagesRepository: directMessagesRepository,
        diagnostics: diagnostics,
      );
      addTearDown(controller.dispose);

      await controller.load();
      repository.membershipLost = true;

      directMessagesRepository.emitError(
        const DirectMessagesException('Channel not found'),
      );
      await pumpEventQueue(times: 20);

      expect(
        diagnostics.payloadsFor('workspace.server.membership_reconcile.result'),
        contains(containsPair('status', 'removed')),
      );
      expect(
        diagnostics.payloadsFor('workspace.server.remove.apply'),
        contains(containsPair('remainingServerCount', 1)),
      );
      expect(controller.state.servers.map((server) => server.id), ['999']);
      expect(controller.state.activeServer?.id, '999');
      expect(controller.state.settings?.server.id, '999');
      expect(controller.state.activeChannelId, '777');
      expect(controller.state.error, isNull);
    },
  );

  test(
    'realtime role updates apply name color without adding it to access-role label',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(
          _server(id: '123', name: 'Actual Verdant'),
          roles: const [
            ServerSettingsListItemSeed(
              id: 'member',
              title: 'Member',
              subtitle: 'Access role',
              accent: Color(0xff2196f3),
              colorOnly: false,
            ),
            ServerSettingsListItemSeed(
              id: 'mint',
              title: 'Mint',
              subtitle: 'Name Color',
              accent: Color(0xff22c55e),
              colorOnly: true,
            ),
          ],
        ),
        activeChannelMembers: const [
          MemberSeed(
            id: 'official/181',
            name: 'Avery',
            status: 'Online',
            initials: 'AV',
          ),
        ],
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      directMessagesRepository.emit(
        const DirectMessagesServerMemberRoleUpdateEvent(
          userId: 'official/181',
          roleIds: ['member', 'mint'],
        ),
      );
      await pumpEventQueue();

      final member = controller.state.activeChannelMembers.single;
      expect(member.role, 'Member');
      expect(member.nameColorName, 'Mint');
      expect(member.displayColor, const Color(0xff22c55e));
    },
  );

  test(
    'does not merge channel activity into a different scoped member by name',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
        activeChannelMembers: const [
          MemberSeed(
            id: 'official/181',
            name: 'Alex',
            status: 'Offline',
            initials: 'AL',
            avatarUrl: 'https://media.verdant.chat/avatars/original.webp',
            isActive: false,
          ),
        ],
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      directMessagesRepository.emit(
        const DirectMessagesChannelActivityEvent(
          channelId: 'official/321',
          localUserId: '333',
          displayName: 'Alex',
          avatarUrl: 'https://media.verdant.chat/avatars/attacker.webp',
        ),
      );
      await pumpEventQueue();

      final original = controller.state.activeChannelMembers.firstWhere(
        (member) => member.id == 'official/181',
      );
      final incoming = controller.state.activeChannelMembers.firstWhere(
        (member) =>
            member.id == '${networkIdFromApiOrigin(officialApiOrigin)}/333',
      );

      expect(original.avatarUrl, contains('/avatars/original.webp'));
      expect(original.isActive, isFalse);
      expect(incoming.name, 'Alex');
      expect(incoming.avatarUrl, contains('/avatars/attacker.webp'));
      expect(incoming.isActive, isTrue);
    },
  );

  test('applies live DM channel and relationship hydration updates', () async {
    final serverRepository = _FakeServerSettingsRepository(
      data: _settings(_server(id: '123', name: 'Actual Verdant')),
    );
    final directMessagesRepository = _FakeDirectMessagesRepository();
    final controller = WorkspaceController(
      session: _session,
      repository: serverRepository,
      directMessagesRepository: directMessagesRepository,
      directMessagesPreferences: DirectMessagesPreferences.memory(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    directMessagesRepository.emit(
      const DirectMessagesRelationshipUpsertEvent(
        FriendPreviewSeed(
          id: 'official/182',
          localUserId: '182',
          networkId: 'official',
          displayName: 'Blake',
          initials: 'BL',
          status: 'Online',
          detail: 'Friend',
          kind: FriendRelationshipKind.friend,
        ),
      ),
    );
    directMessagesRepository.emit(
      const DirectMessagesConversationUpsertEvent(
        DmConversationPreviewSeed(
          channelId: 'official/dm-182',
          localChannelId: 'dm-182',
          networkId: 'official',
          displayName: 'Blake',
          initials: 'BL',
          status: 'Online',
          lastMessage: 'No messages yet',
          localUserId: '182',
        ),
      ),
    );
    directMessagesRepository.emit(
      const DirectMessagesRelationshipRemoveEvent(
        localUserId: '181051381515448321',
      ),
    );
    directMessagesRepository.emit(
      const DirectMessagesChannelUnreadEvent(
        channelId: 'official/dm-182',
        messageId: 'official/dm-message-1',
        localAuthorId: '182',
        mentionsCurrentUser: false,
        isDirectMessage: true,
      ),
    );
    await pumpEventQueue();

    expect(
      controller.state.directMessages?.friends.map(
        (friend) => friend.displayName,
      ),
      contains('Blake'),
    );
    expect(
      controller.state.directMessages?.friends.where(
        (friend) => friend.localUserId == '181051381515448321',
      ),
      isEmpty,
    );
    final conversation = controller.state.directMessages!.conversations
        .firstWhere(
          (conversation) =>
              conversation.channelId == '${_session.networkId}/dm-182',
        );
    expect(conversation.unreadCount, 1);
  });

  test(
    'ignores malformed direct message realtime ids before state mutation',
    () async {
      final serverRepository = _FakeServerSettingsRepository(
        data: _settings(_server(id: '123', name: 'Actual Verdant')),
      );
      final directMessagesRepository = _FakeDirectMessagesRepository();
      final controller = WorkspaceController(
        session: _session,
        repository: serverRepository,
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: DirectMessagesPreferences.memory(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.closeDirectMessageConversation(
        directMessagesRepository.data.conversations.single,
      );

      directMessagesRepository.emit(
        const DirectMessagesMessageCreateEvent(
          channelId: 'official/dm/poison',
          message: MessageSeed(
            id: 'official/message/poison',
            authorId: 'official/181051381515448321',
            author: 'Avery',
            body: 'malformed ids must not enter state',
            initials: 'AV',
            time: '2026-06-02 12:30',
            reactions: [],
          ),
        ),
      );
      directMessagesRepository.emit(
        const DirectMessagesPresenceUpdateEvent(
          localUserId: '181051381515448321/poison',
          status: 'online',
        ),
      );
      await pumpEventQueue();

      expect(controller.state.directMessages?.conversations, isEmpty);
      expect(directMessagesRepository.savedHiddenChannelIds.last, {
        '${_session.networkId}/dm-avery',
      });
    },
  );

  test('maps direct messages and relationships from protobuf READY', () {
    final data = directMessagesDataFromReady(
      verdant_ws.Ready(
        relationships: [
          verdant_models.Relationship(
            userId: '181051381515448321',
            type: verdant_models
                .RelationshipType
                .RELATIONSHIP_TYPE_PENDING_INCOMING,
            user: verdant_models.RelationshipUser(
              id: '181051381515448321',
              username: 'Morgan',
              avatarUrl: 'https://media.verdant.chat/avatars/morgan.webp',
              status: 'idle',
            ),
          ),
        ],
        dmChannels: [
          verdant_models.DmChannel(
            id: 'dm-morgan',
            type: verdant_models.ChannelType.CHANNEL_TYPE_DM,
            lastMessageAt: '2026-06-02T13:14:15Z',
            participants: [
              verdant_models.DmParticipant(
                id: '42',
                username: 'boji',
                status: 'online',
              ),
              verdant_models.DmParticipant(
                id: '181051381515448321',
                username: 'Morgan',
                displayName: 'Morgan Display',
                status: 'idle',
              ),
            ],
          ),
        ],
      ),
      networkId: 'official',
      currentUserId: '42',
      currentUserName: 'boji',
      currentUserInitials: 'BO',
    );

    expect(data.friends, hasLength(1));
    expect(data.friends.single.id, 'official/181051381515448321');
    expect(data.friends.single.displayName, 'Morgan');
    expect(data.friends.single.kind, FriendRelationshipKind.pendingIncoming);
    expect(data.friends.single.status, 'Pending');
    expect(data.friends.single.avatarUrl, contains('/avatars/morgan.webp'));
    expect(data.conversations, hasLength(1));
    expect(data.conversations.single.channelId, 'official/dm-morgan');
    expect(data.conversations.single.displayName, 'Morgan Display');
    expect(data.conversations.single.status, 'Idle');
    expect(data.conversations.single.lastMessage, 'Last active 2026/06/02');
  });

  test('drops malformed direct message READY ids before projection', () {
    final data = directMessagesDataFromReadyJson(
      {
        'relationships': [
          {
            'userId': '181051381515448321',
            'type': 1,
            'user': {'id': '181051381515448321', 'username': 'Avery'},
          },
          {
            'userId': '181051381515448321/poison',
            'type': 1,
            'user': {'id': '181051381515448321/poison', 'username': 'Bad'},
          },
        ],
        'dmChannels': [
          {
            'id': 'dm-avery',
            'participants': [
              {'id': '42', 'username': 'boji'},
              {'id': '181051381515448321', 'username': 'Avery'},
            ],
          },
          {
            'id': 'dm/poison',
            'participants': [
              {'id': '42', 'username': 'boji'},
              {'id': '181051381515448321/poison', 'username': 'Bad'},
            ],
          },
        ],
      },
      networkId: 'official',
      currentUserId: '42',
      currentUserName: 'boji',
      currentUserInitials: 'BO',
    );

    expect(data.friends.map((friend) => friend.id), [
      'official/181051381515448321',
    ]);
    expect(data.conversations.map((conversation) => conversation.channelId), [
      'official/dm-avery',
    ]);
  });

  test(
    'hidden direct message preferences persist only matching scoped ids',
    () async {
      final storage = MemoryDirectMessagesPreferenceStorage();
      final preferences = DirectMessagesPreferences(storage: storage);

      await preferences.saveHiddenChannelIds(
        networkId: 'official',
        userId: '42',
        channelIds: {
          'official/dm-avery',
          'official/dm/poison',
          'other/dm-avery',
          'raw-dm',
        },
      );

      expect(
        await preferences.loadHiddenChannelIds(
          networkId: 'official',
          userId: '42',
        ),
        {'official/dm-avery'},
      );
      expect(storage.debugValues.values.single, isNot(contains('poison')));
      expect(
        storage.debugValues.values.single,
        isNot(contains('other/dm-avery')),
      );
    },
  );
}

final _session = AuthSession.authenticated(
  apiOrigin: 'https://api.verdant.chat',
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

final class _FakeDirectMessagesRepository
    implements
        DirectMessagesRepository,
        WorkspaceRealtimeCommandSink,
        WorkspaceMessageMutationRepository {
  var data = const DirectMessagesWorkspaceData(
    networkId: 'official',
    currentUserName: 'boji',
    currentUserInitials: 'BO',
    conversations: [
      DmConversationPreviewSeed(
        channelId: 'official/dm-avery',
        localChannelId: 'dm-avery',
        networkId: 'official',
        displayName: 'Avery',
        initials: 'AV',
        status: 'Online',
        lastMessage: 'Last active 2026-06-02',
        localUserId: '181051381515448321',
      ),
    ],
    friends: [
      FriendPreviewSeed(
        id: 'official/181051381515448321',
        localUserId: '181051381515448321',
        networkId: 'official',
        displayName: 'Avery',
        initials: 'AV',
        status: 'Online',
        detail: 'Friend',
        kind: FriendRelationshipKind.friend,
      ),
    ],
  );
  var loadCount = 0;
  final loadedConversationChannelIds = <String>[];
  final loadedConversationBeforeIds = <String?>[];
  var _realtime = StreamController<DirectMessagesRealtimeEvent>.broadcast();
  final loadedCurrentUserIds = <String>[];
  final sentMessageChannelIds = <String>[];
  final sentMessageContents = <String>[];
  final sentTypingChannelIds = <String>[];
  final updatedPresenceStatuses = <String>[];
  final connectedStatuses = <String>[];
  final addedReactionMessageIds = <String>[];
  final removedReactionMessageIds = <String>[];
  final focusedServerIds = <String>[];
  final focusedChannelIds = <String?>[];
  final deletedMessageChannelIds = <String>[];
  final deletedMessageIds = <String>[];
  final requestedHiddenChannelIds = <Set<String>>[];
  final savedHiddenChannelIds = <Set<String>>[];
  Set<String> hiddenChannelIds = const {};
  var loadHiddenCount = 0;
  Completer<DirectMessagesWorkspaceData>? loadDirectMessagesCompleter;
  Completer<Set<String>>? loadHiddenChannelIdsCompleter;
  Object? loadHiddenChannelIdsFailure;
  Object? saveHiddenChannelIdsFailure;
  Duration Function(Set<String> channelIds)? saveHiddenChannelIdsDelay;
  var connectCount = 0;
  var failNextLoad = false;
  var initialConversationMessageCount = 2;
  List<List<MessageSeed>>? conversationMessageBatches;
  var sendFailuresRemaining = 0;
  var sendNotReadyFailuresRemaining = 0;
  var sendReconnectingFailuresRemaining = 0;
  DirectMessagesException? sendChannelMessageFailure;
  var presenceReconnectingFailuresRemaining = 0;
  var reactionFailuresRemaining = 0;
  var _requiresFreshConnectForSend = false;

  void emit(DirectMessagesRealtimeEvent event) {
    _realtime.add(event);
  }

  void emitError(Object error) {
    _realtime.addError(error);
  }

  Future<void> closeRealtime() async {
    final previous = _realtime;
    _realtime = StreamController<DirectMessagesRealtimeEvent>.broadcast();
    await previous.close();
  }

  @override
  Future<DirectMessagesWorkspaceData> loadDirectMessages({
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
  }) async {
    loadCount += 1;
    loadedCurrentUserIds.add(currentUserId);
    if (failNextLoad) {
      failNextLoad = false;
      throw const DirectMessagesException('DM snapshot failed');
    }
    final pending = loadDirectMessagesCompleter;
    if (pending != null) {
      loadDirectMessagesCompleter = null;
      final pendingData = await pending.future;
      return pendingData.copyWith(
        currentUserName: currentUserName,
        currentUserInitials: currentUserInitials,
      );
    }
    return data.copyWith(
      currentUserName: currentUserName,
      currentUserInitials: currentUserInitials,
    );
  }

  @override
  Future<Set<String>> loadHiddenChannelIds() async {
    loadHiddenCount += 1;
    final pending = loadHiddenChannelIdsCompleter;
    if (pending != null) {
      return Set<String>.of(await pending.future);
    }
    final failure = loadHiddenChannelIdsFailure;
    if (failure is Exception) {
      throw failure;
    }
    if (failure is Error) {
      throw failure;
    }
    return Set<String>.of(hiddenChannelIds);
  }

  @override
  Future<void> saveHiddenChannelIds({required Set<String> channelIds}) async {
    final requested = Set<String>.of(channelIds);
    requestedHiddenChannelIds.add(requested);
    final failure = saveHiddenChannelIdsFailure;
    if (failure is Exception) {
      throw failure;
    }
    if (failure is Error) {
      throw failure;
    }
    final delay = saveHiddenChannelIdsDelay?.call(requested);
    if (delay != null && delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    hiddenChannelIds = Set<String>.of(requested);
    savedHiddenChannelIds.add(Set<String>.of(requested));
  }

  @override
  Future<void> sendFriendRequest({required String username}) async {}

  @override
  Future<void> acceptFriendRequest({required String localUserId}) async {}

  @override
  Future<void> removeRelationship({required String localUserId}) async {}

  @override
  Future<DmConversationPreviewSeed> openDirectMessage({
    required String localUserId,
    required String currentUserId,
  }) async {
    return data.conversations.first;
  }

  @override
  Future<DmConversationMessages> loadConversationMessages({
    required DmConversationPreviewSeed conversation,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    loadedConversationChannelIds.add(conversation.channelId);
    loadedConversationBeforeIds.add(beforeMessageId);
    if (beforeMessageId != null) {
      return DmConversationMessages(
        channelId: conversation.channelId,
        messages: [
          MessageSeed(
            id: '${conversation.networkId}/dm-older-message-1',
            authorId: '${conversation.networkId}/181051381515448321',
            author: conversation.displayName,
            body: 'Oldest hello from ${conversation.displayName}',
            initials: conversation.initials,
            time: '10:10 AM',
            isOwnMessage: false,
            reactions: const [],
          ),
        ],
      );
    }
    final batches = conversationMessageBatches;
    if (batches != null &&
        loadedConversationChannelIds.length <= batches.length) {
      return DmConversationMessages(
        channelId: conversation.channelId,
        messages: batches[loadedConversationChannelIds.length - 1],
      );
    }
    return DmConversationMessages(
      channelId: conversation.channelId,
      messages: [
        for (var index = 0; index < initialConversationMessageCount; index += 1)
          MessageSeed(
            id: '${conversation.networkId}/dm-message-$index',
            authorId: '${conversation.networkId}/181051381515448321',
            author: conversation.displayName,
            body: switch (index) {
              0 => 'Older hello from ${conversation.displayName}',
              1 => 'Hello from ${conversation.displayName}',
              _ => 'Historical DM $index from ${conversation.displayName}',
            },
            initials: conversation.initials,
            time: '10:${20 + index} AM',
            isOwnMessage: false,
            reactions: const [],
          ),
      ],
    );
  }

  @override
  Stream<DirectMessagesRealtimeEvent> connectRealtime({
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
    required String currentUserStatus,
  }) {
    connectCount += 1;
    connectedStatuses.add(currentUserStatus);
    _requiresFreshConnectForSend = false;
    return _realtime.stream;
  }

  @override
  Future<void> focusServer({required String serverId}) async {
    focusedServerIds.add(serverId);
  }

  @override
  Future<void> focusChannel({String? channelId}) async {
    focusedChannelIds.add(channelId);
  }

  @override
  Future<void> sendChannelMessage({
    required String channelId,
    required String content,
  }) async {
    if (sendNotReadyFailuresRemaining > 0) {
      sendNotReadyFailuresRemaining -= 1;
      _requiresFreshConnectForSend = true;
      throw const DirectMessagesException('Realtime session is not ready');
    }
    if (_requiresFreshConnectForSend) {
      throw const DirectMessagesException('stale realtime session reused');
    }
    if (sendReconnectingFailuresRemaining > 0) {
      sendReconnectingFailuresRemaining -= 1;
      await closeRealtime();
      throw const DirectMessagesException('Realtime is reconnecting');
    }
    if (sendFailuresRemaining > 0) {
      sendFailuresRemaining -= 1;
      await closeRealtime();
      throw const DirectMessagesException(
        'Realtime session closed before READY',
      );
    }
    final failure = sendChannelMessageFailure;
    if (failure != null) {
      throw failure;
    }
    sentMessageChannelIds.add(channelId);
    sentMessageContents.add(content);
  }

  @override
  Future<void> sendTypingStart({required String channelId}) async {
    sentTypingChannelIds.add(channelId);
  }

  @override
  Future<void> updatePresenceStatus({
    required String status,
    bool afk = false,
  }) async {
    updatedPresenceStatuses.add(status);
    if (presenceReconnectingFailuresRemaining > 0) {
      presenceReconnectingFailuresRemaining -= 1;
      await closeRealtime();
      throw const DirectMessagesException('Realtime is reconnecting');
    }
  }

  @override
  Future<void> addReaction({
    required String channelId,
    required String messageId,
    required String emoji,
    String? emojiId,
  }) async {
    if (reactionFailuresRemaining > 0) {
      reactionFailuresRemaining -= 1;
      await closeRealtime();
      throw const DirectMessagesException(
        'Realtime session closed before READY',
      );
    }
    addedReactionMessageIds.add(messageId);
  }

  @override
  Future<void> removeReaction({
    required String channelId,
    required String messageId,
    required String emoji,
  }) async {
    removedReactionMessageIds.add(messageId);
  }

  @override
  Future<void> deleteChannelMessage({
    required String channelId,
    required String messageId,
  }) async {
    deletedMessageChannelIds.add(channelId);
    deletedMessageIds.add(messageId);
  }
}

final class _FakeServerSettingsRepository
    implements
        ServerSettingsRepository,
        ServerSettingsCurrentUserMediaRepository,
        ServerSettingsChannelActivityRepository,
        ServerSettingsUserMediaRepository,
        WorkspaceMessageMutationRepository {
  _FakeServerSettingsRepository({
    required this.data,
    this.servers,
    this.currentUserMedia,
    this.activeChannelMembers = const [],
    this.channelActivityFuture,
    this.userMediaById = const {},
    this.throwUserMediaSecret = false,
    this.messages,
    this.messageBatches,
    this.messageFailuresBeforeSuccess = 0,
  });

  final ServerSettingsData data;
  final List<ServerSettingsServer>? servers;
  final ServerSettingsCurrentUserMedia? currentUserMedia;
  final List<MemberSeed> activeChannelMembers;
  final Future<List<MemberSeed>>? channelActivityFuture;
  final Map<String, ServerSettingsCurrentUserMedia> userMediaById;
  final bool throwUserMediaSecret;
  final List<MessageSeed>? messages;
  final List<List<MessageSeed>>? messageBatches;
  int messageFailuresBeforeSuccess;
  bool listServersCalled = false;
  String? loadedServerId;
  String? loadedActivityChannelId;
  final loadedActivityChannelIds = <String>[];
  final loadedUserMediaIds = <String>[];
  final loadedMessageChannelIds = <String>[];
  final loadedMessageCurrentUserIds = <String>[];
  final loadedMessageBeforeIds = <String?>[];
  final deletedMessageChannelIds = <String>[];
  final deletedMessageIds = <String>[];
  int currentUserMediaLoadCount = 0;
  int listServersCount = 0;
  ServerSettingsException? messageDeleteFailure;

  @override
  Future<List<ServerSettingsServer>> listServers() async {
    listServersCalled = true;
    listServersCount += 1;
    return servers ?? [data.server];
  }

  @override
  Future<ServerSettingsData> loadServerSettings(
    ServerSettingsServer server,
  ) async {
    loadedServerId = server.id;
    return data;
  }

  @override
  Future<ServerSettingsCurrentUserMedia?> loadCurrentUserMedia() async {
    currentUserMediaLoadCount += 1;
    return currentUserMedia;
  }

  @override
  Future<List<MemberSeed>> loadChannelActivity({
    required String channelId,
  }) async {
    loadedActivityChannelId = channelId;
    loadedActivityChannelIds.add(channelId);
    final pending = channelActivityFuture;
    if (pending != null) {
      return pending;
    }
    return activeChannelMembers;
  }

  @override
  Future<ServerSettingsCurrentUserMedia?> loadUserMedia({
    required String localUserId,
  }) async {
    loadedUserMediaIds.add(localUserId);
    if (throwUserMediaSecret) {
      throw const ServerSettingsException(
        'Bearer access-secret session-secret',
      );
    }
    return userMediaById[localUserId];
  }

  @override
  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    loadedMessageChannelIds.add(channelId);
    loadedMessageCurrentUserIds.add(currentUserId);
    loadedMessageBeforeIds.add(beforeMessageId);
    if (messageFailuresBeforeSuccess > 0) {
      messageFailuresBeforeSuccess -= 1;
      throw const ServerSettingsException('Message transport unavailable');
    }
    final batches = messageBatches;
    if (batches != null && loadedMessageChannelIds.length <= batches.length) {
      return batches[loadedMessageChannelIds.length - 1];
    }
    final customMessages = messages;
    if (customMessages != null) {
      return customMessages;
    }
    return [
      MessageSeed(
        id: '$channelId/message-1',
        authorId: currentUserId,
        author: 'boji',
        body: 'Server hello',
        initials: 'BO',
        time: '10:00 AM',
        isOwnMessage: true,
        reactions: const [],
      ),
    ];
  }

  @override
  Future<void> deleteChannelMessage({
    required String channelId,
    required String messageId,
  }) async {
    final failure = messageDeleteFailure;
    if (failure != null) {
      throw failure;
    }
    deletedMessageChannelIds.add(channelId);
    deletedMessageIds.add(messageId);
  }

  @override
  Future<ServerSettingsServer> createServer({required String name}) async {
    return data.server.copyWith(id: 'created-server', name: name);
  }

  @override
  Future<ServerSettingsListItemSeed> createInvite({
    required String serverId,
    int? maxUses,
    Duration? expiresIn,
  }) async {
    return const ServerSettingsListItemSeed(
      id: 'new-code',
      title: 'Invite new-code',
      subtitle: 'Created by boji',
      inviteCode: 'new-code',
    );
  }

  @override
  Future<void> revokeInvite({
    required String serverId,
    required String code,
  }) async {}

  @override
  Future<void> leaveServer({required String serverId}) async {}

  @override
  Future<ServerInvitePreview> previewInvite({required String code}) async {
    return ServerInvitePreview(
      code: code,
      server: data.server,
      inviterUsername: 'boji',
      isMember: false,
    );
  }

  @override
  Future<ServerSettingsServer> acceptInvite({required String code}) async {
    return data.server;
  }

  @override
  Future<ServerSettingsServer> updateServer({
    required String serverId,
    required ServerSettingsPatch patch,
  }) async {
    final payload = patch.toJson();
    return data.server.copyWith(
      name: payload['name'] as String? ?? data.server.name,
      welcomeChannelId: payload.containsKey('welcomeChannelId')
          ? payload['welcomeChannelId'] as String?
          : data.server.welcomeChannelId,
    );
  }

  @override
  Future<ServerSettingsServer> uploadServerIcon({
    required String serverId,
    required ServerSettingsUpload upload,
  }) async {
    return data.server.copyWith(iconUrl: 'https://media.test/icon.webp');
  }

  @override
  Future<ServerSettingsServer> deleteServerIcon({
    required String serverId,
  }) async {
    return data.server.copyWith(iconUrl: null);
  }

  @override
  Future<ServerSettingsServer> uploadServerBanner({
    required String serverId,
    required ServerSettingsUpload upload,
  }) async {
    return data.server.copyWith(
      bannerUrl: 'https://media.test/banner.webp',
      bannerCrop: null,
    );
  }

  @override
  Future<ServerSettingsServer> updateBannerCrop({
    required String serverId,
    required BannerCrop crop,
  }) async {
    return data.server.copyWith(bannerCrop: crop);
  }

  @override
  Future<ServerSettingsServer> deleteServerBanner({
    required String serverId,
  }) async {
    return data.server.copyWith(bannerUrl: null, bannerCrop: null);
  }
}

final class _MultiServerSettingsRepository
    implements
        ServerSettingsRepository,
        ServerSettingsChannelActivityRepository {
  _MultiServerSettingsRepository({
    required this.dataByServerId,
    this.activityByChannelId = const {},
  });

  final Map<String, ServerSettingsData> dataByServerId;
  final Map<String, Future<List<MemberSeed>>> activityByChannelId;
  final loadedServerIds = <String>[];
  final loadedMessageChannelIds = <String>[];

  @override
  Future<List<ServerSettingsServer>> listServers() async {
    return [for (final data in dataByServerId.values) data.server];
  }

  @override
  Future<ServerSettingsData> loadServerSettings(
    ServerSettingsServer server,
  ) async {
    loadedServerIds.add(server.id);
    return dataByServerId[server.id]!;
  }

  @override
  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    loadedMessageChannelIds.add(channelId);
    return [
      MessageSeed(
        id: '$channelId/message-1',
        authorId: currentUserId,
        author: 'boji',
        body: 'Message in $channelId',
        initials: 'BO',
        time: '10:00 AM',
        isOwnMessage: true,
        reactions: const [],
      ),
    ];
  }

  @override
  Future<List<MemberSeed>> loadChannelActivity({
    required String channelId,
  }) async {
    final pendingActivity = activityByChannelId[channelId];
    if (pendingActivity != null) {
      return pendingActivity;
    }
    return const [];
  }

  @override
  Future<ServerSettingsServer> createServer({required String name}) async {
    return dataByServerId.values.first.server.copyWith(
      id: 'created-server',
      name: name,
    );
  }

  @override
  Future<ServerSettingsListItemSeed> createInvite({
    required String serverId,
    int? maxUses,
    Duration? expiresIn,
  }) async {
    return const ServerSettingsListItemSeed(
      id: 'new-code',
      title: 'Invite new-code',
      subtitle: 'Created by boji',
      inviteCode: 'new-code',
    );
  }

  @override
  Future<void> revokeInvite({
    required String serverId,
    required String code,
  }) async {}

  @override
  Future<void> leaveServer({required String serverId}) async {}

  @override
  Future<ServerInvitePreview> previewInvite({required String code}) async {
    return ServerInvitePreview(
      code: code,
      server: dataByServerId.values.first.server,
      inviterUsername: 'boji',
      isMember: false,
    );
  }

  @override
  Future<ServerSettingsServer> acceptInvite({required String code}) async {
    return dataByServerId.values.first.server;
  }

  @override
  Future<ServerSettingsServer> updateServer({
    required String serverId,
    required ServerSettingsPatch patch,
  }) async {
    return dataByServerId[serverId]!.server;
  }

  @override
  Future<ServerSettingsServer> uploadServerIcon({
    required String serverId,
    required ServerSettingsUpload upload,
  }) async {
    return dataByServerId[serverId]!.server;
  }

  @override
  Future<ServerSettingsServer> deleteServerIcon({
    required String serverId,
  }) async {
    return dataByServerId[serverId]!.server.copyWith(iconUrl: null);
  }

  @override
  Future<ServerSettingsServer> uploadServerBanner({
    required String serverId,
    required ServerSettingsUpload upload,
  }) async {
    return dataByServerId[serverId]!.server;
  }

  @override
  Future<ServerSettingsServer> updateBannerCrop({
    required String serverId,
    required BannerCrop crop,
  }) async {
    return dataByServerId[serverId]!.server.copyWith(bannerCrop: crop);
  }

  @override
  Future<ServerSettingsServer> deleteServerBanner({
    required String serverId,
  }) async {
    return dataByServerId[serverId]!.server.copyWith(bannerUrl: null);
  }
}

final class _BatchMultiServerSettingsRepository
    extends _MultiServerSettingsRepository
    implements ServerWorkspaceBootstrapRepository {
  _BatchMultiServerSettingsRepository({required super.dataByServerId});

  final loadedWorkspaceServerIds = <String>[];

  @override
  Future<ServerWorkspaceBootstrap?> loadServerWorkspaceBootstrap(
    ServerSettingsServer server, {
    required String currentUserId,
    int messageLimit = 50,
  }) async {
    loadedWorkspaceServerIds.add(server.id);
    final data = dataByServerId[server.id]!;
    final activeChannelId = data.channels.first.id;
    return ServerWorkspaceBootstrap(
      settings: data,
      currentUserMedia: null,
      activeChannelId: activeChannelId,
      messages: [
        MessageSeed(
          id: '$activeChannelId/batch-message-1',
          authorId: currentUserId,
          author: 'boji',
          body: 'Batch message in $activeChannelId',
          initials: 'BO',
          time: '10:00 AM',
          isOwnMessage: true,
          reactions: const [],
        ),
      ],
      activity: (available: true, members: const []),
    );
  }
}

final class _ServerAccessDeniedOnSelectRepository
    extends _MultiServerSettingsRepository {
  _ServerAccessDeniedOnSelectRepository({
    required this.deniedServerId,
    required super.dataByServerId,
  });

  final String deniedServerId;

  @override
  Future<ServerSettingsData> loadServerSettings(
    ServerSettingsServer server,
  ) async {
    loadedServerIds.add(server.id);
    if (server.id == deniedServerId) {
      throw const ServerSettingsException(
        'You do not have permission for this server',
      );
    }
    return dataByServerId[server.id]!;
  }
}

final class _SlowServerSwitchRepository extends _MultiServerSettingsRepository {
  _SlowServerSwitchRepository({required super.dataByServerId});

  final _pendingLoads = <String, Completer<ServerSettingsData>>{};

  @override
  Future<ServerSettingsData> loadServerSettings(
    ServerSettingsServer server,
  ) async {
    loadedServerIds.add(server.id);
    if (loadedServerIds.length == 1) {
      return dataByServerId[server.id]!;
    }
    final completer = Completer<ServerSettingsData>();
    _pendingLoads[server.id] = completer;
    return completer.future;
  }

  void completeServerLoad(String serverId) {
    _pendingLoads.remove(serverId)?.complete(dataByServerId[serverId]!);
  }
}

final class _QuietServerSwitchRepository
    extends _MultiServerSettingsRepository {
  _QuietServerSwitchRepository({
    required this.quietChannelId,
    required super.dataByServerId,
  });

  final String quietChannelId;

  @override
  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    if (channelId == quietChannelId) {
      loadedMessageChannelIds.add(channelId);
      return const [];
    }
    return super.loadChannelMessages(
      channelId: channelId,
      currentUserId: currentUserId,
      limit: limit,
      beforeMessageId: beforeMessageId,
    );
  }
}

final class _FailingMessageServerSettingsRepository
    extends _FakeServerSettingsRepository {
  _FailingMessageServerSettingsRepository({required super.data});

  var _initialLoad = true;

  @override
  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    if (_initialLoad) {
      _initialLoad = false;
      return super.loadChannelMessages(
        channelId: channelId,
        currentUserId: currentUserId,
        limit: limit,
        beforeMessageId: beforeMessageId,
      );
    }
    throw const ServerSettingsException(
      'Message index timed out; sign in state unknown.',
    );
  }
}

final class _AuthExpiredMessageServerSettingsRepository
    extends _FakeServerSettingsRepository {
  _AuthExpiredMessageServerSettingsRepository({required super.data});

  var _initialLoad = true;

  @override
  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    if (_initialLoad) {
      _initialLoad = false;
      return super.loadChannelMessages(
        channelId: channelId,
        currentUserId: currentUserId,
        limit: limit,
        beforeMessageId: beforeMessageId,
      );
    }
    throw const ServerSettingsException(
      'Sign in again to continue',
      isAuthExpired: true,
    );
  }
}

final class _MembershipLostServerSettingsRepository
    extends _FakeServerSettingsRepository {
  _MembershipLostServerSettingsRepository({
    required super.data,
    this.fallbackData,
    this.messageLoadError =
        "That channel doesn't exist or you don't have access",
  });

  final ServerSettingsData? fallbackData;
  final String messageLoadError;

  var _initialLoad = true;
  var membershipLost = false;

  @override
  Future<List<ServerSettingsServer>> listServers() async {
    listServersCalled = true;
    listServersCount += 1;
    final fallbackServer = fallbackData?.server;
    if (membershipLost) {
      return [?fallbackServer];
    }
    return [data.server, ?fallbackServer];
  }

  @override
  Future<ServerSettingsData> loadServerSettings(
    ServerSettingsServer server,
  ) async {
    loadedServerId = server.id;
    final fallback = fallbackData;
    if (fallback != null && server.id == fallback.server.id) {
      return fallback;
    }
    return data;
  }

  @override
  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    final fallback = fallbackData;
    if (fallback != null &&
        fallback.channels.any((channel) => channel.id == channelId)) {
      return const [
        MessageSeed(
          id: 'fallback-message',
          authorId: '42',
          author: 'boji',
          body: 'Fallback server message',
          initials: 'BJ',
          time: '12:00 PM',
          isOwnMessage: true,
          reactions: [],
        ),
      ];
    }
    if (_initialLoad) {
      _initialLoad = false;
      return super.loadChannelMessages(
        channelId: channelId,
        currentUserId: currentUserId,
        limit: limit,
        beforeMessageId: beforeMessageId,
      );
    }
    membershipLost = true;
    throw ServerSettingsException(messageLoadError);
  }
}

final class _LoadAccessDeniedOnRefreshRepository
    extends _FakeServerSettingsRepository {
  _LoadAccessDeniedOnRefreshRepository({required super.data});

  var _settingsLoadCount = 0;

  @override
  Future<List<ServerSettingsServer>> listServers() async {
    listServersCalled = true;
    listServersCount += 1;
    if (_settingsLoadCount >= 2) {
      return const [];
    }
    return [data.server];
  }

  @override
  Future<ServerSettingsData> loadServerSettings(
    ServerSettingsServer server,
  ) async {
    loadedServerId = server.id;
    _settingsLoadCount += 1;
    if (_settingsLoadCount >= 2) {
      throw const ServerSettingsException('Server was not found');
    }
    return data;
  }
}

final class _SlowChannelServerSettingsRepository
    extends _FakeServerSettingsRepository {
  _SlowChannelServerSettingsRepository({required super.data});

  var _messageLoadCount = 0;
  var _activityLoadCount = 0;
  Completer<List<MessageSeed>>? _messagesCompleter;
  Completer<List<MemberSeed>>? _activityCompleter;

  int get messageLoadCount => _messageLoadCount;
  int get activityLoadCount => _activityLoadCount;

  @override
  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) {
    _messageLoadCount += 1;
    if (_messageLoadCount == 1) {
      return super.loadChannelMessages(
        channelId: channelId,
        currentUserId: currentUserId,
        limit: limit,
        beforeMessageId: beforeMessageId,
      );
    }
    _messagesCompleter = Completer<List<MessageSeed>>();
    return _messagesCompleter!.future;
  }

  @override
  Future<List<MemberSeed>> loadChannelActivity({required String channelId}) {
    _activityLoadCount += 1;
    if (_activityLoadCount == 1) {
      return super.loadChannelActivity(channelId: channelId);
    }
    _activityCompleter = Completer<List<MemberSeed>>();
    return _activityCompleter!.future;
  }

  void completeMessages(List<MessageSeed> messages) {
    _messagesCompleter?.complete(messages);
  }

  void completeActivity(List<MemberSeed> members) {
    _activityCompleter?.complete(members);
  }
}

final class _SlowActivityServerSettingsRepository
    extends _FakeServerSettingsRepository {
  _SlowActivityServerSettingsRepository({required super.data});

  var _activityLoadCount = 0;
  Completer<List<MemberSeed>>? _activityCompleter;

  int get activityLoadCount => _activityLoadCount;

  @override
  Future<List<MemberSeed>> loadChannelActivity({required String channelId}) {
    _activityLoadCount += 1;
    if (_activityLoadCount == 1) {
      return super.loadChannelActivity(channelId: channelId);
    }
    _activityCompleter = Completer<List<MemberSeed>>();
    return _activityCompleter!.future;
  }

  void completeActivity(List<MemberSeed> members) {
    _activityCompleter?.complete(members);
  }
}

ServerSettingsData _settings(
  ServerSettingsServer server, {
  List<ServerSettingsChannelSeed> channels = const [
    ServerSettingsChannelSeed(id: '321', name: 'general'),
  ],
  List<ServerSettingsListItemSeed> roles = const [],
  List<ServerSettingsListItemSeed> members = const [],
  List<ServerSettingsListItemSeed> emojis = const [],
  List<ServerSettingsListItemSeed> stickers = const [],
  List<ServerSettingsListItemSeed> bots = const [],
}) {
  return ServerSettingsData(
    networkId: 'official',
    server: server,
    channels: channels,
    emojis: emojis,
    stickers: stickers,
    invites: const [],
    roles: roles,
    members: members,
    auditEvents: const [],
    feeds: const [],
    bots: bots,
  );
}

ServerSettingsServer _server({required String id, required String name}) {
  return ServerSettingsServer(
    id: id,
    name: name,
    ownerId: '42',
    iconUrl: null,
    description: 'Server $id',
    voiceBitrate: 64000,
    welcomeChannelId: '321',
    announceChannelId: null,
    bannerUrl: null,
    bannerCrop: null,
    accentColor: '#13eab3',
    bannerOffsetY: 50,
    memberCount: 2,
    large: false,
    createdAt: '2026-06-01T10:00:00Z',
    updatedAt: '2026-06-01T10:00:00Z',
  );
}

final class _RecordingDiagnostics implements AuthDiagnostics {
  final events = <String>[];
  final rendered = <String>[];
  final payloads = <String, List<Map<String, Object?>>>{};

  @override
  void record(String event, Map<String, Object?> fields) {
    events.add(event);
    rendered.add('$event $fields');
    payloads.putIfAbsent(event, () => <Map<String, Object?>>[]).add(fields);
  }

  List<Map<String, Object?>> payloadsFor(String event) {
    return payloads[event] ?? const <Map<String, Object?>>[];
  }
}
