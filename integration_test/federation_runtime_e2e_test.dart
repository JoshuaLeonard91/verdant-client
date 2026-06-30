import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:verdant_flutter/features/auth/auth_credentials.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/auth/network_profile_store.dart';
import 'package:verdant_flutter/features/auth/auth_service.dart';
import 'package:verdant_flutter/features/auth/instance_identity.dart';
import 'package:verdant_flutter/features/auth/instance_identity_service.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_models.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_service.dart';
import 'package:verdant_flutter/features/workspace/shared/inactive_backend_runtime.dart';
import 'package:verdant_flutter/features/workspace/shared/sync_summary_service.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/federated_invite_service.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/federated_membership_service.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const enabledFlag = String.fromEnvironment('VERDANT_FEDERATION_E2E');
  const enabled = enabledFlag == '1' || enabledFlag == 'true';
  const backendOrigins = String.fromEnvironment('VERDANT_E2E_BACKEND_ORIGINS');
  const backendOriginsFile = String.fromEnvironment(
    'VERDANT_E2E_BACKENDS_FILE',
  );

  testWidgets('federation runtime uses real client services end to end', (
    tester,
  ) async {
    if (!enabled) {
      markTestSkipped(
        'Set VERDANT_FEDERATION_E2E=true through '
        'clients/flutter-client/scripts/flutter-federation-e2e.ps1 to run the '
        'live two-backend client E2E.',
      );
      return;
    }

    final resolvedOrigins = await _resolveBackendOrigins(
      backendOrigins: backendOrigins,
      backendOriginsFile: backendOriginsFile,
    );
    expect(resolvedOrigins, hasLength(greaterThanOrEqualTo(2)));

    final authService = HttpAuthService();
    final credentialStore = _MemoryCredentialStore();
    final readerCredentialStore = _MemoryCredentialStore();
    final backendA = resolvedOrigins[0];
    final backendB = resolvedOrigins[1];
    final networkId = networkIdFromApiOrigin(backendA);
    final backendBNetworkId = networkIdFromApiOrigin(backendB);

    // no official relay: backend A and backend B are explicit test origins, and
    // the Flutter client constructs per-origin services instead of sending a
    // forged networkId or routing through the official backend.
    expect(backendA, isNot(equals(backendB)));
    expect(networkId, startsWith('origin:'));
    expect(backendBNetworkId, startsWith('origin:'));

    final identityManifestService = HttpInstanceIdentityManifestService();
    final identityStore = InstanceIdentityStore(
      storage: MemoryNetworkProfileStorage(),
    );
    addTearDown(identityManifestService.close);
    await _verifyManifestIdentities(
      origins: resolvedOrigins,
      manifestService: identityManifestService,
      identityStore: identityStore,
    );

    final sessionA = await _loginOrRegister(
      authService,
      apiOrigin: backendA,
      role: 'owner-a',
    );
    final sessionB = await _loginOrRegister(
      authService,
      apiOrigin: backendB,
      role: 'owner-b',
    );
    final readerSessionA = await _loginOrRegister(
      authService,
      apiOrigin: backendA,
      role: 'reader-a',
    );
    final readerSessionB = await _loginOrRegister(
      authService,
      apiOrigin: backendB,
      role: 'reader-b',
    );
    await credentialStore.save(sessionA.credentials);
    await credentialStore.save(sessionB.credentials);
    await readerCredentialStore.save(readerSessionA.credentials);
    await readerCredentialStore.save(readerSessionB.credentials);

    final serverService = ServerSettingsService(
      apiOrigin: backendA,
      credentialStore: credentialStore,
      authService: authService,
    );
    final readerServerService = ServerSettingsService(
      apiOrigin: backendA,
      credentialStore: readerCredentialStore,
      authService: authService,
    );
    final backendBServerService = ServerSettingsService(
      apiOrigin: backendB,
      credentialStore: credentialStore,
      authService: authService,
    );
    final backendBReaderServerService = ServerSettingsService(
      apiOrigin: backendB,
      credentialStore: readerCredentialStore,
      authService: authService,
    );
    final realtimeService = VerdantDirectMessagesService(
      apiOrigin: backendA,
      credentialStore: credentialStore,
      authService: authService,
    );
    final backendBOwnerRealtimeService = VerdantDirectMessagesService(
      apiOrigin: backendB,
      credentialStore: credentialStore,
      authService: authService,
    );
    final readerDmService = VerdantDirectMessagesService(
      apiOrigin: backendA,
      credentialStore: readerCredentialStore,
      authService: authService,
    );
    final readerRuntimeAService = VerdantDirectMessagesService(
      apiOrigin: backendA,
      credentialStore: readerCredentialStore,
      authService: authService,
    );
    final readerRuntimeBService = VerdantDirectMessagesService(
      apiOrigin: backendB,
      credentialStore: readerCredentialStore,
      authService: authService,
    );
    final syncSummaryClient = HttpSyncSummaryClient(
      credentialStore: readerCredentialStore,
    );

    addTearDown(serverService.close);
    addTearDown(readerServerService.close);
    addTearDown(backendBServerService.close);
    addTearDown(backendBReaderServerService.close);
    addTearDown(realtimeService.close);
    addTearDown(backendBOwnerRealtimeService.close);
    addTearDown(readerDmService.close);
    addTearDown(readerRuntimeAService.close);
    addTearDown(readerRuntimeBService.close);
    addTearDown(syncSummaryClient.close);
    addTearDown(authService.close);

    final fixture = await _tryResolveServerFixture(serverService);
    if (fixture == null) {
      final targetFixture = await _tryResolveServerFixture(
        backendBServerService,
      );
      if (targetFixture == null) {
        throw StateError(
          'At least one live E2E backend must allow disposable server '
          'creation or provide a writable fixture.',
        );
      }
      final targetInvite = await _withLiveRateLimitRetry(
        () => backendBServerService.createInvite(
          serverId: targetFixture.server.id,
          maxUses: 2,
          expiresIn: const Duration(hours: 1),
        ),
      );
      expect(targetInvite.inviteCode, isNotNull);
      final federatedJoinCompleted = await _tryExerciseFederatedInviteJoin(
        homeApiOrigin: backendA,
        homeSession: sessionA,
        targetApiOrigin: backendB,
        targetServerId: targetFixture.server.id,
        targetInviteCode: targetInvite.inviteCode!,
        identityManifestService: identityManifestService,
        authService: authService,
      );
      if (!federatedJoinCompleted) {
        debugPrint(
          'Skipping official-home federated invite join because the live home '
          'backend requires email verification for disposable accounts.',
        );
        return;
      }
      debugPrint(
        'Skipping writable-home runtime branch because the home backend '
        'requires email verification for disposable server creation.',
      );
      return;
    }
    final serverId = fixture.server.id;
    final channelId = fixture.channel.id;
    final localId = channelId;
    final readerUserId = readerSessionA.session.user.id;

    final invite = await _withLiveRateLimitRetry(
      () => serverService.createInvite(
        serverId: serverId,
        maxUses: 2,
        expiresIn: const Duration(hours: 1),
      ),
    );
    final inviteCode = invite.inviteCode;
    expect(inviteCode, isNotNull);
    await _withLiveRateLimitRetry(
      () => readerServerService.acceptInvite(code: inviteCode!),
    );

    final servers = await _withLiveRateLimitRetry(serverService.listServers);
    expect(servers.map((server) => server.id), contains(serverId));

    final server = servers.firstWhere((server) => server.id == serverId);
    final settings = await _withLiveRateLimitRetry(
      () => serverService.loadServerSettings(server),
    );
    expect(_channelIds(settings), contains(channelId));

    final ready = Completer<void>();
    final messageSeen = Completer<DirectMessagesMessageCreateEvent>();
    Object? lastRealtimeError;
    StackTrace? lastRealtimeStackTrace;
    final subscription = realtimeService
        .connectRealtime(
          currentUserId:
              sessionA.credentials.user?.id ?? sessionA.session.user.id,
          currentUserName:
              sessionA.credentials.user?.username ??
              sessionA.session.user.username,
          currentUserInitials:
              sessionA.credentials.user?.initials ??
              sessionA.session.user.initials,
          currentUserStatus: 'online',
        )
        .listen(
          (event) {
            if (event is DirectMessagesSnapshotEvent && !ready.isCompleted) {
              ready.complete();
            }
            if (event is DirectMessagesMessageCreateEvent &&
                event.channelId == '$networkId/$localId' &&
                !messageSeen.isCompleted) {
              messageSeen.complete(event);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            lastRealtimeError = error;
            lastRealtimeStackTrace = stackTrace;
          },
        );
    addTearDown(subscription.cancel);

    await _waitForCompleter(
      ready,
      timeout: const Duration(seconds: 20),
      lastError: () => lastRealtimeError,
      lastStackTrace: () => lastRealtimeStackTrace,
    );
    await realtimeService.focusServer(serverId: serverId);
    await realtimeService.focusChannel(channelId: channelId);

    final marker =
        'flutter federation e2e ${DateTime.now().toUtc().microsecondsSinceEpoch} @$readerUserId';
    await realtimeService.sendTypingStart(channelId: channelId);
    await realtimeService.sendChannelMessage(
      channelId: channelId,
      content: marker,
    );

    final created = await _waitForCompleter(
      messageSeen,
      timeout: const Duration(seconds: 30),
      lastError: () => lastRealtimeError,
      lastStackTrace: () => lastRealtimeStackTrace,
    );
    expect(created.message.body, marker);
    expect(created.channelId, '$networkId/$localId');

    await realtimeService.addReaction(
      channelId: channelId,
      messageId: created.message.id,
      emoji: 'smoke',
    );

    final dmConversation = await _withLiveRateLimitRetry(
      () => readerDmService.openDirectMessage(
        localUserId: sessionA.session.user.id,
        currentUserId: readerUserId,
      ),
    );
    final dmMarker =
        'flutter federation summary dm ${DateTime.now().toUtc().microsecondsSinceEpoch}';
    await realtimeService.sendChannelMessage(
      channelId: dmConversation.localChannelId,
      content: '$dmMarker @$readerUserId',
    );

    final backendAProfile = JoinedBackendRuntimeProfile(
      networkId: networkId,
      apiOrigin: backendA,
      authenticated: true,
      available: true,
    );
    final summary = await _waitForSyncSummary(
      syncSummaryClient,
      backendAProfile,
      matches: (summary) =>
          summary.servers.any((server) => server.serverId == serverId) &&
          summary.dms.any(
            (dm) => dm.channelId == dmConversation.localChannelId,
          ),
    );
    expect(summary.requiresReconnect, isFalse);
    expect(
      summary.servers.any((server) => server.serverId == serverId),
      isTrue,
    );
    final serverSummary = summary.servers.firstWhere(
      (server) => server.serverId == serverId,
    );
    expect(serverSummary.unreadCount, greaterThanOrEqualTo(1));
    expect(serverSummary.mentionCount, greaterThanOrEqualTo(1));
    expect(
      summary.dms.any((dm) => dm.channelId == dmConversation.localChannelId),
      isTrue,
    );
    final dmSummary = summary.dms.firstWhere(
      (dm) => dm.channelId == dmConversation.localChannelId,
    );
    expect(dmSummary.unreadCount, greaterThanOrEqualTo(1));
    expect(dmSummary.mentionCount, greaterThanOrEqualTo(1));

    final messages = await _withLiveRateLimitRetry(
      () => serverService.loadChannelMessages(
        channelId: channelId,
        currentUserId: sessionA.session.user.id,
        limit: 10,
      ),
    );
    expect(messages.any((message) => message.body == marker), isTrue);

    final backendBFixture = await _tryResolveServerFixture(
      backendBServerService,
    );
    if (backendBFixture == null) {
      // The manifest/trust smoke already covered backend B. Some public live
      // backends require verified email before disposable accounts can create
      // servers, so keep the server-owned runtime branch limited to the
      // writable backend instead of hardcoding operator credentials.
      debugPrint(
        'Skipping backend B runtime branch because the live backend requires '
        'email verification for disposable server creation.',
      );
      return;
    }
    final backendBServerId = backendBFixture.server.id;
    final backendBChannelId = backendBFixture.channel.id;
    final backendBReaderUserId = readerSessionB.session.user.id;
    final backendBInvite = await _withLiveRateLimitRetry(
      () => backendBServerService.createInvite(
        serverId: backendBServerId,
        maxUses: 2,
        expiresIn: const Duration(hours: 1),
      ),
    );
    expect(backendBInvite.inviteCode, isNotNull);
    final federatedJoinCompleted = await _tryExerciseFederatedInviteJoin(
      homeApiOrigin: backendA,
      homeSession: sessionA,
      targetApiOrigin: backendB,
      targetServerId: backendBServerId,
      targetInviteCode: backendBInvite.inviteCode!,
      identityManifestService: identityManifestService,
      authService: authService,
    );
    if (!federatedJoinCompleted) {
      debugPrint(
        'Skipping federated invite join because the live home backend '
        'requires email verification for disposable accounts.',
      );
      return;
    }
    await _withLiveRateLimitRetry(
      () => backendBReaderServerService.acceptInvite(
        code: backendBInvite.inviteCode!,
      ),
    );

    final backendBOwnerSubscription = await _connectRealtimeUntilReady(
      backendBOwnerRealtimeService,
      sessionB,
    );
    addTearDown(backendBOwnerSubscription.cancel);
    await backendBOwnerRealtimeService.focusServer(serverId: backendBServerId);
    await backendBOwnerRealtimeService.focusChannel(
      channelId: backendBChannelId,
    );
    final inactiveMarker =
        'flutter inactive lifecycle ${DateTime.now().toUtc().microsecondsSinceEpoch} @$backendBReaderUserId';
    await backendBOwnerRealtimeService.sendChannelMessage(
      channelId: backendBChannelId,
      content: inactiveMarker,
    );

    final runtimeDelegate = _RuntimeProbeDelegate(
      syncSummaryClient: syncSummaryClient,
      entries: {
        networkId: _RuntimeProbeEntry(
          service: readerRuntimeAService,
          session: readerSessionA,
        ),
        backendBNetworkId: _RuntimeProbeEntry(
          service: readerRuntimeBService,
          session: readerSessionB,
        ),
      },
    );
    final runtimeManager = InactiveBackendRuntimeManager(
      delegate: runtimeDelegate,
      idleTimeout: const Duration(milliseconds: 1),
      coldTimeout: const Duration(minutes: 30),
      warmPollInterval: const Duration(seconds: 15),
      coldPollInterval: const Duration(minutes: 2),
    );
    final now = DateTime.now().toUtc();
    runtimeManager
      ..register(
        JoinedBackendRuntimeProfile(
          networkId: networkId,
          apiOrigin: backendA,
          authenticated: true,
          available: true,
        ),
        now: now,
      )
      ..register(
        JoinedBackendRuntimeProfile(
          networkId: backendBNetworkId,
          apiOrigin: backendB,
          authenticated: true,
          available: true,
        ),
        now: now,
      );

    await runtimeManager.setActiveNetwork(backendBNetworkId, now: now);
    await runtimeManager.setActiveNetwork(
      networkId,
      now: now.add(const Duration(milliseconds: 1)),
    );
    await runtimeManager.advance(now.add(const Duration(milliseconds: 5)));

    expect(runtimeDelegate.disconnects, contains(backendBNetworkId));
    final inactiveSummary = runtimeManager.summaryOf(backendBNetworkId);
    expect(inactiveSummary, isNotNull);
    expect(
      inactiveSummary!.servers.any(
        (server) =>
            server.serverId == backendBServerId &&
            server.unreadCount >= 1 &&
            server.mentionCount >= 1,
      ),
      isTrue,
    );

    await runtimeManager.setActiveNetwork(
      backendBNetworkId,
      now: now.add(const Duration(milliseconds: 10)),
    );
    expect(
      runtimeDelegate.connects
          .where((network) => network == backendBNetworkId)
          .length,
      greaterThanOrEqualTo(2),
    );
    final hydratedMessages = await _withLiveRateLimitRetry(
      () => backendBReaderServerService.loadChannelMessages(
        channelId: backendBChannelId,
        currentUserId: backendBReaderUserId,
        limit: 10,
      ),
    );
    expect(
      hydratedMessages.any((message) => message.body == inactiveMarker),
      isTrue,
    );
  });
}

