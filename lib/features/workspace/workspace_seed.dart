import 'package:flutter/material.dart';

import 'server_settings_workspace/server_settings_models.dart';
import 'server_settings_workspace/server_media_url_policy.dart';
import 'workspace_local_id.dart';

const Object _messageSeedSentinel = Object();

class WorkspaceSeed {
  WorkspaceSeed({
    required this.networkId,
    required this.serverId,
    required this.serverName,
    required this.serverOwnerId,
    required this.serverIconUrl,
    required this.serverBannerUrl,
    required this.serverBannerCrop,
    required this.memberCount,
    required this.channels,
    required this.members,
    required this.messages,
    required this.serverSettings,
    required this.mediaPolicy,
    this.activeFeedId,
  });

  final String networkId;
  final String serverId;
  final String serverName;
  final String serverOwnerId;
  final String? serverIconUrl;
  final String? serverBannerUrl;
  final BannerCrop? serverBannerCrop;
  final int memberCount;
  final List<ChannelSeed> channels;
  final List<MemberSeed> members;
  final List<MessageSeed> messages;
  final ServerSettingsSeed serverSettings;
  final ServerMediaPolicy mediaPolicy;
  final String? activeFeedId;

  factory WorkspaceSeed.fromSettingsData(
    ServerSettingsData settings, {
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
    String? currentUserAvatarUrl,
    String? currentUserBannerUrl,
    Color? currentUserBannerBaseColor,
    String? currentUserMemberListBannerUrl,
    String? activeChannelId,
    String? activeFeedId,
    List<MessageSeed>? messages,
  }) {
    final currentScopedMemberId = _scopedMemberIdOrNull(
      settings.networkId,
      currentUserId,
    );
    final firstTextChannelIndex = settings.channels.indexWhere(
      (channel) => channel.type == 0,
    );
    final selectedChannelId = activeFeedId == null
        ? activeChannelId ??
              (firstTextChannelIndex >= 0
                  ? settings.channels[firstTextChannelIndex].id
                  : null)
        : null;
    final channels = [
      for (var index = 0; index < settings.channels.length; index += 1)
        if (settings.channels[index].type == 0 ||
            settings.channels[index].type == 3)
          ChannelSeed(
            id: settings.channels[index].id,
            name: settings.channels[index].name,
            type: settings.channels[index].type,
            topic: settings.channels[index].topic,
            readOnly: settings.channels[index].readOnly,
            slowmodeSeconds: settings.channels[index].slowmodeSeconds,
            selected: settings.channels[index].id == selectedChannelId,
            unread: settings.channels[index].unread,
            mentionCount: settings.channels[index].mentionCount,
            disabled: false,
          ),
    ];
    final humanMembers = settings.members.isEmpty
        ? [
            MemberSeed(
              id: _scopedMemberIdOrNull(
                settings.networkId,
                settings.server.ownerId,
              ),
              name: currentUserName,
              username: currentUserName,
              status: 'Online',
              initials: currentUserInitials,
              role: 'Member',
              avatarUrl: currentUserAvatarUrl,
              bannerUrl: currentUserBannerUrl,
              bannerBaseColor: currentUserBannerBaseColor,
              memberListBannerUrl: currentUserMemberListBannerUrl,
              isActive: true,
            ),
          ]
        : [
            for (final member in settings.members)
              _memberSeedFromSettings(
                settings.networkId,
                member,
                roles: settings.roles,
                currentScopedMemberId: currentScopedMemberId,
                currentUserAvatarUrl: currentUserAvatarUrl,
                currentUserBannerUrl: currentUserBannerUrl,
                currentUserBannerBaseColor: currentUserBannerBaseColor,
                currentUserMemberListBannerUrl: currentUserMemberListBannerUrl,
              ),
          ];
    final members = [
      ...humanMembers,
      for (final bot in settings.bots)
        _botMemberSeedFromSettings(
          settings.networkId,
          bot,
          roles: settings.roles,
        ),
    ];

    return WorkspaceSeed(
      networkId: settings.networkId,
      serverId: settings.server.id,
      serverName: settings.server.name,
      serverOwnerId: settings.server.ownerId,
      serverIconUrl: settings.server.iconUrl,
      serverBannerUrl: settings.server.bannerUrl,
      serverBannerCrop: settings.server.bannerCrop,
      memberCount: settings.server.memberCount,
      channels: channels,
      members: members,
      messages: messages ?? const [],
      serverSettings: ServerSettingsSeed.fromData(
        settings,
        currentUserId: currentUserId,
      ),
      mediaPolicy: settings.mediaPolicy,
      activeFeedId: activeFeedId,
    );
  }

