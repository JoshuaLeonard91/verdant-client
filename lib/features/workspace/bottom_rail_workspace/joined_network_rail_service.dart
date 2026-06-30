import '../../auth/auth_diagnostics.dart';
import '../../auth/auth_credentials.dart';
import '../../auth/auth_models.dart';
import '../../auth/network_profile_store.dart';
import '../server_settings_workspace/federated_membership_service.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../server_settings_workspace/server_settings_service.dart';
import '../workspace_local_id.dart';
import 'bottom_rail_models.dart';

export 'bottom_rail_models.dart'
    show RailNetworkAuthStatus, RailNetworkAvailability;

typedef JoinedNetworkRepositoryFactory =
    ServerSettingsRepository Function(String apiOrigin);

typedef FederatedMembershipRepositoryFactory =
    FederatedMembershipRepository Function(String apiOrigin);

final class JoinedNetworkRailSnapshot {
  const JoinedNetworkRailSnapshot({
    required this.records,
    required this.networkOrder,
    required this.railServers,
  });

  final List<RailNetworkRecord> records;
  final List<String> networkOrder;
  final List<RailServerItem> railServers;
}

final class JoinedNetworkRailService {
  const JoinedNetworkRailService({
    required AuthCredentialStore credentialStore,
    required JoinedNetworkRepositoryFactory repositoryFactory,
    NetworkProfileStore? networkProfileStore,
    FederatedMembershipRepositoryFactory? federatedMembershipRepositoryFactory,
    AuthDiagnostics diagnostics = const SilentAuthDiagnostics(),
  }) : this._(
         credentialStore: credentialStore,
         repositoryFactory: repositoryFactory,
         networkProfileStore: networkProfileStore,
         federatedMembershipRepositoryFactory:
             federatedMembershipRepositoryFactory,
         diagnostics: diagnostics,
       );

  const JoinedNetworkRailService._({
    required this._credentialStore,
    required this._repositoryFactory,
    required this._networkProfileStore,
    required this._federatedMembershipRepositoryFactory,
    required this._diagnostics,
  });

  final AuthCredentialStore _credentialStore;
  final JoinedNetworkRepositoryFactory _repositoryFactory;
  final NetworkProfileStore? _networkProfileStore;
  final FederatedMembershipRepositoryFactory?
  _federatedMembershipRepositoryFactory;
  final AuthDiagnostics _diagnostics;

  static const _federatedMembershipCacheTtl = Duration(seconds: 30);
  static const _federatedMembershipStaleFallbackTtl = Duration(minutes: 5);
  static final _federatedMembershipCache =
      <String, _FederatedMembershipCacheEntry>{};