Future<void> _exerciseFederatedInviteJoin({
  required String homeApiOrigin,
  required AuthLoginSuccess homeSession,
  required String targetApiOrigin,
  required String targetServerId,
  required String targetInviteCode,
  required InstanceIdentityManifestService identityManifestService,
  required AuthService authService,
}) async {
  final targetManifest = await identityManifestService.fetchManifest(
    apiOrigin: targetApiOrigin,
  );
  expect(targetManifest, isNotNull);
  final targetPeerId = targetManifest!.instanceId;
  expect(targetPeerId, isNotEmpty);

  final federatedCredentialStore = _MemoryCredentialStore();
  await federatedCredentialStore.save(
    homeSession.credentials.withUser(homeSession.session.user),
  );
  // federated invite does not require target credentials: this must stay empty
  // until the signed capability claim returns a target-scoped federated token.
  final targetCredentialBeforeJoin = await federatedCredentialStore.read(
    targetApiOrigin,
  );
  expect(targetCredentialBeforeJoin, isNull);

  final previewService = HttpFederatedInvitePreviewService();
  final joinService = HttpFederatedInviteJoinService(
    apiOrigin: homeApiOrigin,
    credentialStore: federatedCredentialStore,
    authService: authService,
    capabilityPollAttempts: 60,
    capabilityPollDelay: const Duration(seconds: 1),
  );
  final targetServerService = ServerSettingsService(
    apiOrigin: targetApiOrigin,
    credentialStore: federatedCredentialStore,
    authService: authService,
  );
  try {
    final preview = await _withLiveRateLimitRetry(
      () => previewService.previewInvite(
        apiOrigin: targetApiOrigin,
        code: targetInviteCode,
      ),
    );
    expect(preview.federated, isTrue);
    expect(preview.instanceId, targetPeerId);
    expect(preview.server.id, targetServerId);

    final result = await _withLiveRateLimitRetry(
      () => joinService.joinInvite(
        targetApiOrigin: targetApiOrigin,
        targetPeerId: targetPeerId,
        serverId: targetServerId,
        code: targetInviteCode,
      ),
    );
    expect(result.credentialIssued, isTrue);

    final targetCredentialAfterJoin = await federatedCredentialStore.read(
      targetApiOrigin,
    );
    expect(targetCredentialAfterJoin, isNotNull);
    expect(targetCredentialAfterJoin!.kind, AuthCredentialKind.federatedClient);
    expect(targetCredentialAfterJoin.sessionToken, isEmpty);

    final targetServers = await _withLiveRateLimitRetry(
      targetServerService.listServers,
    );
    expect(targetServers.map((server) => server.id), contains(targetServerId));

    await _exerciseFederatedMembershipPersistenceAfterCredentialLoss(
      homeApiOrigin: homeApiOrigin,
      homeSession: homeSession,
      targetApiOrigin: targetApiOrigin,
      targetPeerId: targetPeerId,
      targetServerId: targetServerId,
      authService: authService,
    );
  } finally {
    previewService.close();
    joinService.close();
    targetServerService.close();
  }
}

