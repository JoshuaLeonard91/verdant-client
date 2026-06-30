import '../workspace_seed.dart';
import '../workspace_local_id.dart';
import '../shared/workspace_entitlements.dart';

enum FriendRelationshipKind {
  friend,
  pendingIncoming,
  pendingOutgoing,
  blocked,
}

final class DirectMessagesWorkspaceData {
  const DirectMessagesWorkspaceData({
    required this.networkId,
    required this.currentUserName,
    required this.currentUserInitials,
    required this.conversations,
    required this.friends,
    this.hiddenChannelIds,
    this.entitlements = const WorkspaceEntitlements.disabled(),
    this.currentUserStatus = 'Online',
    this.hasHydrated = true,
    this.isRefreshing = false,
    this.error,
  });

  factory DirectMessagesWorkspaceData.empty({
    required String networkId,
    required String currentUserName,
    required String currentUserInitials,
    bool hasHydrated = true,
    String? error,
  }) {
    return DirectMessagesWorkspaceData(
      networkId: networkId,
      currentUserName: currentUserName,
      currentUserInitials: currentUserInitials,
      currentUserStatus: 'Online',
      conversations: const [],
      friends: const [],
      entitlements: const WorkspaceEntitlements.disabled(),
      hasHydrated: hasHydrated,
      error: error,
    );
  }

  final String networkId;
  final String currentUserName;
  final String currentUserInitials;
  final String currentUserStatus;
  final List<DmConversationPreviewSeed> conversations;
  final List<FriendPreviewSeed> friends;
  final Set<String>? hiddenChannelIds;
  final WorkspaceEntitlements entitlements;
  final bool hasHydrated;
  final bool isRefreshing;
  final String? error;