  Future<JoinedNetworkRailSnapshot> load({
    required AuthSession activeSession,
    required List<NetworkProfile> savedProfiles,
    required List<ServerSettingsServer> activeServers,
    required ServerMediaPolicy? activeMediaPolicy,
    VerdantUser? activeCurrentUser,
    List<RailServerItem> cachedRailServers = const [],
    Map<String, String> instanceModesByApiOrigin = const {},
    bool preferCachedServers = false,
  }) async {
    final loadWatch = Stopwatch()..start();
    _diagnostics.record('workspace.rail.hydration.start', {
      'activeNetworkId': activeSession.networkId,
      'activeApiOrigin': activeSession.apiOrigin,
      'activeCredentialKind': _credentialKindName(activeSession.credentialKind),
      'savedProfileCount': savedProfiles.length,
      'activeServerCount': activeServers.length,
      'cachedRailServerCount': cachedRailServers.length,
      'preferCachedServers': preferCachedServers,
    });
    final federatedMemberships = await _loadFederatedMemberships(
      activeSession,
      savedProfiles: savedProfiles,
    );
    final federatedMembershipsByNetworkId = _federatedMembershipsByNetworkId(
      federatedMemberships,
    );
    final federatedServersByNetworkId = _federatedServersByNetworkId(
      federatedMemberships,
    );
    final federatedNetworkIds = federatedServersByNetworkId.keys.toSet();
    final profiles = _profilesWithActiveSession(
      activeSession: activeSession,
      savedProfiles: savedProfiles,
      federatedMemberships: federatedMemberships,
    );
    final cachedServersByNetworkId = _cachedServersByNetworkId(
      cachedRailServers,
    );
    final records = <RailNetworkRecord>[];
    final order = <String>[];
    final railServers = <RailServerItem>[];

    for (final profile in profiles) {
      final isActive =
          normalizeBackendApiOrigin(profile.apiOrigin) ==
          normalizeBackendApiOrigin(activeSession.apiOrigin);
      final savedCredentials = isActive
          ? null
          : await _readSavedCredentials(profile);
      final hasCredentials = isActive || savedCredentials != null;
      final accountUser = isActive
          ? (activeCurrentUser ?? activeSession.user)
          : savedCredentials?.user;
      final federatedServers =
          federatedServersByNetworkId[profile.networkId] ??
          const <RailServerItem>[];
      var availability = hasCredentials
          ? RailNetworkAvailability.available
          : RailNetworkAvailability.requiresAuth;
      var authStatus = hasCredentials
          ? RailNetworkAuthStatus.authenticated
          : RailNetworkAuthStatus.signedOut;
      var recordUser = accountUser;
      AuthCredentialKind? credentialKind = isActive
          ? activeSession.credentialKind
          : savedCredentials?.kind;
      final profileRailServers = <RailServerItem>[];
      final usesFederatedTargetCredential =
          !isActive && savedCredentials?.isFederatedClient == true;

      if (isActive) {
        final mediaPolicy =
            activeMediaPolicy ??
            ServerMediaPolicy.fromOrigins(apiOrigin: profile.apiOrigin);
        if (activeSession.credentialKind ==
            AuthCredentialKind.federatedClient) {
          final cachedServers =
              cachedServersByNetworkId[profile.networkId] ??
              const <RailServerItem>[];
          final scopedServers = _federatedActiveRailServers(
            profile: profile,
            activeServers: activeServers,
            mediaPolicy: mediaPolicy,
            federatedServers: federatedServers,
            cachedServers: cachedServers,
          );
          _diagnostics
              .record('workspace.rail.hydration.servers.federated_active', {
                'networkId': profile.networkId,
                'apiOrigin': profile.apiOrigin,
                'activeServerCount': activeServers.length,
                'federatedServerCount': federatedServers.length,
                'cachedServerCount': cachedServers.length,
                'railServerCount': scopedServers.length,
                'activeServerIds': _serverIdPreview(
                  activeServers.map((server) => server.id),
                ),
                'federatedServerIds': _serverIdPreview(
                  federatedServers.map((server) => server.localServerId),
                ),
                'railServerIds': _serverIdPreview(
                  scopedServers.map((server) => server.localServerId),
                ),
              });
          profileRailServers.addAll(scopedServers);
        } else {
          profileRailServers.addAll(
            _railServersFor(
              profile: profile,
              servers: activeServers,
              mediaPolicy: mediaPolicy,
            ),
          );
        }
      } else if (usesFederatedTargetCredential) {
        credentialKind = AuthCredentialKind.federatedClient;
        final cachedServers =
            cachedServersByNetworkId[profile.networkId] ??
            const <RailServerItem>[];
        var result = await _loadServersForProfile(
          profile,
          cachedServers: cachedServers,
          federatedServers: federatedServers,
          enforceFederatedScope: federatedServers.isNotEmpty,
        );
        if (result.usedFederatedFallback) {
          final targetMemberships =
              federatedMembershipsByNetworkId[profile.networkId] ??
              const <FederatedClientMembership>[];
          final refreshed = await _refreshFederatedTargetCredential(
            homeSession: activeSession,
            profile: profile,
            membership: targetMemberships.isEmpty
                ? null
                : targetMemberships.first,
          );
          if (refreshed) {
            final refreshedCredentials = await _readSavedCredentials(profile);
            if (refreshedCredentials?.user != null) {
              recordUser = refreshedCredentials?.user;
            }
            final refreshedResult = await _loadServersForProfile(
              profile,
              cachedServers: cachedServers,
              federatedServers: federatedServers,
              enforceFederatedScope: federatedServers.isNotEmpty,
            );
            if (!refreshedResult.usedFederatedFallback) {
              result = refreshedResult;
            }
          }
        }
        availability = result.availability;
        authStatus = result.authStatus;
        if (result.servers.isNotEmpty) {
          _diagnostics.record(
            'workspace.rail.hydration.servers.federated_target_live',
            {
              'networkId': profile.networkId,
              'apiOrigin': profile.apiOrigin,
              'liveServerCount': result.servers.length,
              'federatedServerCount': federatedServers.length,
              'cachedServerCount': cachedServers.length,
              'liveServerIds': _serverIdPreview(
                result.servers.map((server) => server.localServerId),
              ),
              'federatedServerIds': _serverIdPreview(
                federatedServers.map((server) => server.localServerId),
              ),
              'liveServerMetadata': _railServerMetadataCounts(result.servers),
              'federatedServerMetadata': _railServerMetadataCounts(
                federatedServers,
              ),
            },
          );
          availability = RailNetworkAvailability.available;
          authStatus = RailNetworkAuthStatus.authenticated;
          recordUser = savedCredentials?.user;
          profileRailServers.addAll(result.servers);
        } else {
          _diagnostics
              .record('workspace.rail.hydration.servers.federated_stale', {
                'networkId': profile.networkId,
                'apiOrigin': profile.apiOrigin,
                'reason': 'no_active_home_membership',
                'hasTargetCredential': true,
                'cachedServerCount': cachedServers.length,
              });
          availability = RailNetworkAvailability.requiresAuth;
          authStatus = RailNetworkAuthStatus.signedOut;
          recordUser = null;
        }
      } else if (hasCredentials) {
        final cachedServers =
            cachedServersByNetworkId[profile.networkId] ??
            const <RailServerItem>[];
        if (preferCachedServers && cachedServers.isNotEmpty) {
          _diagnostics.record('workspace.rail.hydration.servers.cached', {
            'networkId': profile.networkId,
            'apiOrigin': profile.apiOrigin,
            'cachedServerCount': cachedServers.length,
          });
          profileRailServers.addAll(
            _availableCachedServers(
              profile: profile,
              cachedServers: cachedServers,
            ),
          );
        } else {
          final result = await _loadServersForProfile(
            profile,
            cachedServers: cachedServers,
            federatedServers: federatedServers,
          );
          availability = result.availability;
          authStatus = result.authStatus;
          profileRailServers.addAll(result.servers);
        }
      } else if (federatedServers.isNotEmpty) {
        availability = RailNetworkAvailability.available;
        authStatus = RailNetworkAuthStatus.authenticated;
        recordUser = activeCurrentUser ?? activeSession.user;
        credentialKind = AuthCredentialKind.federatedClient;
        final targetMemberships =
            federatedMembershipsByNetworkId[profile.networkId] ??
            const <FederatedClientMembership>[];
        final refreshed = await _refreshFederatedTargetCredential(
          homeSession: activeSession,
          profile: profile,
          membership: targetMemberships.isEmpty
              ? null
              : targetMemberships.first,
        );
        if (refreshed) {
          final refreshedCredentials = await _readSavedCredentials(profile);
          if (refreshedCredentials?.user != null) {
            recordUser = refreshedCredentials?.user;
          }
          final result = await _loadServersForProfile(
            profile,
            federatedServers: federatedServers,
            enforceFederatedScope: true,
          );
          availability = result.availability;
          authStatus = result.authStatus;
          if (result.servers.isNotEmpty && !result.usedFederatedFallback) {
            _diagnostics.record(
              'workspace.rail.hydration.servers.federated_restored_live',
              {
                'networkId': profile.networkId,
                'apiOrigin': profile.apiOrigin,
                'liveServerCount': result.servers.length,
                'federatedServerCount': federatedServers.length,
                'liveServerMetadata': _railServerMetadataCounts(result.servers),
              },
            );
            profileRailServers.addAll(result.servers);
          } else {
            _diagnostics.record('workspace.rail.hydration.servers.federated', {
              'networkId': profile.networkId,
              'apiOrigin': profile.apiOrigin,
              'federatedServerCount': federatedServers.length,
              'reason': 'live_refresh_unavailable',
            });
            profileRailServers.addAll(federatedServers);
          }
        } else {
          _diagnostics.record('workspace.rail.hydration.servers.federated', {
            'networkId': profile.networkId,
            'apiOrigin': profile.apiOrigin,
            'federatedServerCount': federatedServers.length,
            'reason': 'credential_refresh_unavailable',
          });
          profileRailServers.addAll(federatedServers);
        }
      }

      order.add(profile.networkId);
      records.add(
        RailNetworkRecord(
          networkId: profile.networkId,
          networkName: profile.name,
          mode: _modeFor(
            profile,
            instanceModesByApiOrigin,
            federatedNetworkIds,
          ),
          availability: availability,
          authStatus: authStatus,
          apiOrigin: profile.apiOrigin,
          currentUserId: recordUser?.id,
          currentUsername: recordUser?.username,
          usernameSet: recordUser?.usernameSet,
          credentialKind: credentialKind,
        ),
      );
      railServers.addAll(
        _stableRailServerOrder(
          servers: profileRailServers,
          cachedServers:
              cachedServersByNetworkId[profile.networkId] ??
              const <RailServerItem>[],
        ),
      );
    }

    _diagnostics.record('workspace.rail.hydration.result', {
      'ms': loadWatch.elapsedMilliseconds,
      'recordCount': records.length,
      'networkOrder': order,
      'railServerCount': railServers.length,
      'railServerOrder': _scopedServerIdPreview(
        railServers.map((server) => server.scopedServerId),
      ),
      'federatedMembershipCount': federatedMemberships.length,
      'federatedNetworkIds': federatedNetworkIds.toList(growable: false),
      'railServersByNetwork': _railServersByNetworkDiagnostics(railServers),
      'availabilityCounts': _availabilityCounts(records),
      'authStatusCounts': _authStatusCounts(records),
    });

    return JoinedNetworkRailSnapshot(
      records: List.unmodifiable(records),
      networkOrder: List.unmodifiable(order),
      railServers: List.unmodifiable(railServers),
    );
  }

