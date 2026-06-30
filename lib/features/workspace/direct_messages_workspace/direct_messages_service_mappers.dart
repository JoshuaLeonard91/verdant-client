part of 'direct_messages_service.dart';

DirectMessagesWorkspaceData directMessagesDataFromReady(
  verdant_ws.Ready ready, {
  required String networkId,
  required String currentUserId,
  required String currentUserName,
  required String currentUserInitials,
}) {
  final entitlements =
      WorkspaceEntitlements.fromJsonString(
        ready.entitlementsJson,
      ).mergeCapabilityFallback(
        WorkspaceEntitlements.fromInstanceJsonValue(
          ready.hasInstanceJson()
              ? _tryDecodeJsonObject(ready.instanceJson)
              : null,
        ),
      );
  final friends =
      ready.relationships
          .map((relationship) {
            return _friendFromProtoRelationshipOrNull(relationship, networkId);
          })
          .whereType<FriendPreviewSeed>()
          .toList()
        ..sort(_sortFriends);

  final conversations =
      ready.dmChannels
          .map((dmChannel) {
            return _conversationFromProtoDmChannelOrNull(
              dmChannel,
              networkId: networkId,
              currentUserId: currentUserId,
            );
          })
          .whereType<DmConversationPreviewSeed>()
          .toList()
        ..sort(_sortConversations);

  return DirectMessagesWorkspaceData(
    networkId: networkId,
    currentUserName: currentUserName,
    currentUserInitials: currentUserInitials,
    entitlements: entitlements,
    hiddenChannelIds: _hiddenChannelIdsFromPreferences(
      ready.hasPreferencesJson()
          ? _tryDecodeJsonObject(ready.preferencesJson)
          : null,
      networkId,
    ),
    currentUserStatus: _normalizeStatus(
      _stringValue(ready.userStatus, fallback: 'online'),
    ),
    conversations: conversations,
    friends: friends,
  );
}

DirectMessagesWorkspaceData directMessagesDataFromReadyJson(
  Map<String, Object?> ready, {
  required String networkId,
  required String currentUserId,
  required String currentUserName,
  required String currentUserInitials,
}) {
  final rawRelationships = ready['relationships'];
  final relationships = rawRelationships is List
      ? rawRelationships
      : const <Object?>[];
  final rawDmChannels = ready['dmChannels'];
  final dmChannels = rawDmChannels is List ? rawDmChannels : const <Object?>[];
  final entitlements =
      WorkspaceEntitlements.fromReadyJsonValue(
        ready['entitlements'] ?? ready['entitlementsJson'],
      ).mergeCapabilityFallback(
        WorkspaceEntitlements.fromInstanceJsonValue(
          ready['instance'] ?? ready['instanceJson'],
        ),
      );
  final preferences = _readyPreferencesFromJson(ready);

  final friends =
      relationships
          .map(_mapValue)
          .whereType<Map<String, Object?>>()
          .map((map) => _friendFromRelationshipOrNull(map, networkId))
          .whereType<FriendPreviewSeed>()
          .toList()
        ..sort(_sortFriends);

  final conversations =
      dmChannels
          .map(_mapValue)
          .whereType<Map<String, Object?>>()
          .map((map) {
            return _conversationFromDmChannelOrNull(
              map,
              networkId: networkId,
              currentUserId: currentUserId,
            );
          })
          .whereType<DmConversationPreviewSeed>()
          .toList()
        ..sort(_sortConversations);

  return DirectMessagesWorkspaceData(
    networkId: networkId,
    currentUserName: currentUserName,
    currentUserInitials: currentUserInitials,
    entitlements: entitlements,
    hiddenChannelIds: _hiddenChannelIdsFromPreferences(preferences, networkId),
    currentUserStatus: _normalizeStatus(
      _stringValue(ready['userStatus'], fallback: 'online'),
    ),
    conversations: conversations,
    friends: friends,
  );
}

FriendPreviewSeed _friendFromProtoRelationship(
  verdant_models.Relationship relationship,
  String networkId,
) {
  final user = relationship.hasUser() ? relationship.user : null;
  final localUserId = _stringValue(
    relationship.userId,
    fallback: _stringValue(user?.id, fallback: 'unknown'),
  );
  final displayName = _stringValue(user?.username, fallback: localUserId);
  final kind = _relationshipKind(relationship.type.value);
  final status = _friendStatus(
    _stringValue(user?.status, fallback: 'offline'),
    kind,
  );
  return FriendPreviewSeed(
    id: scopedWorkspaceId(networkId, localUserId),
    localUserId: localUserId,
    networkId: networkId,
    displayName: displayName,
    initials: initialsForDisplayName(displayName),
    status: status,
    detail: _relationshipDetail(kind),
    kind: kind,
    avatarUrl: user != null && user.hasAvatarUrl()
        ? _nullableString(user.avatarUrl)
        : null,
    bannerUrl: null,
  );
}

FriendPreviewSeed? _friendFromProtoRelationshipOrNull(
  verdant_models.Relationship relationship,
  String networkId,
) {
  try {
    return _friendFromProtoRelationship(relationship, networkId);
  } on FormatException {
    return null;
  }
}

