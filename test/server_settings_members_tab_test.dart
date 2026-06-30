import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_members_tab.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  testWidgets('members tab searches and routes moderation actions', (
    tester,
  ) async {
    final repository = _FakeModerationRepository(
      bans: const [
        ServerSettingsListItemSeed(
          id: 'user-2',
          userId: 'user-2',
          title: 'Banned User',
          subtitle: 'spam',
          username: 'banned',
          reason: 'spam',
        ),
      ],
    );
    var changedMembers = const <ServerSettingsListItemSeed>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerSettingsMembersTab(
            serverId: 'server-1',
            networkId: networkIdFromApiOrigin('https://api.verdant.chat'),
            members: _memberSeeds,
            roles: _roleSeeds,
            currentUserId: 'user-1',
            ownerId: 'owner-1',
            canKickMembers: true,
            canBanMembers: true,
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: 'https://api.verdant.chat',
            ),
            moderationRepository: repository,
            onMembersChanged: (members) => changedMembers = members,
          ),
        ),
      ),
    );

    expect(find.text('Members'), findsWidgets);
    expect(find.text('Joshy'), findsOneWidget);
    expect(find.text('Cyra Loop'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('server-member-backend-user-2')),
      findsOneWidget,
    );
    expect(find.text('api.verdant.chat'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('server-members-search-field')),
      'cyra',
    );
    await tester.pumpAndSettle();

    expect(find.text('Joshy'), findsNothing);
    expect(find.text('Cyra Loop'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('server-members-row-user-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-member-kick-user-2')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('server-member-kick-reason-field')),
      '  spam links  ',
    );
    await tester.tap(find.byKey(const ValueKey('server-member-kick-confirm')));
    await tester.pumpAndSettle();

    expect(repository.kicked, [
      (serverId: 'server-1', userId: 'user-2', reason: '  spam links  '),
    ]);
    expect(changedMembers.any((member) => member.userId == 'user-2'), isFalse);

    await tester.enterText(
      find.byKey(const ValueKey('server-members-search-field')),
      '',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-members-row-user-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-member-ban-user-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-member-ban-confirm')));
    await tester.pumpAndSettle();

    expect(repository.banned.single.userId, 'user-3');

    await tester.tap(find.byKey(const ValueKey('server-members-bans-tab')));
    await tester.pumpAndSettle();

    expect(repository.listBansCalls, 1);
    expect(find.text('Banned User'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('server-ban-backend-user-2')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('server-ban-unban-user-2')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('server-ban-unban-confirm-user-2')),
    );
    await tester.pumpAndSettle();

    expect(repository.unbanned, [(serverId: 'server-1', userId: 'user-2')]);
    expect(find.text('Banned User'), findsNothing);
  });

  testWidgets('members tab keeps users visible and shows moderation errors', (
    tester,
  ) async {
    final repository = _FakeModerationRepository(
      bans: const [],
      kickError: const ServerSettingsException('You do not have permission'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(),
        home: Scaffold(
          body: ServerSettingsMembersTab(
            serverId: 'server-1',
            networkId: networkIdFromApiOrigin('https://api.verdant.chat'),
            members: _memberSeeds,
            roles: _roleSeeds,
            currentUserId: 'user-1',
            ownerId: 'owner-1',
            canKickMembers: true,
            canBanMembers: true,
            mediaPolicy: ServerMediaPolicy.fromOrigins(
              apiOrigin: 'https://api.verdant.chat',
            ),
            moderationRepository: repository,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('server-members-row-user-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-member-kick-user-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-member-kick-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('You do not have permission'), findsOneWidget);
    expect(find.text('Cyra Loop'), findsOneWidget);
  });
}

const _roleSeeds = [
  ServerSettingsListItemSeed(
    id: 'member',
    title: 'Member',
    subtitle: 'Access role',
    permissions: 1024,
  ),
];

const _memberSeeds = [
  ServerSettingsListItemSeed(
    id: 'user-1',
    userId: 'user-1',
    title: 'Joshy',
    subtitle: 'online - joined 2026-06-01',
    username: 'josh',
    roleIds: ['member'],
  ),
  ServerSettingsListItemSeed(
    id: 'user-2',
    userId: 'user-2',
    title: 'Cyra Loop',
    subtitle: 'offline - joined 2026-06-02',
    username: 'cyra',
    roleIds: ['member'],
  ),
  ServerSettingsListItemSeed(
    id: 'user-3',
    userId: 'user-3',
    title: 'OceanGlass',
    subtitle: 'offline - joined 2026-06-03',
    username: 'ocean',
    roleIds: ['member'],
  ),
];

final class _FakeModerationRepository
    implements ServerSettingsModerationRepository {
  _FakeModerationRepository({
    required List<ServerSettingsListItemSeed> bans,
    this.kickError,
  }) : _bans = [...bans];

  List<ServerSettingsListItemSeed> _bans;
  final ServerSettingsException? kickError;
  final kicked = <({String serverId, String userId, String? reason})>[];
  final banned = <({String serverId, String userId, String? reason})>[];
  final unbanned = <({String serverId, String userId})>[];
  int listBansCalls = 0;

  @override
  Future<void> kickMember({
    required String serverId,
    required String userId,
    String? reason,
  }) async {
    final kickError = this.kickError;
    if (kickError != null) {
      throw kickError;
    }
    kicked.add((serverId: serverId, userId: userId, reason: reason));
  }

  @override
  Future<void> banMember({
    required String serverId,
    required String userId,
    String? reason,
  }) async {
    banned.add((serverId: serverId, userId: userId, reason: reason));
  }

  @override
  Future<List<ServerSettingsListItemSeed>> listBans({
    required String serverId,
  }) async {
    listBansCalls += 1;
    return _bans;
  }

  @override
  Future<void> unbanMember({
    required String serverId,
    required String userId,
  }) async {
    unbanned.add((serverId: serverId, userId: userId));
    _bans = [
      for (final ban in _bans)
        if (ban.userId != userId) ban,
    ];
  }
}