  Future<AuthCredentialBundle?> _readSavedCredentials(
    NetworkProfile profile,
  ) async {
    try {
      final credentials = await _credentialStore.read(profile.apiOrigin);
      _diagnostics.record('workspace.rail.hydration.credentials.result', {
        'networkId': profile.networkId,
        'apiOrigin': profile.apiOrigin,
        'hasCredentials': credentials != null,
        'credentialKind': _credentialKindName(credentials?.kind),
        'hasUser': credentials?.user != null,
      });
      return credentials;
    } catch (error) {
      _diagnostics.record('workspace.rail.hydration.credentials.error', {
        'networkId': profile.networkId,
        'apiOrigin': profile.apiOrigin,
        'errorType': error.runtimeType.toString(),
      });
      return null;
    }
  }

  Future<
    ({
      RailNetworkAvailability availability,
      RailNetworkAuthStatus authStatus,
      List<RailServerItem> servers,
      bool usedFederatedFallback,
    })
  >
  _loadServersForProfile(
    NetworkProfile profile, {
    List<RailServerItem> cachedServers = const [],
    List<RailServerItem> federatedServers = const [],
    bool enforceFederatedScope = false,
  }) async {
    final watch = Stopwatch()..start();
    ServerSettingsRepository? repository;
    try {
      _diagnostics.record('workspace.rail.hydration.servers.start', {
        'networkId': profile.networkId,
        'apiOrigin': profile.apiOrigin,
        'cachedServerCount': cachedServers.length,
        'federatedServerCount': federatedServers.length,
        'enforceFederatedScope': enforceFederatedScope,
      });
      repository = _repositoryFactory(profile.apiOrigin);
      final servers = await repository.listServers();
      final liveServers = _railServersFor(
        profile: profile,
        servers: servers,
        mediaPolicy: ServerMediaPolicy.fromOrigins(
          apiOrigin: profile.apiOrigin,
        ),
      );
      final scopedServers = enforceFederatedScope
          ? _federatedScopedRailServers(
              liveServers: liveServers,
              federatedServers: federatedServers,
            )
          : liveServers;
      _diagnostics.record('workspace.rail.hydration.servers.result', {
        'ms': watch.elapsedMilliseconds,
        'networkId': profile.networkId,
        'apiOrigin': profile.apiOrigin,
        'serverCount': servers.length,
        'visibleServerCount': scopedServers.length,
        'filteredServerCount': servers.length - scopedServers.length,
        'enforceFederatedScope': enforceFederatedScope,
        'visibleServerOrder': _scopedServerIdPreview(
          scopedServers.map((server) => server.scopedServerId),
        ),
      });
      return (
        availability: RailNetworkAvailability.available,
        authStatus: RailNetworkAuthStatus.authenticated,
        usedFederatedFallback: false,
        servers: scopedServers,
      );
    } on ServerSettingsException catch (error) {
      if (error.isAuthExpired) {
        _diagnostics.record('workspace.rail.hydration.servers.auth_expired', {
          'ms': watch.elapsedMilliseconds,
          'networkId': profile.networkId,
          'apiOrigin': profile.apiOrigin,
          'usingFederatedFallback': federatedServers.isNotEmpty,
          'federatedServerCount': federatedServers.length,
          'cachedServerCount': cachedServers.length,
        });
        if (federatedServers.isNotEmpty) {
          return (
            availability: RailNetworkAvailability.available,
            authStatus: RailNetworkAuthStatus.authenticated,
            usedFederatedFallback: true,
            servers: federatedServers,
          );
        }
        return (
          availability: RailNetworkAvailability.requiresAuth,
          authStatus: RailNetworkAuthStatus.signedOut,
          usedFederatedFallback: false,
          servers: const <RailServerItem>[],
        );
      }
      _diagnostics.record('workspace.rail.hydration.servers.unavailable', {
        'ms': watch.elapsedMilliseconds,
        'networkId': profile.networkId,
        'apiOrigin': profile.apiOrigin,
        'errorType': error.runtimeType.toString(),
        'cachedServerCount': cachedServers.length,
      });
      return (
        availability: RailNetworkAvailability.unavailable,
        authStatus: RailNetworkAuthStatus.authenticated,
        usedFederatedFallback: false,
        servers: _unavailableCachedServers(
          profile: profile,
          cachedServers: cachedServers,
        ),
      );
    } catch (error) {
      _diagnostics.record('workspace.rail.hydration.servers.error', {
        'ms': watch.elapsedMilliseconds,
        'networkId': profile.networkId,
        'apiOrigin': profile.apiOrigin,
        'errorType': error.runtimeType.toString(),
        'cachedServerCount': cachedServers.length,
      });
      return (
        availability: RailNetworkAvailability.unavailable,
        authStatus: RailNetworkAuthStatus.authenticated,
        usedFederatedFallback: false,
        servers: _unavailableCachedServers(
          profile: profile,
          cachedServers: cachedServers,
        ),
      );
    } finally {
      final ownedRepository = repository;
      if (ownedRepository is ServerSettingsService) {
        ownedRepository.close();
      }
    }
  }

