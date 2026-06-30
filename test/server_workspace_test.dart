import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_image.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_workspace/server_workspace.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  setUp(() {
    debugSetServerMediaWidgetLoader((_, {required policy, maxBytes}) async {
      return Uint8List.fromList(_transparentPngBytes);
    });
  });

  tearDown(() => debugSetServerMediaWidgetLoader(null));

  testWidgets(
    'channel panel exposes selected unread mention and disabled states',
    (tester) async {
      final selected = <String>[];
      final voiceSelected = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: ServerWorkspace(
              seed: _seed(
                channels: const [
                  ChannelSeed(id: 'general', name: 'general', selected: true),
                  ChannelSeed(id: 'changes', name: 'change-logs', unread: true),
                  ChannelSeed(id: 'alerts', name: 'alerts', mentionCount: 2),
                  ChannelSeed(id: 'locked', name: 'staff', disabled: true),
                  ChannelSeed(
                    id: 'voice-general',
                    name: 'General Voice',
                    type: 3,
                  ),
                ],
              ),
              width: 360,
              currentUserName: 'boji',
              currentUserInitials: 'BO',
              onLogout: () {},
              onOpenServerSettings: () {},
              onOpenUserSettings: () {},
              onSelectTextChannel: (channel) => selected.add(channel.id),
              onSelectVoiceChannel: (channel) => voiceSelected.add(channel.id),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('server-channel-selected-general')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('server-channel-unread-changes')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('server-channel-mention-alerts')),
        findsOneWidget,
      );
      expect(find.text('2'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('server-channel-disabled-locked')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('server-channel-changes')));
      await tester.tap(find.byKey(const ValueKey('server-channel-locked')));
      await tester.tap(
        find.byKey(const ValueKey('server-voice-channel-voice-general')),
      );
      await tester.pumpAndSettle();

      expect(selected, ['changes']);
      expect(voiceSelected, ['voice-general']);
    },
  );

  testWidgets(
    'channel rows expose a scoped right-click settings menu for managers',
    (tester) async {
      final overviewOpened = <String>[];
      final permissionsOpened = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: ServerWorkspace(
              seed: _seed(
                channels: const [
                  ChannelSeed(id: 'general', name: 'general', selected: true),
                ],
              ),
              width: 360,
              currentUserName: 'boji',
              currentUserInitials: 'BO',
              onLogout: () {},
              onOpenServerSettings: () {},
              onOpenUserSettings: () {},
              onSelectTextChannel: (_) {},
              onOpenChannelSettings: (channel) =>
                  overviewOpened.add(channel.id),
              onOpenChannelPermissions: (channel) =>
                  permissionsOpened.add(channel.id),
            ),
          ),
        ),
      );

      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('server-channel-general'))),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('user-context-menu-item-channel-settings')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('user-context-menu-item-channel-permissions'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('user-context-menu-item-copy-channel-id')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('user-context-menu-item-channel-permissions'),
        ),
      );
      await tester.pumpAndSettle();

      expect(overviewOpened, isEmpty);
      expect(permissionsOpened, ['general']);
    },
  );

  testWidgets('channel panel renders visible announcement feeds before text', (
    tester,
  ) async {
    final selectedFeeds = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerWorkspace(
            seed: _seed(
              channels: const [
                ChannelSeed(id: 'general', name: 'general', selected: true),
              ],
              serverSettings: WorkspaceSeed.sample.serverSettings.copyWith(
                feeds: const [
                  ServerSettingsListItemSeed(
                    id: 'feed-1',
                    title: 'Announcements',
                    subtitle: 'Release notes and maintenance windows',
                    feedIcon: 'AN',
                  ),
                  ServerSettingsListItemSeed(
                    id: 'feed-2',
                    title: 'Change Logs',
                    subtitle: 'Client and server release notes',
                  ),
                ],
              ),
            ),
            width: 360,
            currentUserName: 'boji',
            currentUserInitials: 'BO',
            onLogout: () {},
            onOpenServerSettings: () {},
            onOpenUserSettings: () {},
            onSelectTextChannel: (_) {},
            onSelectFeed: (feed) => selectedFeeds.add(feed.id ?? feed.title),
          ),
        ),
      ),
    );

    final feedsHeading = tester.getTopLeft(find.text('FEEDS'));
    final textHeading = tester.getTopLeft(find.text('TEXT CHANNELS'));
    expect(feedsHeading.dy, lessThan(textHeading.dy));
    expect(
      find.byKey(const ValueKey('server-feed-channel-row-feed-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('server-feed-channel-name-announcements')),
      findsOneWidget,
    );
    expect(find.text('Change Logs'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('server-feed-channel-row-feed-1')),
    );
    await tester.pumpAndSettle();

    expect(selectedFeeds, ['feed-1']);
  });

  testWidgets(
    'channel context menu keeps non-managers to safe copy-only actions',
    (tester) async {
      final clipboardWrites = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardWrites.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: ServerWorkspace(
              seed: _seed(
                channels: const [
                  ChannelSeed(id: 'general', name: 'general', selected: true),
                ],
                serverSettings: WorkspaceSeed.sample.serverSettings.copyWith(
                  canManageServer: false,
                  canManageChannels: false,
                  canManageRoles: false,
                ),
              ),
              width: 360,
              currentUserName: 'boji',
              currentUserInitials: 'BO',
              onLogout: () {},
              onOpenServerSettings: () {},
              onOpenUserSettings: () {},
              onSelectTextChannel: (_) {},
              onOpenChannelSettings: (_) {},
              onOpenChannelPermissions: (_) {},
            ),
          ),
        ),
      );

      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('server-channel-general'))),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('user-context-menu-item-channel-settings')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('user-context-menu-item-channel-permissions'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('user-context-menu-item-copy-channel-id')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('user-context-menu-item-copy-channel-id')),
      );
      await tester.pumpAndSettle();

      expect(clipboardWrites, hasLength(1));
      expect(clipboardWrites.single, containsPair('text', 'general'));
    },
  );

  testWidgets('channel panel exposes stable name keys for driver probes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerWorkspace(
            seed: _seed(
              channels: const [
                ChannelSeed(id: 'c-1', name: 'bot-test'),
                ChannelSeed(id: 'c-2', name: 'change-logs'),
                ChannelSeed(id: 'voice-1', name: 'General Voice', type: 3),
              ],
            ),
            width: 360,
            currentUserName: 'boji',
            currentUserInitials: 'BO',
            onLogout: () {},
            onOpenServerSettings: () {},
            onOpenUserSettings: () {},
            onSelectTextChannel: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('server-channel-name-bot-test')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('server-channel-name-change-logs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('server-voice-channel-name-general-voice')),
      findsOneWidget,
    );
  });

  testWidgets('channel panel does not render categories as text channels', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerWorkspace(
            seed: _seed(
              channels: const [
                ChannelSeed(id: 'category-chat', name: 'Chat', type: 1),
                ChannelSeed(id: 'general', name: 'general', selected: true),
                ChannelSeed(
                  id: 'voice-general',
                  name: 'General Voice',
                  type: 3,
                ),
              ],
            ),
            width: 360,
            currentUserName: 'boji',
            currentUserInitials: 'BO',
            onLogout: () {},
            onOpenServerSettings: () {},
            onOpenUserSettings: () {},
            onSelectTextChannel: (channel) => selected.add(channel.id),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('server-channel-category-chat')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('server-channel-general')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('server-channel-general')));
    await tester.pumpAndSettle();

    expect(selected, ['general']);
  });

  testWidgets(
    'current user identity opens a quick profile popover above panel',
    (tester) async {
      final clipboardWrites = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardWrites.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: ServerWorkspace(
              seed: _seed(
                channels: const [
                  ChannelSeed(id: 'general', name: 'general', selected: true),
                ],
                mediaPolicy: ServerMediaPolicy.fromOrigins(
                  apiOrigin: 'https://api.verdant.chat',
                ),
              ),
              width: 360,
              currentUserId: 'official/42',
              currentUserName: 'boji',
              currentUserInitials: 'BO',
              currentUserAvatarUrl:
                  'https://media.verdant.chat/server-icons/profile.webp',
              currentUserBannerUrl:
                  'https://media.verdant.chat/server-banners/profile.webp',
              onLogout: () {},
              onOpenServerSettings: () {},
              onOpenUserSettings: () {},
              onSelectTextChannel: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('current-user-profile-popover')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('workspace-current-user-profile-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('current-user-profile-popover')),
        findsOneWidget,
      );
      expect(find.text('boji'), findsWidgets);
      expect(find.text('Online'), findsWidgets);
      expect(
        find.byKey(const ValueKey('current-user-profile-status-current')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('current-user-profile-status-flyout')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('current-user-profile-edit-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('current-user-profile-copy-user-id-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('current-user-profile-avatar-media-root')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('current-user-profile-banner-media-root')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.upload_outlined), findsNothing);

      final profileAvatars = tester
          .widgetList<ServerMediaIcon>(find.byType(ServerMediaIcon))
          .where((icon) => icon.size == 72)
          .toList();
      expect(profileAvatars, hasLength(1));
      expect(profileAvatars.single.animate, isTrue);
      final profileBanners = tester
          .widgetList<CroppedServerBannerImage>(
            find.byType(CroppedServerBannerImage),
          )
          .where(
            (banner) =>
                banner.imageKey ==
                const ValueKey('current-user-profile-banner-media'),
          )
          .toList();
      expect(profileBanners, hasLength(1));
      expect(profileBanners.single.animate, isTrue);
      expect(
        find.byKey(const ValueKey('current-user-profile-avatar-hover-surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('current-user-profile-banner-hover-surface')),
        findsOneWidget,
      );

      final popoverRect = tester.getRect(
        find.byKey(const ValueKey('current-user-profile-popover')),
      );
      final panelRect = tester.getRect(
        find.byKey(const ValueKey('workspace-current-user-panel')),
      );
      expect(popoverRect.bottom, lessThanOrEqualTo(panelRect.top + 1));
      expect(panelRect.left, 12);
      expect(360 - panelRect.right, 12);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(
        location: tester.getCenter(
          find.byKey(const ValueKey('current-user-profile-avatar-button')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);
      await mouse.moveTo(
        tester.getCenter(
          find.byKey(const ValueKey('current-user-profile-banner-button')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey('current-user-profile-copy-user-id-button')),
      );
      await tester.pump();
      expect(clipboardWrites, hasLength(1));
      expect(clipboardWrites.single, containsPair('text', 'official/42'));

      await tester.tap(find.text('boji').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('current-user-profile-popover')),
        findsOneWidget,
      );

      await tester.tapAt(const Offset(340, 20));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('current-user-profile-popover')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('current-user-profile-avatar-media-root')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('current-user-profile-banner-media-root')),
        findsNothing,
      );
    },
  );

  testWidgets('current user footer always shows username under display name', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerWorkspace(
            seed: _seed(
              channels: const [
                ChannelSeed(id: 'general', name: 'general', selected: true),
              ],
            ),
            width: 360,
            currentUserId: 'origin:https%3A%2F%2Fapi-test.pryzmapp.com/42',
            currentUserName: 'Josh',
            currentUserUsername: 'Josh',
            currentUserInitials: 'JO',
            onLogout: () {},
            onOpenServerSettings: () {},
            onOpenUserSettings: () {},
            onSelectTextChannel: (_) {},
          ),
        ),
      ),
    );

    final panel = find.byKey(const ValueKey('workspace-current-user-panel'));

    expect(find.descendant(of: panel, matching: find.text('Josh')), findsOne);
    expect(find.descendant(of: panel, matching: find.text('@Josh')), findsOne);
    expect(
      find.descendant(of: panel, matching: find.text('Authenticated')),
      findsNothing,
    );
  });

  testWidgets('focused workspace media opts into live animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerWorkspace(
            seed: _seed(
              channels: const [
                ChannelSeed(id: 'general', name: 'general', selected: true),
              ],
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: 'https://api.verdant.chat',
              ),
              serverIconUrl:
                  'https://media.verdant.chat/server-icons/server.webp',
              serverBannerUrl:
                  'https://media.verdant.chat/server-banners/server.webp',
            ),
            width: 360,
            currentUserName: 'boji',
            currentUserInitials: 'BO',
            currentUserAvatarUrl:
                'https://media.verdant.chat/server-icons/profile.webp',
            onLogout: () {},
            onOpenServerSettings: () {},
            onOpenUserSettings: () {},
            onSelectTextChannel: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();
    await tester.pump();

    final headerBanners = tester
        .widgetList<CroppedServerBannerImage>(
          find.byType(CroppedServerBannerImage),
        )
        .where(
          (banner) =>
              banner.imageKey == const ValueKey('server-banner-media-image'),
        )
        .toList();
    expect(headerBanners, hasLength(1));
    expect(headerBanners.single.animate, isTrue);

    final icons = tester.widgetList<ServerMediaIcon>(
      find.byType(ServerMediaIcon),
    );
    final serverHeaderIcon = icons.singleWhere(
      (icon) => icon.imageKey == const ValueKey('server-icon-media-image'),
    );
    expect(serverHeaderIcon.animate, isTrue);

    final currentUserAvatar = icons.singleWhere(
      (icon) =>
          icon.imageKey == const ValueKey('current-user-avatar-media-boji'),
    );
    expect(currentUserAvatar.animate, isTrue);
  });

  testWidgets(
    'current status opens animated flyout and retrying updates stay calm',
    (tester) async {
      final attemptedStatuses = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(),
          home: Scaffold(
            body: ServerWorkspace(
              seed: _seed(
                channels: const [
                  ChannelSeed(id: 'general', name: 'general', selected: true),
                ],
              ),
              width: 360,
              currentUserName: 'boji',
              currentUserInitials: 'BO',
              currentUserStatus: 'online',
              onLogout: () {},
              onOpenServerSettings: () {},
              onOpenUserSettings: () {},
              onUpdateCurrentUserStatus: (status) async {
                attemptedStatuses.add(status);
                throw Exception('Realtime commands are unavailable');
              },
              onSelectTextChannel: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('workspace-current-user-profile-button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('current-user-profile-status-flyout')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('current-user-profile-status-idle')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('current-user-profile-status-current')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      expect(
        find.byKey(const ValueKey('current-user-profile-status-flyout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('current-user-profile-status-idle')),
        findsOneWidget,
      );
      final popoverRect = tester.getRect(
        find.byKey(const ValueKey('current-user-profile-popover')),
      );
      final flyoutRect = tester.getRect(
        find.byKey(const ValueKey('current-user-profile-status-flyout')),
      );
      expect(flyoutRect.left, greaterThan(popoverRect.right));

      await tester.tap(
        find.byKey(const ValueKey('current-user-profile-status-idle')),
      );
      await tester.pumpAndSettle();

      expect(attemptedStatuses, ['idle']);
      expect(find.text('Status update is waiting for realtime'), findsNothing);
      expect(find.textContaining('Reconnecting'), findsNothing);
      expect(find.text('Idle'), findsWidgets);
      expect(
        find.byKey(const ValueKey('current-user-profile-popover')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'current user status rebuild refreshes an open profile popover safely',
    (tester) async {
      Future<void> pumpWorkspace(String status) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildVerdantTheme(),
            home: Scaffold(
              body: ServerWorkspace(
                seed: _seed(
                  channels: const [
                    ChannelSeed(id: 'general', name: 'general', selected: true),
                  ],
                ),
                width: 360,
                currentUserName: 'boji',
                currentUserInitials: 'BO',
                currentUserStatus: status,
                onLogout: () {},
                onOpenServerSettings: () {},
                onOpenUserSettings: () {},
                onSelectTextChannel: (_) {},
              ),
            ),
          ),
        );
      }

      await pumpWorkspace('online');
      await tester.tap(
        find.byKey(const ValueKey('workspace-current-user-profile-button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('current-user-profile-popover')),
        findsOneWidget,
      );

      await pumpWorkspace('idle');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Idle'), findsWidgets);
      expect(
        find.byKey(const ValueKey('current-user-profile-popover')),
        findsOneWidget,
      );
    },
  );

  testWidgets('quick profile avatar and banner actions open profile settings', (
    tester,
  ) async {
    var settingsOpenCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerWorkspace(
            seed: _seed(
              channels: const [
                ChannelSeed(id: 'general', name: 'general', selected: true),
              ],
            ),
            width: 360,
            currentUserName: 'boji',
            currentUserInitials: 'BO',
            onLogout: () {},
            onOpenServerSettings: () {},
            onOpenUserSettings: () => settingsOpenCount += 1,
            onSelectTextChannel: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('workspace-current-user-profile-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('current-user-profile-avatar-button')),
    );
    await tester.pumpAndSettle();

    expect(settingsOpenCount, 1);
    expect(
      find.byKey(const ValueKey('current-user-profile-popover')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('workspace-current-user-profile-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('current-user-profile-banner-button')),
    );
    await tester.pumpAndSettle();

    expect(settingsOpenCount, 2);
  });
}

final _transparentPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
);

WorkspaceSeed _seed({
  required List<ChannelSeed> channels,
  ServerMediaPolicy? mediaPolicy,
  ServerSettingsSeed? serverSettings,
  String? serverIconUrl,
  String? serverBannerUrl,
}) {
  final sample = WorkspaceSeed.sample;
  return WorkspaceSeed(
    networkId: sample.networkId,
    serverId: sample.serverId,
    serverName: sample.serverName,
    serverOwnerId: sample.serverOwnerId,
    serverIconUrl: serverIconUrl ?? sample.serverIconUrl,
    serverBannerUrl: serverBannerUrl ?? sample.serverBannerUrl,
    serverBannerCrop: sample.serverBannerCrop,
    memberCount: sample.memberCount,
    channels: channels,
    members: sample.members,
    messages: const [],
    serverSettings: serverSettings ?? sample.serverSettings,
    mediaPolicy: mediaPolicy ?? sample.mediaPolicy,
  );
}
