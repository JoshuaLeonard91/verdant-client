import 'package:flutter/material.dart';

import '../shared/json_value.dart';
import '../shared/workspace_entitlements.dart';
import 'server_media_url_policy.dart';
import 'server_settings_permissions.dart';

class FederatedOriginIdentity {
  const FederatedOriginIdentity({
    required this.homePeerId,
    required this.remoteUserId,
    this.remoteUsername,
  });

  final String homePeerId;
  final String remoteUserId;
  final String? remoteUsername;
}

final class BannerCrop {
  const BannerCrop({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory BannerCrop.fromJson(Map<String, Object?> json) {
    return BannerCrop(
      x: _roundedPercent(_doubleValue(json['x'])),
      y: _roundedPercent(_doubleValue(json['y'])),
      width: _roundedPercent(_doubleValue(json['width'])),
      height: _roundedPercent(_doubleValue(json['height'])),
    );
  }

  final double x;
  final double y;
  final double width;
  final double height;

  Map<String, Object?> toJson() {
    return {'x': x, 'y': y, 'width': width, 'height': height};
  }

  BannerCrop normalized() {
    final nextX = x.clamp(0, 100).toDouble();
    final nextY = y.clamp(0, 100).toDouble();
    final nextWidth = width.clamp(0.01, 100).toDouble();
    final nextHeight = height.clamp(0.01, 100).toDouble();
    if (nextX + nextWidth > 100.25 || nextY + nextHeight > 100.25) {
      return const BannerCrop(x: 0, y: 0, width: 100, height: 100);
    }
    return BannerCrop(
      x: _roundedPercent(nextX),
      y: _roundedPercent(nextY),
      width: _roundedPercent(nextWidth),
      height: _roundedPercent(nextHeight),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BannerCrop &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() {
    return 'BannerCrop(x: $x, y: $y, width: $width, height: $height)';
  }
}

final class ServerSettingsServer {
  const ServerSettingsServer({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.voiceBitrate,
    required this.bannerOffsetY,
    required this.memberCount,
    required this.large,
    required this.createdAt,
    required this.updatedAt,
    this.iconUrl,
    this.description,
    this.welcomeChannelId,
    this.announceChannelId,
    this.bannerUrl,
    this.bannerCrop,
    this.accentColor,
  });

  factory ServerSettingsServer.fromJson(Map<String, Object?> json) {
    final bannerCrop = _mapValue(json['bannerCrop']);
    final legacyBannerCrop = _mapValue(json['banner_crop']);
    return ServerSettingsServer(
      id: _stringValue(json['id'], fallback: 'unknown'),
      name: _stringValue(json['name'], fallback: 'Untitled Server'),
      ownerId: _stringValue(
        json['ownerId'],
        fallback: _stringValue(json['owner_id'], fallback: ''),
      ),
      iconUrl:
          _nullableString(json['iconUrl']) ?? _nullableString(json['icon_url']),
      description: _nullableString(json['description']),
      voiceBitrate: _intValue(json['voiceBitrate'], fallback: 64000),
      welcomeChannelId: _nullableString(json['welcomeChannelId']),
      announceChannelId: _nullableString(json['announceChannelId']),
      bannerUrl:
          _nullableString(json['bannerUrl']) ??
          _nullableString(json['banner_url']),
      bannerCrop: (bannerCrop ?? legacyBannerCrop) == null
          ? null
          : BannerCrop.fromJson((bannerCrop ?? legacyBannerCrop)!).normalized(),
      accentColor: _nullableString(json['accentColor']),
      bannerOffsetY: _intValue(json['bannerOffsetY'], fallback: 50),
      memberCount: _intValue(json['memberCount'], fallback: 0),
      large: json['large'] == true,
      createdAt: _stringValue(json['createdAt'], fallback: ''),
      updatedAt: _stringValue(json['updatedAt'], fallback: ''),
    );
  }

  final String id;
  final String name;
  final String ownerId;
  final String? iconUrl;
  final String? description;
  final int voiceBitrate;
  final String? welcomeChannelId;
  final String? announceChannelId;
  final String? bannerUrl;
  final BannerCrop? bannerCrop;
  final String? accentColor;
  final int bannerOffsetY;
  final int memberCount;
  final bool large;
  final String createdAt;
  final String updatedAt;

  ServerSettingsServer copyWith({
    String? id,
    String? name,
    String? ownerId,
    Object? iconUrl = _sentinel,
    Object? description = _sentinel,
    int? voiceBitrate,
    Object? welcomeChannelId = _sentinel,
    Object? announceChannelId = _sentinel,
    Object? bannerUrl = _sentinel,
    Object? bannerCrop = _sentinel,
    Object? accentColor = _sentinel,
    int? bannerOffsetY,
    int? memberCount,
    bool? large,
    String? createdAt,
    String? updatedAt,
  }) {
    return ServerSettingsServer(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      iconUrl: identical(iconUrl, _sentinel)
          ? this.iconUrl
          : iconUrl as String?,
      description: identical(description, _sentinel)
          ? this.description
          : description as String?,
      voiceBitrate: voiceBitrate ?? this.voiceBitrate,
      welcomeChannelId: identical(welcomeChannelId, _sentinel)
          ? this.welcomeChannelId
          : welcomeChannelId as String?,
      announceChannelId: identical(announceChannelId, _sentinel)
          ? this.announceChannelId
          : announceChannelId as String?,
      bannerUrl: identical(bannerUrl, _sentinel)
          ? this.bannerUrl
          : bannerUrl as String?,
      bannerCrop: identical(bannerCrop, _sentinel)
          ? this.bannerCrop
          : bannerCrop as BannerCrop?,
      accentColor: identical(accentColor, _sentinel)
          ? this.accentColor
          : accentColor as String?,
      bannerOffsetY: bannerOffsetY ?? this.bannerOffsetY,
      memberCount: memberCount ?? this.memberCount,
      large: large ?? this.large,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

final class ServerInvitePreview {
  const ServerInvitePreview({
    required this.code,
    required this.server,
    required this.inviterUsername,
    required this.isMember,
    this.federated = false,
    this.instanceId,
    this.instanceMode,
  });

  factory ServerInvitePreview.fromJson(Map<String, Object?> json) {
    final server = _mapValue(json['server']);
    if (server == null) {
      throw const FormatException('Invite preview was missing server');
    }
    final instance = _mapValue(json['instance']);
    return ServerInvitePreview(
      code: _stringValue(json['code'], fallback: ''),
      server: ServerSettingsServer.fromJson(server),
      inviterUsername: _stringValue(
        json['inviterUsername'],
        fallback: 'someone',
      ),
      isMember: json['isMember'] == true,
      federated: json['federated'] == true,
      instanceId: _nullableString(instance?['id']),
      instanceMode: _nullableString(instance?['mode']),
    );
  }

  final String code;
  final ServerSettingsServer server;
  final String inviterUsername;
  final bool isMember;
  final bool federated;
  final String? instanceId;
  final String? instanceMode;
}

final class ServerSettingsData {
  const ServerSettingsData({
    required this.networkId,
    required this.server,
    required this.channels,
    required this.emojis,
    required this.invites,
    required this.roles,
    required this.members,
    required this.auditEvents,
    required this.feeds,
    required this.bots,
    this.mediaPolicy = const ServerMediaPolicy(
      allowedOrigins: {},
      allowLocalHttp: false,
    ),
    this.entitlements = const WorkspaceEntitlements.disabled(),
    this.stickers = const <ServerSettingsListItemSeed>[],
  });

  final String networkId;
  final ServerSettingsServer server;
  final List<ServerSettingsChannelSeed> channels;
  final List<ServerSettingsListItemSeed> emojis;
  final List<ServerSettingsListItemSeed> stickers;
  final List<ServerSettingsListItemSeed> invites;
  final List<ServerSettingsListItemSeed> roles;
  final List<ServerSettingsListItemSeed> members;
  final List<ServerSettingsListItemSeed> auditEvents;
  final List<ServerSettingsListItemSeed> feeds;
  final List<ServerSettingsListItemSeed> bots;
  final ServerMediaPolicy mediaPolicy;
  final WorkspaceEntitlements entitlements;

  ServerSettingsData copyWith({
    ServerSettingsServer? server,
    List<ServerSettingsChannelSeed>? channels,
    List<ServerSettingsListItemSeed>? emojis,
    List<ServerSettingsListItemSeed>? stickers,
    List<ServerSettingsListItemSeed>? invites,
    List<ServerSettingsListItemSeed>? roles,
    List<ServerSettingsListItemSeed>? members,
    List<ServerSettingsListItemSeed>? auditEvents,
    List<ServerSettingsListItemSeed>? feeds,
    List<ServerSettingsListItemSeed>? bots,
    ServerMediaPolicy? mediaPolicy,
    WorkspaceEntitlements? entitlements,
  }) {
    return ServerSettingsData(
      networkId: networkId,
      server: server ?? this.server,
      channels: channels ?? this.channels,
      emojis: emojis ?? this.emojis,
      stickers: stickers ?? this.stickers,
      invites: invites ?? this.invites,
      roles: roles ?? this.roles,
      members: members ?? this.members,
      auditEvents: auditEvents ?? this.auditEvents,
      feeds: feeds ?? this.feeds,
      bots: bots ?? this.bots,
      mediaPolicy: mediaPolicy ?? this.mediaPolicy,
      entitlements: entitlements ?? this.entitlements,
    );
  }
}

final class ServerSettingsCurrentUserMedia {
  const ServerSettingsCurrentUserMedia({
    required this.id,
    this.username,
    this.displayName,
    this.email,
    this.bio,
    this.status,
    this.usernameSet,
    this.emailVerified,
    this.totpEnabled,
    this.avatarUrl,
    this.bannerUrl,
    this.bannerBaseColor,
    this.bannerCrop,
    this.memberListBannerUrl,
    this.memberListBannerCrop,
  });

  factory ServerSettingsCurrentUserMedia.fromJson(Map<String, Object?> json) {
    final bannerCrop = _mapValue(json['bannerCrop']);
    final memberListBannerCrop = _mapValue(json['memberListBannerCrop']);
    return ServerSettingsCurrentUserMedia(
      id: _stringValue(json['id'], fallback: ''),
      username: _nullableString(json['username']),
      displayName: _nullableString(json['displayName']),
      email: _nullableString(json['email']),
      bio: _nullableString(json['bio']),
      status: _nullableString(json['status']),
      usernameSet: _nullableBool(json['usernameSet']),
      emailVerified: _nullableBool(json['emailVerified']),
      totpEnabled: _nullableBool(json['totpEnabled']),
      avatarUrl: _nullableString(json['avatarUrl']),
      bannerUrl: _nullableString(json['bannerUrl']),
      bannerBaseColor: _colorValue(json['bannerBaseColor']),
      bannerCrop: bannerCrop == null
          ? null
          : BannerCrop.fromJson(bannerCrop).normalized(),
      memberListBannerUrl: _nullableString(json['memberListBannerUrl']),
      memberListBannerCrop: memberListBannerCrop == null
          ? null
          : BannerCrop.fromJson(memberListBannerCrop).normalized(),
    );
  }

  final String id;
  final String? username;
  final String? displayName;
  final String? email;
  final String? bio;
  final String? status;
  final bool? usernameSet;
  final bool? emailVerified;
  final bool? totpEnabled;
  final String? avatarUrl;
  final String? bannerUrl;
  final Color? bannerBaseColor;
  final BannerCrop? bannerCrop;
  final String? memberListBannerUrl;
  final BannerCrop? memberListBannerCrop;

  ServerSettingsCurrentUserMedia copyWith({
    String? id,
    Object? username = _sentinel,
    Object? displayName = _sentinel,
    Object? email = _sentinel,
    Object? bio = _sentinel,
    Object? status = _sentinel,
    Object? usernameSet = _sentinel,
    Object? emailVerified = _sentinel,
    Object? totpEnabled = _sentinel,
    Object? avatarUrl = _sentinel,
    Object? bannerUrl = _sentinel,
    Object? bannerBaseColor = _sentinel,
    Object? bannerCrop = _sentinel,
    Object? memberListBannerUrl = _sentinel,
    Object? memberListBannerCrop = _sentinel,
  }) {
    return ServerSettingsCurrentUserMedia(
      id: id ?? this.id,
      username: identical(username, _sentinel)
          ? this.username
          : username as String?,
      displayName: identical(displayName, _sentinel)
          ? this.displayName
          : displayName as String?,
      email: identical(email, _sentinel) ? this.email : email as String?,
      bio: identical(bio, _sentinel) ? this.bio : bio as String?,
      status: identical(status, _sentinel) ? this.status : status as String?,
      usernameSet: identical(usernameSet, _sentinel)
          ? this.usernameSet
          : usernameSet as bool?,
      emailVerified: identical(emailVerified, _sentinel)
          ? this.emailVerified
          : emailVerified as bool?,
      totpEnabled: identical(totpEnabled, _sentinel)
          ? this.totpEnabled
          : totpEnabled as bool?,
      avatarUrl: identical(avatarUrl, _sentinel)
          ? this.avatarUrl
          : avatarUrl as String?,
      bannerUrl: identical(bannerUrl, _sentinel)
          ? this.bannerUrl
          : bannerUrl as String?,
      bannerBaseColor: identical(bannerBaseColor, _sentinel)
          ? this.bannerBaseColor
          : bannerBaseColor as Color?,
      bannerCrop: identical(bannerCrop, _sentinel)
          ? this.bannerCrop
          : bannerCrop as BannerCrop?,
      memberListBannerUrl: identical(memberListBannerUrl, _sentinel)
          ? this.memberListBannerUrl
          : memberListBannerUrl as String?,
      memberListBannerCrop: identical(memberListBannerCrop, _sentinel)
          ? this.memberListBannerCrop
          : memberListBannerCrop as BannerCrop?,
    );
  }
}

final class UserAvatarUpdate {
  const UserAvatarUpdate({this.avatarUrl});

  factory UserAvatarUpdate.fromJson(Map<String, Object?> json) {
    return UserAvatarUpdate(avatarUrl: _nullableString(json['avatarUrl']));
  }

  final String? avatarUrl;
}

final class UserProfileBannerUpdate {
  const UserProfileBannerUpdate({this.bannerUrl, this.bannerCrop});

  factory UserProfileBannerUpdate.fromJson(Map<String, Object?> json) {
    final bannerCrop = _mapValue(json['bannerCrop']);
    return UserProfileBannerUpdate(
      bannerUrl: _nullableString(json['bannerUrl']),
      bannerCrop: bannerCrop == null
          ? null
          : BannerCrop.fromJson(bannerCrop).normalized(),
    );
  }

  final String? bannerUrl;
  final BannerCrop? bannerCrop;
}

final class UserMemberListBannerUpdate {
  const UserMemberListBannerUpdate({
    this.memberListBannerUrl,
    this.memberListBannerCrop,
  });

  factory UserMemberListBannerUpdate.fromJson(Map<String, Object?> json) {
    final memberListBannerCrop = _mapValue(json['memberListBannerCrop']);
    return UserMemberListBannerUpdate(
      memberListBannerUrl: _nullableString(json['memberListBannerUrl']),
      memberListBannerCrop: memberListBannerCrop == null
          ? null
          : BannerCrop.fromJson(memberListBannerCrop).normalized(),
    );
  }

  final String? memberListBannerUrl;
  final BannerCrop? memberListBannerCrop;
}

enum ServerSettingsTabId {
  overview(
    key: 'overview',
    label: 'Overview',
    icon: Icons.tune,
    permissionHint: 'Manage server',
  ),
  emoji(
    key: 'emoji',
    label: 'Emoji',
    icon: Icons.emoji_emotions_outlined,
    permissionHint: 'Manage server',
  ),
  stickers(
    key: 'stickers',
    label: 'Stickers',
    icon: Icons.sticky_note_2_outlined,
    permissionHint: 'Manage server',
  ),
  invites(
    key: 'invites',
    label: 'Invites',
    icon: Icons.link,
    permissionHint: 'Manage server',
  ),
  roles(
    key: 'roles',
    label: 'Roles',
    icon: Icons.shield_outlined,
    permissionHint: 'Manage roles',
  ),
  members(
    key: 'members',
    label: 'Members',
    icon: Icons.groups_outlined,
    permissionHint: 'Moderate members',
  ),
  auditLog(
    key: 'audit-log',
    label: 'Audit Log',
    icon: Icons.assignment_outlined,
    permissionHint: 'Manage server',
  ),
  feeds(
    key: 'feeds',
    label: 'Feeds',
    icon: Icons.campaign_outlined,
    permissionHint: 'Manage server',
  ),
  bots(
    key: 'bots',
    label: 'Bots',
    icon: Icons.smart_toy_outlined,
    permissionHint: 'Manage server',
  );

  const ServerSettingsTabId({
    required this.key,
    required this.label,
    required this.icon,
    required this.permissionHint,
  });

  final String key;
  final String label;
  final IconData icon;
  final String permissionHint;
}

class ServerSettingsSeed {
  const ServerSettingsSeed({
    required this.networkId,
    required this.localServerId,
    required this.serverName,
    required this.description,
    required this.memberCount,
    required this.ownerName,
    required this.createdLabel,
    required this.channels,
    required this.emojis,
    required this.invites,
    required this.roles,
    required this.members,
    required this.auditEvents,
    required this.feeds,
    required this.bots,
    this.canManageServer = false,
    this.canManageChannels = false,
    this.canManageMessages = false,
    this.canManageRoles = false,
    this.canKickMembers = false,
    this.canBanMembers = false,
    this.canModerateMembers = false,
    this.stickers = const <ServerSettingsListItemSeed>[],
  });

  factory ServerSettingsSeed.fromData(
    ServerSettingsData data, {
    String? currentUserId,
  }) {
    final isOwner =
        currentUserId != null &&
        _sameScopedOrLocalId(
          data.server.ownerId,
          currentUserId,
          networkId: data.networkId,
        );
    final permissions = isOwner || currentUserId == null
        ? 0
        : _serverPermissions(data, currentUserId);
    return ServerSettingsSeed(
      networkId: data.networkId,
      localServerId: data.server.id,
      serverName: data.server.name,
      description: data.server.description ?? 'No server description set.',
      memberCount: data.server.memberCount,
      ownerName: data.server.ownerId,
      createdLabel: _dateLabel(data.server.createdAt),
      channels: data.channels,
      emojis: data.emojis,
      stickers: data.stickers,
      invites: data.invites,
      roles: data.roles,
      members: data.members,
      auditEvents: data.auditEvents,
      feeds: data.feeds,
      bots: data.bots,
      canManageServer:
          isOwner || permissionsInclude(permissions, permissionManageServer),
      canManageChannels:
          isOwner || permissionsInclude(permissions, permissionManageChannels),
      canManageMessages:
          isOwner || permissionsInclude(permissions, permissionManageMessages),
      canManageRoles:
          isOwner || permissionsInclude(permissions, permissionManageRoles),
      canKickMembers:
          isOwner || permissionsInclude(permissions, permissionKickMembers),
      canBanMembers:
          isOwner || permissionsInclude(permissions, permissionBanMembers),
      canModerateMembers:
          isOwner ||
          permissionsInclude(permissions, permissionKickMembers) ||
          permissionsInclude(permissions, permissionBanMembers),
    );
  }

  final String networkId;
  final String localServerId;
  final String serverName;
  final String description;
  final int memberCount;
  final String ownerName;
  final String createdLabel;
  final List<ServerSettingsChannelSeed> channels;
  final List<ServerSettingsListItemSeed> emojis;
  final List<ServerSettingsListItemSeed> stickers;
  final List<ServerSettingsListItemSeed> invites;
  final List<ServerSettingsListItemSeed> roles;
  final List<ServerSettingsListItemSeed> members;
  final List<ServerSettingsListItemSeed> auditEvents;
  final List<ServerSettingsListItemSeed> feeds;
  final List<ServerSettingsListItemSeed> bots;
  final bool canManageServer;
  final bool canManageChannels;
  final bool canManageMessages;
  final bool canManageRoles;
  final bool canKickMembers;
  final bool canBanMembers;
  final bool canModerateMembers;

  ServerSettingsSeed copyWith({
    String? networkId,
    String? localServerId,
    String? serverName,
    String? description,
    int? memberCount,
    String? ownerName,
    String? createdLabel,
    List<ServerSettingsChannelSeed>? channels,
    List<ServerSettingsListItemSeed>? emojis,
    List<ServerSettingsListItemSeed>? stickers,
    List<ServerSettingsListItemSeed>? invites,
    List<ServerSettingsListItemSeed>? roles,
    List<ServerSettingsListItemSeed>? members,
    List<ServerSettingsListItemSeed>? auditEvents,
    List<ServerSettingsListItemSeed>? feeds,
    List<ServerSettingsListItemSeed>? bots,
    bool? canManageServer,
    bool? canManageChannels,
    bool? canManageMessages,
    bool? canManageRoles,
    bool? canKickMembers,
    bool? canBanMembers,
    bool? canModerateMembers,
  }) {
    return ServerSettingsSeed(
      networkId: networkId ?? this.networkId,
      localServerId: localServerId ?? this.localServerId,
      serverName: serverName ?? this.serverName,
      description: description ?? this.description,
      memberCount: memberCount ?? this.memberCount,
      ownerName: ownerName ?? this.ownerName,
      createdLabel: createdLabel ?? this.createdLabel,
      channels: channels ?? this.channels,
      emojis: emojis ?? this.emojis,
      stickers: stickers ?? this.stickers,
      invites: invites ?? this.invites,
      roles: roles ?? this.roles,
      members: members ?? this.members,
      auditEvents: auditEvents ?? this.auditEvents,
      feeds: feeds ?? this.feeds,
      bots: bots ?? this.bots,
      canManageServer: canManageServer ?? this.canManageServer,
      canManageChannels: canManageChannels ?? this.canManageChannels,
      canManageMessages: canManageMessages ?? this.canManageMessages,
      canManageRoles: canManageRoles ?? this.canManageRoles,
      canKickMembers: canKickMembers ?? this.canKickMembers,
      canBanMembers: canBanMembers ?? this.canBanMembers,
      canModerateMembers: canModerateMembers ?? this.canModerateMembers,
    );
  }

  bool canOpen(ServerSettingsTabId tab) {
    return switch (tab) {
      ServerSettingsTabId.overview => true,
      ServerSettingsTabId.emoji ||
      ServerSettingsTabId.stickers ||
      ServerSettingsTabId.invites ||
      ServerSettingsTabId.auditLog ||
      ServerSettingsTabId.feeds ||
      ServerSettingsTabId.bots => canManageServer,
      ServerSettingsTabId.roles => canManageRoles,
      ServerSettingsTabId.members => canModerateMembers || canManageRoles,
    };
  }
}

class ServerSettingsChannelSeed {
  const ServerSettingsChannelSeed({
    required this.id,
    required this.name,
    this.type = 0,
    this.topic,
    this.readOnly = false,
    this.slowmodeSeconds = 0,
    this.unread = false,
    this.mentionCount = 0,
  });

  final String id;
  final String name;
  final int type;
  final String? topic;
  final bool readOnly;
  final int slowmodeSeconds;
  final bool unread;
  final int mentionCount;

  ServerSettingsChannelSeed copyWith({
    String? id,
    String? name,
    int? type,
    Object? topic = _sentinel,
    bool? readOnly,
    int? slowmodeSeconds,
    bool? unread,
    int? mentionCount,
  }) {
    return ServerSettingsChannelSeed(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      topic: identical(topic, _sentinel) ? this.topic : topic as String?,
      readOnly: readOnly ?? this.readOnly,
      slowmodeSeconds: slowmodeSeconds ?? this.slowmodeSeconds,
      unread: unread ?? this.unread,
      mentionCount: mentionCount ?? this.mentionCount,
    );
  }
}

class ServerSettingsListItemSeed {
  const ServerSettingsListItemSeed({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.accent,
    this.id,
    this.userId,
    this.username,
    this.roleIds = const [],
    this.permissions,
    this.position,
    this.colorOnly = false,
    this.showAsSection = false,
    this.colorPriority,
    this.avatarUrl,
    this.bannerUrl,
    this.bannerBaseColor,
    this.bannerCrop,
    this.memberListBannerUrl,
    this.memberListBannerCrop,
    this.originIdentity,
    this.inviteCode,
    this.inviterUsername,
    this.inviteUses,
    this.inviteMaxUses,
    this.inviteExpiresAt,
    this.inviteCreatedAt,
    this.feedServerId,
    this.feedIcon,
    this.publishRoleIds = const [],
    this.visibleRoleIds = const [],
    this.feedCreatedAt,
    this.action,
    this.actorId,
    this.actorUsername,
    this.actorAvatarUrl,
    this.targetType,
    this.targetId,
    this.reason,
    this.createdAt,
    this.metadata = const {},
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final Color? accent;
  final String? id;
  final String? userId;
  final String? username;
  final List<String> roleIds;
  final int? permissions;
  final int? position;
  final bool colorOnly;
  final bool showAsSection;
  final int? colorPriority;
  final String? avatarUrl;
  final String? bannerUrl;
  final Color? bannerBaseColor;
  final BannerCrop? bannerCrop;
  final String? memberListBannerUrl;
  final BannerCrop? memberListBannerCrop;
  final FederatedOriginIdentity? originIdentity;
  final String? inviteCode;
  final String? inviterUsername;
  final int? inviteUses;
  final int? inviteMaxUses;
  final String? inviteExpiresAt;
  final String? inviteCreatedAt;
  final String? feedServerId;
  final String? feedIcon;
  final List<String> publishRoleIds;
  final List<String> visibleRoleIds;
  final String? feedCreatedAt;
  final String? action;
  final String? actorId;
  final String? actorUsername;
  final String? actorAvatarUrl;
  final String? targetType;
  final String? targetId;
  final String? reason;
  final String? createdAt;
  final Map<String, Object?> metadata;
}

final class ServerSettingsAuditPage {
  const ServerSettingsAuditPage({required this.entries, required this.hasMore});

  final List<ServerSettingsListItemSeed> entries;
  final bool hasMore;
}

const Object _sentinel = Object();

double _doubleValue(Object? value) {
  if (value is num && value.isFinite) {
    return value.toDouble();
  }
  return 0;
}

double _roundedPercent(double value) {
  return double.parse(value.toStringAsFixed(4));
}

int _intValue(Object? value, {required int fallback}) {
  return jsonInt(value, fallback: fallback);
}

String _stringValue(Object? value, {required String fallback}) {
  return jsonString(value, fallback: fallback);
}

String? _nullableString(Object? value) {
  return jsonNullableString(value);
}

Color? _colorValue(Object? value) {
  return jsonHexColor(value);
}

bool? _nullableBool(Object? value) {
  return jsonNullableBool(value);
}

Map<String, Object?>? _mapValue(Object? value) {
  return jsonMap(value);
}

String _dateLabel(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value.isEmpty ? 'Unknown' : value;
  }
  return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
}

bool _sameScopedOrLocalId(
  String left,
  String right, {
  required String networkId,
}) {
  return _localId(left, networkId) == _localId(right, networkId);
}

String _localId(String value, String networkId) {
  final prefix = '$networkId/';
  return value.startsWith(prefix) ? value.substring(prefix.length) : value;
}

int _serverPermissions(ServerSettingsData data, String currentUserId) {
  final currentLocalId = _localId(currentUserId, data.networkId);
  ServerSettingsListItemSeed? currentMember;
  for (final member in data.members) {
    final userId = member.userId;
    if (userId != null && _localId(userId, data.networkId) == currentLocalId) {
      currentMember = member;
      break;
    }
  }
  if (currentMember == null) {
    return 0;
  }

  var combined = 0;
  final rolesById = <String, ServerSettingsListItemSeed>{};
  for (final role in data.roles) {
    final roleId = role.id;
    if (roleId == null || roleId.isEmpty) {
      continue;
    }
    rolesById[_localId(roleId, data.networkId)] = role;
    if (role.position == 0) {
      combined |= role.permissions ?? 0;
    }
  }

  for (final roleId in currentMember.roleIds) {
    final role = rolesById[_localId(roleId, data.networkId)];
    if (role == null || role.colorOnly) {
      continue;
    }
    combined |= role.permissions ?? 0;
  }
  return combined;
}