  Future<bool> _refreshFederatedTargetCredential({
    required AuthSession homeSession,
    required NetworkProfile profile,
    required FederatedClientMembership? membership,
  }) async {
    final watch = Stopwatch()..start();
    final factory = _federatedMembershipRepositoryFactory;
    if (factory == null ||
        homeSession.credentialKind == AuthCredentialKind.federatedClient ||
        membership == null) {
      _diagnostics.record('workspace.rail.hydration.federated_refresh.skip', {
        'ms': watch.elapsedMilliseconds,
        'homeNetworkId': homeSession.networkId,
        'homeApiOrigin': homeSession.apiOrigin,
        'targetNetworkId': profile.networkId,
        'targetApiOrigin': profile.apiOrigin,
        'reason': factory == null
            ? 'repository_unavailable'
            : homeSession.credentialKind == AuthCredentialKind.federatedClient
            ? 'home_session_is_federated_client'
            : 'membership_unavailable',
      });
      return false;
    }
    FederatedMembershipRepository? repository;
    try {
      _diagnostics.record('workspace.rail.hydration.federated_refresh.start', {
        'homeNetworkId': homeSession.networkId,
        'homeApiOrigin': homeSession.apiOrigin,
        'targetNetworkId': profile.networkId,
        'targetApiOrigin': profile.apiOrigin,
        'targetServerId': membership.targetServerId,
      });
      repository = factory(homeSession.apiOrigin);
      final capability = await repository.refreshCapability(
        membershipId: membership.id,
      );
      _diagnostics.record('workspace.rail.hydration.federated_refresh.result', {
        'ms': watch.elapsedMilliseconds,
        'homeNetworkId': homeSession.networkId,
        'homeApiOrigin': homeSession.apiOrigin,
        'targetNetworkId': profile.networkId,
        'targetApiOrigin': profile.apiOrigin,
        'targetServerId': membership.targetServerId,
        'capabilityStatus': capability.status.name,
        'serverMatches': capability.serverId == membership.targetServerId,
      });
      if (!capability.isReady ||
          capability.serverId != membership.targetServerId) {
        return false;
      }
      await _credentialStore.save(
        capability.toCredential(targetApiOrigin: membership.targetApiOrigin),
      );
      await _networkProfileStore?.saveProfile(
        name: profile.name,
        apiOrigin: profile.apiOrigin,
      );
      _diagnostics
          .record('workspace.rail.hydration.federated_refresh.success', {
            'ms': watch.elapsedMilliseconds,
            'homeNetworkId': homeSession.networkId,
            'homeApiOrigin': homeSession.apiOrigin,
            'targetNetworkId': profile.networkId,
            'targetApiOrigin': profile.apiOrigin,
            'targetServerId': membership.targetServerId,
          });
      return true;
    } on FederatedMembershipException catch (error) {
      _diagnostics.record('workspace.rail.hydration.federated_refresh.error', {
        'ms': watch.elapsedMilliseconds,
        'homeNetworkId': homeSession.networkId,
        'homeApiOrigin': homeSession.apiOrigin,
        'targetNetworkId': profile.networkId,
        'targetApiOrigin': profile.apiOrigin,
        'errorType': error.runtimeType.toString(),
        'statusCode': error.statusCode,
        'code': error.code,
        'isAuthExpired': error.isAuthExpired,
      });
      return false;
    } catch (error) {
      _diagnostics.record('workspace.rail.hydration.federated_refresh.error', {
        'ms': watch.elapsedMilliseconds,
        'homeNetworkId': homeSession.networkId,
        'homeApiOrigin': homeSession.apiOrigin,
        'targetNetworkId': profile.networkId,
        'targetApiOrigin': profile.apiOrigin,
        'errorType': error.runtimeType.toString(),
      });
      return false;
    } finally {
      final ownedRepository = repository;
      if (ownedRepository is HttpFederatedMembershipService) {
        ownedRepository.close();
      }
    }
  }

