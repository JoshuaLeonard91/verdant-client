import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/app/verdant_app_profile.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_preferences.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_preferences.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/workspace_accessibility_settings.dart';

void main() {
  test('defaults to the primary app profile', () {
    final profile = VerdantAppProfile.fromArgs(const []);

    expect(profile, VerdantAppProfile.primary);
    expect(profile.isPrimary, isTrue);
    expect(profile.storageNamespace, isEmpty);
    expect(profile.windowTitle, 'Verdant');
    expect(profile.titleBarBadgeLabel, isNull);
  });

  test('parses secondary test profile from entrypoint args', () {
    for (final args in const [
      ['--secondary'],
      ['--verdant-profile=secondary'],
      ['--verdant-profile', 'secondary'],
      ['--verdant-profile=test'],
    ]) {
      final profile = VerdantAppProfile.fromArgs(args);

      expect(profile, VerdantAppProfile.secondary);
      expect(profile.isPrimary, isFalse);
      expect(profile.storageNamespace, 'secondary');
      expect(profile.windowTitle, 'Verdant - Secondary Test Client');
      expect(profile.titleBarBadgeLabel, 'Secondary Test Client');
    }
  });

  test(
    'rejects unknown profile names instead of creating arbitrary storage',
    () {
      expect(
        () => VerdantAppProfile.fromArgs(const ['--verdant-profile=prod-copy']),
        throwsA(isA<ArgumentError>()),
      );
    },
  );

  test('secondary profile isolates non-secret local preferences', () async {
    final networkId = networkIdFromApiOrigin(officialApiOrigin);
    final dmStorage = MemoryDirectMessagesPreferenceStorage();
    final primaryDms = DirectMessagesPreferences(storage: dmStorage);
    final secondaryDms = DirectMessagesPreferences(
      storage: dmStorage,
      storageNamespace: VerdantAppProfile.secondary.storageNamespace,
    );
    await primaryDms.saveHiddenChannelIds(
      networkId: networkId,
      userId: '42',
      channelIds: {'$networkId/dm-primary'},
    );
    await secondaryDms.saveHiddenChannelIds(
      networkId: networkId,
      userId: '42',
      channelIds: {'$networkId/dm-secondary'},
    );
    await primaryDms.saveCurrentUserStatus(
      networkId: networkId,
      userId: '42',
      status: 'online',
    );
    await secondaryDms.saveCurrentUserStatus(
      networkId: networkId,
      userId: '42',
      status: 'dnd',
    );

    expect(
      await primaryDms.loadHiddenChannelIds(networkId: networkId, userId: '42'),
      {'$networkId/dm-primary'},
    );
    expect(
      await secondaryDms.loadHiddenChannelIds(
        networkId: networkId,
        userId: '42',
      ),
      {'$networkId/dm-secondary'},
    );
    expect(
      await primaryDms.loadCurrentUserStatus(
        networkId: networkId,
        userId: '42',
      ),
      'online',
    );
    expect(
      await secondaryDms.loadCurrentUserStatus(
        networkId: networkId,
        userId: '42',
      ),
      'dnd',
    );

    final userStorage = MemoryUserSettingsPreferencesStorage();
    final primaryUserSettings = UserSettingsPreferencesStore(
      storage: userStorage,
    );
    final secondaryUserSettings = UserSettingsPreferencesStore(
      storage: userStorage,
      storageNamespace: VerdantAppProfile.secondary.storageNamespace,
    );
    await primaryUserSettings.save(
      const UserSettingsPreferences(
        density: UserSettingsDensityPreference.compact,
        pushToTalk: false,
      ),
    );
    await secondaryUserSettings.save(
      const UserSettingsPreferences(
        density: UserSettingsDensityPreference.comfortable,
        pushToTalk: true,
      ),
    );
    expect(
      (await primaryUserSettings.load()).density,
      UserSettingsDensityPreference.compact,
    );
    expect((await primaryUserSettings.load()).pushToTalk, isFalse);
    expect(
      (await secondaryUserSettings.load()).density,
      UserSettingsDensityPreference.comfortable,
    );
    expect((await secondaryUserSettings.load()).pushToTalk, isTrue);

    final accessibilityStorage = MemoryWorkspaceAccessibilitySettingsStorage();
    final primaryAccessibility = WorkspaceAccessibilitySettingsStore(
      storage: accessibilityStorage,
    );
    final secondaryAccessibility = WorkspaceAccessibilitySettingsStore(
      storage: accessibilityStorage,
      storageNamespace: VerdantAppProfile.secondary.storageNamespace,
    );
    await primaryAccessibility.save(
      const WorkspaceAccessibilitySettings(textScaleFactor: 1.0),
    );
    await secondaryAccessibility.save(
      const WorkspaceAccessibilitySettings(textScaleFactor: 1.5),
    );
    expect((await primaryAccessibility.load()).textScaleFactor, 1.0);
    expect((await secondaryAccessibility.load()).textScaleFactor, 1.5);
  });
}