DmConversationPreviewSeed _conversationFromProtoDmChannel(
  verdant_models.DmChannel dmChannel, {
  required String networkId,
  required String currentUserId,
}) {
  final localChannelId = _stringValue(dmChannel.id, fallback: 'unknown');
  final participants = dmChannel.participants;
  final other = participants.firstWhere(
    (participant) =>
        _stringValue(participant.id, fallback: '') != currentUserId,
    orElse: () => participants.isEmpty
        ? verdant_models.DmParticipant()
        : participants.first,
  );
  final explicitName = dmChannel.hasName()
      ? _nullableString(dmChannel.name)
      : null;
  final displayName =
      explicitName ??
      _stringValue(
        other.hasDisplayName() ? other.displayName : null,
        fallback: _stringValue(other.username, fallback: 'Direct Message'),
      );
  final lastMessageAt = dmChannel.hasLastMessageAt()
      ? _nullableString(dmChannel.lastMessageAt)
      : null;
  return DmConversationPreviewSeed(
    channelId: scopedWorkspaceId(networkId, localChannelId),
    localChannelId: localChannelId,
    networkId: networkId,
    displayName: displayName,
    initials: initialsForDisplayName(displayName),
    status: _normalizeStatus(_stringValue(other.status, fallback: 'offline')),
    lastMessage: lastMessageAt == null
        ? 'No messages yet'
        : 'Last active ${formatWorkspaceDateLabel(lastMessageAt)}',
    localUserId: _nullableString(other.id),
    avatarUrl: other.hasAvatarUrl() ? _nullableString(other.avatarUrl) : null,
    bannerUrl: null,
    unreadCount: 0,
  );
}

DmConversationPreviewSeed? _conversationFromProtoDmChannelOrNull(
  verdant_models.DmChannel dmChannel, {
  required String networkId,
  required String currentUserId,
}) {
  try {
    return _conversationFromProtoDmChannel(
      dmChannel,
      networkId: networkId,
      currentUserId: currentUserId,
    );
  } on FormatException {
    return null;
  }
}

MessageSeed _messageFromProto(
  verdant_models.Message message, {
  required String networkId,
  required String currentUserId,
}) {
  final localMessageId = _stringValue(message.id, fallback: 'unknown-message');
  final localAuthorId = _stringValue(
    message.authorId,
    fallback: _stringValue(message.author.id, fallback: 'unknown-user'),
  );
  final displayName = _stringValue(
    message.author.hasDisplayName() ? message.author.displayName : null,
    fallback: _stringValue(message.author.username, fallback: localAuthorId),
  );
  return MessageSeed(
    id: scopedWorkspaceId(networkId, localMessageId),
    authorId: scopedWorkspaceId(networkId, localAuthorId),
    author: displayName,
    time: formatWorkspaceDateTimeLabel(message.createdAt),
    createdAt: message.createdAt,
    body: _stringValue(message.content, fallback: ''),
    initials: initialsForDisplayName(displayName),
    avatarUrl: message.author.hasAvatarUrl()
        ? _nullableString(message.author.avatarUrl)
        : null,
    media: _messageMediaFromProto(message, networkId: networkId),
    reactions: [
      for (final reaction in message.reactions)
        ReactionSeed(
          emoji: _stringValue(reaction.emoji, fallback: '?'),
          emojiId: reaction.hasEmojiId()
              ? scopedWorkspaceId(networkId, reaction.emojiId)
              : null,
          count: reaction.count,
          reactedByCurrentUser: reaction.me,
        ),
    ],
    isOwnMessage: localAuthorId == currentUserId,
  );
}

MessageSeed? _messageFromProtoOrNull(
  verdant_models.Message message, {
  required String networkId,
  required String currentUserId,
}) {
  try {
    return _messageFromProto(
      message,
      networkId: networkId,
      currentUserId: currentUserId,
    );
  } on FormatException {
    return null;
  }
}

MessageSeed _messageFromJson(
  Map<String, Object?> json, {
  required String networkId,
  required String currentUserId,
}) {
  final localMessageId = _stringValue(json['id'], fallback: 'unknown-message');
  final localAuthorId = _stringValue(
    json['authorId'],
    fallback: _stringValue(json['author_id'], fallback: 'unknown-user'),
  );
  final author = _mapValue(json['author']);
  final displayName = _stringValue(
    author?['displayName'],
    fallback: _stringValue(author?['username'], fallback: localAuthorId),
  );
  final createdAt = _stringValue(
    json['createdAt'],
    fallback: _stringValue(json['created_at'], fallback: ''),
  );
  return MessageSeed(
    id: scopedWorkspaceId(networkId, localMessageId),
    authorId: scopedWorkspaceId(networkId, localAuthorId),
    author: displayName,
    time: formatWorkspaceDateTimeLabel(createdAt),
    createdAt: createdAt,
    body: _stringValue(
      json['content'],
      fallback: _stringValue(json['body'], fallback: ''),
    ),
    initials: initialsForDisplayName(displayName),
    avatarUrl: _nullableString(author?['avatarUrl']),
    authorColor: parseVerdantColor(
      author?['nameColor'] ??
          author?['displayColor'] ??
          author?['nicknameColor'] ??
          json['nameColor'],
    ),
    authorBannerBaseColor: parseVerdantColor(
      author?['bannerBaseColor'] ?? json['bannerBaseColor'],
    ),
    media: _messageMediaFromJson(json, networkId: networkId),
    reactions: _reactionsFromJson(json['reactions'], networkId: networkId),
    isOwnMessage: localAuthorId == currentUserId,
  );
}

MessageSeed? _messageFromJsonOrNull(
  Map<String, Object?> json, {
  required String networkId,
  required String currentUserId,
}) {
  try {
    return _messageFromJson(
      json,
      networkId: networkId,
      currentUserId: currentUserId,
    );
  } on FormatException {
    return null;
  }
}

DirectMessagesMessageDeleteEvent? _messageDeleteEventFromProtoOrNull(
  verdant_ws.MessageDelete message, {
  required String networkId,
}) {
  final channelId = _safeScopedIdOrNull(networkId, message.channelId);
  final messageId = _safeScopedIdOrNull(networkId, message.id);
  if (channelId == null || messageId == null) {
    return null;
  }
  return DirectMessagesMessageDeleteEvent(
    channelId: channelId,
    messageId: messageId,
  );
}

