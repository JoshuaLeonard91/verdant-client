import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/bottom_rail_workspace/bottom_rail_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';
import 'package:verdant_flutter/features/workspace/shared/workspace_entitlements.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_context.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_sessions.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_workspace.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_preferences.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/workspace_accessibility_settings.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  group('UserSettingsSession', () {
    test('sorts the current session first then other sessions by activity', () {
      final sessions = sortUserSettingsSessions([
        UserSettingsSession.fromJson({
          'id': 'old',
          'isCurrent': false,
          'device': 'Firefox on Windows',
          'createdAt': '2026-06-15T10:00:00Z',
          'lastRefreshAt': '2026-06-15T10:05:00Z',
        }),
        UserSettingsSession.fromJson({
          'id': 'current',
          'isCurrent': true,
          'device': 'Verdant Desktop',
          'city': 'New York',
          'country': 'US',
          'createdAt': '2026-06-15T10:00:00Z',
          'lastRefreshAt': '2026-06-15T10:10:00Z',
        }),
        UserSettingsSession.fromJson({
          'id': 'recent',
          'isCurrent': false,
          'device': 'Chrome on Windows',
          'createdAt': '2026-06-15T10:00:00Z',
          'lastRefreshAt': '2026-06-15T10:20:00Z',
        }),
      ]);

      expect(sessions.map((session) => session.id), [
        'current',
        'recent',
        'old',
      ]);
      expect(sessions.first.locationLabel, 'New York, US');
    });

    test('ignores token-bearing response fields and redacts debug output', () {
      final session = UserSettingsSession.fromJson({
        'id': '1',
        'isCurrent': false,
        'device': 'Chrome on Windows',
        'createdAt': '2026-06-15T10:00:00Z',
        'lastRefreshAt': '2026-06-15T10:10:00Z',
        'accessToken': 'access-secret',
        'sessionToken': 'session-secret',
        'bearer': 'bearer-secret',
        'cookie': 'cookie-secret',
      });

      expect(session.id, '1');
      expect(session.toString(), isNot(contains('access-secret')));
      expect(session.toString(), isNot(contains('session-secret')));
      expect(session.toString(), isNot(contains('bearer-secret')));
      expect(session.toString(), isNot(contains('cookie-secret')));
    });

    test('parses fallback location fields and labels missing geo data', () {
      final session = UserSettingsSession.fromJson({
        'id': '1',
        'isCurrent': true,
        'device': 'Verdant Desktop',
        'createdAt': '2026-06-15T10:00:00Z',
        'lastRefreshAt': '2026-06-15T10:10:00Z',
        'last_city': 'Toronto',
        'last_country': 'CA',
      });

      final missingLocation = UserSettingsSession.fromJson({
        'id': '2',
        'isCurrent': false,
        'device': 'Chrome on Windows',
        'createdAt': '2026-06-15T10:00:00Z',
        'lastRefreshAt': '2026-06-15T10:10:00Z',
      });

      expect(session.locationLabel, 'Toronto, CA');
      expect(missingLocation.locationLabel, isNull);
      expect(missingLocation.locationStatusLabel, 'Location unavailable');
    });
  });

  group('UserSettingsSessionsController', () {
    test(
      'loads sessions through the repository and exposes sorted state',
      () async {
        final repository = _RecordingUserSettingsRepository(
          sessions: [
            UserSettingsSession(
              id: 'other',
              isCurrent: false,
              device: 'Chrome on Windows',
              createdAt: DateTime.utc(2026, 6, 15, 10),
              lastRefreshAt: DateTime.utc(2026, 6, 15, 10, 20),
            ),
            UserSettingsSession(
              id: 'current',
              isCurrent: true,
              device: 'Verdant Desktop',
              createdAt: DateTime.utc(2026, 6, 15, 10),
              lastRefreshAt: DateTime.utc(2026, 6, 15, 10, 5),
            ),
          ],
        );
        final controller = UserSettingsSessionsController(
          repository: repository,
        );

        await controller.load();

        expect(repository.loaded, isTrue);
        expect(controller.loading, isFalse);
        expect(controller.error, isNull);
        expect(controller.sessions.map((session) => session.id), [
          'current',
          'other',
        ]);
      },
    );

    test('revoke removes only the selected non-current session', () async {
      final repository = _RecordingUserSettingsRepository(
        sessions: [
          UserSettingsSession(
            id: 'current',
            isCurrent: true,
            device: 'Verdant Desktop',
            createdAt: DateTime.utc(2026, 6, 15, 10),
            lastRefreshAt: DateTime.utc(2026, 6, 15, 10, 5),
          ),
          UserSettingsSession(
            id: 'other',
            isCurrent: false,
            device: 'Chrome on Windows',
            createdAt: DateTime.utc(2026, 6, 15, 10),
            lastRefreshAt: DateTime.utc(2026, 6, 15, 10, 20),
          ),
        ],
      );
      final controller = UserSettingsSessionsController(repository: repository);

      await controller.load();
      await controller.revokeSession('other');

      expect(repository.revokedSessionIds, ['other']);
      expect(controller.sessions.map((session) => session.id), ['current']);
    });

    test('ignores delayed load completion after disposal', () async {
      final repository = _DelayedUserSettingsSessionsRepository();
      final controller = UserSettingsSessionsController(repository: repository);

      final future = controller.load();

      expect(repository.listRequested, isTrue);
      controller.dispose();
      repository.completeSessions([
        UserSettingsSession(
          id: 'current',
          isCurrent: true,
          device: 'Verdant Desktop',
          createdAt: DateTime.utc(2026, 6, 15, 10),
          lastRefreshAt: DateTime.utc(2026, 6, 15, 10, 5),
        ),
      ]);

      await expectLater(future, completes);
    });

    test('ignores delayed revoke completion after disposal', () async {
      final repository = _DelayedUserSettingsSessionsRepository();
      final controller = UserSettingsSessionsController(repository: repository);

      final future = controller.revokeSession('other');

      expect(repository.revokedSessionId, 'other');
      controller.dispose();
      repository.completeRevoke();

      await expectLater(future, completes);
    });

    test('ignores delayed revoke-all completion after disposal', () async {
      final repository = _DelayedUserSettingsSessionsRepository();
      final controller = UserSettingsSessionsController(repository: repository);

      final future = controller.revokeAllOtherSessions();

      expect(repository.revokeAllRequested, isTrue);
      controller.dispose();
      repository.completeRevokeAll();

      await expectLater(future, completes);
    });
  });

  testWidgets('Sessions settings renders backend sessions', (tester) async {
    final repository = _RecordingUserSettingsRepository(
      sessions: [
        UserSettingsSession(
          id: 'current',
          isCurrent: true,
          device: 'Verdant Desktop',
          city: 'Buffalo',
          country: 'US',
          createdAt: DateTime.utc(2026, 6, 15, 10),
          lastRefreshAt: DateTime.utc(2026, 6, 15, 10, 5),
        ),
        UserSettingsSession(
          id: 'other',
          isCurrent: false,
          device: 'Chrome on Windows',
          createdAt: DateTime.utc(2026, 6, 15, 10),
          lastRefreshAt: DateTime.utc(2026, 6, 15, 10, 20),
        ),
      ],
    );

    await tester.pumpWidget(_userSettingsHarness(repository));
    await tester.tap(
      find.byKey(const ValueKey('user-settings-category-sessions')),
    );
    await tester.pumpAndSettle();

    expect(repository.loaded, isTrue);
    expect(find.text('Verdant Desktop'), findsOneWidget);
    expect(find.text('Current Session'), findsOneWidget);
    expect(find.text('Chrome on Windows'), findsOneWidget);
    expect(find.text('OTHER SESSIONS (1)'), findsOneWidget);
  });

  testWidgets('User settings stays on active network sessions', (tester) async {
    const selfHostOrigin = 'https://api-test.pryzmapp.com';
    final officialRepository = _RecordingUserSettingsRepository(
      sessions: [
        UserSettingsSession(
          id: 'official-current',
          isCurrent: true,
          device: 'Official Desktop',
          city: 'Buffalo',
          country: 'US',
          createdAt: DateTime.utc(2026, 6, 15, 10),
          lastRefreshAt: DateTime.utc(2026, 6, 15, 10, 5),
        ),
      ],
    );
    final selfHostRepository = _RecordingUserSettingsRepository(
      sessions: [
        UserSettingsSession(
          id: 'selfhost-current',
          isCurrent: true,
          device: 'Self-host Desktop',
          city: 'Toronto',
          country: 'CA',
          createdAt: DateTime.utc(2026, 6, 15, 10),
          lastRefreshAt: DateTime.utc(2026, 6, 15, 10, 15),
        ),
      ],
    );
    final officialNetworkId = networkIdFromApiOrigin(officialApiOrigin);
    final selfHostNetworkId = networkIdFromApiOrigin(selfHostOrigin);

    await tester.pumpWidget(
      _userSettingsHarness(
        officialRepository,
        settingsContexts: [
          UserSettingsContext(
            networkId: officialNetworkId,
            networkName: 'Official',
            apiOrigin: officialApiOrigin,
            currentUser: _joshyUser,
            currentUserMedia: null,
            mediaPolicy: _mediaPolicyFor(officialApiOrigin),
            entitlements: const WorkspaceEntitlements.disabled(),
            repository: officialRepository,
            signedIn: true,
          ),
          UserSettingsContext(
            networkId: selfHostNetworkId,
            networkName: 'SH-Test',
            apiOrigin: selfHostOrigin,
            currentUser: _selfHostUser,
            currentUserMedia: null,
            mediaPolicy: _mediaPolicyFor(selfHostOrigin),
            entitlements: const WorkspaceEntitlements.disabled(),
            repository: selfHostRepository,
            signedIn: true,
          ),
        ],
      ),
    );

    expect(find.text('@joshy'), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey('user-settings-category-sessions')),
    );
    await tester.pumpAndSettle();

    expect(officialRepository.loaded, isTrue);
    expect(selfHostRepository.loaded, isFalse);
    expect(find.text('Official Desktop'), findsOneWidget);

    expect(
      find.byKey(const ValueKey('user-settings-context-selector')),
      findsNothing,
    );
    expect(find.text('SH-Test'), findsNothing);
    expect(selfHostRepository.loaded, isFalse);
    expect(find.text('Self-host Desktop'), findsNothing);
  });
}