  Future<List<FederatedClientMembership>> _loadFederatedMemberships(
    AuthSession activeSession, {
    required List<NetworkProfile> savedProfiles,
  }) async {
    final watch = Stopwatch()..start();
    final factory = _federatedMembershipRepositoryFactory;
    if (factory == null) {
      _diagnostics
          .record('workspace.rail.hydration.federated_memberships.skip', {
            'ms': watch.elapsedMilliseconds,
            'activeNetworkId': activeSession.networkId,
            'activeApiOrigin': activeSession.apiOrigin,
            'reason': 'repository_unavailable',
          });
      return const [];
    }
    final seenHomeOrigins = <String>{};
    final memberships = <FederatedClientMembership>[];
    if (activeSession.credentialKind != AuthCredentialKind.federatedClient) {
      final homeApiOrigin = normalizeBackendApiOrigin(activeSession.apiOrigin);
      seenHomeOrigins.add(homeApiOrigin);
      memberships.addAll(
        await _loadFederatedMembershipsForHome(
          homeApiOrigin: homeApiOrigin,
          homeNetworkId: activeSession.networkId,
          homeUserId: activeSession.user.id,
          source: 'active_home',
        ),
      );
    }
    return _loadFederatedMembershipsFromSavedHomes(
      activeSession: activeSession,
      savedProfiles: savedProfiles,
      seedMemberships: memberships,
      seenHomeOrigins: seenHomeOrigins,
    );
  }

  Future<List<FederatedClientMembership>>
  _loadFederatedMembershipsFromSavedHomes({
    required AuthSession activeSession,
    required List<NetworkProfile> savedProfiles,
    List<FederatedClientMembership> seedMemberships = const [],
    Set<String>? seenHomeOrigins,
  }) async {
    final watch = Stopwatch()..start();
    final activeApiOrigin = normalizeBackendApiOrigin(activeSession.apiOrigin);
    final seenOrigins = <String>{...?seenHomeOrigins};
    final memberships = <FederatedClientMembership>[...seedMemberships];
    for (final profile in savedProfiles) {
      final candidateApiOrigin = normalizeBackendApiOrigin(profile.apiOrigin);
      if (candidateApiOrigin == activeApiOrigin ||
          !seenOrigins.add(candidateApiOrigin)) {
        continue;
      }
      AuthCredentialBundle? credentials;
      try {
        credentials = await _credentialStore.read(candidateApiOrigin);
      } catch (error) {
        _diagnostics.record(
          'workspace.rail.hydration.federated_memberships.home_error',
          {
            'activeNetworkId': activeSession.networkId,
            'activeApiOrigin': activeSession.apiOrigin,
            'homeNetworkId': networkIdFromApiOrigin(candidateApiOrigin),
            'homeApiOrigin': candidateApiOrigin,
            'errorType': error.runtimeType.toString(),
          },
        );
        continue;
      }
      if (credentials == null || credentials.isFederatedClient) {
        _diagnostics.record(
          'workspace.rail.hydration.federated_memberships.home_skip',
          {
            'activeNetworkId': activeSession.networkId,
            'activeApiOrigin': activeSession.apiOrigin,
            'homeNetworkId': networkIdFromApiOrigin(candidateApiOrigin),
            'homeApiOrigin': candidateApiOrigin,
            'credentialKind': _credentialKindName(credentials?.kind),
          },
        );
        continue;
      }
      memberships.addAll(
        await _loadFederatedMembershipsForHome(
          homeApiOrigin: candidateApiOrigin,
          homeNetworkId: networkIdFromApiOrigin(candidateApiOrigin),
          homeUserId: credentials.user?.id,
          source: 'saved_home',
        ),
      );
    }
    final deduped = _dedupeFederatedMemberships(memberships);
    _diagnostics.record(
      'workspace.rail.hydration.federated_memberships.aggregate.result',
      {
        'ms': watch.elapsedMilliseconds,
        'activeNetworkId': activeSession.networkId,
        'activeApiOrigin': activeSession.apiOrigin,
        'homeCandidateCount': seenOrigins.length,
        'seedMembershipCount': seedMemberships.length,
        'activeMembershipCount': deduped.length,
        'targetNetworkIds': _targetNetworkIds(deduped),
        'membershipServers': _membershipServerDiagnostics(deduped),
      },
    );
    return deduped;
  }