DirectMessagesMessageDeleteEvent? _messageDeleteEventFromJsonOrNull(
  Map<String, Object?> data, {
  required String networkId,
}) {
  final localChannelId = _safeInboundLocalId(
    data['channelId'],
    fallback: _stringValue(data['channel_id'], fallback: ''),
    networkId: networkId,
  );
  final localMessageId = _safeInboundLocalId(
    data['id'],
    fallback: _stringValue(data['messageId'], fallback: ''),
    networkId: networkId,
  );
  if (localChannelId == null || localMessageId == null) {
    return null;
  }
  return DirectMessagesMessageDeleteEvent(
    channelId: scopedWorkspaceId(networkId, localChannelId),
    messageId: scopedWorkspaceId(networkId, localMessageId),
  );
}

DirectMessagesChannelUnreadEvent? _channelUnreadEventFromProtoOrNull(
  verdant_ws.ChannelUnreadSignal signal, {
  required String networkId,
}) {
  final channelId = _safeScopedIdOrNull(networkId, signal.channelId);
  final messageId = _safeScopedIdOrNull(networkId, signal.messageId);
  final localAuthorId = _safeInboundLocalId(
    signal.authorId,
    fallback: '',
    networkId: networkId,
  );
  if (channelId == null || messageId == null || localAuthorId == null) {
    return null;
  }
  return DirectMessagesChannelUnreadEvent(
    channelId: channelId,
    messageId: messageId,
    localAuthorId: localAuthorId,
    mentionsCurrentUser: signal.mentionsCurrentUser,
    isDirectMessage: signal.dm,
  );
}

DirectMessagesChannelUnreadEvent? _channelUnreadEventFromJsonOrNull(
  Map<String, Object?> data, {
  required String networkId,
}) {
  final localChannelId = _safeInboundLocalId(
    data['channelId'],
    fallback: _stringValue(data['channel_id'], fallback: ''),
    networkId: networkId,
  );
  final localMessageId = _safeInboundLocalId(
    data['messageId'],
    fallback: _stringValue(data['message_id'], fallback: ''),
    networkId: networkId,
  );
  final localAuthorId = _safeInboundLocalId(
    data['authorId'],
    fallback: _stringValue(data['author_id'], fallback: ''),
    networkId: networkId,
  );
  if (localChannelId == null ||
      localMessageId == null ||
      localAuthorId == null) {
    return null;
  }
  return DirectMessagesChannelUnreadEvent(
    channelId: scopedWorkspaceId(networkId, localChannelId),
    messageId: scopedWorkspaceId(networkId, localMessageId),
    localAuthorId: localAuthorId,
    mentionsCurrentUser: data['mentionsCurrentUser'] == true,
    isDirectMessage: data['dm'] == true,
  );
}

DirectMessagesChannelActivityEvent? _channelActivityEventFromProtoOrNull(
  verdant_ws.ChannelActivityUpdate update, {
  required String networkId,
}) {
  final channelId = _safeScopedIdOrNull(networkId, update.channelId);
  final localUserId = _safeInboundLocalId(
    update.userId,
    fallback: '',
    networkId: networkId,
  );
  if (channelId == null || localUserId == null) {
    return null;
  }
  return DirectMessagesChannelActivityEvent(
    channelId: channelId,
    localUserId: localUserId,
    lastMessageAt: update.hasLastMessageAt()
        ? _nullableString(update.lastMessageAt)
        : null,
    displayName: update.hasDisplayName()
        ? _nullableString(update.displayName)
        : _nullableString(update.username),
    avatarUrl: update.hasAvatarUrl() ? _nullableString(update.avatarUrl) : null,
  );
}

DirectMessagesChannelActivityEvent? _channelActivityEventFromJsonOrNull(
  Map<String, Object?> data, {
  required String networkId,
}) {
  final localChannelId = _safeInboundLocalId(
    data['channelId'],
    fallback: _stringValue(data['channel_id'], fallback: ''),
    networkId: networkId,
  );
  final localUserId = _safeInboundLocalId(
    data['userId'],
    fallback: _stringValue(data['user_id'], fallback: ''),
    networkId: networkId,
  );
  if (localChannelId == null || localUserId == null) {
    return null;
  }
  return DirectMessagesChannelActivityEvent(
    channelId: scopedWorkspaceId(networkId, localChannelId),
    localUserId: localUserId,
    lastMessageAt:
        _nullableString(data['lastMessageAt']) ??
        _nullableString(data['last_message_at']),
    displayName:
        _nullableString(data['displayName']) ??
        _nullableString(data['username']),
    avatarUrl: _nullableString(data['avatarUrl']),
  );
}

DirectMessagesTypingStartEvent? _typingStartEventFromProtoOrNull(
  verdant_ws.TypingStart event, {
  required String networkId,
}) {
  final channelId = _safeScopedIdOrNull(networkId, event.channelId);
  final localUserId = _safeInboundLocalId(
    event.userId,
    fallback: '',
    networkId: networkId,
  );
  if (channelId == null || localUserId == null) {
    return null;
  }
  return DirectMessagesTypingStartEvent(
    channelId: channelId,
    localUserId: localUserId,
  );
}

DirectMessagesTypingStartEvent? _typingStartEventFromJsonOrNull(
  Map<String, Object?> data, {
  required String networkId,
}) {
  final localChannelId = _safeInboundLocalId(
    data['channelId'],
    fallback: _stringValue(data['channel_id'], fallback: ''),
    networkId: networkId,
  );
  final localUserId = _safeInboundLocalId(
    data['userId'],
    fallback: _stringValue(data['user_id'], fallback: ''),
    networkId: networkId,
  );
  if (localChannelId == null || localUserId == null) {
    return null;
  }
  return DirectMessagesTypingStartEvent(
    channelId: scopedWorkspaceId(networkId, localChannelId),
    localUserId: localUserId,
  );
}