Widget _userSettingsHarness(
  UserSettingsRepository repository, {
  List<UserSettingsContext> settingsContexts = const [],
}) {
  final mediaPolicy = _mediaPolicyFor(officialApiOrigin);
  final networkId = networkIdFromApiOrigin(officialApiOrigin);
  return MaterialApp(
    theme: buildVerdantTheme(),
    home: SizedBox(
      width: 900,
      height: 720,
      child: UserSettingsWorkspace(
        currentUser: _joshyUser,
        currentUserMedia: null,
        mediaPolicy: mediaPolicy,
        entitlements: const WorkspaceEntitlements.disabled(),
        repository: repository,
        settingsContexts: settingsContexts,
        accessibilitySettings: const WorkspaceAccessibilitySettings(),
        preferencesStore: UserSettingsPreferencesStore.memory(),
        networkRecords: [
          RailNetworkRecord(
            networkId: networkId,
            networkName: 'Official',
            mode: RailNetworkMode.official,
            availability: RailNetworkAvailability.available,
            authStatus: RailNetworkAuthStatus.authenticated,
            apiOrigin: officialApiOrigin,
            currentUserId: '$networkId/42',
            currentUsername: 'joshy',
            usernameSet: true,
          ),
        ],
        activeNetworkId: networkId,
        homeNetworkId: networkId,
        onPreferencesChanged: (_) {},
        onAccessibilityChanged: (_) {},
        onProfileUpdated: () async {},
        onSetNetworkUsername: (_) {},
        onRetryNetwork: (_) {},
        onRemoveNetwork: (_) {},
        onClose: () {},
      ),
    ),
  );
}