  static final sample = WorkspaceSeed(
    networkId: 'official',
    serverId: 'fake-server-1',
    serverName: 'Verdant',
    serverOwnerId: 'user-joshy',
    serverIconUrl: null,
    serverBannerUrl: null,
    serverBannerCrop: null,
    memberCount: 2,
    channels: const [
      ChannelSeed(id: 'fake-channel-general', name: 'general', selected: true),
      ChannelSeed(id: 'fake-channel-change-logs', name: 'change-logs'),
      ChannelSeed(id: 'fake-channel-bot-test', name: 'bot-test'),
    ],
    members: const [
      MemberSeed(
        name: 'Joshy',
        status: 'Online',
        initials: 'JO',
        role: 'Owner',
      ),
      MemberSeed(
        name: 'User 181051381515448320',
        status: 'Idle',
        initials: 'U1',
        role: 'Member',
      ),
    ],
    messages: buildFakeMessages(count: 240),
    serverSettings: const ServerSettingsSeed(
      networkId: 'official',
      localServerId: 'fake-server-1',
      serverName: 'Verdant',
      description: 'Flutter parity workspace',
      memberCount: 2,
      ownerName: 'Joshy',
      createdLabel: 'Today',
      channels: [
        ServerSettingsChannelSeed(id: 'fake-channel-general', name: 'general'),
        ServerSettingsChannelSeed(
          id: 'fake-channel-change-logs',
          name: 'change-logs',
        ),
      ],
      emojis: [
        ServerSettingsListItemSeed(
          title: ':verdant:',
          subtitle: 'Static fake emoji asset placeholder',
          trailing: 'PNG',
        ),
        ServerSettingsListItemSeed(
          title: ':spark:',
          subtitle: 'Animated emoji placeholder',
          trailing: 'GIF',
        ),
      ],
      invites: [
        ServerSettingsListItemSeed(
          title: 'verdant.chat/invite/flutter',
          subtitle: 'Created by Joshy. Expires in 7 days.',
          trailing: '12 uses',
        ),
      ],
      roles: [
        ServerSettingsListItemSeed(
          title: 'Owner',
          subtitle: 'Full administrative control',
          trailing: '1',
          accent: Color(0xFF7CFFDE),
        ),
        ServerSettingsListItemSeed(
          title: 'Member',
          subtitle: 'Default server access',
          trailing: '1',
          accent: Color(0xFFC1B3FF),
        ),
      ],
      members: [
        ServerSettingsListItemSeed(
          title: 'Joshy',
          subtitle: 'Online - joined from official/fake-server-1',
          trailing: 'Owner',
          accent: Color(0xFF7CFFDE),
        ),
        ServerSettingsListItemSeed(
          title: 'User 181051381515448320',
          subtitle: 'Idle - local member row remains network-scoped',
          trailing: 'Member',
        ),
      ],
      auditEvents: [
        ServerSettingsListItemSeed(
          title: 'Joshy updated server settings',
          subtitle: 'Changed welcome channel to #general',
          trailing: '2m',
        ),
        ServerSettingsListItemSeed(
          title: 'Joshy created invite',
          subtitle: 'Invite target remained on official/fake-server-1',
          trailing: '8m',
        ),
      ],
      feeds: [
        ServerSettingsListItemSeed(
          title: 'Announcements',
          subtitle: 'Posts release notes into #change-logs',
          trailing: 'Active',
        ),
      ],
      bots: [
        ServerSettingsListItemSeed(
          title: 'Verdant Helper',
          subtitle: 'Scoped bot presence placeholder',
          trailing: 'Online',
        ),
      ],
      canManageServer: true,
      canManageChannels: true,
      canManageMessages: true,
      canManageRoles: true,
      canModerateMembers: true,
    ),
    mediaPolicy: ServerMediaPolicy(allowedOrigins: {}, allowLocalHttp: false),
  );
}