DirectMessagesServerChannelUpsertEvent?
_serverChannelUpsertEventFromProtoOrNull(
  verdant_models.Channel channel, {
  required String networkId,
}) {
  final channelId = _safeScopedIdOrNull(networkId, channel.id);
  final serverId = channel.hasServerId()
      ? _safeScopedIdOrNull(networkId, channel.serverId)
      : null;
  if (channelId == null || (channel.hasServerId() && serverId == null)) {
    return null;
  }
  final name = _stringValue(channel.name, fallback: 'channel');
  return DirectMessagesServerChannelUpsertEvent(
    serverId: serverId,
    channel: ChannelSeed(
      id: channelId,
      name: name,
      type: channel.hasType() ? channel.type.value : 0,
    ),
  );
}

DirectMessagesServerChannelUpsertEvent? _serverChannelUpsertEventFromJsonOrNull(
  Map<String, Object?> data, {
  required String networkId,
}) {
  final localChannelId = _safeInboundLocalId(
    data['id'],
    fallback: _stringValue(data['channelId'], fallback: ''),
    networkId: networkId,
  );
  final localServerId = _safeOptionalInboundLocalId(
    data['serverId'],
    fallback: _stringValue(data['server_id'], fallback: ''),
    networkId: networkId,
  );
  if (localChannelId == null) {
    return null;
  }
  return DirectMessagesServerChannelUpsertEvent(
    serverId: localServerId == null
        ? null
        : scopedWorkspaceId(networkId, localServerId),
    channel: ChannelSeed(
      id: scopedWorkspaceId(networkId, localChannelId),
      name: _stringValue(data['name'], fallback: 'channel'),
      type: _channelTypeValue(data['type']),
    ),
  );
}

DirectMessagesServerChannelDeleteEvent?
_serverChannelDeleteEventFromProtoOrNull(
  verdant_ws.ChannelDelete event, {
  required String networkId,
}) {
  final channelId = _safeScopedIdOrNull(networkId, event.channelId);
  final serverId = event.hasServerId()
      ? _safeScopedIdOrNull(networkId, event.serverId)
      : null;
  if (channelId == null || (event.hasServerId() && serverId == null)) {
    return null;
  }
  return DirectMessagesServerChannelDeleteEvent(
    channelId: channelId,
    serverId: serverId,
  );
}

DirectMessagesServerChannelDeleteEvent? _serverChannelDeleteEventFromJsonOrNull(
  Map<String, Object?> data, {
  required String networkId,
}) {
  final localChannelId = _safeInboundLocalId(
    data['channelId'],
    fallback: _stringValue(data['channel_id'], fallback: ''),
    networkId: networkId,
  );
  final localServerId = _safeOptionalInboundLocalId(
    data['serverId'],
    fallback: _stringValue(data['server_id'], fallback: ''),
    networkId: networkId,
  );
  if (localChannelId == null) {
    return null;
  }
  return DirectMessagesServerChannelDeleteEvent(
    channelId: scopedWorkspaceId(networkId, localChannelId),
    serverId: localServerId == null
        ? null
        : scopedWorkspaceId(networkId, localServerId),
  );
}

DirectMessagesServerDeleteEvent? _serverDeleteEventFromProtoOrNull(
  verdant_ws.ServerDelete event, {
  required String networkId,
}) {
  final serverId = _safeScopedIdOrNull(networkId, event.serverId);
  if (serverId == null) {
    return null;
  }
  return DirectMessagesServerDeleteEvent(serverId: serverId);
}

DirectMessagesServerDeleteEvent? _serverDeleteEventFromJsonOrNull(
  Map<String, Object?> data, {
  required String networkId,
}) {
  final localServerId = _safeInboundLocalId(
    data['serverId'],
    fallback: _stringValue(data['server_id'], fallback: ''),
    networkId: networkId,
  );
  if (localServerId == null) {
    return null;
  }
  return DirectMessagesServerDeleteEvent(
    serverId: scopedWorkspaceId(networkId, localServerId),
  );
}

DirectMessagesServerMemberUpsertEvent? _serverMemberUpsertEventFromProtoOrNull(
  verdant_ws.MemberJoin event, {
  required String networkId,
}) {
  final userId = _safeScopedIdOrNull(networkId, event.userId);
  final serverId = event.hasServerId()
      ? _safeScopedIdOrNull(networkId, event.serverId)
      : null;
  if (userId == null || (event.hasServerId() && serverId == null)) {
    return null;
  }
  final displayName =
      _nullableString(event.displayName) ??
      _stringValue(event.username, fallback: event.userId);
  return DirectMessagesServerMemberUpsertEvent(
    serverId: serverId,
    member: MemberSeed(
      id: userId,
      name: displayName,
      username: event.hasUsername() ? _nullableString(event.username) : null,
      status: 'Online',
      initials: initialsForDisplayName(displayName),
      avatarUrl: event.hasAvatarUrl() ? _nullableString(event.avatarUrl) : null,
      isActive: true,
    ),
  );
}

DirectMessagesServerMemberUpsertEvent? _serverMemberUpsertEventFromJsonOrNull(
  Map<String, Object?> data, {
  required String networkId,
}) {
  final localUserId = _safeInboundLocalId(
    data['userId'],
    fallback: _stringValue(data['user_id'], fallback: ''),
    networkId: networkId,
  );
  final localServerId = _safeOptionalInboundLocalId(
    data['serverId'],
    fallback: _stringValue(data['server_id'], fallback: ''),
    networkId: networkId,
  );
  if (localUserId == null) {
    return null;
  }
  final displayName =
      _nullableString(data['displayName']) ??
      _nullableString(data['username']) ??
      localUserId;
  final status = _normalizeStatus(_nullableString(data['status']) ?? 'online');
  return DirectMessagesServerMemberUpsertEvent(
    serverId: localServerId == null
        ? null
        : scopedWorkspaceId(networkId, localServerId),
    member: MemberSeed(
      id: scopedWorkspaceId(networkId, localUserId),
      name: displayName,
      username: _nullableString(data['username']),
      status: status,
      initials: initialsForDisplayName(displayName),
      avatarUrl: _nullableString(data['avatarUrl']),
      isActive: !status.contains('Offline'),
    ),
  );
}