ServerMediaPolicy _mediaPolicyFor(String apiOrigin) {
  return ServerMediaPolicy(
    allowedOrigins: {apiOrigin},
    allowLocalHttp: false,
    apiOrigin: apiOrigin,
  );
}

const _joshyUser = VerdantUser(
  id: '42',
  username: 'joshy',
  displayName: 'Joshy',
  email: 'joshy@example.com',
  status: 'online',
  usernameSet: true,
  emailVerified: true,
  totpEnabled: false,
);

const _selfHostUser = VerdantUser(
  id: '87',
  username: 'selfhost-joshy',
  displayName: 'Self-host Joshy',
  email: 'selfhost@example.com',
  status: 'online',
  usernameSet: true,
  emailVerified: true,
  totpEnabled: false,
);

final class _RecordingUserSettingsRepository implements UserSettingsRepository {
  _RecordingUserSettingsRepository({required this._sessions});

  List<UserSettingsSession> _sessions;
  final revokedSessionIds = <String>[];
  var loaded = false;

  @override
  Future<List<UserSettingsSession>> listSessions() async {
    loaded = true;
    return _sessions;
  }

  @override
  Future<void> revokeSession({required String sessionId}) async {
    revokedSessionIds.add(sessionId);
    _sessions = [
      for (final session in _sessions)
        if (session.id != sessionId) session,
    ];
  }

  @override
  Future<void> revokeAllOtherSessions() async {
    _sessions = [
      for (final session in _sessions)
        if (session.isCurrent) session,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _DelayedUserSettingsSessionsRepository
    implements UserSettingsSessionsRepository {
  final _sessionsCompleter = Completer<List<UserSettingsSession>>();
  final _revokeCompleter = Completer<void>();
  final _revokeAllCompleter = Completer<void>();
  var listRequested = false;
  String? revokedSessionId;
  var revokeAllRequested = false;

  @override
  Future<List<UserSettingsSession>> listSessions() {
    listRequested = true;
    return _sessionsCompleter.future;
  }

  void completeSessions(List<UserSettingsSession> sessions) {
    _sessionsCompleter.complete(sessions);
  }

  @override
  Future<void> revokeSession({required String sessionId}) {
    revokedSessionId = sessionId;
    return _revokeCompleter.future;
  }

  void completeRevoke() {
    _revokeCompleter.complete();
  }

  @override
  Future<void> revokeAllOtherSessions() {
    revokeAllRequested = true;
    return _revokeAllCompleter.future;
  }

  void completeRevokeAll() {
    _revokeAllCompleter.complete();
  }
}