String _initialsFor(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  final compact = value.replaceAll(RegExp(r'\s+'), '');
  if (compact.length >= 2) {
    return compact.substring(0, 2).toUpperCase();
  }
  return compact.toUpperCase();
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

MemberSeed _botMemberSeedFromSettings(
  String networkId,
  ServerSettingsListItemSeed bot, {
  required List<ServerSettingsListItemSeed> roles,
}) {
  final status =
      _nonEmpty(bot.trailing) ?? _nonEmpty(bot.subtitle) ?? 'offline';
  return MemberSeed(
    id: _scopedMemberIdOrNull(networkId, bot.id ?? bot.title),
    name: bot.title,
    username: bot.username,
    status: status,
    initials: _initialsFor(bot.title),
    role: 'Bot',
    roleIds: bot.roleIds,
    displayColor: bot.accent ?? _roleAccentForIds(bot.roleIds, roles),
    avatarUrl: bot.avatarUrl,
    bannerUrl: bot.bannerUrl,
    bannerBaseColor: bot.bannerBaseColor,
    bannerCrop: bot.bannerCrop,
    memberListBannerUrl: bot.memberListBannerUrl,
    memberListBannerCrop: bot.memberListBannerCrop,
    isActive: !_statusLooksOffline(status),
    isBot: true,
  );
}

MemberSeed _memberSeedFromSettings(
  String networkId,
  ServerSettingsListItemSeed member, {
  required List<ServerSettingsListItemSeed> roles,
  required String? currentScopedMemberId,
  String? currentUserAvatarUrl,
  String? currentUserBannerUrl,
  Color? currentUserBannerBaseColor,
  String? currentUserMemberListBannerUrl,
}) {
  final scopedMemberId = _scopedMemberIdOrNull(
    networkId,
    member.userId ?? member.title,
  );
  final isCurrentUser =
      currentScopedMemberId != null && scopedMemberId == currentScopedMemberId;
  return MemberSeed(
    id: scopedMemberId,
    name: member.title,
    username: member.username,
    status: member.subtitle,
    initials: _initialsFor(member.title),
    role: _roleLabelForIds(member.roleIds, roles, fallback: member.trailing),
    roleIds: member.roleIds,
    displayColor: member.accent ?? _roleAccentForIds(member.roleIds, roles),
    nameColorName: _nameColorRoleForIds(member.roleIds, roles)?.title,
    avatarUrl:
        member.avatarUrl ?? (isCurrentUser ? currentUserAvatarUrl : null),
    bannerUrl:
        member.bannerUrl ?? (isCurrentUser ? currentUserBannerUrl : null),
    bannerBaseColor:
        member.bannerBaseColor ??
        (isCurrentUser ? currentUserBannerBaseColor : null),
    bannerCrop: member.bannerCrop,
    memberListBannerUrl:
        member.memberListBannerUrl ??
        (isCurrentUser ? currentUserMemberListBannerUrl : null),
    memberListBannerCrop: member.memberListBannerCrop,
    isActive: !_statusLooksOffline(member.subtitle),
    originIdentity: member.originIdentity,
  );
}

String? _scopedMemberIdOrNull(String networkId, String rawId) {
  final trimmed = rawId.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  try {
    final network = _safeWorkspaceNetworkId(networkId);
    final slash = trimmed.indexOf('/');
    if (slash >= 0) {
      if (slash == 0 ||
          slash == trimmed.length - 1 ||
          trimmed.indexOf('/', slash + 1) >= 0 ||
          !sameWorkspaceNetworkId(trimmed.substring(0, slash), network)) {
        return null;
      }
      return '$network/${safeWorkspaceLocalId(trimmed.substring(slash + 1))}';
    }
    return '$network/${safeWorkspaceLocalId(trimmed)}';
  } on FormatException {
    return null;
  }
}

String _safeWorkspaceNetworkId(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty ||
      trimmed.contains('/') ||
      trimmed.contains('\\') ||
      trimmed.contains(RegExp(r'\s')) ||
      _containsControlCharacter(trimmed)) {
    throw const FormatException('Invalid workspace network id');
  }
  return trimmed;
}

bool _containsControlCharacter(String value) {
  for (final unit in value.codeUnits) {
    if (unit < 0x20 || unit == 0x7f) {
      return true;
    }
  }
  return false;
}

