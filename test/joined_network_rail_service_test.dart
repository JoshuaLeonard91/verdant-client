import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_credentials.dart';
import 'package:verdant_flutter/features/auth/auth_diagnostics.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/auth/network_profile_store.dart';
import 'package:verdant_flutter/features/workspace/bottom_rail_workspace/bottom_rail_models.dart';
import 'package:verdant_flutter/features/workspace/bottom_rail_workspace/joined_network_rail_service.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/federated_membership_service.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';
import 'package:verdant_flutter/features/workspace/workspace_local_id.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';

void main() {
  test(
    'builds one joined-network rail snapshot without official/self-host branches',
    () async {
      const activeOrigin = 'https://api.verdant.chat';
      const communityOrigin = 'https://api.community.example';
      final activeSession = AuthSession.authenticated(
        apiOrigin: activeOrigin,
        user: _user,
      );
      final communityProfile = NetworkProfile(
        name: 'Community',
        apiOrigin: communityOrigin,
      );
      final credentialStore = _MemoryCredentialStore({
        communityOrigin: const AuthCredentialBundle(
          apiOrigin: communityOrigin,
          accessToken: 'community-access-not-rendered',
          sessionToken: 'community-session-not-rendered',
        ),
      });
      final requestedOrigins = <String>[];
      final service = JoinedNetworkRailService(
        credentialStore: credentialStore,
        repositoryFactory: (apiOrigin) {
          requestedOrigins.add(apiOrigin);
          return _FakeServerSettingsRepository(
            server: _server('community-server', 'Community Grove'),
          );
        },
      );

      final snapshot = await service.load(
        activeSession: activeSession,
        savedProfiles: [NetworkProfile.official(), communityProfile],
        activeServers: [_server('official-server', 'Verdant')],
        activeMediaPolicy: _officialMediaPolicy,
        instanceModesByApiOrigin: const {communityOrigin: 'federated'},
      );

      expect(credentialStore.readOrigins, [communityOrigin]);
      expect(requestedOrigins, [communityOrigin]);
      expect(snapshot.networkOrder, [
        networkIdFromApiOrigin(activeOrigin),
        networkIdFromApiOrigin(communityOrigin),
      ]);
      expect(snapshot.records.map((record) => record.networkName), [
        'Official',
        'Community',
      ]);
      expect(snapshot.records.map((record) => record.mode), [
        RailNetworkMode.official,
        RailNetworkMode.federated,
      ]);
      expect(snapshot.railServers.map((server) => server.scopedServerId), [
        '${networkIdFromApiOrigin(activeOrigin)}/official-server',
        '${networkIdFromApiOrigin(communityOrigin)}/community-server',
      ]);
    },
  );

  test('records rail hydration timing and scoped server order', () async {
    const activeOrigin = 'https://api.verdant.chat';
    const communityOrigin = 'https://api.community.example';
    final activeSession = AuthSession.authenticated(
      apiOrigin: activeOrigin,
      user: _user,
    );
    final communityProfile = NetworkProfile(
      name: 'Community',
      apiOrigin: communityOrigin,
    );
    final diagnostics = _RecordingAuthDiagnostics();
    final service = JoinedNetworkRailService(
      credentialStore: _MemoryCredentialStore({
        communityOrigin: const AuthCredentialBundle(
          apiOrigin: communityOrigin,
          accessToken: 'community-access-not-rendered',
          sessionToken: 'community-session-not-rendered',
        ),
      }),
      repositoryFactory: (_) => _FakeServerSettingsRepository(
        server: _server('community-server', 'Community Grove'),
      ),
      diagnostics: diagnostics,
    );

    await service.load(
      activeSession: activeSession,
      savedProfiles: [NetworkProfile.official(), communityProfile],
      activeServers: [_server('official-server', 'Verdant')],
      activeMediaPolicy: _officialMediaPolicy,
    );

    final hydrationResult = diagnostics
        .payloadsFor('workspace.rail.hydration.result')
        .single;
    expect(hydrationResult['ms'], isA<int>());
    expect(hydrationResult['networkOrder'], [
      networkIdFromApiOrigin(activeOrigin),
      networkIdFromApiOrigin(communityOrigin),
    ]);
    expect(hydrationResult['railServerOrder'], [
      '${networkIdFromApiOrigin(activeOrigin)}/official-server',
      '${networkIdFromApiOrigin(communityOrigin)}/community-server',
    ]);
    final serverResult = diagnostics
        .payloadsFor('workspace.rail.hydration.servers.result')
        .single;
    expect(serverResult['ms'], isA<int>());
    expect(serverResult['visibleServerOrder'], [
      '${networkIdFromApiOrigin(communityOrigin)}/community-server',
    ]);
  });

  test('preserves cached scoped server order during live refresh', () async {
    const activeOrigin = 'https://api.verdant.chat';
    const communityOrigin = 'https://api.community.example';
    final communityProfile = NetworkProfile(
      name: 'Community',
      apiOrigin: communityOrigin,
    );
    final communityNetworkId = networkIdFromApiOrigin(communityOrigin);
    final mediaPolicy = ServerMediaPolicy.fromOrigins(
      apiOrigin: communityOrigin,
    );
    final cachedRailServers = [
      RailServerItem.fromServer(
        networkId: communityNetworkId,
        server: _server('community-b', 'Community B'),
        mediaPolicy: mediaPolicy,
      ),
      RailServerItem.fromServer(
        networkId: communityNetworkId,
        server: _server('community-a', 'Community A'),
        mediaPolicy: mediaPolicy,
      ),
    ];
    final service = JoinedNetworkRailService(
      credentialStore: _MemoryCredentialStore({
        communityOrigin: const AuthCredentialBundle(
          apiOrigin: communityOrigin,
          accessToken: 'community-access-not-rendered',
          sessionToken: 'community-session-not-rendered',
        ),
      }),
      repositoryFactory: (_) => _FakeServerSettingsRepository(
        server: _server('community-a', 'Community A'),
        servers: [
          _server('community-a', 'Community A'),
          _server('community-b', 'Community B'),
          _server('community-c', 'Community C'),
        ],
      ),
    );

    final snapshot = await service.load(
      activeSession: AuthSession.authenticated(
        apiOrigin: activeOrigin,
        user: _user,
      ),
      savedProfiles: [NetworkProfile.official(), communityProfile],
      activeServers: [_server('official-server', 'Verdant')],
      activeMediaPolicy: _officialMediaPolicy,
      cachedRailServers: cachedRailServers,
    );

    final communityServers = [
      for (final server in snapshot.railServers)
        if (sameWorkspaceNetworkId(server.networkId, communityNetworkId))
          server.localServerId,
    ];
    expect(communityServers, ['community-b', 'community-a', 'community-c']);
  });

  test(
    'keeps saved network order when the active session is self-host',
    () async {
      const selfHostOrigin = 'https://api.community.example';
      final activeSession = AuthSession.authenticated(
        apiOrigin: selfHostOrigin,
        user: _user,
      );
      final selfHostProfile = NetworkProfile(
        name: 'Community',
        apiOrigin: selfHostOrigin,
      );
      final credentialStore = _MemoryCredentialStore({
        officialApiOrigin: const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-not-rendered',
          sessionToken: 'official-session-not-rendered',
        ),
      });
      final service = JoinedNetworkRailService(
        credentialStore: credentialStore,
        repositoryFactory: (_) => _FakeServerSettingsRepository(
          server: _server('official-server', 'Verdant'),
        ),
      );

      final snapshot = await service.load(
        activeSession: activeSession,
        savedProfiles: [NetworkProfile.official(), selfHostProfile],
        activeServers: [_server('community-server', 'Community Grove')],
        activeMediaPolicy: ServerMediaPolicy.fromOrigins(
          apiOrigin: selfHostOrigin,
        ),
      );

      expect(snapshot.networkOrder, [
        networkIdFromApiOrigin(officialApiOrigin),
        networkIdFromApiOrigin(selfHostOrigin),
      ]);
      expect(snapshot.records.map((record) => record.networkName), [
        'Official',
        'Community',
      ]);
    },
  );

  test(
    'marks only an unavailable target network cached servers unavailable',
    () async {
      const activeOrigin = 'https://api.verdant.chat';
      const communityOrigin = 'https://api.community.example';
      final activeSession = AuthSession.authenticated(
        apiOrigin: activeOrigin,
        user: _user,
      );
      final communityProfile = NetworkProfile(
        name: 'Community',
        apiOrigin: communityOrigin,
      );
      final credentialStore = _MemoryCredentialStore({
        activeOrigin: const AuthCredentialBundle(
          apiOrigin: activeOrigin,
          accessToken: 'official-access-not-rendered',
          sessionToken: 'official-session-not-rendered',
        ),
        communityOrigin: const AuthCredentialBundle(
          apiOrigin: communityOrigin,
          accessToken: 'community-access-not-rendered',
          sessionToken: 'community-session-not-rendered',
        ),
      });
      final service = JoinedNetworkRailService(
        credentialStore: credentialStore,
        repositoryFactory: (_) => _FakeServerSettingsRepository(
          server: _server('community-server', 'Community Grove'),
        ),
      );

      final readySnapshot = await service.load(
        activeSession: activeSession,
        savedProfiles: [NetworkProfile.official(), communityProfile],
        activeServers: [_server('official-server', 'Verdant')],
        activeMediaPolicy: _officialMediaPolicy,
      );

      final failingService = JoinedNetworkRailService(
        credentialStore: credentialStore,
        repositoryFactory: (_) => const _UnavailableServerSettingsRepository(),
      );
      final unavailableSnapshot = await failingService.load(
        activeSession: activeSession,
        savedProfiles: [NetworkProfile.official(), communityProfile],
        activeServers: [_server('official-server', 'Verdant')],
        activeMediaPolicy: _officialMediaPolicy,
        cachedRailServers: readySnapshot.railServers,
      );

      final officialServer = unavailableSnapshot.railServers.singleWhere(
        (server) => server.localServerId == 'official-server',
      );
      final communityServer = unavailableSnapshot.railServers.singleWhere(
        (server) => server.localServerId == 'community-server',
      );
      final communityRecord = unavailableSnapshot.records.singleWhere(
        (record) => record.networkId == networkIdFromApiOrigin(communityOrigin),
      );

      expect(officialServer.isUnavailable, isFalse);
      expect(communityServer.isUnavailable, isTrue);
      expect(communityRecord.availability, RailNetworkAvailability.unavailable);
      expect(communityRecord.authStatus, RailNetworkAuthStatus.authenticated);
      expect(await credentialStore.contains(activeOrigin), isTrue);
      expect(await credentialStore.contains(communityOrigin), isTrue);
      expect(credentialStore.clearOrigins, isEmpty);
    },
  );

  test(
    'can reuse cached inactive rail servers without another backend list call',
    () async {
      const activeOrigin = 'https://api.verdant.chat';
      const communityOrigin = 'https://api.community.example';
      final activeSession = AuthSession.authenticated(
        apiOrigin: activeOrigin,
        user: _user,
      );
      final communityProfile = NetworkProfile(
        name: 'Community',
        apiOrigin: communityOrigin,
      );
      final credentialStore = _MemoryCredentialStore({
        communityOrigin: const AuthCredentialBundle(
          apiOrigin: communityOrigin,
          accessToken: 'community-access-not-rendered',
          sessionToken: 'community-session-not-rendered',
        ),
      });
      final firstRequestedOrigins = <String>[];
      final service = JoinedNetworkRailService(
        credentialStore: credentialStore,
        repositoryFactory: (apiOrigin) {
          firstRequestedOrigins.add(apiOrigin);
          return _FakeServerSettingsRepository(
            server: _server('community-server', 'Community Grove'),
          );
        },
      );
      final readySnapshot = await service.load(
        activeSession: activeSession,
        savedProfiles: [NetworkProfile.official(), communityProfile],
        activeServers: [_server('official-server', 'Verdant')],
        activeMediaPolicy: _officialMediaPolicy,
      );

      final cachedRequestedOrigins = <String>[];
      final cachedService = JoinedNetworkRailService(
        credentialStore: credentialStore,
        repositoryFactory: (apiOrigin) {
          cachedRequestedOrigins.add(apiOrigin);
          throw StateError('cached inactive rail should not fetch servers');
        },
      );
      final cachedSnapshot = await cachedService.load(
        activeSession: activeSession,
        savedProfiles: [NetworkProfile.official(), communityProfile],
        activeServers: [_server('official-server', 'Verdant')],
        activeMediaPolicy: _officialMediaPolicy,
        cachedRailServers: readySnapshot.railServers,
        preferCachedServers: true,
      );

      final communityServer = cachedSnapshot.railServers.singleWhere(
        (server) => server.localServerId == 'community-server',
      );
      final communityRecord = cachedSnapshot.records.singleWhere(
        (record) => record.networkId == networkIdFromApiOrigin(communityOrigin),
      );

      expect(firstRequestedOrigins, [communityOrigin]);
      expect(cachedRequestedOrigins, isEmpty);
      expect(communityServer.isUnavailable, isFalse);
      expect(communityRecord.availability, RailNetworkAvailability.available);
      expect(communityRecord.authStatus, RailNetworkAuthStatus.authenticated);
    },
  );

  test(
    'keeps signed-out saved networks visible without backend egress',
    () async {
      const communityOrigin = 'https://api.community.example';
      final service = JoinedNetworkRailService(
        credentialStore: _MemoryCredentialStore(),
        repositoryFactory: (_) {
          throw StateError('signed-out networks must not call REST');
        },
      );

      final snapshot = await service.load(
        activeSession: AuthSession.authenticated(
          apiOrigin: 'https://api.verdant.chat',
          user: _user,
        ),
        savedProfiles: [
          NetworkProfile.official(),
          NetworkProfile(name: 'Community', apiOrigin: communityOrigin),
        ],
        activeServers: [_server('official-server', 'Verdant')],
        activeMediaPolicy: _officialMediaPolicy,
      );

      final communityRecord = snapshot.records.singleWhere(
        (record) => record.networkId == networkIdFromApiOrigin(communityOrigin),
      );
      expect(communityRecord.authStatus, RailNetworkAuthStatus.signedOut);
      expect(
        communityRecord.availability,
        RailNetworkAvailability.requiresAuth,
      );
      expect(
        snapshot.railServers.any(
          (server) => server.networkId == communityRecord.networkId,
        ),
        isFalse,
      );
    },
  );

  test(
    'surfaces scoped account username state from saved credentials',
    () async {
      const communityOrigin = 'https://api.community.example';
      final communityProfile = NetworkProfile(
        name: 'Community',
        apiOrigin: communityOrigin,
      );
      final service = JoinedNetworkRailService(
        credentialStore: _MemoryCredentialStore({
          communityOrigin: const AuthCredentialBundle(
            apiOrigin: communityOrigin,
            accessToken: 'community-access-not-rendered',
            sessionToken: 'community-session-not-rendered',
            user: _pendingUsernameUser,
          ),
        }),
        repositoryFactory: (_) => _FakeServerSettingsRepository(
          server: _server('community-server', 'Community Grove'),
        ),
      );

      final snapshot = await service.load(
        activeSession: AuthSession.authenticated(
          apiOrigin: 'https://api.verdant.chat',
          user: _user,
        ),
        savedProfiles: [NetworkProfile.official(), communityProfile],
        activeServers: [_server('official-server', 'Verdant')],
        activeMediaPolicy: _officialMediaPolicy,
      );

      final communityRecord = snapshot.records.singleWhere(
        (record) => record.networkId == networkIdFromApiOrigin(communityOrigin),
      );
      expect(communityRecord.authStatus, RailNetworkAuthStatus.authenticated);
      expect(communityRecord.currentUserId, _pendingUsernameUser.id);
      expect(communityRecord.currentUsername, _pendingUsernameUser.username);
      expect(communityRecord.usernameSet, isFalse);
      expect(communityRecord.toString(), isNot(contains('community-access')));
      expect(communityRecord.toString(), isNot(contains('community-session')));
    },
  );

  test(
    'loads durable federated memberships from the home backend without target credentials',
    () async {
      const activeOrigin = 'https://api.verdant.chat';
      const communityOrigin = 'https://api.community.example';
      final activeSession = AuthSession.authenticated(
        apiOrigin: activeOrigin,
        user: _user,
      );
      final membershipRepository = _FakeFederatedMembershipRepository([
        _membership(
          id: 'mem-1',
          targetApiOrigin: communityOrigin,
          targetServerId: 'community-server',
          serverName: 'Community Grove',
        ),
      ]);
      final diagnostics = _RecordingAuthDiagnostics();
      final service = JoinedNetworkRailService(
        credentialStore: _MemoryCredentialStore(),
        repositoryFactory: (_) {
          throw StateError(
            'federated membership rail must not require target REST',
          );
        },
        federatedMembershipRepositoryFactory: (apiOrigin) {
          expect(apiOrigin, activeOrigin);
          return membershipRepository;
        },
        diagnostics: diagnostics,
      );

      final snapshot = await service.load(
        activeSession: activeSession,
        savedProfiles: [NetworkProfile.official()],
        activeServers: [_server('official-server', 'Verdant')],
        activeMediaPolicy: _officialMediaPolicy,
      );

      final communityNetworkId = networkIdFromApiOrigin(communityOrigin);
      final communityRecord = snapshot.records.singleWhere(
        (record) => record.networkId == communityNetworkId,
      );
      final communityServer = snapshot.railServers.singleWhere(
        (server) =>
            server.scopedServerId == '$communityNetworkId/community-server',
      );

      expect(membershipRepository.listCalls, 1);
      expect(communityRecord.mode, RailNetworkMode.federated);
      expect(communityRecord.availability, RailNetworkAvailability.available);
      expect(communityRecord.authStatus, RailNetworkAuthStatus.authenticated);
      expect(communityRecord.currentUserId, _user.id);
      expect(communityServer.name, 'Community Grove');
      expect(communityServer.isUnavailable, isFalse);
      final membershipEvent = diagnostics.events.singleWhere(
        (event) =>
            event.name ==
            'workspace.rail.hydration.federated_memberships.result',
      );
      expect(membershipEvent.fields['membershipCount'], 1);
      expect(membershipEvent.fields['activeMembershipCount'], 1);
      expect(membershipEvent.fields['targetNetworkIds'], [communityNetworkId]);
      final resultEvent = diagnostics.events.singleWhere(
        (event) => event.name == 'workspace.rail.hydration.result',
      );
      expect(resultEvent.fields['recordCount'], 2);
      expect(resultEvent.fields['railServerCount'], 2);
      expect(resultEvent.fields['federatedMembershipCount'], 1);
    },
  );

  test('reuses recent federated membership hydration metadata', () async {
    const activeOrigin = 'https://api.cache-home.example';
    const communityOrigin = 'https://api.cache-community.example';
    final activeSession = AuthSession.authenticated(
      apiOrigin: activeOrigin,
      user: _user,
    );
    final membershipRepository = _FakeFederatedMembershipRepository([
      _membership(
        id: 'mem-cache',
        targetApiOrigin: communityOrigin,
        targetServerId: 'community-server',
        serverName: 'Community Grove',
      ),
    ]);
    final diagnostics = _RecordingAuthDiagnostics();
    final service = JoinedNetworkRailService(
      credentialStore: _MemoryCredentialStore(),
      repositoryFactory: (_) {
        throw StateError(
          'federated membership rail must not require target REST',
        );
      },
      federatedMembershipRepositoryFactory: (apiOrigin) {
        expect(apiOrigin, activeOrigin);
        return membershipRepository;
      },
      diagnostics: diagnostics,
    );
    final savedProfiles = <NetworkProfile>[
      NetworkProfile(name: 'Home', apiOrigin: activeOrigin),
    ];
    final activeServers = [_server('official-server', 'Verdant')];

    final first = await service.load(
      activeSession: activeSession,
      savedProfiles: savedProfiles,
      activeServers: activeServers,
      activeMediaPolicy: _officialMediaPolicy,
    );
    final second = await service.load(
      activeSession: activeSession,
      savedProfiles: savedProfiles,
      activeServers: activeServers,
      activeMediaPolicy: _officialMediaPolicy,
    );

    final communityNetworkId = networkIdFromApiOrigin(communityOrigin);
    expect(membershipRepository.listCalls, 1);
    expect(
      first.railServers.map((server) => server.scopedServerId),
      contains('$communityNetworkId/community-server'),
    );
    expect(
      second.railServers.map((server) => server.scopedServerId),
      contains('$communityNetworkId/community-server'),
    );
    final cacheHitEvent = diagnostics.events.singleWhere(
      (event) =>
          event.name ==
          'workspace.rail.hydration.federated_memberships.cache_hit',
    );
    expect(cacheHitEvent.fields['membershipCount'], 1);
  });

  test(
    'does not reuse federated membership metadata across home users',
    () async {
      const activeOrigin = 'https://api.cache-home-user-boundary.example';
      const communityAOrigin = 'https://api.cache-community-a.example';
      const communityBOrigin = 'https://api.cache-community-b.example';
      final userASession = AuthSession.authenticated(
        apiOrigin: activeOrigin,
        user: _user,
      );
      final userBSession = AuthSession.authenticated(
        apiOrigin: activeOrigin,
        user: _pendingUsernameUser,
      );
      final repositoryA = _FakeFederatedMembershipRepository([
        _membership(
          id: 'mem-cache-a',
          targetApiOrigin: communityAOrigin,
          targetServerId: 'community-a',
          serverName: 'Community A',
        ),
      ]);
      final repositoryB = _FakeFederatedMembershipRepository([
        _membership(
          id: 'mem-cache-b',
          targetApiOrigin: communityBOrigin,
          targetServerId: 'community-b',
          serverName: 'Community B',
        ),
      ]);
      var currentRepository = repositoryA;
      final service = JoinedNetworkRailService(
        credentialStore: _MemoryCredentialStore(),
        repositoryFactory: (_) {
          throw StateError(
            'federated membership rail must not require target REST',
          );
        },
        federatedMembershipRepositoryFactory: (apiOrigin) {
          expect(apiOrigin, activeOrigin);
          return currentRepository;
        },
      );
      final savedProfiles = <NetworkProfile>[
        NetworkProfile(name: 'Home', apiOrigin: activeOrigin),
      ];
      final activeServers = [_server('official-server', 'Verdant')];

      final first = await service.load(
        activeSession: userASession,
        savedProfiles: savedProfiles,
        activeServers: activeServers,
        activeMediaPolicy: _officialMediaPolicy,
      );
      currentRepository = repositoryB;
      final second = await service.load(
        activeSession: userBSession,
        savedProfiles: savedProfiles,
        activeServers: activeServers,
        activeMediaPolicy: _officialMediaPolicy,
      );

      final communityANetworkId = networkIdFromApiOrigin(communityAOrigin);
      final communityBNetworkId = networkIdFromApiOrigin(communityBOrigin);
      final firstServers = first.railServers
          .map((server) => server.scopedServerId)
          .toList(growable: false);
      final secondServers = second.railServers
          .map((server) => server.scopedServerId)
          .toList(growable: false);

      expect(repositoryA.listCalls, 1);
      expect(repositoryB.listCalls, 1);
      expect(firstServers, contains('$communityANetworkId/community-a'));
      expect(
        secondServers,
        isNot(contains('$communityANetworkId/community-a')),
      );
      expect(secondServers, contains('$communityBNetworkId/community-b'));
    },
  );

  test(
    'restores missing federated target credentials during rail hydration',
    () async {
      const activeOrigin = 'https://api.verdant.chat';
      const communityOrigin = 'https://api.community.example';
      final communityNetworkId = networkIdFromApiOrigin(communityOrigin);
      final activeSession = AuthSession.authenticated(
        apiOrigin: activeOrigin,
        user: _user,
      );
      final membershipRepository = _FakeFederatedMembershipRepository(
        [
          _membership(
            id: 'mem-1',
            targetApiOrigin: communityOrigin,
            targetServerId: 'community-server',
            serverName: 'Community Grove',
          ),
        ],
        capabilitiesByMembershipId: {
          'mem-1': FederatedMembershipCapabilityResult.fromJson({
            'status': 'ready',
            'tokenType': 'federated_client',
            'accessToken': 'fresh-target-federated-access-not-rendered',
            'expiresAt': '2099-01-01T00:00:00Z',
            'serverId': 'community-server',
            'user': {
              'id': 'fed_fresh',
              'username': 'fed_fresh',
              'email': '',
              'status': 'online',
              'usernameSet': true,
              'emailVerified': false,
              'totpEnabled': false,
            },
          }),
        },
      );
      final credentialStore = _MemoryCredentialStore();
      final liveServer = _server('community-server', 'Community Grove Live')
          .copyWith(
            iconUrl: 'https://media.community.example/server-icons/live.webp',
            bannerUrl: 'https://media.community.example/banners/live.webp',
          );
      final requestedOrigins = <String>[];
      final service = JoinedNetworkRailService(
        credentialStore: credentialStore,
        repositoryFactory: (apiOrigin) {
          requestedOrigins.add(apiOrigin);
          return _FakeServerSettingsRepository(
            server: liveServer,
            servers: [liveServer],
          );
        },
        federatedMembershipRepositoryFactory: (apiOrigin) {
          expect(apiOrigin, activeOrigin);
          return membershipRepository;
        },
      );

      final snapshot = await service.load(
        activeSession: activeSession,
        savedProfiles: [NetworkProfile.official()],
        activeServers: [_server('official-server', 'Verdant')],
        activeMediaPolicy: _officialMediaPolicy,
      );

      final communityServer = snapshot.railServers.singleWhere(
        (server) =>
            server.scopedServerId == '$communityNetworkId/community-server',
      );
      final freshCredentials = await credentialStore.read(communityOrigin);

      expect(requestedOrigins, [communityOrigin]);
      expect(membershipRepository.refreshCalls, ['mem-1']);
      expect(
        freshCredentials?.accessToken,
        'fresh-target-federated-access-not-rendered',
      );
      expect(freshCredentials?.kind, AuthCredentialKind.federatedClient);
      expect(communityServer.name, 'Community Grove Live');
      expect(communityServer.iconUrl, liveServer.iconUrl);
      expect(communityServer.bannerUrl, liveServer.bannerUrl);
    },
  );

  test(
    'aggregates active and saved home federated memberships for startup rail',
    () async {
      const activeOrigin = 'https://api.verdant.chat';
      const secondHomeOrigin = 'https://api.home-two.example';
      const firstCommunityOrigin = 'https://api.community-one.example';
      const secondCommunityOrigin = 'https://api.community-two.example';
      final firstCommunityNetworkId = networkIdFromApiOrigin(
        firstCommunityOrigin,
      );
      final secondCommunityNetworkId = networkIdFromApiOrigin(
        secondCommunityOrigin,
      );
      final activeSession = AuthSession.authenticated(
        apiOrigin: activeOrigin,
        user: _user,
      );
      final activeHomeMemberships = _FakeFederatedMembershipRepository([
        _membership(
          id: 'mem-active',
          targetApiOrigin: firstCommunityOrigin,
          targetServerId: 'first-community-server',
          serverName: 'First Community',
        ),
      ]);
      final savedHomeMemberships = _FakeFederatedMembershipRepository([
        _membership(
          id: 'mem-saved',
          targetApiOrigin: secondCommunityOrigin,
          targetServerId: 'second-community-server',
          serverName: 'Second Community',
        ),
      ]);
      final diagnostics = _RecordingAuthDiagnostics();
      final service = JoinedNetworkRailService(
        credentialStore: _MemoryCredentialStore({
          secondHomeOrigin: const AuthCredentialBundle(
            apiOrigin: secondHomeOrigin,
            accessToken: 'second-home-access-not-rendered',
            sessionToken: 'second-home-session-not-rendered',
            user: _user,
          ),
        }),
        repositoryFactory: (_) =>
            _FakeServerSettingsRepository(server: _server('unused', 'Unused')),
        federatedMembershipRepositoryFactory: (apiOrigin) {
          if (apiOrigin == activeOrigin) {
            return activeHomeMemberships;
          }
          if (apiOrigin == secondHomeOrigin) {
            return savedHomeMemberships;
          }
          throw StateError('Unexpected membership origin: $apiOrigin');
        },
        diagnostics: diagnostics,
      );

      final snapshot = await service.load(
        activeSession: activeSession,
        savedProfiles: [
          NetworkProfile.official(),
          NetworkProfile(name: 'Home Two', apiOrigin: secondHomeOrigin),
        ],
        activeServers: [_server('official-server', 'Verdant')],
        activeMediaPolicy: _officialMediaPolicy,
      );

      expect(activeHomeMemberships.listCalls, 1);
      expect(savedHomeMemberships.listCalls, 1);
      expect(
        snapshot.railServers.map((server) => server.scopedServerId),
        contains('$firstCommunityNetworkId/first-community-server'),
      );
      expect(
        snapshot.railServers.map((server) => server.scopedServerId),
        contains('$secondCommunityNetworkId/second-community-server'),
      );
      final aggregateEvent = diagnostics.events.singleWhere(
        (event) =>
            event.name ==
            'workspace.rail.hydration.federated_memberships.aggregate.result',
      );
      expect(aggregateEvent.fields['seedMembershipCount'], 1);
      expect(aggregateEvent.fields['activeMembershipCount'], 2);
    },
  );

  test(
    'keeps pending federated memberships out of authenticated rail rows',
    () async {
      const activeOrigin = 'https://api.verdant.chat';
      const communityOrigin = 'https://api.community.example';
      final communityNetworkId = networkIdFromApiOrigin(communityOrigin);
      final activeSession = AuthSession.authenticated(
        apiOrigin: activeOrigin,
        user: _user,
      );
      final membershipRepository = _FakeFederatedMembershipRepository([
        _membership(
          id: 'mem-1',
          targetApiOrigin: communityOrigin,
          targetServerId: 'community-server',
          serverName: 'Community Grove',
          status: 'pending',
        ),
      ]);
      final diagnostics = _RecordingAuthDiagnostics();
      final service = JoinedNetworkRailService(
        credentialStore: _MemoryCredentialStore(),
        repositoryFactory: (_) =>
            _FakeServerSettingsRepository(server: _server('unused', 'Unused')),
        federatedMembershipRepositoryFactory: (_) => membershipRepository,
        diagnostics: diagnostics,
      );

      final snapshot = await service.load(
        activeSession: activeSession,
        savedProfiles: [NetworkProfile.official()],
        activeServers: [_server('official-server', 'Verdant')],
        activeMediaPolicy: _officialMediaPolicy,
      );

      expect(
        snapshot.records.any(
          (record) => record.networkId == communityNetworkId,
        ),
        isFalse,
      );
      expect(
        snapshot.railServers.any(
          (server) =>
              server.scopedServerId == '$communityNetworkId/community-server',
        ),
        isFalse,
      );
      final membershipEvent = diagnostics.events.singleWhere(
        (event) =>
            event.name ==
            'workspace.rail.hydration.federated_memberships.result',
      );
      expect(membershipEvent.fields['membershipCount'], 1);
      expect(membershipEvent.fields['activeMembershipCount'], 0);
    },
  );

  test(
    'filters saved federated target credentials to active home membership scope',
    () async {
      const activeOrigin = 'https://api.verdant.chat';
      const communityOrigin = 'https://api.community.example';
      final communityNetworkId = networkIdFromApiOrigin(communityOrigin);
      final activeSession = AuthSession.authenticated(
        apiOrigin: activeOrigin,
        user: _user,
      );
      final membershipRepository = _FakeFederatedMembershipRepository([
        _membership(
          id: 'mem-1',
          targetApiOrigin: communityOrigin,
          targetServerId: 'allowed-server',
          serverName: 'Allowed Grove',
        ),
      ]);
      final requestedOrigins = <String>[];
      final service = JoinedNetworkRailService(
        credentialStore: _MemoryCredentialStore({
          communityOrigin: const AuthCredentialBundle(
            apiOrigin: communityOrigin,
            accessToken: 'stale-target-federated-access-not-rendered',
            sessionToken: '',
            kind: AuthCredentialKind.federatedClient,
            user: VerdantUser(
              id: 'fed_old',
              username: 'fed_old',
              email: '',
              status: 'offline',
              usernameSet: true,
              emailVerified: false,
              totpEnabled: false,
            ),
          ),
        }),
        repositoryFactory: (apiOrigin) {
          requestedOrigins.add(apiOrigin);
          return _FakeServerSettingsRepository(
            server: _server('allowed-server', 'Allowed Grove'),
            servers: [
              _server('allowed-server', 'Allowed Grove'),
              _server('unrelated-server', 'Unrelated Grove'),
            ],
          );
        },
        federatedMembershipRepositoryFactory: (_) => membershipRepository,
      );

      final snapshot = await service.load(
        activeSession: activeSession,
        savedProfiles: [
          NetworkProfile.official(),
          NetworkProfile(name: 'Community', apiOrigin: communityOrigin),
        ],
        activeServers: [_server('official-server', 'Verdant')],
        activeMediaPolicy: _officialMediaPolicy,
      );

      final communityRecord = snapshot.records.singleWhere(
        (record) => record.networkId == communityNetworkId,
      );
      expect(requestedOrigins, [communityOrigin]);
      expect(
        communityRecord.credentialKind,
        AuthCredentialKind.federatedClient,
      );
      expect(communityRecord.currentUsername, 'fed_old');
      expect(
        snapshot.railServers.map((server) => server.scopedServerId),
        contains('$communityNetworkId/allowed-server'),
      );
      expect(
        snapshot.railServers.map((server) => server.scopedServerId),
        isNot(contains('$communityNetworkId/unrelated-server')),
      );
    },
  );

  test(
    'remints expired federated target credentials during rail hydration',
    () async {
      const activeOrigin = 'https://api.verdant.chat';
      const communityOrigin = 'https://api.community.example';
      final communityNetworkId = networkIdFromApiOrigin(communityOrigin);
      final activeSession = AuthSession.authenticated(
        apiOrigin: activeOrigin,
        user: _user,
      );
      final membershipRepository = _FakeFederatedMembershipRepository(
        [
          _membership(
            id: 'mem-1',
            targetApiOrigin: communityOrigin,
            targetServerId: 'allowed-server',
            serverName: 'Allowed Grove',
          ),
        ],
        capabilitiesByMembershipId: {
          'mem-1': FederatedMembershipCapabilityResult.fromJson({
            'status': 'ready',
            'tokenType': 'federated_client',
            'accessToken': 'fresh-target-federated-access-not-rendered',
            'expiresAt': '2099-01-01T00:00:00Z',
            'serverId': 'allowed-server',
            'user': {
              'id': 'fed_fresh',
              'username': 'fed_fresh',
              'email': '',
              'status': 'online',
              'usernameSet': true,
              'emailVerified': false,
              'totpEnabled': false,
            },
          }),
        },
      );
      final credentialStore = _MemoryCredentialStore({
        communityOrigin: const AuthCredentialBundle(
          apiOrigin: communityOrigin,
          accessToken: 'expired-target-federated-access-not-rendered',
          sessionToken: '',
          kind: AuthCredentialKind.federatedClient,
          user: VerdantUser(
            id: 'fed_old',
            username: 'fed_old',
            email: '',
            status: 'offline',
            usernameSet: true,
            emailVerified: false,
            totpEnabled: false,
          ),
        ),
      });
      final liveServer = _server('allowed-server', 'Allowed Grove Live')
          .copyWith(
            iconUrl: 'https://media.community.example/server-icons/live.webp',
            bannerUrl: 'https://media.community.example/banners/live.webp',
          );
      final requestedOrigins = <String>[];
      final targetRepository = _FakeServerSettingsRepository(
        server: liveServer,
        listServerResults: [
          const ServerSettingsException(
            'federated target expired',
            isAuthExpired: true,
          ),
          [liveServer],
        ],
      );
      final service = JoinedNetworkRailService(
        credentialStore: credentialStore,
        repositoryFactory: (apiOrigin) {
          requestedOrigins.add(apiOrigin);
          return targetRepository;
        },
        federatedMembershipRepositoryFactory: (_) => membershipRepository,
      );

      final snapshot = await service.load(
        activeSession: activeSession,
        savedProfiles: [
          NetworkProfile.official(),
          NetworkProfile(name: 'Community', apiOrigin: communityOrigin),
        ],
        activeServers: [_server('official-server', 'Verdant')],
        activeMediaPolicy: _officialMediaPolicy,
      );

      final communityServer = snapshot.railServers.singleWhere(
        (server) =>
            server.scopedServerId == '$communityNetworkId/allowed-server',
      );
      final freshCredentials = await credentialStore.read(communityOrigin);

      expect(requestedOrigins, [communityOrigin, communityOrigin]);
      expect(membershipRepository.refreshCalls, ['mem-1']);
      expect(
        freshCredentials?.accessToken,
        'fresh-target-federated-access-not-rendered',
      );
      expect(freshCredentials?.kind, AuthCredentialKind.federatedClient);
      expect(communityServer.name, 'Allowed Grove Live');
      expect(communityServer.iconUrl, liveServer.iconUrl);
      expect(communityServer.bannerUrl, liveServer.bannerUrl);
    },
  );

  test(
    'filters active federated workspace target servers to home membership scope',
    () async {
      const homeOrigin = 'https://api.verdant.chat';
      const communityOrigin = 'https://api.community.example';
      final homeNetworkId = networkIdFromApiOrigin(homeOrigin);
      final communityNetworkId = networkIdFromApiOrigin(communityOrigin);
      final activeSession = AuthSession.authenticated(
        apiOrigin: communityOrigin,
        user: _pendingUsernameUser,
        hasSessionToken: false,
        credentialKind: AuthCredentialKind.federatedClient,
      );
      final membershipRepository = _FakeFederatedMembershipRepository([
        _membership(
          id: 'mem-1',
          targetApiOrigin: communityOrigin,
          targetServerId: 'allowed-server',
          serverName: 'Allowed Grove',
        ),
      ]);
      final service = JoinedNetworkRailService(
        credentialStore: _MemoryCredentialStore({
          homeOrigin: const AuthCredentialBundle(
            apiOrigin: homeOrigin,
            accessToken: 'home-access-not-rendered',
            sessionToken: 'home-session-not-rendered',
            user: _user,
          ),
        }),
        repositoryFactory: (_) => _FakeServerSettingsRepository(
          server: _server('official-server', 'Verdant'),
        ),
        federatedMembershipRepositoryFactory: (apiOrigin) {
          expect(apiOrigin, homeOrigin);
          return membershipRepository;
        },
      );

      final snapshot = await service.load(
        activeSession: activeSession,
        savedProfiles: [
          NetworkProfile.official(),
          NetworkProfile(name: 'Community', apiOrigin: communityOrigin),
        ],
        activeServers: [
          _server('allowed-server', 'Allowed Grove Live'),
          _server('unrelated-server-1', 'Unrelated One'),
          _server('unrelated-server-2', 'Unrelated Two'),
        ],
        activeMediaPolicy: ServerMediaPolicy.fromOrigins(
          apiOrigin: communityOrigin,
        ),
      );

      final communityRecord = snapshot.records.singleWhere(
        (record) => record.networkId == communityNetworkId,
      );
      expect(membershipRepository.listCalls, 1);
      expect(
        communityRecord.credentialKind,
        AuthCredentialKind.federatedClient,
      );
      expect(communityRecord.authStatus, RailNetworkAuthStatus.authenticated);
      expect(
        snapshot.railServers.map((server) => server.scopedServerId),
        contains('$homeNetworkId/official-server'),
      );
      expect(
        snapshot.railServers.map((server) => server.scopedServerId),
        contains('$communityNetworkId/allowed-server'),
      );
      expect(
        snapshot.railServers.map((server) => server.scopedServerId),
        isNot(contains('$communityNetworkId/unrelated-server-1')),
      );
      expect(
        snapshot.railServers.map((server) => server.scopedServerId),
        isNot(contains('$communityNetworkId/unrelated-server-2')),
      );
    },
  );

  test('records why durable federated membership hydration failed', () async {
    const activeOrigin = 'https://api.verdant.chat';
    const communityOrigin = 'https://api.community.example';
    final diagnostics = _RecordingAuthDiagnostics();
    final activeSession = AuthSession.authenticated(
      apiOrigin: activeOrigin,
      user: _user,
    );
    final service = JoinedNetworkRailService(
      credentialStore: _MemoryCredentialStore(),
      repositoryFactory: (_) => _FakeServerSettingsRepository(
        server: _server('community-server', 'Community Grove'),
      ),
      federatedMembershipRepositoryFactory: (apiOrigin) {
        expect(apiOrigin, activeOrigin);
        return const _FailingFederatedMembershipRepository(
          FederatedMembershipException(
            'rate limited',
            code: 'RATE_LIMITED',
            statusCode: 429,
          ),
        );
      },
      diagnostics: diagnostics,
    );

    final snapshot = await service.load(
      activeSession: activeSession,
      savedProfiles: [
        NetworkProfile.official(),
        NetworkProfile(name: 'Community', apiOrigin: communityOrigin),
      ],
      activeServers: [_server('official-server', 'Verdant')],
      activeMediaPolicy: _officialMediaPolicy,
    );

    final communityRecord = snapshot.records.singleWhere(
      (record) => record.networkId == networkIdFromApiOrigin(communityOrigin),
    );
    expect(communityRecord.authStatus, RailNetworkAuthStatus.signedOut);
    expect(communityRecord.availability, RailNetworkAvailability.requiresAuth);
    final errorEvent = diagnostics.events.singleWhere(
      (event) =>
          event.name == 'workspace.rail.hydration.federated_memberships.error',
    );
    expect(errorEvent.fields['homeApiOrigin'], activeOrigin);
    expect(errorEvent.fields['statusCode'], 429);
    expect(errorEvent.fields['code'], 'RATE_LIMITED');
    expect(errorEvent.fields['isAuthExpired'], isFalse);
  });
}