DirectMessagesServerMemberRemoveEvent? _serverMemberRemoveEventFromProtoOrNull(
  verdant_ws.MemberRemove event, {
  required String networkId,
}) {
  final userId = _safeScopedIdOrNull(networkId, event.userId);
  final serverId = event.hasServerId()
      ? _safeScopedIdOrNull(networkId, event.serverId)
      : null;
  if (userId == null || (event.hasServerId() && serverId == null)) {
    return null;
  }
  return DirectMessagesServerMemberRemoveEvent(
    userId: userId,
    serverId: serverId,
  );
}

DirectMessagesServerMemberRemoveEvent? _serverMemberRemoveEventFromJsonOrNull(
  Map<String, Object?> data, {
  required String networkId,
}) {
  final localUserId = _safeInboundLocalId(
    data['userId'],
    fallback: _stringValue(data['user_id'], fallback: ''),
    networkId: networkId,
  );
  final localServerId = _safeOptionalInboundLocalId(
    data['serverId'],
    fallback: _stringValue(data['server_id'], fallback: ''),
    networkId: networkId,
  );
  if (localUserId == null) {
    return null;
  }
  return DirectMessagesServerMemberRemoveEvent(
    userId: scopedWorkspaceId(networkId, localUserId),
    serverId: localServerId == null
        ? null
        : scopedWorkspaceId(networkId, localServerId),
  );
}

DirectMessagesServerMemberRoleUpdateEvent?
_serverMemberRoleUpdateEventFromProtoOrNull(
  verdant_ws.MemberRoleUpdate event, {
  required String networkId,
}) {
  final userId = _safeScopedIdOrNull(networkId, event.userId);
  final serverId = event.hasServerId()
      ? _safeScopedIdOrNull(networkId, event.serverId)
      : null;
  if (userId == null || (event.hasServerId() && serverId == null)) {
    return null;
  }
  return DirectMessagesServerMemberRoleUpdateEvent(
    userId: userId,
    roleIds: [
      for (final roleId in event.roleIds)
        if (_safeInboundLocalId(roleId, fallback: '', networkId: networkId) !=
            null)
          _safeInboundLocalId(roleId, fallback: '', networkId: networkId)!,
    ],
    serverId: serverId,
  );
}

DirectMessagesServerMemberRoleUpdateEvent?
_serverMemberRoleUpdateEventFromJsonOrNull(
  Map<String, Object?> data, {
  required String networkId,
}) {
  final localUserId = _safeInboundLocalId(
    data['userId'],
    fallback: _stringValue(data['user_id'], fallback: ''),
    networkId: networkId,
  );
  final localServerId = _safeOptionalInboundLocalId(
    data['serverId'],
    fallback: _stringValue(data['server_id'], fallback: ''),
    networkId: networkId,
  );
  if (localUserId == null) {
    return null;
  }
  final rawRoleIds = data['roleIds'] is List
      ? data['roleIds'] as List
      : data['role_ids'] is List
      ? data['role_ids'] as List
      : const <Object?>[];
  return DirectMessagesServerMemberRoleUpdateEvent(
    userId: scopedWorkspaceId(networkId, localUserId),
    roleIds: [
      for (final roleId in rawRoleIds)
        if (_safeInboundLocalId(roleId, fallback: '', networkId: networkId) !=
            null)
          _safeInboundLocalId(roleId, fallback: '', networkId: networkId)!,
    ],
    serverId: localServerId == null
        ? null
        : scopedWorkspaceId(networkId, localServerId),
  );
}

DirectMessagesReactionAddEvent? _reactionAddEventFromProtoOrNull(
  verdant_ws.ReactionAdd reaction, {
  required String networkId,
}) {
  final channelId = _safeScopedIdOrNull(networkId, reaction.channelId);
  final messageId = _safeScopedIdOrNull(networkId, reaction.messageId);
  final localUserId = _safeInboundLocalId(
    reaction.userId,
    fallback: '',
    networkId: networkId,
  );
  final emoji = _nullableString(reaction.emoji);
  if (channelId == null ||
      messageId == null ||
      localUserId == null ||
      emoji == null) {
    return null;
  }
  return DirectMessagesReactionAddEvent(
    channelId: channelId,
    messageId: messageId,
    localUserId: localUserId,
    emoji: emoji,
    emojiId: reaction.hasEmojiId()
        ? _safeScopedIdOrNull(networkId, reaction.emojiId)
        : null,
  );
}

DirectMessagesReactionRemoveEvent? _reactionRemoveEventFromProtoOrNull(
  verdant_ws.ReactionRemove reaction, {
  required String networkId,
}) {
  final channelId = _safeScopedIdOrNull(networkId, reaction.channelId);
  final messageId = _safeScopedIdOrNull(networkId, reaction.messageId);
  final localUserId = _safeInboundLocalId(
    reaction.userId,
    fallback: '',
    networkId: networkId,
  );
  final emoji = _nullableString(reaction.emoji);
  if (channelId == null ||
      messageId == null ||
      localUserId == null ||
      emoji == null) {
    return null;
  }
  return DirectMessagesReactionRemoveEvent(
    channelId: channelId,
    messageId: messageId,
    localUserId: localUserId,
    emoji: emoji,
  );
}