Future<void> _exerciseFederatedMembershipPersistenceAfterCredentialLoss({
  required String homeApiOrigin,
  required AuthLoginSuccess homeSession,
  required String targetApiOrigin,
  required String targetPeerId,
  required String targetServerId,
  required AuthService authService,
}) async {
  final restartCredentialStore = _MemoryCredentialStore();
  await restartCredentialStore.save(
    homeSession.credentials.withUser(homeSession.session.user),
  );

  final targetCredentialAfterRestart = await restartCredentialStore.read(
    targetApiOrigin,
  );
  expect(
    targetCredentialAfterRestart,
    isNull,
    reason: 'federated membership restart does not keep target credentials',
  );

  final membershipService = HttpFederatedMembershipService(
    apiOrigin: homeApiOrigin,
    credentialStore: restartCredentialStore,
    authService: authService,
  );
  final targetServerService = ServerSettingsService(
    apiOrigin: targetApiOrigin,
    credentialStore: restartCredentialStore,
    authService: authService,
  );
  try {
    final memberships = await _withLiveRateLimitRetry(
      membershipService.listMemberships,
    );
    final membership = memberships.firstWhere(
      (candidate) =>
          candidate.targetApiOrigin ==
              normalizeBackendApiOrigin(targetApiOrigin) &&
          candidate.targetPeerId == targetPeerId &&
          candidate.targetServerId == targetServerId,
      orElse: () => throw StateError(
        'Durable federated membership was missing after restart',
      ),
    );
    expect(membership.server.id, targetServerId);
    expect(membership.targetServerId, targetServerId);
    expect(membership.isActive, isTrue);

    final capability = await _waitForFederatedMembershipCapability(
      membershipService,
      membershipId: membership.id,
      expectedServerId: targetServerId,
    );
    await restartCredentialStore.save(
      capability.toCredential(targetApiOrigin: membership.targetApiOrigin),
    );

    final targetCredentialAfterRemint = await restartCredentialStore.read(
      targetApiOrigin,
    );
    expect(targetCredentialAfterRemint, isNotNull);
    expect(
      targetCredentialAfterRemint?.kind,
      AuthCredentialKind.federatedClient,
      reason: 'credentialKind, AuthCredentialKind.federatedClient',
    );
    expect(targetCredentialAfterRemint?.sessionToken, isEmpty);

    final targetServersAfterRemint = await _withLiveRateLimitRetry(
      targetServerService.listServers,
    );
    expect(
      targetServersAfterRemint.map((server) => server.id),
      contains(targetServerId),
    );
  } finally {
    membershipService.close();
    targetServerService.close();
  }
}