List<MessageSeed> buildFakeMessages({int count = 240}) {
  final baseTime = DateTime(2026, 6, 3, 8, 25);
  return List<MessageSeed>.generate(count, (index) {
    final isJoshy = index % 4 != 1;
    final author = isJoshy ? 'Joshy' : 'User 181051381515448320';
    final initials = isJoshy ? 'JO' : 'U1';
    final hasMedia = index % 9 == 2 || index % 17 == 0;
    final hasLongerText = index % 7 == 0;
    final mediaKind = index.isEven
        ? MessageMediaKind.gif
        : MessageMediaKind.webp;
    final width = index % 17 == 0 ? 360 : 320;
    final height = index % 17 == 0 ? 240 : 180;

    return MessageSeed(
      id: 'official/fake-message-${100000 + index}',
      authorId: isJoshy ? 'official/user-joshy' : 'official/user-181',
      author: author,
      authorColor: isJoshy ? VerdantAuthorColors.green : null,
      time: 'Today at ${8 + (index ~/ 48)}:${(25 + index) % 60} AM',
      createdAt: baseTime.add(Duration(minutes: index)).toIso8601String(),
      body: hasLongerText
          ? 'Keeping the fake Flutter timeline close to Tauri behavior: stable rows, selectable text, reactions, and media frames.'
          : hasMedia
          ? 'https://static.klipy.com/i/fake-${index.toString().padLeft(3, '0')}.${mediaKind.extension}'
          : 'Fake chat message ${index + 1} for scroll and rebuild profiling.',
      initials: initials,
      media: hasMedia
          ? MessageMediaSeed(
              id: 'official/fake-media-$index',
              label: mediaKind == MessageMediaKind.gif
                  ? 'Klipy GIF preview'
                  : 'WebP sticker preview',
              kind: mediaKind,
              url:
                  'https://static.klipy.com/i/fake-${index.toString().padLeft(3, '0')}.${mediaKind.extension}',
              width: width,
              height: height,
            )
          : null,
      reactions: index % 5 == 0
          ? const [
              ReactionSeed(
                emoji: '\u{1F44D}',
                count: 3,
                reactedByCurrentUser: true,
              ),
              ReactionSeed(emoji: '\u{1F602}', count: 1),
            ]
          : index % 6 == 0
          ? const [ReactionSeed(emoji: '\u{1F440}', count: 2)]
          : const [],
      isOwnMessage: isJoshy,
    );
  });
}

class ChannelSeed {
  const ChannelSeed({
    required this.id,
    required this.name,
    this.type = 0,
    this.topic,
    this.readOnly = false,
    this.slowmodeSeconds = 0,
    this.selected = false,
    this.unread = false,
    this.mentionCount = 0,
    this.disabled = false,
  });

  final String id;
  final String name;
  final int type;
  final String? topic;
  final bool readOnly;
  final int slowmodeSeconds;
  final bool selected;
  final bool unread;
  final int mentionCount;
  final bool disabled;

  ChannelSeed copyWith({
    String? id,
    String? name,
    int? type,
    Object? topic = _messageSeedSentinel,
    bool? readOnly,
    int? slowmodeSeconds,
    bool? selected,
    bool? unread,
    int? mentionCount,
    bool? disabled,
  }) {
    return ChannelSeed(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      topic: identical(topic, _messageSeedSentinel)
          ? this.topic
          : topic as String?,
      readOnly: readOnly ?? this.readOnly,
      slowmodeSeconds: slowmodeSeconds ?? this.slowmodeSeconds,
      selected: selected ?? this.selected,
      unread: unread ?? this.unread,
      mentionCount: mentionCount ?? this.mentionCount,
      disabled: disabled ?? this.disabled,
    );
  }
}

class MemberSeed {
  const MemberSeed({
    this.id,
    required this.name,
    this.username,
    required this.status,
    required this.initials,
    this.role = 'Member',
    this.roleIds = const [],
    this.displayColor,
    this.nameColorName,
    this.avatarUrl,
    this.bannerUrl,
    this.bannerBaseColor,
    this.bannerCrop,
    this.memberListBannerUrl,
    this.memberListBannerCrop,
    this.lastMessageAt,
    this.isActive = true,
    this.isBot = false,
    this.originIdentity,
  });