DirectMessagesReactionAddEvent? _reactionAddEventFromJsonOrNull(
  Map<String, Object?> data, {
  required String networkId,
}) {
  final localChannelId = _safeInboundLocalId(
    data['channelId'],
    fallback: _stringValue(data['channel_id'], fallback: ''),
    networkId: networkId,
  );
  final localMessageId = _safeInboundLocalId(
    data['messageId'],
    fallback: _stringValue(data['message_id'], fallback: ''),
    networkId: networkId,
  );
  final localUserId = _safeInboundLocalId(
    data['userId'],
    fallback: _stringValue(data['user_id'], fallback: ''),
    networkId: networkId,
  );
  final emoji = _nullableString(data['emoji']);
  if (localChannelId == null ||
      localMessageId == null ||
      localUserId == null ||
      emoji == null) {
    return null;
  }
  final rawEmojiId =
      _nullableString(data['emojiId']) ?? _nullableString(data['emoji_id']);
  return DirectMessagesReactionAddEvent(
    channelId: scopedWorkspaceId(networkId, localChannelId),
    messageId: scopedWorkspaceId(networkId, localMessageId),
    localUserId: localUserId,
    emoji: emoji,
    emojiId: rawEmojiId == null
        ? null
        : _safeScopedIdOrNull(networkId, rawEmojiId),
  );
}

DirectMessagesReactionRemoveEvent? _reactionRemoveEventFromJsonOrNull(
  Map<String, Object?> data, {
  required String networkId,
}) {
  final localChannelId = _safeInboundLocalId(
    data['channelId'],
    fallback: _stringValue(data['channel_id'], fallback: ''),
    networkId: networkId,
  );
  final localMessageId = _safeInboundLocalId(
    data['messageId'],
    fallback: _stringValue(data['message_id'], fallback: ''),
    networkId: networkId,
  );
  final localUserId = _safeInboundLocalId(
    data['userId'],
    fallback: _stringValue(data['user_id'], fallback: ''),
    networkId: networkId,
  );
  final emoji = _nullableString(data['emoji']);
  if (localChannelId == null ||
      localMessageId == null ||
      localUserId == null ||
      emoji == null) {
    return null;
  }
  return DirectMessagesReactionRemoveEvent(
    channelId: scopedWorkspaceId(networkId, localChannelId),
    messageId: scopedWorkspaceId(networkId, localMessageId),
    localUserId: localUserId,
    emoji: emoji,
  );
}

int _messageRowOldestFirst(
  ({int index, Map<String, Object?> map}) a,
  ({int index, Map<String, Object?> map}) b,
) {
  final aCreatedAt = _messageCreatedAt(a.map);
  final bCreatedAt = _messageCreatedAt(b.map);
  if (aCreatedAt != null && bCreatedAt != null) {
    return aCreatedAt.compareTo(bCreatedAt);
  }
  if (aCreatedAt != null) {
    return -1;
  }
  if (bCreatedAt != null) {
    return 1;
  }
  return b.index.compareTo(a.index);
}

DateTime? _messageCreatedAt(Map<String, Object?> json) {
  final value =
      _nullableString(json['createdAt']) ?? _nullableString(json['created_at']);
  return value == null ? null : DateTime.tryParse(value);
}

List<ReactionSeed> _reactionsFromJson(
  Object? raw, {
  required String networkId,
}) {
  if (raw is! List) {
    return const [];
  }
  return [
    for (final item in raw)
      if (_mapValue(item) case final reaction?)
        ReactionSeed(
          emoji: _stringValue(reaction['emoji'], fallback: '?'),
          emojiId: _nullableString(reaction['emojiId']) == null
              ? null
              : scopedWorkspaceId(
                  networkId,
                  _nullableString(reaction['emojiId'])!,
                ),
          count: _intValue(reaction['count'], fallback: 1),
          reactedByCurrentUser: reaction['me'] == true,
        ),
  ];
}

MessageMediaSeed? _messageMediaFromProto(
  verdant_models.Message message, {
  required String networkId,
}) {
  for (final attachment in message.attachments) {
    if (!_isImageContentType(attachment.contentType)) {
      continue;
    }
    return MessageMediaSeed(
      id: scopedWorkspaceId(
        networkId,
        _stringValue(attachment.id, fallback: attachment.url),
      ),
      label: _stringValue(attachment.filename, fallback: 'Image attachment'),
      kind: _mediaKindFor(
        contentType: attachment.contentType,
        url: attachment.url,
      ),
      width: 360,
      height: 240,
      url: _nullableString(attachment.url),
      contentType: _nullableString(attachment.contentType),
      sizeBytes: attachment.hasSize() ? attachment.size : null,
    );
  }
  return null;
}

MessageMediaSeed? _messageMediaFromJson(
  Map<String, Object?> json, {
  required String networkId,
}) {
  final rawAttachments = json['attachments'];
  if (rawAttachments is! List) {
    return null;
  }
  for (final rawAttachment in rawAttachments) {
    final attachment = _mapValue(rawAttachment);
    if (attachment == null) {
      continue;
    }
    final contentType =
        _nullableString(attachment['contentType']) ??
        _nullableString(attachment['content_type']);
    final url = _nullableString(attachment['url']);
    if (!_isImageContentType(contentType) && !_imageUrlLooksRenderable(url)) {
      continue;
    }
    return MessageMediaSeed(
      id: scopedWorkspaceId(
        networkId,
        _stringValue(attachment['id'], fallback: url ?? 'unknown-media'),
      ),
      label: _stringValue(
        attachment['filename'],
        fallback: _stringValue(
          attachment['name'],
          fallback: 'Image attachment',
        ),
      ),
      kind: _mediaKindFor(contentType: contentType, url: url),
      width: _intValue(attachment['width'], fallback: 360),
      height: _intValue(attachment['height'], fallback: 240),
      url: url,
      contentType: contentType,
      sizeBytes: _nullableInt(attachment['size']),
    );
  }
  return null;
}

bool _isImageContentType(String? contentType) {
  return switch (contentType?.toLowerCase()) {
    'image/png' ||
    'image/jpeg' ||
    'image/jpg' ||
    'image/gif' ||
    'image/webp' => true,
    _ => false,
  };
}

bool _imageUrlLooksRenderable(String? url) {
  final lower = url?.toLowerCase();
  if (lower == null) {
    return false;
  }
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.webp');
}