const _user = VerdantUser(
  id: '42',
  username: 'boji',
  email: 'boji@example.com',
  status: 'online',
  usernameSet: true,
  emailVerified: true,
  totpEnabled: false,
);

const _pendingUsernameUser = VerdantUser(
  id: '84',
  username: 'user_84',
  email: 'new@example.com',
  status: 'online',
  usernameSet: false,
  emailVerified: true,
  totpEnabled: false,
);

const _officialMediaPolicy = ServerMediaPolicy(
  allowedOrigins: {'https://media.verdant.chat'},
  allowLocalHttp: false,
  apiOrigin: 'https://api.verdant.chat',
);

ServerSettingsServer _server(String id, String name) {
  return ServerSettingsServer(
    id: id,
    name: name,
    ownerId: '42',
    voiceBitrate: 64000,
    bannerOffsetY: 50,
    memberCount: 1,
    large: false,
    createdAt: '2026-06-01T10:00:00Z',
    updatedAt: '2026-06-01T10:00:00Z',
  );
}

final class _MemoryCredentialStore implements AuthCredentialStore {
  _MemoryCredentialStore([Map<String, AuthCredentialBundle>? initial])
    : _credentials = {...?initial};

  final Map<String, AuthCredentialBundle> _credentials;
  final readOrigins = <String>[];
  final clearOrigins = <String>[];