  final String? id;
  final String name;
  final String? username;
  final String status;
  final String initials;
  final String role;
  final List<String> roleIds;
  final Color? displayColor;
  final String? nameColorName;
  final String? avatarUrl;
  final String? bannerUrl;
  final Color? bannerBaseColor;
  final BannerCrop? bannerCrop;
  final String? memberListBannerUrl;
  final BannerCrop? memberListBannerCrop;
  final String? lastMessageAt;
  final bool isActive;
  final bool isBot;
  final FederatedOriginIdentity? originIdentity;

  MemberSeed copyWith({
    String? id,
    String? name,
    Object? username = _messageSeedSentinel,
    String? status,
    String? initials,
    String? role,
    List<String>? roleIds,
    Object? displayColor = _messageSeedSentinel,
    Object? nameColorName = _messageSeedSentinel,
    String? avatarUrl,
    String? bannerUrl,
    Color? bannerBaseColor,
    BannerCrop? bannerCrop,
    String? memberListBannerUrl,
    BannerCrop? memberListBannerCrop,
    String? lastMessageAt,
    bool? isActive,
    bool? isBot,
    Object? originIdentity = _messageSeedSentinel,
  }) {
    return MemberSeed(
      id: id ?? this.id,
      name: name ?? this.name,
      username: identical(username, _messageSeedSentinel)
          ? this.username
          : username as String?,
      status: status ?? this.status,
      initials: initials ?? this.initials,
      role: role ?? this.role,
      roleIds: roleIds ?? this.roleIds,
      displayColor: identical(displayColor, _messageSeedSentinel)
          ? this.displayColor
          : displayColor as Color?,
      nameColorName: identical(nameColorName, _messageSeedSentinel)
          ? this.nameColorName
          : nameColorName as String?,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bannerBaseColor: bannerBaseColor ?? this.bannerBaseColor,
      bannerCrop: bannerCrop ?? this.bannerCrop,
      memberListBannerUrl: memberListBannerUrl ?? this.memberListBannerUrl,
      memberListBannerCrop: memberListBannerCrop ?? this.memberListBannerCrop,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isActive: isActive ?? this.isActive,
      isBot: isBot ?? this.isBot,
      originIdentity: identical(originIdentity, _messageSeedSentinel)
          ? this.originIdentity
          : originIdentity as FederatedOriginIdentity?,
    );
  }
}

class MessageSeed {
  const MessageSeed({
    required this.id,
    required this.authorId,
    required this.author,
    required this.time,
    required this.body,
    required this.initials,
    this.createdAt,
    this.avatarUrl,
    this.authorColor,
    this.authorBannerBaseColor,
    this.media,
    this.reactions = const [],
    this.isOwnMessage = false,
  });

  final String id;
  final String authorId;
  final String author;
  final String time;
  final String body;
  final String initials;
  final String? createdAt;
  final String? avatarUrl;
  final Color? authorColor;
  final Color? authorBannerBaseColor;
  final MessageMediaSeed? media;
  final List<ReactionSeed> reactions;
  final bool isOwnMessage;

  MessageSeed copyWith({List<ReactionSeed>? reactions}) {
    return MessageSeed(
      id: id,
      authorId: authorId,
      author: author,
      time: time,
      body: body,
      initials: initials,
      createdAt: createdAt,
      avatarUrl: avatarUrl,
      authorColor: authorColor,
      authorBannerBaseColor: authorBannerBaseColor,
      media: media,
      reactions: reactions ?? this.reactions,
      isOwnMessage: isOwnMessage,
    );
  }

  MessageSeed copyWithFields({
    String? author,
    String? time,
    String? body,
    String? initials,
    String? createdAt,
    Object? avatarUrl = _messageSeedSentinel,
    Color? authorColor,
    Color? authorBannerBaseColor,
    MessageMediaSeed? media,
    List<ReactionSeed>? reactions,
    bool? isOwnMessage,
  }) {
    return MessageSeed(
      id: id,
      authorId: authorId,
      author: author ?? this.author,
      time: time ?? this.time,
      body: body ?? this.body,
      initials: initials ?? this.initials,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: identical(avatarUrl, _messageSeedSentinel)
          ? this.avatarUrl
          : avatarUrl as String?,
      authorColor: authorColor ?? this.authorColor,
      authorBannerBaseColor:
          authorBannerBaseColor ?? this.authorBannerBaseColor,
      media: media ?? this.media,
      reactions: reactions ?? this.reactions,
      isOwnMessage: isOwnMessage ?? this.isOwnMessage,
    );
  }
}

