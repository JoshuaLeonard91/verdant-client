import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';

void main() {
  test(
    'name colors override access-role colors without becoming access roles',
    () {
      final seed = WorkspaceSeed.fromSettingsData(
        const ServerSettingsData(
          networkId: 'official',
          server: ServerSettingsServer(
            id: 'server-1',
            name: 'Verdant',
            ownerId: 'owner',
            voiceBitrate: 64000,
            bannerOffsetY: 50,
            memberCount: 1,
            large: false,
            createdAt: '',
            updatedAt: '',
          ),
          channels: [],
          emojis: [],
          invites: [],
          roles: [
            ServerSettingsListItemSeed(
              id: 'access',
              title: 'Member',
              subtitle: 'Access role',
              trailing: '#2196f3',
              accent: Color(0xff2196f3),
              colorOnly: false,
            ),
            ServerSettingsListItemSeed(
              id: 'mint',
              title: 'Mint',
              subtitle: 'Name Color',
              trailing: '#22c55e',
              accent: Color(0xff22c55e),
              colorOnly: true,
            ),
          ],
          members: [
            ServerSettingsListItemSeed(
              title: 'Avery',
              subtitle: 'Online',
              userId: 'user-1',
              roleIds: ['access', 'mint'],
            ),
          ],
          auditEvents: [],
          feeds: [],
          bots: [],
        ),
        currentUserId: 'user-1',
        currentUserName: 'Avery',
        currentUserInitials: 'AV',
      );

      final member = seed.members.single;
      expect(member.role, 'Member');
      expect(member.nameColorName, 'Mint');
      expect(member.displayColor, const Color(0xff22c55e));
    },
  );

  test('workspace seed projects server bots into member list rows', () {
    final seed = WorkspaceSeed.fromSettingsData(
      const ServerSettingsData(
        networkId: 'official',
        server: ServerSettingsServer(
          id: 'server-1',
          name: 'Verdant',
          ownerId: 'owner',
          voiceBitrate: 64000,
          bannerOffsetY: 50,
          memberCount: 2,
          large: false,
          createdAt: '',
          updatedAt: '',
        ),
        channels: [],
        emojis: [],
        invites: [],
        roles: [],
        members: [
          ServerSettingsListItemSeed(
            title: 'Joshy',
            subtitle: 'Online',
            userId: 'user-1',
          ),
        ],
        auditEvents: [],
        feeds: [],
        bots: [
          ServerSettingsListItemSeed(
            id: 'bot-1',
            title: 'Codex Feed Bot',
            subtitle: 'online',
            trailing: 'online',
          ),
        ],
      ),
      currentUserId: 'user-1',
      currentUserName: 'Joshy',
      currentUserInitials: 'JO',
    );

    final bot = seed.members.singleWhere(
      (member) => member.name == 'Codex Feed Bot',
    );
    expect(bot.id, 'official/bot-1');
    expect(bot.role, 'Bot');
    expect(bot.status, 'online');
    expect(bot.isActive, isTrue);
  });
}