MessageMediaKind _mediaKindFor({String? contentType, String? url}) {
  final normalizedType = contentType?.toLowerCase();
  final normalizedUrl = url?.toLowerCase() ?? '';
  if (normalizedType == 'image/gif' || normalizedUrl.endsWith('.gif')) {
    return MessageMediaKind.gif;
  }
  if (normalizedType == 'image/webp' || normalizedUrl.endsWith('.webp')) {
    return MessageMediaKind.webp;
  }
  return MessageMediaKind.image;
}

FriendPreviewSeed _friendFromRelationship(
  Map<String, Object?> json,
  String networkId,
) {
  final user = _mapValue(json['user']);
  final localUserId = _stringValue(
    json['userId'],
    fallback: _stringValue(user?['id'], fallback: 'unknown'),
  );
  final displayName = _stringValue(
    user?['displayName'],
    fallback: _stringValue(user?['username'], fallback: localUserId),
  );
  final kind = _relationshipKind(_intValue(json['type'], fallback: 0));
  final status = _friendStatus(
    _stringValue(user?['status'], fallback: 'offline'),
    kind,
  );
  return FriendPreviewSeed(
    id: scopedWorkspaceId(networkId, localUserId),
    localUserId: localUserId,
    networkId: networkId,
    displayName: displayName,
    initials: initialsForDisplayName(displayName),
    status: status,
    detail: _relationshipDetail(kind),
    kind: kind,
    avatarUrl: _nullableString(user?['avatarUrl']),
    bannerUrl: _nullableString(user?['bannerUrl']),
  );
}

FriendPreviewSeed? _friendFromRelationshipOrNull(
  Map<String, Object?> json,
  String networkId,
) {
  try {
    return _friendFromRelationship(json, networkId);
  } on FormatException {
    return null;
  }
}

DmConversationPreviewSeed _conversationFromDmChannel(
  Map<String, Object?> json, {
  required String networkId,
  required String currentUserId,
}) {
  final localChannelId = _stringValue(json['id'], fallback: 'unknown');
  final rawParticipants = json['participants'];
  final participants =
      (rawParticipants is List ? rawParticipants : const <Object?>[])
          .map(_mapValue)
          .whereType<Map<String, Object?>>()
          .toList(growable: false);
  final other = participants.firstWhere(
    (participant) =>
        _stringValue(participant['id'], fallback: '') != currentUserId,
    orElse: () =>
        participants.isEmpty ? <String, Object?>{} : participants.first,
  );
  final explicitName = _nullableString(json['name']);
  final displayName =
      explicitName ??
      _stringValue(
        other['displayName'],
        fallback: _stringValue(other['username'], fallback: 'Direct Message'),
      );
  final status = _stringValue(other['status'], fallback: 'offline');
  final lastMessageAt = _nullableString(json['lastMessageAt']);
  return DmConversationPreviewSeed(
    channelId: scopedWorkspaceId(networkId, localChannelId),
    localChannelId: localChannelId,
    networkId: networkId,
    displayName: displayName,
    initials: initialsForDisplayName(displayName),
    status: _normalizeStatus(status),
    lastMessage: lastMessageAt == null
        ? 'No messages yet'
        : 'Last active ${formatWorkspaceDateLabel(lastMessageAt)}',
    localUserId: _nullableString(other['id']),
    avatarUrl: _nullableString(other['avatarUrl']),
    bannerUrl: _nullableString(other['bannerUrl']),
    unreadCount: 0,
  );
}

DmConversationPreviewSeed? _conversationFromDmChannelOrNull(
  Map<String, Object?> json, {
  required String networkId,
  required String currentUserId,
}) {
  try {
    return _conversationFromDmChannel(
      json,
      networkId: networkId,
      currentUserId: currentUserId,
    );
  } on FormatException {
    return null;
  }
}

FriendRelationshipKind _relationshipKind(int type) {
  return switch (type) {
    1 => FriendRelationshipKind.friend,
    2 => FriendRelationshipKind.blocked,
    3 => FriendRelationshipKind.pendingOutgoing,
    4 => FriendRelationshipKind.pendingIncoming,
    _ => FriendRelationshipKind.friend,
  };
}

String _relationshipDetail(FriendRelationshipKind kind) {
  return switch (kind) {
    FriendRelationshipKind.friend => 'Friend',
    FriendRelationshipKind.pendingIncoming => 'Incoming request',
    FriendRelationshipKind.pendingOutgoing => 'Outgoing request',
    FriendRelationshipKind.blocked => 'Blocked',
  };
}

String _friendStatus(String raw, FriendRelationshipKind kind) {
  return switch (kind) {
    FriendRelationshipKind.pendingIncoming => 'Pending',
    FriendRelationshipKind.pendingOutgoing => 'Sent',
    FriendRelationshipKind.blocked => 'Blocked',
    FriendRelationshipKind.friend => _normalizeStatus(raw),
  };
}

String _normalizeStatus(String rawStatus) {
  final normalized = rawStatus.toLowerCase();
  if (normalized.contains('online')) {
    return 'Online';
  }
  if (normalized.contains('idle')) {
    return 'Idle';
  }
  if (normalized.contains('dnd') || normalized.contains('busy')) {
    return 'Busy';
  }
  return 'Offline';
}

String _statusFromProto(verdant_models.UserStatus status) {
  return switch (status) {
    verdant_models.UserStatus.USER_STATUS_ONLINE => 'Online',
    verdant_models.UserStatus.USER_STATUS_IDLE => 'Idle',
    verdant_models.UserStatus.USER_STATUS_DND => 'Busy',
    verdant_models.UserStatus.USER_STATUS_OFFLINE => 'Offline',
    _ => 'Offline',
  };
}