class MessageMediaSeed {
  const MessageMediaSeed({
    required this.id,
    required this.label,
    required this.kind,
    required this.width,
    required this.height,
    this.url,
    this.contentType,
    this.sizeBytes,
  });

  final String id;
  final String label;
  final MessageMediaKind kind;
  final int width;
  final int height;
  final String? url;
  final String? contentType;
  final int? sizeBytes;
}

enum MessageMediaKind {
  gif('GIF', 'gif'),
  webp('WebP', 'webp'),
  image('Image', 'png');

  const MessageMediaKind(this.label, this.extension);

  final String label;
  final String extension;
}

class ReactionSeed {
  const ReactionSeed({
    required this.emoji,
    required this.count,
    this.emojiId,
    this.reactedByCurrentUser = false,
  });

  final String emoji;
  final int count;
  final String? emojiId;
  final bool reactedByCurrentUser;
}

typedef ServerReactionChangeHandler =
    Future<void> Function({
      required String messageId,
      required String emoji,
      String? emojiId,
      required bool selected,
    });

abstract final class VerdantAuthorColors {
  static const green = Color(0xFF7CFFDE);
  static const purple = Color(0xFFC1B3FF);
  static const yellow = Color(0xFFFFD166);
  static const blue = Color(0xFF8AB4FF);
}

Color? parseVerdantColor(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final normalized = trimmed.startsWith('#')
      ? trimmed.substring(1)
      : trimmed.startsWith('0x')
      ? trimmed.substring(2)
      : trimmed;
  if (!RegExp(r'^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(normalized)) {
    return null;
  }
  final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
  return Color(int.parse(hex, radix: 16));
}

bool _statusLooksOffline(String value) {
  return value.toLowerCase().contains('offline');
}

String _roleLabelForIds(
  List<String> roleIds,
  List<ServerSettingsListItemSeed> roles, {
  String? fallback,
}) {
  final names = _rolesForIds(roleIds, roles)
      .where((role) => !role.colorOnly)
      .where((role) => role.title.trim().isNotEmpty)
      .map((role) => role.title.trim())
      .toList(growable: false);
  if (names.isNotEmpty) {
    return names.join(', ');
  }
  final trimmedFallback = fallback?.trim();
  return trimmedFallback == null || trimmedFallback.isEmpty
      ? 'Member'
      : trimmedFallback;
}

Color? _roleAccentForIds(
  List<String> roleIds,
  List<ServerSettingsListItemSeed> roles,
) {
  final nameColor = _nameColorRoleForIds(roleIds, roles);
  if (nameColor?.accent != null) {
    return nameColor!.accent;
  }
  for (final role in _rolesForIds(roleIds, roles)) {
    if (!role.colorOnly && role.accent != null) {
      return role.accent;
    }
  }
  return null;
}

ServerSettingsListItemSeed? _nameColorRoleForIds(
  List<String> roleIds,
  List<ServerSettingsListItemSeed> roles,
) {
  final colorRoles = _rolesForIds(roleIds, roles)
      .where((role) => role.colorOnly && role.accent != null)
      .toList(growable: false);
  if (colorRoles.isEmpty) {
    return null;
  }
  colorRoles.sort((left, right) {
    final priority = (right.colorPriority ?? 0).compareTo(
      left.colorPriority ?? 0,
    );
    if (priority != 0) {
      return priority;
    }
    return left.title.compareTo(right.title);
  });
  return colorRoles.first;
}

List<ServerSettingsListItemSeed> _rolesForIds(
  List<String> roleIds,
  List<ServerSettingsListItemSeed> roles,
) {
  if (roleIds.isEmpty || roles.isEmpty) {
    return const [];
  }
  final rolesById = <String, ServerSettingsListItemSeed>{};
  for (final role in roles) {
    final id = role.id;
    if (id != null && id.trim().isNotEmpty) {
      rolesById[_localRoleId(id)] = role;
    }
  }
  return [for (final roleId in roleIds) ?rolesById[_localRoleId(roleId)]];
}

String _localRoleId(String value) {
  final slash = value.indexOf('/');
  if (slash >= 0 && slash < value.length - 1) {
    return value.substring(slash + 1);
  }
  return value;
}
