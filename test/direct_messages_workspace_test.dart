import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_models.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_workspace.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  testWidgets('DM sidebar reuses the workspace current user panel', (
    tester,
  ) async {
    var settingsOpenCount = 0;
    var logoutCount = 0;
    final attemptedStatuses = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(mode: VerdantThemeMode.light),
        home: Scaffold(
          body: DmSidebarModule(
            data: _dmData,
            width: 360,
            activeChannelId: null,
            currentUserId: 'official/42',
            currentUserUsername: 'Josh',
            currentUserBio: 'Available for tests',
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: 'https://api.verdant.chat',
            ),
            onLogout: () => logoutCount += 1,
            onOpenUserSettings: () => settingsOpenCount += 1,
            onUpdateCurrentUserStatus: (status) async {
              attemptedStatuses.add(status);
            },
            onShowFriends: () {},
            onOpenConversation: (_) async {},
            onCloseConversation: (_) async {},
            onRemoveFriend: (_) async {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('workspace-current-user-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace-current-user-profile-button')),
      findsOneWidget,
    );
    expect(find.text('api.verdant.chat'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('workspace-user-settings-button')),
    );
    await tester.tap(find.byKey(const ValueKey('workspace-logout-button')));
    await tester.pump();

    expect(settingsOpenCount, 1);
    expect(logoutCount, 1);

    await tester.tap(
      find.byKey(const ValueKey('workspace-current-user-profile-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('current-user-profile-popover')),
      findsOneWidget,
    );
    expect(find.text('@Josh'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('current-user-profile-status-current')),
    );
    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(
      find.byKey(const ValueKey('current-user-profile-status-idle')),
    );
    await tester.pumpAndSettle();

    expect(attemptedStatuses, ['idle']);
  });

  testWidgets('friends list disambiguates friends by backend origin', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(mode: VerdantThemeMode.light),
        home: Scaffold(
          body: FriendsListModule(
            data: _dmData,
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: 'https://api.verdant.chat',
            ),
            onAddFriend: (_) async {},
            onAcceptFriend: (_) async {},
            onRemoveFriend: (_) async {},
            onMessageFriend: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Avery'), findsOneWidget);
    expect(find.text('api.verdant.chat'), findsWidgets);
  });

  testWidgets('DM sidebar shows hydration placeholder before first snapshot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(mode: VerdantThemeMode.light),
        home: Scaffold(
          body: DmSidebarModule(
            data: DirectMessagesWorkspaceData.empty(
              networkId: 'official',
              currentUserName: 'Joshy',
              currentUserInitials: 'JO',
              hasHydrated: false,
            ).copyWith(isRefreshing: true),
            width: 360,
            activeChannelId: null,
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: 'https://api.verdant.chat',
            ),
            onLogout: () {},
            onOpenUserSettings: () {},
            onShowFriends: () {},
            onOpenConversation: (_) async {},
            onCloseConversation: (_) async {},
            onRemoveFriend: (_) async {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('dm-sidebar-hydration-placeholder')),
      findsOneWidget,
    );
    expect(find.text('No conversations yet'), findsNothing);
  });

  testWidgets(
    'friends list shows hydration placeholder before first snapshot',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildVerdantTheme(mode: VerdantThemeMode.light),
          home: Scaffold(
            body: FriendsListModule(
              data: DirectMessagesWorkspaceData.empty(
                networkId: 'official',
                currentUserName: 'Joshy',
                currentUserInitials: 'JO',
                hasHydrated: false,
              ).copyWith(isRefreshing: true),
              mediaPolicy: ServerMediaPolicy.fromOrigins(
                apiOrigin: 'https://api.verdant.chat',
              ),
              onAddFriend: (_) async {},
              onAcceptFriend: (_) async {},
              onRemoveFriend: (_) async {},
              onMessageFriend: (_) async {},
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('friends-hydration-placeholder')),
        findsOneWidget,
      );
      expect(find.text('No friends yet'), findsNothing);
    },
  );
}

const _dmData = DirectMessagesWorkspaceData(
  networkId: 'official',
  currentUserName: 'Joshy',
  currentUserInitials: 'JO',
  currentUserStatus: 'online',
  conversations: [
    DmConversationPreviewSeed(
      channelId: 'official/dm-avery',
      localChannelId: 'dm-avery',
      networkId: 'official',
      displayName: 'Avery',
      initials: 'AV',
      status: 'online',
      lastMessage: 'Last active 2026/06/02',
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
      status: 'online',
      detail: 'Friend',
      kind: FriendRelationshipKind.friend,
    ),
  ],
);