Future<FederatedMembershipCapabilityResult>
_waitForFederatedMembershipCapability(
  HttpFederatedMembershipService service, {
  required String membershipId,
  required String expectedServerId,
  int maxAttempts = 60,
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
    final capability = await _withLiveRateLimitRetry(
      () => service.refreshCapability(membershipId: membershipId),
    );
    if (capability.status == FederatedMembershipCapabilityStatus.pending) {
      await Future<void>.delayed(const Duration(seconds: 1));
      continue;
    }
    expect(capability.serverId, expectedServerId);
    return capability;
  }
  throw StateError('Timed out waiting for federated membership capability');
}

Future<bool> _tryExerciseFederatedInviteJoin({
  required String homeApiOrigin,
  required AuthLoginSuccess homeSession,
  required String targetApiOrigin,
  required String targetServerId,
  required String targetInviteCode,
  required InstanceIdentityManifestService identityManifestService,
  required AuthService authService,
}) async {
  try {
    await _exerciseFederatedInviteJoin(
      homeApiOrigin: homeApiOrigin,
      homeSession: homeSession,
      targetApiOrigin: targetApiOrigin,
      targetServerId: targetServerId,
      targetInviteCode: targetInviteCode,
      identityManifestService: identityManifestService,
      authService: authService,
    );
    return true;
  } on FederatedInviteJoinException catch (error) {
    if (_isEmailVerificationRequired(error.message)) {
      return false;
    }
    rethrow;
  }
}