  DirectMessagesWorkspaceData copyWith({
    String? networkId,
    String? currentUserName,
    String? currentUserInitials,
    String? currentUserStatus,
    List<DmConversationPreviewSeed>? conversations,
    List<FriendPreviewSeed>? friends,
    Object? hiddenChannelIds = _sentinel,
    WorkspaceEntitlements? entitlements,
    bool? hasHydrated,
    bool? isRefreshing,
    Object? error = _sentinel,
  }) {
    return DirectMessagesWorkspaceData(
      networkId: networkId ?? this.networkId,
      currentUserName: currentUserName ?? this.currentUserName,
      currentUserInitials: currentUserInitials ?? this.currentUserInitials,
      currentUserStatus: currentUserStatus ?? this.currentUserStatus,
      conversations: conversations ?? this.conversations,
      friends: friends ?? this.friends,
      hiddenChannelIds: identical(hiddenChannelIds, _sentinel)
          ? this.hiddenChannelIds
          : hiddenChannelIds as Set<String>?,
      entitlements: entitlements ?? this.entitlements,
      hasHydrated: hasHydrated ?? this.hasHydrated,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

final class DmConversationPreviewSeed {
  const DmConversationPreviewSeed({
    required this.channelId,
    required this.localChannelId,
    required this.networkId,
    required this.displayName,
    required this.initials,
    required this.status,
    required this.lastMessage,
    this.localUserId,
    this.avatarUrl,
    this.bannerUrl,
    this.unreadCount = 0,
  });

  final String channelId;
  final String localChannelId;
  final String networkId;
  final String displayName;
  final String initials;
  final String status;
  final String lastMessage;
  final String? localUserId;
  final String? avatarUrl;
  final String? bannerUrl;
  final int unreadCount;

  DmConversationPreviewSeed copyWith({
    String? channelId,
    String? localChannelId,
    String? networkId,
    String? displayName,
    String? initials,
    String? status,
    String? lastMessage,
    Object? localUserId = _sentinel,
    Object? avatarUrl = _sentinel,
    Object? bannerUrl = _sentinel,
    int? unreadCount,
  }) {
    return DmConversationPreviewSeed(
      channelId: channelId ?? this.channelId,
      localChannelId: localChannelId ?? this.localChannelId,
      networkId: networkId ?? this.networkId,
      displayName: displayName ?? this.displayName,
      initials: initials ?? this.initials,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      localUserId: identical(localUserId, _sentinel)
          ? this.localUserId
          : localUserId as String?,
      avatarUrl: identical(avatarUrl, _sentinel)
          ? this.avatarUrl
          : avatarUrl as String?,
      bannerUrl: identical(bannerUrl, _sentinel)
          ? this.bannerUrl
          : bannerUrl as String?,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

final class DmConversationMessages {
  const DmConversationMessages({
    required this.channelId,
    required this.messages,
    this.error,
  });

  final String channelId;
  final List<MessageSeed> messages;
  final String? error;
}

final class FriendPreviewSeed {
  const FriendPreviewSeed({
    required this.id,
    required this.localUserId,
    required this.networkId,
    required this.displayName,
    required this.initials,
    required this.status,
    required this.detail,
    required this.kind,
    this.avatarUrl,
    this.bannerUrl,
  });

  final String id;
  final String localUserId;
  final String networkId;
  final String displayName;
  final String initials;
  final String status;
  final String detail;
  final FriendRelationshipKind kind;
  final String? avatarUrl;
  final String? bannerUrl;

  FriendPreviewSeed copyWith({
    String? id,
    String? localUserId,
    String? networkId,
    String? displayName,
    String? initials,
    String? status,
    String? detail,
    FriendRelationshipKind? kind,
    Object? avatarUrl = _sentinel,
    Object? bannerUrl = _sentinel,
  }) {
    return FriendPreviewSeed(
      id: id ?? this.id,
      localUserId: localUserId ?? this.localUserId,
      networkId: networkId ?? this.networkId,
      displayName: displayName ?? this.displayName,
      initials: initials ?? this.initials,
      status: status ?? this.status,
      detail: detail ?? this.detail,
      kind: kind ?? this.kind,
      avatarUrl: identical(avatarUrl, _sentinel)
          ? this.avatarUrl
          : avatarUrl as String?,
      bannerUrl: identical(bannerUrl, _sentinel)
          ? this.bannerUrl
          : bannerUrl as String?,
    );
  }
}

sealed class DirectMessagesRealtimeEvent {
  const DirectMessagesRealtimeEvent();
}

const Object workspaceEventUnset = Object();

final class DirectMessagesSnapshotEvent extends DirectMessagesRealtimeEvent {
  const DirectMessagesSnapshotEvent(this.data);

  final DirectMessagesWorkspaceData data;
}

final class DirectMessagesMessageCreateEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesMessageCreateEvent({
    required this.channelId,
    required this.message,
  });

  final String channelId;
  final MessageSeed message;
}

final class DirectMessagesMessageUpdateEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesMessageUpdateEvent({
    required this.channelId,
    required this.message,
  });

  final String channelId;
  final MessageSeed message;
}

final class DirectMessagesMessageDeleteEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesMessageDeleteEvent({
    required this.channelId,
    required this.messageId,
  });

  final String channelId;
  final String messageId;
}

final class DirectMessagesPresenceUpdateEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesPresenceUpdateEvent({
    required this.localUserId,
    required this.status,
  });

  final String localUserId;
  final String status;
}

final class DirectMessagesBotPresenceUpdateEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesBotPresenceUpdateEvent({
    required this.localBotId,
    required this.serverId,
    required this.status,
  });

  final String localBotId;
  final String serverId;
  final String status;
}

final class DirectMessagesUserProfileUpdateEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesUserProfileUpdateEvent({
    required this.localUserId,
    this.displayName = workspaceEventUnset,
    this.avatarUrl = workspaceEventUnset,
    this.bannerUrl = workspaceEventUnset,
    this.bannerBaseColor = workspaceEventUnset,
    this.bio = workspaceEventUnset,
  });

  final String localUserId;
  final Object? displayName;
  final Object? avatarUrl;
  final Object? bannerUrl;
  final Object? bannerBaseColor;
  final Object? bio;
}

final class DirectMessagesChannelActivityEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesChannelActivityEvent({
    required this.channelId,
    required this.localUserId,
    this.lastMessageAt,
    this.displayName,
    this.avatarUrl,
  });

  final String channelId;
  final String localUserId;
  final String? lastMessageAt;
  final String? displayName;
  final String? avatarUrl;
}

final class DirectMessagesChannelUnreadEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesChannelUnreadEvent({
    required this.channelId,
    required this.messageId,
    required this.localAuthorId,
    required this.mentionsCurrentUser,
    required this.isDirectMessage,
  });

  final String channelId;
  final String messageId;
  final String localAuthorId;
  final bool mentionsCurrentUser;
  final bool isDirectMessage;
}

