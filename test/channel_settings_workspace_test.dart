import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/channel_settings_workspace/channel_settings_workspace.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  testWidgets(
    'channel settings exposes overview slowmode and permissions tabs',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: ChannelSettingsWorkspace(
              data: _settingsData,
              channel: _settingsData.channels.first,
              initialTab: ChannelSettingsTabId.overview,
              repository: const _ReadOnlyChannelSettingsRepository(),
              onChannelUpdated: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('channel-settings-workspace')),
        findsOneWidget,
      );
      expect(find.text('#general'), findsOneWidget);
      expect(find.text('Channel Settings'), findsOneWidget);
      expect(find.text('Channel Name'), findsOneWidget);
      expect(find.text('Channel Topic'), findsOneWidget);
      expect(find.text('Slowmode'), findsOneWidget);
      expect(find.text('10 seconds'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('channel-settings-tab-permissions')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Permission Overrides'), findsOneWidget);
      expect(find.text('@everyone'), findsOneWidget);
      expect(find.text('Moderator'), findsOneWidget);
      expect(find.text('View Channel'), findsWidgets);
      expect(find.text('Send Messages'), findsWidgets);
      expect(find.text('Connect'), findsWidgets);
    },
  );

  testWidgets(
    'channel overview saves through the channel settings repository',
    (tester) async {
      final repository = _RecordingChannelSettingsRepository();
      final updated = <ServerSettingsChannelSeed>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: ChannelSettingsWorkspace(
              data: _settingsData,
              channel: _settingsData.channels.first,
              initialTab: ChannelSettingsTabId.overview,
              repository: repository,
              onChannelUpdated: updated.add,
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('channel-settings-name-field')),
        'announcements',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('channel-slowmode-60')),
      );
      await tester.tap(find.byKey(const ValueKey('channel-slowmode-60')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('channel-settings-save-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('channel-settings-save-button')),
      );
      await tester.pumpAndSettle();

      expect(repository.updatedChannelIds, ['general']);
      expect(repository.patches.single.name, 'announcements');
      expect(repository.patches.single.slowmodeSeconds, 60);
      expect(updated.single.name, 'announcements');
      expect(updated.single.slowmodeSeconds, 60);
    },
  );
}

const _settingsData = ServerSettingsData(
  networkId: 'official',
  server: ServerSettingsServer(
    id: 'server-1',
    name: 'Verdant',
    ownerId: '42',
    voiceBitrate: 64000,
    bannerOffsetY: 50,
    memberCount: 3,
    large: false,
    createdAt: '2026-06-01T10:00:00Z',
    updatedAt: '2026-06-01T10:00:00Z',
  ),
  channels: [
    ServerSettingsChannelSeed(
      id: 'general',
      name: 'general',
      topic: 'Start here.',
      readOnly: false,
      slowmodeSeconds: 10,
    ),
  ],
  emojis: [],
  invites: [],
  roles: [
    ServerSettingsListItemSeed(
      id: 'everyone',
      title: '@everyone',
      subtitle: 'Default access',
      permissions: 12291,
      position: 0,
    ),
    ServerSettingsListItemSeed(
      id: 'mod',
      title: 'Moderator',
      subtitle: 'Can manage channels',
      permissions: 1063,
      position: 1,
      accent: Color(0xFF7CFFDE),
    ),
  ],
  members: [],
  auditEvents: [],
  feeds: [],
  bots: [],
);

final class _ReadOnlyChannelSettingsRepository
    implements ChannelSettingsRepository {
  const _ReadOnlyChannelSettingsRepository();

  @override
  Future<ServerSettingsChannelSeed> updateChannel({
    required String channelId,
    required ChannelSettingsPatch patch,
  }) {
    throw const ServerSettingsException('Channel updates are unavailable');
  }
}

final class _RecordingChannelSettingsRepository
    implements ChannelSettingsRepository {
  final updatedChannelIds = <String>[];
  final patches = <ChannelSettingsPatch>[];

  @override
  Future<ServerSettingsChannelSeed> updateChannel({
    required String channelId,
    required ChannelSettingsPatch patch,
  }) async {
    updatedChannelIds.add(channelId);
    patches.add(patch);
    return _settingsData.channels.first.copyWith(
      name: patch.name ?? _settingsData.channels.first.name,
      topic: patch.topic == ChannelSettingsPatch.unset
          ? _settingsData.channels.first.topic
          : patch.topic as String?,
      readOnly: patch.readOnly ?? _settingsData.channels.first.readOnly,
      slowmodeSeconds:
          patch.slowmodeSeconds ?? _settingsData.channels.first.slowmodeSeconds,
    );
  }
}