verdant_models.UserStatus _statusToProto(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('online')) {
    return verdant_models.UserStatus.USER_STATUS_ONLINE;
  }
  if (normalized.contains('idle')) {
    return verdant_models.UserStatus.USER_STATUS_IDLE;
  }
  if (normalized.contains('dnd') || normalized.contains('busy')) {
    return verdant_models.UserStatus.USER_STATUS_DND;
  }
  return verdant_models.UserStatus.USER_STATUS_OFFLINE;
}

int _sortFriends(FriendPreviewSeed left, FriendPreviewSeed right) {
  final kindComparison = _kindOrder(
    left.kind,
  ).compareTo(_kindOrder(right.kind));
  if (kindComparison != 0) {
    return kindComparison;
  }
  return left.displayName.toLowerCase().compareTo(
    right.displayName.toLowerCase(),
  );
}

int _sortConversations(
  DmConversationPreviewSeed left,
  DmConversationPreviewSeed right,
) {
  return left.displayName.toLowerCase().compareTo(
    right.displayName.toLowerCase(),
  );
}

int _kindOrder(FriendRelationshipKind kind) {
  return switch (kind) {
    FriendRelationshipKind.pendingIncoming => 0,
    FriendRelationshipKind.friend => 1,
    FriendRelationshipKind.pendingOutgoing => 2,
    FriendRelationshipKind.blocked => 3,
  };
}

Map<String, Object?>? _mapValue(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }
  return null;
}

Map<String, Object?>? _tryDecodeJsonObject(String value) {
  try {
    return _mapValue(jsonDecode(value));
  } catch (_) {
    return null;
  }
}

Map<String, Object?>? _readyPreferencesFromJson(Map<String, Object?> ready) {
  final direct = _mapValue(ready['preferences']);
  if (direct != null) {
    return direct;
  }
  final encoded = ready['preferencesJson'];
  if (encoded is String && encoded.trim().isNotEmpty) {
    return _tryDecodeJsonObject(encoded);
  }
  return null;
}

Set<String>? _hiddenChannelIdsFromPreferences(
  Map<String, Object?>? preferences,
  String networkId,
) {
  if (preferences == null) {
    return null;
  }
  return _hiddenChannelIdsFromRaw(preferences['hiddenDmIds'], networkId);
}

Set<String> _hiddenChannelIdsFromRaw(Object? rawHidden, String networkId) {
  if (rawHidden is! List) {
    return {};
  }
  return {
    for (final item in rawHidden)
      if (item is String)
        if (_safeHiddenDmLocalIdOrNull(item) case final localId?)
          scopedWorkspaceId(networkId, localId),
  };
}

({List<Object?> channels, Set<String>? hiddenChannelIds})?
_directMessagesBootstrapFromRest(Object? decoded, String networkId) {
  if (decoded is List) {
    return (channels: List<Object?>.of(decoded), hiddenChannelIds: null);
  }
  final map = _mapValue(decoded);
  if (map == null) {
    return null;
  }
  final channels = map['dmChannels'];
  if (channels is! List) {
    return null;
  }
  return (
    channels: List<Object?>.of(channels),
    hiddenChannelIds: _hiddenChannelIdsFromRaw(map['hiddenDmIds'], networkId),
  );
}

int _intValue(Object? value, {required int fallback}) {
  return value is num ? value.toInt() : fallback;
}

int? _nullableInt(Object? value) {
  return value is num ? value.toInt() : null;
}

String _stringValue(Object? value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

String? _nullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}

String? _safeInboundLocalId(
  Object? value, {
  required String fallback,
  String? networkId,
}) {
  final raw = _stringValue(value, fallback: fallback).trim();
  if (raw.isEmpty) {
    return null;
  }
  try {
    if (networkId != null && raw.contains('/')) {
      final scoped = scopedWorkspaceId(networkId, raw);
      return scoped.substring(scoped.indexOf('/') + 1);
    }
    return safeWorkspaceLocalId(raw, allowScopedPrefix: networkId == null);
  } on FormatException {
    return null;
  }
}

String? _safeOptionalInboundLocalId(
  Object? value, {
  required String fallback,
  String? networkId,
}) {
  final raw = _stringValue(value, fallback: fallback).trim();
  if (raw.isEmpty) {
    return null;
  }
  return _safeInboundLocalId(raw, fallback: '', networkId: networkId);
}

String? _safeScopedIdOrNull(String networkId, Object? value) {
  try {
    final raw = _stringValue(value, fallback: '').trim();
    if (raw.isEmpty) {
      return null;
    }
    return scopedWorkspaceId(networkId, raw);
  } on FormatException {
    return null;
  }
}

int _channelTypeValue(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  final normalized = value is String ? value.toLowerCase() : '';
  if (normalized.contains('voice')) {
    return 3;
  }
  if (normalized.contains('group')) {
    return 2;
  }
  if (normalized.contains('dm')) {
    return 1;
  }
  return 0;
}

String _safeReactionEmoji(String value) {
  final sanitized = sanitizeSearchInput(value, maxLength: 80);
  if (sanitized.isEmpty) {
    throw const DirectMessagesException('Choose a reaction');
  }
  return sanitized;
}

String _safeCommandLocalId(String networkId, String value) {
  try {
    final scoped = scopedWorkspaceId(networkId, value);
    return scoped.substring(scoped.indexOf('/') + 1);
  } on FormatException {
    throw const DirectMessagesException('Invalid realtime target');
  }
}

String _messageNonce() {
  return 'flutter-${DateTime.now().microsecondsSinceEpoch}';
}

String _safeLocalId(String value) {
  try {
    return safeWorkspaceLocalId(value);
  } on FormatException {
    throw const DirectMessagesException('Invalid relationship target');
  }
}

String _safeMessageRouteLocalId(String networkId, String value) {
  try {
    final scoped = scopedWorkspaceId(networkId, value);
    return scoped.substring(scoped.indexOf('/') + 1);
  } on FormatException {
    throw const DirectMessagesException('Invalid message route');
  }
}