  @override
  Future<void> save(AuthCredentialBundle credentials) async {
    _credentials[credentials.normalizedApiOrigin] = credentials;
  }

  @override
  Future<AuthCredentialBundle?> read(String apiOrigin) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    readOrigins.add(normalizedOrigin);
    return _credentials[normalizedOrigin];
  }

  @override
  Future<bool> contains(String apiOrigin) async {
    return _credentials.containsKey(normalizeBackendApiOrigin(apiOrigin));
  }

  @override
  Future<void> clear(String apiOrigin) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    clearOrigins.add(normalizedOrigin);
    _credentials.remove(normalizedOrigin);
  }
}

final class _RecordingAuthDiagnostics implements AuthDiagnostics {
  final events = <({String name, Map<String, Object?> fields})>[];

  @override
  void record(String event, Map<String, Object?> fields) {
    events.add((name: event, fields: Map.unmodifiable(fields)));
  }

  List<Map<String, Object?>> payloadsFor(String event) => [
    for (final record in events)
      if (record.name == event) record.fields,
  ];
}

final class _FakeServerSettingsRepository implements ServerSettingsRepository {
  _FakeServerSettingsRepository({
    required this.server,
    this.servers,
    List<Object> listServerResults = const [],
  }) : _listServerResults = List<Object>.of(listServerResults);