Future<void> _verifyManifestIdentities({
  required List<String> origins,
  required InstanceIdentityManifestService manifestService,
  required InstanceIdentityStore identityStore,
}) async {
  for (final origin in origins) {
    final manifest = await manifestService.fetchManifest(apiOrigin: origin);
    expect(
      manifest,
      isNotNull,
      reason: '$origin must expose federation manifest',
    );
    final identity = await identityStore.recordSelfReportedManifest(
      connectedApiOrigin: origin,
      manifest: manifest!,
    );
    expect(identity.apiOrigin, normalizeBackendApiOrigin(origin));
    expect(identity.networkId, networkIdFromApiOrigin(origin));
    expect(identity.instanceId, isNotEmpty);
    expect(
      identity.warnings,
      isNot(contains(InstanceIdentityWarning.apiOriginMismatch)),
    );
    if (identity.apiOrigin == officialApiOrigin) {
      expect(identity.trustSource, InstanceTrustSource.pinnedOfficial);
      expect(identity.trustStatus, InstanceTrustStatus.official);
    } else {
      expect(identity.trustSource, InstanceTrustSource.selfReported);
      expect(
        identity.trustStatus,
        anyOf(InstanceTrustStatus.unverified, InstanceTrustStatus.warning),
      );
    }
  }
}