final class DirectMessagesTypingStartEvent extends DirectMessagesRealtimeEvent {
  const DirectMessagesTypingStartEvent({
    required this.channelId,
    required this.localUserId,
  });

  final String channelId;
  final String localUserId;
}

final class DirectMessagesServerChannelUpsertEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesServerChannelUpsertEvent({
    required this.channel,
    this.serverId,
  });

  final ChannelSeed channel;
  final String? serverId;
}

final class DirectMessagesServerChannelDeleteEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesServerChannelDeleteEvent({
    required this.channelId,
    this.serverId,
  });

  final String channelId;
  final String? serverId;
}

final class DirectMessagesServerDeleteEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesServerDeleteEvent({required this.serverId});

  final String serverId;
}

final class DirectMessagesServerMemberUpsertEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesServerMemberUpsertEvent({
    required this.member,
    this.serverId,
  });

  final MemberSeed member;
  final String? serverId;
}

final class DirectMessagesServerMemberRemoveEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesServerMemberRemoveEvent({
    required this.userId,
    this.serverId,
  });

  final String userId;
  final String? serverId;
}

final class DirectMessagesServerMemberRoleUpdateEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesServerMemberRoleUpdateEvent({
    required this.userId,
    required this.roleIds,
    this.serverId,
  });

  final String userId;
  final List<String> roleIds;
  final String? serverId;
}

final class DirectMessagesConversationUpsertEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesConversationUpsertEvent(this.conversation);

  final DmConversationPreviewSeed conversation;
}

final class DirectMessagesRelationshipUpsertEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesRelationshipUpsertEvent(this.friend);

  final FriendPreviewSeed friend;
}

final class DirectMessagesRelationshipRemoveEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesRelationshipRemoveEvent({required this.localUserId});

  final String localUserId;
}

final class DirectMessagesReactionAddEvent extends DirectMessagesRealtimeEvent {
  const DirectMessagesReactionAddEvent({
    required this.channelId,
    required this.messageId,
    required this.localUserId,
    required this.emoji,
    this.emojiId,
  });

  final String channelId;
  final String messageId;
  final String localUserId;
  final String emoji;
  final String? emojiId;
}

final class DirectMessagesReactionRemoveEvent
    extends DirectMessagesRealtimeEvent {
  const DirectMessagesReactionRemoveEvent({
    required this.channelId,
    required this.messageId,
    required this.localUserId,
    required this.emoji,
  });

  final String channelId;
  final String messageId;
  final String localUserId;
  final String emoji;
}

String scopedWorkspaceId(String networkId, String localId) {
  final network = _safeWorkspaceNetworkId(networkId);
  final raw = localId.trim();
  if (raw.isEmpty) {
    throw const FormatException('Invalid workspace local id');
  }
  final slash = raw.indexOf('/');
  if (slash >= 0) {
    if (slash == 0 ||
        slash == raw.length - 1 ||
        raw.indexOf('/', slash + 1) >= 0) {
      throw const FormatException('Invalid workspace scoped id');
    }
    final incomingNetwork = raw.substring(0, slash);
    if (!sameWorkspaceNetworkId(incomingNetwork, network)) {
      throw const FormatException('Invalid workspace scoped id');
    }
    final local = safeWorkspaceLocalId(raw.substring(slash + 1));
    return '$network/$local';
  }
  return '$network/${safeWorkspaceLocalId(raw)}';
}

bool isSafeScopedWorkspaceId(String value, {required String networkId}) {
  try {
    final trimmed = value.trim();
    final scoped = scopedWorkspaceId(networkId, trimmed);
    if (scoped == trimmed) {
      return true;
    }
    final slash = trimmed.indexOf('/');
    if (slash <= 0 || slash == trimmed.length - 1) {
      return false;
    }
    return sameWorkspaceNetworkId(trimmed.substring(0, slash), networkId) &&
        scoped.substring(scoped.indexOf('/') + 1) ==
            trimmed.substring(slash + 1);
  } on FormatException {
    return false;
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

String initialsForDisplayName(String value) {
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

const Object _sentinel = Object();