  final ServerSettingsServer server;
  final List<ServerSettingsServer>? servers;
  final List<Object> _listServerResults;

  @override
  Future<List<ServerSettingsServer>> listServers() async {
    if (_listServerResults.isNotEmpty) {
      final result = _listServerResults.removeAt(0);
      if (result is ServerSettingsException) {
        throw result;
      }
      return result as List<ServerSettingsServer>;
    }
    return servers ?? [server];
  }

  @override
  Future<ServerSettingsData> loadServerSettings(ServerSettingsServer server) {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> createServer({required String name}) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsListItemSeed> createInvite({
    required String serverId,
    int? maxUses,
    Duration? expiresIn,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> revokeInvite({required String serverId, required String code}) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveServer({required String serverId}) {
    throw UnimplementedError();
  }

  @override
  Future<ServerInvitePreview> previewInvite({required String code}) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> acceptInvite({required String code}) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> updateServer({
    required String serverId,
    required ServerSettingsPatch patch,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> uploadServerIcon({
    required String serverId,
    required ServerSettingsUpload upload,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> deleteServerIcon({required String serverId}) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> uploadServerBanner({
    required String serverId,
    required ServerSettingsUpload upload,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> updateBannerCrop({
    required String serverId,
    required BannerCrop crop,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> deleteServerBanner({required String serverId}) {
    throw UnimplementedError();
  }
}

final class _UnavailableServerSettingsRepository
    implements ServerSettingsRepository {
  const _UnavailableServerSettingsRepository();

  static const _error = ServerSettingsException('network unavailable');

  @override
  Future<List<ServerSettingsServer>> listServers() async {
    throw _error;
  }

  @override
  Future<ServerSettingsData> loadServerSettings(ServerSettingsServer server) {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> createServer({required String name}) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsListItemSeed> createInvite({
    required String serverId,
    int? maxUses,
    Duration? expiresIn,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> revokeInvite({required String serverId, required String code}) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveServer({required String serverId}) {
    throw UnimplementedError();
  }

  @override
  Future<ServerInvitePreview> previewInvite({required String code}) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> acceptInvite({required String code}) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> updateServer({
    required String serverId,
    required ServerSettingsPatch patch,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> uploadServerIcon({
    required String serverId,
    required ServerSettingsUpload upload,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> deleteServerIcon({required String serverId}) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> uploadServerBanner({
    required String serverId,
    required ServerSettingsUpload upload,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> updateBannerCrop({
    required String serverId,
    required BannerCrop crop,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ServerSettingsServer> deleteServerBanner({required String serverId}) {
    throw UnimplementedError();
  }
}

FederatedClientMembership _membership({
  required String id,
  required String targetApiOrigin,
  required String targetServerId,
  required String serverName,
  String status = 'active',
}) {
  return FederatedClientMembership.fromJson({
    'id': id,
    'targetPeerId': 'host:community.example',
    'targetApiOrigin': targetApiOrigin,
    'targetServerId': targetServerId,
    'status': status,
    'server': {
      'id': targetServerId,
      'name': serverName,
      'iconUrl': null,
      'bannerUrl': null,
    },
  });
}

final class _FakeFederatedMembershipRepository
    implements FederatedMembershipRepository {
  _FakeFederatedMembershipRepository(
    this.memberships, {
    this.capabilitiesByMembershipId = const {},
  });

  final List<FederatedClientMembership> memberships;
  final Map<String, FederatedMembershipCapabilityResult>
  capabilitiesByMembershipId;
  var listCalls = 0;
  final refreshCalls = <String>[];

  @override
  Future<List<FederatedClientMembership>> listMemberships() async {
    listCalls += 1;
    return memberships;
  }

  @override
  Future<FederatedMembershipCapabilityResult> refreshCapability({
    required String membershipId,
  }) async {
    refreshCalls.add(membershipId);
    final capability = capabilitiesByMembershipId[membershipId];
    if (capability == null) {
      throw UnimplementedError();
    }
    return capability;
  }
}

final class _FailingFederatedMembershipRepository
    implements FederatedMembershipRepository {
  const _FailingFederatedMembershipRepository(this.error);

  final FederatedMembershipException error;

  @override
  Future<List<FederatedClientMembership>> listMemberships() {
    throw error;
  }

  @override
  Future<FederatedMembershipCapabilityResult> refreshCapability({
    required String membershipId,
  }) {
    throw UnimplementedError();
  }
}