Future<List<String>> _resolveBackendOrigins({
  required String backendOrigins,
  required String backendOriginsFile,
}) async {
  final fromList = _normalizeOriginList(_splitOriginList(backendOrigins));
  if (fromList.length >= 2) {
    return fromList;
  }

  if (backendOriginsFile.trim().isNotEmpty) {
    final fromFile = _normalizeOriginList(
      await _readBackendOriginsFile(backendOriginsFile),
    );
    if (fromFile.length >= 2) {
      return fromFile;
    }
  }

  final saved = await NetworkProfileStore().load();
  final fromProfiles = _normalizeOriginList([
    for (final profile in saved.profiles)
      if (!profile.isOfficial) profile.apiOrigin,
    for (final profile in saved.profiles)
      if (profile.isOfficial) profile.apiOrigin,
  ]);
  if (fromProfiles.length >= 2) {
    return fromProfiles;
  }

  throw StateError(
    'Live federation E2E needs at least two backend profiles. Add another '
    'backend in the Flutter client, pass VERDANT_E2E_BACKEND_ORIGINS, or pass '
    'VERDANT_E2E_BACKENDS_FILE. No public API origins are hardcoded by this '
    'harness.',
  );
}

List<String> _splitOriginList(String raw) {
  return raw
      .split(RegExp(r'[\n,;]+'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

Future<List<String>> _readBackendOriginsFile(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw StateError('Live federation E2E backend file was not found: $path');
  }
  final raw = await file.readAsString();
  final decoded = jsonDecode(raw);
  if (decoded is List<Object?>) {
    return [
      for (final item in decoded)
        if (item is String) item,
    ];
  }
  if (decoded is Map<String, Object?>) {
    final origins = decoded['origins'];
    if (origins is List<Object?>) {
      return [
        for (final item in origins)
          if (item is String) item,
      ];
    }
    final backends = decoded['backends'];
    if (backends is List<Object?>) {
      return [
        for (final item in backends)
          if (item is Map<String, Object?> && item['apiOrigin'] is String)
            item['apiOrigin']! as String,
      ];
    }
  }
  throw StateError(
    'Live federation E2E backend file must be a JSON string list, '
    '{"origins":[...]}, or {"backends":[{"apiOrigin":"..."}]}.',
  );
}

List<String> _normalizeOriginList(Iterable<String> values) {
  final seen = <String>{};
  final origins = <String>[];
  for (final value in values) {
    if (value.trim().isEmpty) {
      continue;
    }
    final normalized = normalizeBackendApiOrigin(value);
    if (seen.add(normalized)) {
      origins.add(normalized);
    }
  }
  return origins;
}

Future<AuthLoginSuccess> _loginOrRegister(
  HttpAuthService authService, {
  required String apiOrigin,
  required String role,
}) async {
  final store = FlutterSecureAuthCredentialStore(
    keyPrefix: 'federation-e2e.$role',
  );
  final stored = await store.read(apiOrigin);
  if (stored != null && stored.user != null && stored.hasSessionToken) {
    try {
      final refresh = await _withLiveRateLimitRetry(
        () => authService.refreshSession(
          apiOrigin: apiOrigin,
          sessionToken: stored.sessionToken,
        ),
      );
      final refreshed = AuthCredentialBundle(
        apiOrigin: stored.normalizedApiOrigin,
        accessToken: refresh.accessToken,
        sessionToken: refresh.sessionTokenOr(stored.sessionToken),
        user: stored.user,
      );
      await store.save(refreshed);
      return AuthLoginSuccess(
        session: AuthSession.inMemory(
          apiOrigin: refreshed.normalizedApiOrigin,
          accessToken: refreshed.accessToken,
          sessionToken: refreshed.sessionToken,
          user: stored.user!,
        ),
        credentials: refreshed,
        accountRestored: true,
      );
    } on AuthRefreshException catch (error) {
      if (error.shouldClearCredentials) {
        await store.clear(apiOrigin);
      } else {
        rethrow;
      }
    }
  }

  final credentials = _LiveAccountCredentials.forBackend(apiOrigin: apiOrigin);
  final outcome = await _withLiveRateLimitRetry(
    () => authService.register(
      apiOrigin: apiOrigin,
      email: credentials.email,
      password: credentials.password,
      termsAccepted: true,
      privacyAccepted: true,
    ),
  );
  final success = _expectLoginSuccess(apiOrigin, outcome);
  await store.save(success.credentials.withUser(success.session.user));
  return success;
}

AuthLoginSuccess _expectLoginSuccess(
  String apiOrigin,
  AuthLoginOutcome result,
) {
  if (result is AuthLoginSuccess) {
    return result;
  }
  if (result is AuthLoginRequiresVerification) {
    throw StateError(
      'Live E2E account for $apiOrigin requires email verification. '
      'Use a public test backend that allows temporary account registration.',
    );
  }
  if (result is AuthLoginRequiresTwoFactor) {
    throw StateError(
      'Live E2E account for $apiOrigin requires two-factor authentication. '
      'Use a public test backend that allows temporary account registration.',
    );
  }
  throw StateError('Live E2E account for $apiOrigin did not complete login');
}

Future<StreamSubscription<DirectMessagesRealtimeEvent>>
_connectRealtimeUntilReady(
  VerdantDirectMessagesService service,
  AuthLoginSuccess session,
) async {
  final ready = Completer<void>();
  Object? lastRealtimeError;
  StackTrace? lastRealtimeStackTrace;
  final subscription = service
      .connectRealtime(
        currentUserId: session.credentials.user?.id ?? session.session.user.id,
        currentUserName:
            session.credentials.user?.username ?? session.session.user.username,
        currentUserInitials:
            session.credentials.user?.initials ?? session.session.user.initials,
        currentUserStatus: 'online',
      )
      .listen(
        (event) {
          if (event is DirectMessagesSnapshotEvent && !ready.isCompleted) {
            ready.complete();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          lastRealtimeError = error;
          lastRealtimeStackTrace = stackTrace;
        },
      );
  try {
    await _waitForCompleter(
      ready,
      timeout: const Duration(seconds: 20),
      lastError: () => lastRealtimeError,
      lastStackTrace: () => lastRealtimeStackTrace,
    );
  } catch (_) {
    await subscription.cancel();
    rethrow;
  }
  return subscription;
}

Future<T> _waitForCompleter<T>(
  Completer<T> completer, {
  required Duration timeout,
  required Object? Function() lastError,
  required StackTrace? Function() lastStackTrace,
}) async {
  try {
    return await completer.future.timeout(timeout);
  } on TimeoutException catch (error, stackTrace) {
    final recordedError = lastError();
    if (recordedError != null) {
      Error.throwWithStackTrace(recordedError, lastStackTrace() ?? stackTrace);
    }
    throw TimeoutException(
      'Timed out waiting for federation realtime condition',
      error.duration,
    );
  }
}

Future<({ServerSettingsServer server, ServerSettingsChannelSeed channel})>
_resolveServerFixture(ServerSettingsService serverService) async {
  final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
  final server = await _withLiveRateLimitRetry(
    () => serverService.createServer(name: 'Flutter Federation E2E $stamp'),
  );
  final settings = await _withLiveRateLimitRetry(
    () => serverService.loadServerSettings(server),
  );
  final channel = settings.channels.firstWhere(
    (channel) => channel.type == 0,
    orElse: () => throw StateError(
      'Auto-provisioned live E2E server did not include a text channel',
    ),
  );
  return (server: server, channel: channel);
}

Future<({ServerSettingsServer server, ServerSettingsChannelSeed channel})?>
_tryResolveServerFixture(ServerSettingsService serverService) async {
  try {
    return await _resolveServerFixture(serverService);
  } on ServerSettingsException catch (error) {
    if (_isEmailVerificationRequired(error.message)) {
      return null;
    }
    rethrow;
  }
}

Future<T> _withLiveRateLimitRetry<T>(
  Future<T> Function() operation, {
  int maxAttempts = 4,
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      return await operation();
    } on DirectMessagesException catch (error) {
      if (!_isLiveRateLimit(error.message) || attempt == maxAttempts) {
        rethrow;
      }
    } on ServerSettingsException catch (error) {
      if (!_isLiveRateLimit(error.message) || attempt == maxAttempts) {
        rethrow;
      }
    } on SyncSummaryClientException catch (error) {
      if (!_isLiveRateLimit(error.message) || attempt == maxAttempts) {
        rethrow;
      }
    } on AuthException catch (error) {
      if (!_isLiveRateLimit(error.message) || attempt == maxAttempts) {
        rethrow;
      }
    } on FederatedInvitePreviewException catch (error) {
      if (!_isLiveRateLimit(error.message) || attempt == maxAttempts) {
        rethrow;
      }
    } on FederatedInviteJoinException catch (error) {
      if (!_isLiveRateLimit(error.message) || attempt == maxAttempts) {
        rethrow;
      }
    } on FederatedMembershipException catch (error) {
      if (!_isLiveRateLimit(error.message) || attempt == maxAttempts) {
        rethrow;
      }
    }
    await Future<void>.delayed(Duration(seconds: attempt * 5));
  }
  throw StateError('Live E2E retry loop exhausted unexpectedly');
}

Future<SyncSummarySnapshot> _waitForSyncSummary(
  HttpSyncSummaryClient client,
  JoinedBackendRuntimeProfile profile, {
  required bool Function(SyncSummarySnapshot summary) matches,
  int maxAttempts = 20,
}) async {
  SyncSummarySnapshot? lastSummary;
  for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
    final summary = await _withLiveRateLimitRetry(
      () => client.fetchSummary(profile),
    );
    if (matches(summary)) {
      return summary;
    }
    lastSummary = summary;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  throw StateError(
    'Timed out waiting for sync summary condition '
    '(servers=${lastSummary?.servers.length ?? 0}, '
    'dms=${lastSummary?.dms.length ?? 0})',
  );
}

bool _isLiveRateLimit(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('rate limited') || normalized.contains('too fast');
}

bool _isEmailVerificationRequired(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('verify your email') ||
      normalized.contains('email verification');
}

final class _RuntimeProbeEntry {
  _RuntimeProbeEntry({required this.service, required this.session});

  final VerdantDirectMessagesService service;
  final AuthLoginSuccess session;
  StreamSubscription<DirectMessagesRealtimeEvent>? subscription;
}

final class _RuntimeProbeDelegate implements InactiveBackendRuntimeDelegate {
  _RuntimeProbeDelegate({
    required this.syncSummaryClient,
    required this.entries,
  });

  final SyncSummaryClient syncSummaryClient;
  final Map<String, _RuntimeProbeEntry> entries;
  final connects = <String>[];
  final disconnects = <String>[];

  @override
  Future<void> connect(JoinedBackendRuntimeProfile profile) async {
    final entry = entries[profile.networkId];
    if (entry == null) {
      throw StateError('Missing runtime entry for ${profile.networkId}');
    }
    await entry.subscription?.cancel();
    entry.subscription = await _connectRealtimeUntilReady(
      entry.service,
      entry.session,
    );
    connects.add(profile.networkId);
  }

  @override
  Future<void> disconnect(JoinedBackendRuntimeProfile profile) async {
    final entry = entries[profile.networkId];
    if (entry == null) {
      throw StateError('Missing runtime entry for ${profile.networkId}');
    }
    await entry.subscription?.cancel();
    entry.subscription = null;
    disconnects.add(profile.networkId);
  }

  @override
  Future<SyncSummarySnapshot> fetchSummary(
    JoinedBackendRuntimeProfile profile, {
    String? since,
  }) {
    return _withLiveRateLimitRetry(
      () => syncSummaryClient.fetchSummary(profile, since: since),
    );
  }
}

final class _LiveAccountCredentials {
  const _LiveAccountCredentials({required this.email, required this.password});

  factory _LiveAccountCredentials.forBackend({required String apiOrigin}) {
    final host = Uri.parse(normalizeBackendApiOrigin(apiOrigin)).host
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .toLowerCase();
    final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    return _LiveAccountCredentials(
      email: 'flutter-fed-e2e-$host-$stamp@${_e2eEmailDomain()}',
      password: 'Vd!flutter-fed-e2e-$stamp-a9',
    );
  }

  final String email;
  final String password;
}

String _e2eEmailDomain() {
  const configured = String.fromEnvironment(
    'VERDANT_E2E_EMAIL_DOMAIN',
    defaultValue: 'verdant-e2e.dev',
  );
  final domain = configured.trim().toLowerCase();
  final label = r'[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?';
  final pattern = RegExp('^$label(?:\\.$label)+\$');
  if (!pattern.hasMatch(domain)) {
    throw StateError('VERDANT_E2E_EMAIL_DOMAIN must be a routable domain');
  }
  return domain;
}

Set<String> _channelIds(ServerSettingsData settings) {
  return {for (final channel in settings.channels) channel.id};
}

final class _MemoryCredentialStore implements AuthCredentialStore {
  final _credentials = <String, AuthCredentialBundle>{};

  @override
  Future<void> save(AuthCredentialBundle credentials) async {
    _credentials[credentials.normalizedApiOrigin] = credentials;
  }

  @override
  Future<AuthCredentialBundle?> read(String apiOrigin) async {
    return _credentials[normalizeBackendApiOrigin(apiOrigin)];
  }

  @override
  Future<bool> contains(String apiOrigin) async {
    return _credentials.containsKey(normalizeBackendApiOrigin(apiOrigin));
  }

  @override
  Future<void> clear(String apiOrigin) async {
    _credentials.remove(normalizeBackendApiOrigin(apiOrigin));
  }
}