  Future<List<FederatedClientMembership>> _loadFederatedMembershipsForHome({
    required String homeApiOrigin,
    required String homeNetworkId,
    required String? homeUserId,
    required String source,
  }) async {
    final watch = Stopwatch()..start();
    final cacheKey = homeUserId == null
        ? null
        : _federatedMembershipCacheKey(homeApiOrigin, homeUserId);
    final cached = cacheKey == null
        ? null
        : _readFederatedMembershipCache(
            cacheKey,
            ttl: _federatedMembershipCacheTtl,
          );
    if (cached != null) {
      _diagnostics
          .record('workspace.rail.hydration.federated_memberships.cache_hit', {
            'ms': watch.elapsedMilliseconds,
            'homeNetworkId': homeNetworkId,
            'homeApiOrigin': homeApiOrigin,
            'source': source,
            'homeUserScoped': true,
            'membershipCount': cached.memberships.length,
            'cacheAgeMs': cached.age.inMilliseconds,
          });
      return cached.memberships;
    }

    FederatedMembershipRepository? repository;
    try {
      _diagnostics
          .record('workspace.rail.hydration.federated_memberships.start', {
            'homeNetworkId': homeNetworkId,
            'homeApiOrigin': homeApiOrigin,
            'source': source,
            'homeUserScoped': homeUserId != null,
          });
      repository = _federatedMembershipRepositoryFactory!(homeApiOrigin);
      final memberships = await repository.listMemberships();
      final activeMemberships = [
        for (final membership in memberships)
          if (membership.isActive) membership,
      ];
      _diagnostics.record(
        'workspace.rail.hydration.federated_memberships.result',
        {
          'ms': watch.elapsedMilliseconds,
          'homeNetworkId': homeNetworkId,
          'homeApiOrigin': homeApiOrigin,
          'source': source,
          'homeUserScoped': homeUserId != null,
          'membershipCount': memberships.length,
          'activeMembershipCount': activeMemberships.length,
          'statusCounts': _membershipStatusCounts(memberships),
          'targetNetworkIds': _targetNetworkIds(activeMemberships),
          'membershipServers': _membershipServerDiagnostics(activeMemberships),
        },
      );
      if (cacheKey != null) {
        _writeFederatedMembershipCache(cacheKey, activeMemberships);
        _diagnostics.record(
          'workspace.rail.hydration.federated_memberships.cache_store',
          {
            'ms': watch.elapsedMilliseconds,
            'homeNetworkId': homeNetworkId,
            'homeApiOrigin': homeApiOrigin,
            'source': source,
            'homeUserScoped': true,
            'membershipCount': activeMemberships.length,
          },
        );
      }
      return activeMemberships;
    } on FederatedMembershipException catch (error) {
      _diagnostics
          .record('workspace.rail.hydration.federated_memberships.error', {
            'ms': watch.elapsedMilliseconds,
            'homeNetworkId': homeNetworkId,
            'homeApiOrigin': homeApiOrigin,
            'source': source,
            'errorType': error.runtimeType.toString(),
            'statusCode': error.statusCode,
            'code': error.code,
            'isAuthExpired': error.isAuthExpired,
          });
      return _federatedMembershipCacheFallback(
        cacheKey: cacheKey,
        watch: watch,
        homeNetworkId: homeNetworkId,
        homeApiOrigin: homeApiOrigin,
        source: source,
      );
    } catch (error) {
      _diagnostics
          .record('workspace.rail.hydration.federated_memberships.error', {
            'ms': watch.elapsedMilliseconds,
            'homeNetworkId': homeNetworkId,
            'homeApiOrigin': homeApiOrigin,
            'source': source,
            'errorType': error.runtimeType.toString(),
          });
      return _federatedMembershipCacheFallback(
        cacheKey: cacheKey,
        watch: watch,
        homeNetworkId: homeNetworkId,
        homeApiOrigin: homeApiOrigin,
        source: source,
      );
    } finally {
      final ownedRepository = repository;
      if (ownedRepository is HttpFederatedMembershipService) {
        ownedRepository.close();
      }
    }
  }

  String _federatedMembershipCacheKey(String homeApiOrigin, String homeUserId) {
    return '${identityHashCode(_credentialStore)}:${normalizeBackendApiOrigin(homeApiOrigin)}:$homeUserId';
  }

  _FederatedMembershipCacheEntry? _readFederatedMembershipCache(
    String cacheKey, {
    required Duration ttl,
  }) {
    final cached = _federatedMembershipCache[cacheKey];
    if (cached == null || !cached.isFresh(ttl)) {
      return null;
    }
    return cached;
  }

  void _writeFederatedMembershipCache(
    String cacheKey,
    List<FederatedClientMembership> memberships,
  ) {
    _federatedMembershipCache[cacheKey] = _FederatedMembershipCacheEntry(
      cachedAt: DateTime.now().toUtc(),
      memberships: List.unmodifiable(memberships),
    );
  }

  List<FederatedClientMembership> _federatedMembershipCacheFallback({
    required String? cacheKey,
    required Stopwatch watch,
    required String homeNetworkId,
    required String homeApiOrigin,
    required String source,
  }) {
    if (cacheKey == null) {
      return const [];
    }
    final cached = _readFederatedMembershipCache(
      cacheKey,
      ttl: _federatedMembershipStaleFallbackTtl,
    );
    if (cached == null) {
      return const [];
    }
    _diagnostics
        .record('workspace.rail.hydration.federated_memberships.cache_stale', {
          'ms': watch.elapsedMilliseconds,
          'homeNetworkId': homeNetworkId,
          'homeApiOrigin': homeApiOrigin,
          'source': source,
          'homeUserScoped': true,
          'membershipCount': cached.memberships.length,
          'cacheAgeMs': cached.age.inMilliseconds,
        });
    return cached.memberships;
  }
}

