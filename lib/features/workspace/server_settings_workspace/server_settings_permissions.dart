import 'package:flutter/material.dart';

final class ServerPermissionDefinition {
  const ServerPermissionDefinition({
    required this.key,
    required this.bit,
    required this.label,
    required this.description,
    this.danger = false,
  });

  final String key;
  final int bit;
  final String label;
  final String description;
  final bool danger;
}

final class ServerPermissionCategory {
  const ServerPermissionCategory({
    required this.name,
    required this.permissions,
  });

  final String name;
  final List<ServerPermissionDefinition> permissions;
}

const permissionViewChannel = 1 << 0;
const permissionSendMessages = 1 << 1;
const permissionManageMessages = 1 << 2;
const permissionManageChannels = 1 << 3;
const permissionManageServer = 1 << 4;
const permissionManageRoles = 1 << 5;
const permissionKickMembers = 1 << 6;
const permissionBanMembers = 1 << 7;
const permissionAttachFiles = 1 << 8;
const permissionUseCustomEmojis = 1 << 9;
const permissionAdministrator = 1 << 10;
const permissionCreateInvite = 1 << 11;
const permissionConnect = 1 << 12;
const permissionSpeak = 1 << 13;
const permissionMuteMembers = 1 << 14;
const permissionDeafenMembers = 1 << 15;

const serverPermissionCategories = <ServerPermissionCategory>[
  ServerPermissionCategory(
    name: 'General',
    permissions: [
      ServerPermissionDefinition(
        key: 'VIEW_CHANNEL',
        bit: permissionViewChannel,
        label: 'View Channels',
        description: 'Allows members to view channels.',
      ),
      ServerPermissionDefinition(
        key: 'MANAGE_CHANNELS',
        bit: permissionManageChannels,
        label: 'Manage Channels',
        description: 'Create, edit, and delete channels.',
      ),
      ServerPermissionDefinition(
        key: 'MANAGE_SERVER',
        bit: permissionManageServer,
        label: 'Manage Server',
        description: 'Edit server name, icon, and settings.',
      ),
      ServerPermissionDefinition(
        key: 'MANAGE_ROLES',
        bit: permissionManageRoles,
        label: 'Manage Roles',
        description: 'Create, edit, and assign roles.',
      ),
      ServerPermissionDefinition(
        key: 'ADMINISTRATOR',
        bit: permissionAdministrator,
        label: 'Administrator',
        description: 'Full access and bypasses channel overrides.',
        danger: true,
      ),
    ],
  ),
  ServerPermissionCategory(
    name: 'Membership',
    permissions: [
      ServerPermissionDefinition(
        key: 'KICK_MEMBERS',
        bit: permissionKickMembers,
        label: 'Kick Members',
        description: 'Remove members from the server.',
      ),
      ServerPermissionDefinition(
        key: 'BAN_MEMBERS',
        bit: permissionBanMembers,
        label: 'Ban Members',
        description: 'Permanently ban members.',
      ),
      ServerPermissionDefinition(
        key: 'CREATE_INVITE',
        bit: permissionCreateInvite,
        label: 'Create Invite',
        description: 'Create invite links for the server.',
      ),
    ],
  ),
  ServerPermissionCategory(
    name: 'Text',
    permissions: [
      ServerPermissionDefinition(
        key: 'SEND_MESSAGES',
        bit: permissionSendMessages,
        label: 'Send Messages',
        description: 'Send messages in text channels.',
      ),
      ServerPermissionDefinition(
        key: 'MANAGE_MESSAGES',
        bit: permissionManageMessages,
        label: 'Manage Messages',
        description: 'Delete and pin messages by others.',
      ),
      ServerPermissionDefinition(
        key: 'ATTACH_FILES',
        bit: permissionAttachFiles,
        label: 'Attach Files',
        description: 'Upload files and images.',
      ),
      ServerPermissionDefinition(
        key: 'USE_CUSTOM_EMOJIS',
        bit: permissionUseCustomEmojis,
        label: 'Use Custom Emojis',
        description: 'Use custom server emoji.',
      ),
    ],
  ),
  ServerPermissionCategory(
    name: 'Voice',
    permissions: [
      ServerPermissionDefinition(
        key: 'CONNECT',
        bit: permissionConnect,
        label: 'Connect',
        description: 'Join voice channels.',
      ),
      ServerPermissionDefinition(
        key: 'SPEAK',
        bit: permissionSpeak,
        label: 'Speak',
        description: 'Speak in voice channels.',
      ),
      ServerPermissionDefinition(
        key: 'MUTE_MEMBERS',
        bit: permissionMuteMembers,
        label: 'Mute Members',
        description: 'Mute other members in voice.',
      ),
      ServerPermissionDefinition(
        key: 'DEAFEN_MEMBERS',
        bit: permissionDeafenMembers,
        label: 'Deafen Members',
        description: 'Deafen other members in voice.',
      ),
    ],
  ),
];

