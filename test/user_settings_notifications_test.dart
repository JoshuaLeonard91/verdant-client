import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/bottom_rail_workspace/bottom_rail_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';
import 'package:verdant_flutter/features/workspace/shared/workspace_entitlements.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_context.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_notification_sound.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_notifications.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_preferences.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_workspace.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/workspace_accessibility_settings.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  group('UserSettingsNotificationPreference', () {
    test('parses backend global target and ignores token-bearing fields', () {
      final preference = UserSettingsNotificationPreference.fromJson({
        'targetType': 'global',
        'targetId': '0',
        'muted': false,
        'desktopEnabled': true,
        'token': 'lk_secret_token',
        'bearer': 'secret_bearer',
      });

      expect(preference.targetType, UserSettingsNotificationTargetType.global);
      expect(preference.targetId, '0');
      expect(preference.muted, isFalse);
      expect(preference.desktopEnabled, isTrue);
      expect(preference.toString(), isNot(contains('lk_secret_token')));
      expect(preference.toString(), isNot(contains('secret_bearer')));
    });
  });

  group('UserSettingsNotificationsController', () {
    test(
      'reports unavailable when the selected network has no repository',
      () async {
        final controller = UserSettingsNotificationsController(
          repository: null,
        );

        await controller.load();

        expect(controller.loading, isFalse);
        expect(controller.error, contains('unavailable'));
        expect(
          controller.globalPreference,
          UserSettingsNotificationPreference.globalDefault,
        );
      },
    );

    test(
      'saves global desktop preference through the selected repository',
      () async {
        final repository = _RecordingUserSettingsRepository(
          notificationPreferences: [
            UserSettingsNotificationPreference.globalDefault.copyWith(
              desktopEnabled: true,
              muted: false,
            ),
          ],
        );
        final controller = UserSettingsNotificationsController(
          repository: repository,
        );

        await controller.load();
        await controller.updateGlobalPreference(desktopEnabled: false);

        expect(repository.loadedNotifications, isTrue);
        expect(repository.savedNotifications, hasLength(1));
        expect(
          repository.savedNotifications.single.targetType,
          UserSettingsNotificationTargetType.global,
        );
        expect(repository.savedNotifications.single.desktopEnabled, isFalse);
        expect(controller.globalPreference.desktopEnabled, isFalse);
      },
    );
  });

  testWidgets('Notifications settings stays on the active network context', (
    tester,
  ) async {
    const selfHostOrigin = 'https://api-test.pryzmapp.com';
    final officialRepository = _RecordingUserSettingsRepository(
      notificationPreferences: [
        UserSettingsNotificationPreference.globalDefault.copyWith(
          desktopEnabled: true,
          muted: false,
        ),
      ],
    );
    final selfHostRepository = _RecordingUserSettingsRepository(
      notificationPreferences: [
        UserSettingsNotificationPreference.globalDefault.copyWith(
          desktopEnabled: false,
          muted: true,
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

    await tester.tap(
      find.byKey(const ValueKey('user-settings-category-notifications')),
    );
    await tester.pumpAndSettle();

    expect(officialRepository.loadedNotifications, isTrue);
    expect(selfHostRepository.loadedNotifications, isFalse);
    expect(
      tester
          .widget<Switch>(
            find.descendant(
              of: find.byKey(
                const ValueKey('user-settings-desktop-notifications'),
              ),
              matching: find.byType(Switch),
            ),
          )
          .value,
      isTrue,
    );

    expect(
      find.byKey(const ValueKey('user-settings-context-selector')),
      findsNothing,
    );
    expect(find.text('SH-Test'), findsNothing);
    expect(selfHostRepository.loadedNotifications, isFalse);
    expect(
      tester
          .widget<Switch>(
            find.descendant(
              of: find.byKey(
                const ValueKey('user-settings-desktop-notifications'),
              ),
              matching: find.byType(Switch),
            ),
          )
          .value,
      isTrue,
    );
  });

  testWidgets('Notifications settings exposes a local sound preview action', (
    tester,
  ) async {
    final repository = _RecordingUserSettingsRepository();
    final soundPreview = _RecordingNotificationSoundPreview();

    await tester.pumpWidget(
      _userSettingsHarness(repository, notificationSoundPreview: soundPreview),
    );

    await tester.tap(
      find.byKey(const ValueKey('user-settings-category-notifications')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('user-settings-play-notification-sound')),
      findsOneWidget,
    );
    expect(find.text('Backend'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('user-settings-play-notification-sound')),
    );
    await tester.pump();

    expect(soundPreview.playCount, 1);
  });

  testWidgets('Network settings labels a self-host session as home', (
    tester,
  ) async {
    final repository = _RecordingUserSettingsRepository();
    const selfHostOrigin = 'https://api-home.example.com';
    final homeNetworkId = networkIdFromApiOrigin(selfHostOrigin);

    await tester.pumpWidget(
      _userSettingsHarness(
        repository,
        apiOrigin: selfHostOrigin,
        networkName: 'Self-host Verdant',
        networkMode: RailNetworkMode.standalone,
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('user-settings-category-network')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home Network'), findsWidgets);
    expect(find.text('Official'), findsNothing);
    expect(find.text('Standalone'), findsNothing);
    expect(find.text('Federated Network'), findsNothing);
    expect(find.text(selfHostOrigin), findsNothing);

    await tester.tap(
      find.byKey(ValueKey('user-settings-network-row-$homeNetworkId')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Network Origin'), findsOneWidget);
    expect(find.text(selfHostOrigin), findsOneWidget);
    expect(
      find.byKey(ValueKey('user-settings-network-remove-$homeNetworkId')),
      findsNothing,
    );
  });

  test('Windows notification sound loads WinMM from System32', () {
    if (defaultTargetPlatform != TargetPlatform.windows) {
      return;
    }

    final libraryPath = debugWindowsNotificationSoundLibraryPath();
    expect(libraryPath, isNot(equals('winmm.dll')));
    expect(libraryPath.toLowerCase(), endsWith(r'\winmm.dll'));
    expect(libraryPath.toLowerCase(), contains(r'\system32\'));
  });
}

Widget _userSettingsHarness(
  UserSettingsRepository repository, {
  List<UserSettingsContext> settingsContexts = const [],
  UserSettingsNotificationSoundPreview? notificationSoundPreview,
  String apiOrigin = officialApiOrigin,
  String networkName = 'Official',
  RailNetworkMode networkMode = RailNetworkMode.official,
}) {
  final mediaPolicy = _mediaPolicyFor(apiOrigin);
  final networkId = networkIdFromApiOrigin(apiOrigin);
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
            networkName: networkName,
            mode: networkMode,
            availability: RailNetworkAvailability.available,
            authStatus: RailNetworkAuthStatus.authenticated,
            apiOrigin: apiOrigin,
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
        notificationSoundPreview:
            notificationSoundPreview ??
            const SystemUserSettingsNotificationSoundPreview(),
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
  _RecordingUserSettingsRepository({this.notificationPreferences = const []});

  List<UserSettingsNotificationPreference> notificationPreferences;
  final savedNotifications = <UserSettingsNotificationPreference>[];
  var loadedNotifications = false;

  @override
  Future<List<UserSettingsNotificationPreference>>
  listNotificationPreferences() async {
    loadedNotifications = true;
    return notificationPreferences;
  }

  @override
  Future<void> saveNotificationPreference({
    required UserSettingsNotificationPreference preference,
  }) async {
    savedNotifications.add(preference);
    notificationPreferences = [
      for (final existing in notificationPreferences)
        if (!existing.hasSameTarget(preference)) existing,
      preference,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RecordingNotificationSoundPreview
    implements UserSettingsNotificationSoundPreview {
  var playCount = 0;

  @override
  Future<void> play() async {
    playCount += 1;
  }
}