final class _FederatedMembershipCacheEntry {
  const _FederatedMembershipCacheEntry({
    required this.cachedAt,
    required this.memberships,
  });

  final DateTime cachedAt;
  final List<FederatedClientMembership> memberships;

  Duration get age => DateTime.now().toUtc().difference(cachedAt);

  bool isFresh(Duration ttl) {
    final currentAge = age;
    return !currentAge.isNegative && currentAge <= ttl;
  }
}

String _credentialKindName(AuthCredentialKind? kind) => kind?.name ?? 'none';

Map<String, int> _availabilityCounts(List<RailNetworkRecord> records) {
  final counts = <String, int>{};
  for (final record in records) {
    counts.update(
      record.availability.name,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
  }
  return counts;
}

Map<String, int> _authStatusCounts(List<RailNetworkRecord> records) {
  final counts = <String, int>{};
  for (final record in records) {
    counts.update(
      record.authStatus.name,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
  }
  return counts;
}

List<String> _serverIdPreview(Iterable<String> serverIds) {
  return serverIds.take(24).toList(growable: false);
}

List<String> _scopedServerIdPreview(Iterable<String> scopedServerIds) {
  return scopedServerIds.take(24).toList(growable: false);
}

Map<String, int> _railServerMetadataCounts(List<RailServerItem> servers) {
  var iconCount = 0;
  var bannerCount = 0;
  for (final server in servers) {
    if (server.iconUrl != null && server.iconUrl!.trim().isNotEmpty) {
      iconCount += 1;
    }
    if (server.bannerUrl != null && server.bannerUrl!.trim().isNotEmpty) {
      bannerCount += 1;
    }
  }
  return {
    'serverCount': servers.length,
    'iconCount': iconCount,
    'bannerCount': bannerCount,
  };
}

List<Map<String, Object?>> _railServersByNetworkDiagnostics(
  List<RailServerItem> servers,
) {
  final byNetworkId = <String, List<RailServerItem>>{};
  for (final server in servers) {
    byNetworkId
        .putIfAbsent(server.networkId, () => <RailServerItem>[])
        .add(server);
  }
  return [
    for (final entry in byNetworkId.entries)
      {
        'networkId': entry.key,
        'serverIds': _serverIdPreview(
          entry.value.map((server) => server.localServerId),
        ),
        ..._railServerMetadataCounts(entry.value),
      },
  ];
}

Map<String, int> _membershipStatusCounts(
  List<FederatedClientMembership> memberships,
) {
  final counts = <String, int>{};
  for (final membership in memberships) {
    counts.update(membership.status, (value) => value + 1, ifAbsent: () => 1);
  }
  return counts;
}

List<String> _targetNetworkIds(List<FederatedClientMembership> memberships) {
  return {
    for (final membership in memberships)
      networkIdFromApiOrigin(membership.targetApiOrigin),
  }.take(12).toList(growable: false);
}

List<Map<String, Object?>> _membershipServerDiagnostics(
  List<FederatedClientMembership> memberships,
) {
  return [
    for (final membership in memberships.take(24))
      {
        'targetNetworkId': networkIdFromApiOrigin(membership.targetApiOrigin),
        'targetServerId': membership.targetServerId,
        'status': membership.status,
        'hasServerName':
            membership.server.name != null &&
            membership.server.name!.trim().isNotEmpty,
        'hasIcon':
            membership.server.iconUrl != null &&
            membership.server.iconUrl!.trim().isNotEmpty,
        'hasBanner':
            membership.server.bannerUrl != null &&
            membership.server.bannerUrl!.trim().isNotEmpty,
      },
  ];
}

List<FederatedClientMembership> _dedupeFederatedMemberships(
  List<FederatedClientMembership> memberships,
) {
  final seen = <String>{};
  final deduped = <FederatedClientMembership>[];
  for (final membership in memberships) {
    final key = '${membership.targetApiOrigin}/${membership.targetServerId}';
    if (seen.add(key)) {
      deduped.add(membership);
    }
  }
  return List.unmodifiable(deduped);
}

Map<String, List<RailServerItem>> _cachedServersByNetworkId(
  List<RailServerItem> cachedRailServers,
) {
  final grouped = <String, List<RailServerItem>>{};
  for (final server in cachedRailServers) {
    grouped.putIfAbsent(server.networkId, () => <RailServerItem>[]).add(server);
  }
  return grouped;
}

List<NetworkProfile> _profilesWithActiveSession({
  required AuthSession activeSession,
  required List<NetworkProfile> savedProfiles,
  List<FederatedClientMembership> federatedMemberships = const [],
}) {
  final profilesByOrigin = <String, NetworkProfile>{};
  for (final profile in savedProfiles) {
    profilesByOrigin[normalizeBackendApiOrigin(profile.apiOrigin)] = profile;
  }
  final activeApiOrigin = normalizeBackendApiOrigin(activeSession.apiOrigin);
  profilesByOrigin.putIfAbsent(
    activeApiOrigin,
    () => NetworkProfile(
      name: _hostLabelFor(activeApiOrigin),
      apiOrigin: activeApiOrigin,
    ),
  );
  for (final membership in federatedMemberships) {
    profilesByOrigin.putIfAbsent(
      membership.targetApiOrigin,
      () => NetworkProfile(
        name: _hostLabelFor(membership.targetApiOrigin),
        apiOrigin: membership.targetApiOrigin,
      ),
    );
  }

  return profilesByOrigin.values.toList(growable: false);
}

Map<String, List<RailServerItem>> _federatedServersByNetworkId(
  List<FederatedClientMembership> memberships,
) {
  final grouped = <String, List<RailServerItem>>{};
  for (final membership in memberships) {
    final networkId = networkIdFromApiOrigin(membership.targetApiOrigin);
    final server = RailServerItem(
      networkId: networkId,
      localServerId: membership.targetServerId,
      name:
          membership.server.name ??
          '${_hostLabelFor(membership.targetApiOrigin)} server',
      iconUrl: membership.server.iconUrl,
      bannerUrl: membership.server.bannerUrl,
      mediaPolicy: ServerMediaPolicy.fromOrigins(
        apiOrigin: membership.targetApiOrigin,
      ),
    );
    grouped.putIfAbsent(networkId, () => <RailServerItem>[]).add(server);
  }
  return grouped;
}

Map<String, List<FederatedClientMembership>> _federatedMembershipsByNetworkId(
  List<FederatedClientMembership> memberships,
) {
  final grouped = <String, List<FederatedClientMembership>>{};
  for (final membership in memberships) {
    grouped
        .putIfAbsent(
          networkIdFromApiOrigin(membership.targetApiOrigin),
          () => <FederatedClientMembership>[],
        )
        .add(membership);
  }
  return grouped;
}

List<RailServerItem> _railServersFor({
  required NetworkProfile profile,
  required List<ServerSettingsServer> servers,
  required ServerMediaPolicy mediaPolicy,
}) {
  return [
    for (final server in servers)
      RailServerItem.fromServer(
        networkId: profile.networkId,
        server: server,
        mediaPolicy: mediaPolicy,
      ),
  ];
}

List<RailServerItem> _federatedScopedRailServers({
  required List<RailServerItem> liveServers,
  required List<RailServerItem> federatedServers,
}) {
  if (federatedServers.isEmpty) {
    return const <RailServerItem>[];
  }

  final liveServersById = {
    for (final server in liveServers) server.localServerId: server,
  };
  return [
    for (final server in federatedServers)
      liveServersById[server.localServerId] ?? server,
  ];
}

List<RailServerItem> _federatedActiveRailServers({
  required NetworkProfile profile,
  required List<ServerSettingsServer> activeServers,
  required ServerMediaPolicy mediaPolicy,
  required List<RailServerItem> federatedServers,
  required List<RailServerItem> cachedServers,
}) {
  final liveServers = _railServersFor(
    profile: profile,
    servers: activeServers,
    mediaPolicy: mediaPolicy,
  );
  if (liveServers.isNotEmpty) {
    if (federatedServers.isEmpty) {
      return liveServers;
    }
    return _federatedScopedRailServers(
      liveServers: liveServers,
      federatedServers: federatedServers,
    );
  }

  final cached = _availableCachedServers(
    profile: profile,
    cachedServers: cachedServers,
  );
  if (cached.isNotEmpty) {
    return cached;
  }
  return const <RailServerItem>[];
}

List<RailServerItem> _stableRailServerOrder({
  required List<RailServerItem> servers,
  required List<RailServerItem> cachedServers,
}) {
  if (servers.length < 2 || cachedServers.isEmpty) {
    return servers;
  }
  final serversByScopedId = {
    for (final server in servers) server.scopedServerId: server,
  };
  final seen = <String>{};
  final ordered = <RailServerItem>[];
  for (final cachedServer in cachedServers) {
    final server = serversByScopedId[cachedServer.scopedServerId];
    if (server != null && seen.add(server.scopedServerId)) {
      ordered.add(server);
    }
  }
  for (final server in servers) {
    if (seen.add(server.scopedServerId)) {
      ordered.add(server);
    }
  }
  return ordered;
}

List<RailServerItem> _unavailableCachedServers({
  required NetworkProfile profile,
  required List<RailServerItem> cachedServers,
}) {
  return [
    for (final server in cachedServers)
      if (sameWorkspaceNetworkId(server.networkId, profile.networkId))
        server.copyWith(networkId: profile.networkId, isUnavailable: true),
  ];
}

List<RailServerItem> _availableCachedServers({
  required NetworkProfile profile,
  required List<RailServerItem> cachedServers,
}) {
  return [
    for (final server in cachedServers)
      if (sameWorkspaceNetworkId(server.networkId, profile.networkId))
        server.copyWith(networkId: profile.networkId, isUnavailable: false),
  ];
}

RailNetworkMode _modeFor(
  NetworkProfile profile,
  Map<String, String> instanceModesByApiOrigin,
  Set<String> federatedNetworkIds,
) {
  if (profile.isOfficial) {
    return RailNetworkMode.official;
  }
  if (federatedNetworkIds.contains(profile.networkId)) {
    return RailNetworkMode.federated;
  }
  final mode = instanceModesByApiOrigin[profile.apiOrigin]?.toLowerCase();
  return switch (mode) {
    'standalone' => RailNetworkMode.standalone,
    'linked' => RailNetworkMode.linked,
    'federated' => RailNetworkMode.federated,
    _ => RailNetworkMode.unknown,
  };
}

String _hostLabelFor(String apiOrigin) {
  try {
    return Uri.parse(normalizeBackendApiOrigin(apiOrigin)).host;
  } on AuthException {
    return 'Saved Network';
  }
}