const channelPermissionDefinitions = <ServerPermissionDefinition>[
  ServerPermissionDefinition(
    key: 'VIEW_CHANNEL',
    bit: permissionViewChannel,
    label: 'View Channel',
    description: 'See this channel in the channel list.',
  ),
  ServerPermissionDefinition(
    key: 'SEND_MESSAGES',
    bit: permissionSendMessages,
    label: 'Send Messages',
    description: 'Send messages in this channel.',
  ),
  ServerPermissionDefinition(
    key: 'MANAGE_MESSAGES',
    bit: permissionManageMessages,
    label: 'Manage Messages',
    description: 'Delete and pin messages.',
  ),
  ServerPermissionDefinition(
    key: 'MANAGE_CHANNELS',
    bit: permissionManageChannels,
    label: 'Manage Channel',
    description: 'Edit this channel settings.',
  ),
  ServerPermissionDefinition(
    key: 'ATTACH_FILES',
    bit: permissionAttachFiles,
    label: 'Attach Files',
    description: 'Upload files and images.',
  ),
  ServerPermissionDefinition(
    key: 'USE_CUSTOM_EMOJIS',
    bit: permissionUseCustomEmojis,
    label: 'Use Custom Emojis',
    description: 'Use custom server emoji.',
  ),
  ServerPermissionDefinition(
    key: 'CREATE_INVITE',
    bit: permissionCreateInvite,
    label: 'Create Invite',
    description: 'Create invite links.',
  ),
  ServerPermissionDefinition(
    key: 'CONNECT',
    bit: permissionConnect,
    label: 'Connect',
    description: 'Join if this is a voice channel.',
  ),
  ServerPermissionDefinition(
    key: 'SPEAK',
    bit: permissionSpeak,
    label: 'Speak',
    description: 'Speak in voice channels.',
  ),
];

bool permissionsInclude(int permissions, int bit) {
  return (permissions & permissionAdministrator) == permissionAdministrator ||
      (permissions & bit) == bit;
}

IconData iconForPermission(ServerPermissionDefinition permission) {
  return switch (permission.key) {
    'VIEW_CHANNEL' => Icons.visibility_outlined,
    'SEND_MESSAGES' => Icons.chat_bubble_outline,
    'MANAGE_MESSAGES' => Icons.push_pin_outlined,
    'MANAGE_CHANNELS' => Icons.tune,
    'MANAGE_SERVER' => Icons.settings_outlined,
    'MANAGE_ROLES' => Icons.shield_outlined,
    'KICK_MEMBERS' => Icons.person_remove_outlined,
    'BAN_MEMBERS' => Icons.block,
    'ATTACH_FILES' => Icons.attach_file,
    'USE_CUSTOM_EMOJIS' => Icons.emoji_emotions_outlined,
    'ADMINISTRATOR' => Icons.admin_panel_settings_outlined,
    'CREATE_INVITE' => Icons.link,
    'CONNECT' => Icons.headset_mic_outlined,
    'SPEAK' => Icons.mic_none,
    'MUTE_MEMBERS' => Icons.mic_off_outlined,
    'DEAFEN_MEMBERS' => Icons.headset_off_outlined,
    _ => Icons.check_circle_outline,
  };
}
