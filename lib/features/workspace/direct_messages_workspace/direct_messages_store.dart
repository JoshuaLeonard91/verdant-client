import 'direct_messages_models.dart';
import '../workspace_local_id.dart';
import '../workspace_seed.dart';

final class DirectMessagesStore {
  DirectMessagesWorkspaceData? _data;
  final _hiddenChannelIds = <String>{};
  final _messagesByChannel = <String, DmConversationMessages>{};
  final _pendingPresenceByUser = <String, String>{};

  DirectMessagesWorkspaceData? get visibleData {
    final data = _data;
    if (data == null) {
      return null;
    }
    return _applyVisibility(data);
  }

  DmConversationMessages? messagesFor(String channelId) {
    return _messagesByChannel[channelId];
  }

  DmConversationPreviewSeed? conversationFor(String channelId) {
    return _conversationInData(_data, channelId);
  }

  Set<String> get hiddenChannelIds => Set.unmodifiable(_hiddenChannelIds);

  void restoreHiddenChannelIds(Set<String> channelIds) {
    _hiddenChannelIds
      ..clear()
      ..addAll(
        channelIds.where(
          (channelId) => isSafeScopedWorkspaceId(
            channelId,
            networkId: _networkIdFromScopedChannel(channelId),
          ),
        ),
      );
  }

  DirectMessagesWorkspaceData markRefreshing(
    DirectMessagesWorkspaceData fallback,
  ) {
    final data = _data ?? fallback;
    _data = data.copyWith(isRefreshing: true, error: null);
    return _applyVisibility(_data!);
  }

  DirectMessagesWorkspaceData replaceSnapshot(
    DirectMessagesWorkspaceData next,
  ) {
    _data = _mergeSnapshot(next);
    return _applyVisibility(_data!);
  }

  DirectMessagesWorkspaceData applyConversationMessages(
    DmConversationPreviewSeed conversation,
    DmConversationMessages messages,
  ) {
    final mergedMessages = _mergeMessages(conversation.channelId, messages);
    _messagesByChannel[conversation.channelId] = mergedMessages;
    final data = _data;
    final baseConversation =
        _conversationInData(data, conversation.channelId) ??
        _applyPendingPresence(conversation);
    final nextConversation = conversationWithMessages(
      baseConversation,
      mergedMessages,
    );
    if (data == null) {
      _data = _emptyForConversation(
        baseConversation,
      ).copyWith(conversations: [nextConversation]);
      return _applyVisibility(_data!);
    }
    _data = _replaceConversation(data, nextConversation);
    return _applyVisibility(_data!);
  }

  DirectMessagesWorkspaceData applyConversationPreview(
    DmConversationPreviewSeed conversation,
    DmConversationMessages messages,
  ) {
    if (messages.messages.isEmpty) {
      return visibleData ?? _emptyForConversation(conversation);
    }
    final nextConversation = conversationWithMessages(conversation, messages);
    final data = _data;
    if (data == null) {
      _data = _emptyForConversation(
        conversation,
      ).copyWith(conversations: [nextConversation]);
    } else {
      _data = _replaceConversation(data, nextConversation);
    }
    return _applyVisibility(_data!);
  }

  DirectMessagesWorkspaceData applyRealtimeMessage({
    required String channelId,
    required MessageSeed message,
  }) {
    final networkId = _networkIdFromScopedChannel(channelId);
    if (!isSafeScopedWorkspaceId(channelId, networkId: networkId) ||
        !isSafeScopedWorkspaceId(message.id, networkId: networkId) ||
        !isSafeScopedWorkspaceId(message.authorId, networkId: networkId)) {
      return visibleData ??
          DirectMessagesWorkspaceData.empty(
            networkId: networkId,
            currentUserName: '',
            currentUserInitials: '',
          );
    }
    final existingMessages = _messagesByChannel[channelId];
    if (existingMessages != null) {
      final nextMessages = [
        for (final existing in existingMessages.messages)
          if (existing.id != message.id) existing,
        message,
      ];
      _messagesByChannel[channelId] = DmConversationMessages(
        channelId: channelId,
        messages: nextMessages,
      );
    } else {
      _messagesByChannel[channelId] = DmConversationMessages(
        channelId: channelId,
        messages: [message],
      );
    }

    final data = _data;
    if (data == null) {
      return DirectMessagesWorkspaceData.empty(
        networkId: _networkIdFromScopedChannel(channelId),
        currentUserName: '',
        currentUserInitials: '',
      );
    }

    var replaced = false;
    final conversations = <DmConversationPreviewSeed>[];
    for (final conversation in data.conversations) {
      if (conversation.channelId == channelId) {
        conversations.add(
          conversation.copyWith(
            lastMessage: _truncatePreview(
              message.body.trim().isEmpty ? 'Message' : message.body.trim(),
            ),
          ),
        );
        replaced = true;
      } else {
        conversations.add(conversation);
      }
    }
    if (!replaced) {
      final localUserId = message.isOwnMessage
          ? null
          : _localIdFromScopedUser(message.authorId, networkId);
      conversations.add(
        _applyPendingPresence(
          DmConversationPreviewSeed(
            channelId: channelId,
            localChannelId: _localIdFromScopedChannel(channelId),
            networkId: networkId,
            localUserId: localUserId,
            displayName: message.isOwnMessage
                ? 'Direct Message'
                : message.author,
            initials: message.isOwnMessage
                ? 'DM'
                : initialsForDisplayName(message.author),
            status: 'Offline',
            lastMessage: _truncatePreview(
              message.body.trim().isEmpty ? 'Message' : message.body.trim(),
            ),
            avatarUrl: message.isOwnMessage ? null : message.avatarUrl,
          ),
        ),
      );
    }
    _data = data.copyWith(conversations: conversations);
    return _applyVisibility(_data!);
  }

  DirectMessagesWorkspaceData applyRealtimeMessageUpdate({
    required String channelId,
    required MessageSeed message,
  }) {
    final networkId = _networkIdFromScopedChannel(channelId);
    if (!isSafeScopedWorkspaceId(channelId, networkId: networkId) ||
        !isSafeScopedWorkspaceId(message.id, networkId: networkId) ||
        !isSafeScopedWorkspaceId(message.authorId, networkId: networkId)) {
      return visibleData ??
          DirectMessagesWorkspaceData.empty(
            networkId: networkId,
            currentUserName: '',
            currentUserInitials: '',
          );
    }
    final existingMessages = _messagesByChannel[channelId];
    if (existingMessages != null) {
      var replaced = false;
      final nextMessages = [
        for (final existing in existingMessages.messages)
          if (existing.id == message.id) ...[message] else existing,
      ];
      replaced = existingMessages.messages.any(
        (existing) => existing.id == message.id,
      );
      if (replaced) {
        _messagesByChannel[channelId] = DmConversationMessages(
          channelId: channelId,
          messages: nextMessages,
        );
      }
    }
    final data = _data;
    if (data == null) {
      return DirectMessagesWorkspaceData.empty(
        networkId: networkId,
        currentUserName: '',
        currentUserInitials: '',
      );
    }
    final activeMessages = _messagesByChannel[channelId];
    if (activeMessages == null || activeMessages.messages.isEmpty) {
      return _applyVisibility(data);
    }
    _data = _replaceConversation(
      data,
      conversationWithMessages(
        conversationFor(channelId) ??
            DmConversationPreviewSeed(
              channelId: channelId,
              localChannelId: _localIdFromScopedChannel(channelId),
              networkId: networkId,
              displayName: message.author,
              initials: initialsForDisplayName(message.author),
              status: 'Offline',
              lastMessage: 'No messages yet',
            ),
        activeMessages,
      ),
      insertWhenMissing: true,
    );
    return _applyVisibility(_data!);
  }

  DirectMessagesWorkspaceData applyRealtimeMessageDelete({
    required String channelId,
    required String messageId,
  }) {
    final networkId = _networkIdFromScopedChannel(channelId);
    if (!isSafeScopedWorkspaceId(channelId, networkId: networkId) ||
        !isSafeScopedWorkspaceId(messageId, networkId: networkId)) {
      return visibleData ??
          DirectMessagesWorkspaceData.empty(
            networkId: networkId,
            currentUserName: '',
            currentUserInitials: '',
          );
    }
    final existingMessages = _messagesByChannel[channelId];
    if (existingMessages != null) {
      _messagesByChannel[channelId] = DmConversationMessages(
        channelId: channelId,
        messages: [
          for (final message in existingMessages.messages)
            if (message.id != messageId) message,
        ],
      );
    }
    final data = _data;
    if (data == null) {
      return DirectMessagesWorkspaceData.empty(
        networkId: networkId,
        currentUserName: '',
        currentUserInitials: '',
      );
    }
    final conversation = conversationFor(channelId);
    final activeMessages = _messagesByChannel[channelId];
    if (conversation == null || activeMessages == null) {
      return _applyVisibility(data);
    }
    _data = _replaceConversation(
      data,
      conversationWithMessages(conversation, activeMessages),
    );
    return _applyVisibility(_data!);
  }

  DirectMessagesWorkspaceData applyUnreadSignal({
    required String channelId,
    required bool mentionsCurrentUser,
  }) {
    final data = _data;
    if (data == null) {
      return DirectMessagesWorkspaceData.empty(
        networkId: _networkIdFromScopedChannel(channelId),
        currentUserName: '',
        currentUserInitials: '',
      );
    }
    _data = data.copyWith(
      conversations: [
        for (final conversation in data.conversations)
          if (conversation.channelId == channelId)
            conversation.copyWith(
              unreadCount:
                  conversation.unreadCount +
                  (mentionsCurrentUser
                      ? 1
                      : conversation.unreadCount == 0
                      ? 1
                      : 0),
            )
          else
            conversation,
      ],
    );
    return _applyVisibility(_data!);
  }

  DirectMessagesWorkspaceData upsertConversation(
    DmConversationPreviewSeed conversation,
  ) {
    final nextConversation = _applyPendingPresence(conversation);
    final data = _data;
    if (data == null) {
      _data = _emptyForConversation(
        nextConversation,
      ).copyWith(conversations: [nextConversation]);
    } else {
      _data = _replaceConversation(
        data,
        nextConversation,
        insertWhenMissing: true,
      );
    }
    return _applyVisibility(_data!);
  }

  DirectMessagesWorkspaceData upsertRelationship(FriendPreviewSeed friend) {
    final data = _data;
    if (data == null) {
      _data = DirectMessagesWorkspaceData.empty(
        networkId: friend.networkId,
        currentUserName: '',
        currentUserInitials: '',
      ).copyWith(friends: [friend]);
      return _applyVisibility(_data!);
    }
    var replaced = false;
    final friends = [
      for (final existing in data.friends)
        if (_sameFriendIdentity(existing, friend)) ...[friend] else existing,
    ];
    replaced = data.friends.any(
      (existing) => _sameFriendIdentity(existing, friend),
    );
    _data = data.copyWith(friends: replaced ? friends : [...friends, friend]);
    return _applyVisibility(_data!);
  }

  DirectMessagesWorkspaceData removeRelationship({
    required String networkId,
    required String localUserId,
  }) {
    final data = _data;
    if (data == null) {
      return DirectMessagesWorkspaceData.empty(
        networkId: networkId,
        currentUserName: '',
        currentUserInitials: '',
      );
    }
    _data = data.copyWith(
      friends: [
        for (final friend in data.friends)
          if (!(sameWorkspaceNetworkId(friend.networkId, networkId) &&
              friend.localUserId == localUserId))
            friend,
      ],
    );
    return _applyVisibility(_data!);
  }

  DirectMessagesWorkspaceData applyPresenceUpdate({
    required String networkId,
    required String localUserId,
    required String status,
    required String currentUserId,
  }) {
    if (_safeLocalIdOrNull(localUserId) == null ||
        _safeLocalIdOrNull(currentUserId) == null) {
      return visibleData ??
          DirectMessagesWorkspaceData.empty(
            networkId: networkId,
            currentUserName: '',
            currentUserInitials: '',
          );
    }
    final normalizedStatus = _normalizeRealtimeStatus(status);
    _pendingPresenceByUser[_presenceKey(networkId, localUserId)] =
        normalizedStatus;
    final data = _data;
    if (data == null) {
      return DirectMessagesWorkspaceData.empty(
        networkId: networkId,
        currentUserName: '',
        currentUserInitials: '',
      );
    }
    _data = data.copyWith(
      currentUserStatus: localUserId == currentUserId
          ? normalizedStatus
          : data.currentUserStatus,
      conversations: [
        for (final conversation in data.conversations)
          if (sameWorkspaceNetworkId(conversation.networkId, networkId) &&
              conversation.localUserId == localUserId)
            conversation.copyWith(status: normalizedStatus)
          else
            conversation,
      ],
      friends: [
        for (final friend in data.friends)
          if (sameWorkspaceNetworkId(friend.networkId, networkId) &&
              friend.localUserId == localUserId)
            friend.copyWith(status: normalizedStatus)
          else
            friend,
      ],
    );
    return _applyVisibility(_data!);
  }

  DirectMessagesWorkspaceData hideConversation(String channelId) {
    final networkId = _networkIdFromScopedChannel(channelId);
    if (!isSafeScopedWorkspaceId(channelId, networkId: networkId)) {
      throw StateError('Direct message channel is invalid');
    }
    _hiddenChannelIds.add(channelId);
    final data = _data;
    if (data == null) {
      throw StateError('Direct messages are not loaded');
    }
    return _applyVisibility(data);
  }

  DirectMessagesWorkspaceData unhideConversation(
    DmConversationPreviewSeed conversation,
  ) {
    _hiddenChannelIds.remove(conversation.channelId);
    final nextConversation = _applyPendingPresence(conversation);
    final data = _data;
    if (data == null) {
      _data = _emptyForConversation(
        nextConversation,
      ).copyWith(conversations: [nextConversation]);
    } else if (data.conversations.any(
      (existing) => existing.channelId == conversation.channelId,
    )) {
      _data = data;
    } else {
      _data = _replaceConversation(
        data,
        nextConversation,
        insertWhenMissing: true,
      );
    }
    return _applyVisibility(_data!);
  }

  DirectMessagesWorkspaceData _mergeSnapshot(DirectMessagesWorkspaceData next) {
    final existingById = {
      for (final conversation in _data?.conversations ?? const [])
        conversation.channelId: conversation,
    };
    final conversations = [
      for (final incoming in next.conversations)
        _mergeConversation(existingById[incoming.channelId], incoming),
    ];
    return next.copyWith(conversations: conversations, isRefreshing: false);
  }

  DmConversationPreviewSeed _mergeConversation(
    DmConversationPreviewSeed? existing,
    DmConversationPreviewSeed incoming,
  ) {
    final cachedMessages = _messagesByChannel[incoming.channelId];
    if (cachedMessages != null) {
      return conversationWithMessages(incoming, cachedMessages);
    }
    if (existing == null || existing.lastMessage == 'No messages yet') {
      return incoming;
    }
    if (incoming.lastMessage == 'No messages yet') {
      return incoming.copyWith(lastMessage: existing.lastMessage);
    }
    return incoming;
  }

  DirectMessagesWorkspaceData _replaceConversation(
    DirectMessagesWorkspaceData data,
    DmConversationPreviewSeed conversation, {
    bool insertWhenMissing = false,
  }) {
    var replaced = false;
    final conversations = <DmConversationPreviewSeed>[];
    for (final existing in data.conversations) {
      if (existing.channelId == conversation.channelId) {
        conversations.add(conversation);
        replaced = true;
      } else {
        conversations.add(existing);
      }
    }
    if (!replaced && insertWhenMissing) {
      conversations.add(conversation);
    }
    return data.copyWith(conversations: conversations);
  }

  DirectMessagesWorkspaceData _applyVisibility(
    DirectMessagesWorkspaceData data,
  ) {
    return data.copyWith(
      conversations: [
        for (final conversation in data.conversations)
          if (!_hiddenChannelIds.contains(conversation.channelId)) conversation,
      ],
    );
  }

  DirectMessagesWorkspaceData _emptyForConversation(
    DmConversationPreviewSeed conversation,
  ) {
    return DirectMessagesWorkspaceData.empty(
      networkId: conversation.networkId,
      currentUserName: '',
      currentUserInitials: '',
    );
  }

  DmConversationMessages _mergeMessages(
    String channelId,
    DmConversationMessages incoming,
  ) {
    final existing = _messagesByChannel[channelId];
    if (existing == null || existing.messages.isEmpty) {
      return incoming;
    }
    final byId = <String, MessageSeed>{};
    for (final message in incoming.messages) {
      byId[message.id] = message;
    }
    for (final message in existing.messages) {
      byId[message.id] = message;
    }
    return DmConversationMessages(
      channelId: channelId,
      messages: byId.values.toList(growable: false),
      error: incoming.error ?? existing.error,
    );
  }

  DmConversationPreviewSeed _applyPendingPresence(
    DmConversationPreviewSeed conversation,
  ) {
    final localUserId = conversation.localUserId;
    if (localUserId == null) {
      return conversation;
    }
    final status =
        _pendingPresenceByUser[_presenceKey(
          conversation.networkId,
          localUserId,
        )];
    if (status == null) {
      return conversation;
    }
    return conversation.copyWith(status: status);
  }

  DmConversationPreviewSeed? _conversationInData(
    DirectMessagesWorkspaceData? data,
    String channelId,
  ) {
    if (data == null) {
      return null;
    }
    for (final conversation in data.conversations) {
      if (conversation.channelId == channelId) {
        return conversation;
      }
    }
    return null;
  }
}

DmConversationPreviewSeed conversationWithMessages(
  DmConversationPreviewSeed conversation,
  DmConversationMessages messages,
) {
  if (messages.messages.isEmpty) {
    return conversation.copyWith(lastMessage: 'No messages yet');
  }
  final body = messages.messages.last.body.trim();
  final preview = body.isEmpty ? 'Message' : body;
  return conversation.copyWith(lastMessage: _truncatePreview(preview));
}

String _truncatePreview(String value) {
  if (value.length <= 72) {
    return value;
  }
  return '${value.substring(0, 69)}...';
}

String _networkIdFromScopedChannel(String channelId) {
  final slash = channelId.indexOf('/');
  return slash <= 0 ? 'official' : channelId.substring(0, slash);
}

String _localIdFromScopedChannel(String channelId) {
  final slash = channelId.indexOf('/');
  return slash < 0 ? channelId : channelId.substring(slash + 1);
}

String? _localIdFromScopedUser(String userId, String networkId) {
  if (!isSafeScopedWorkspaceId(userId, networkId: networkId)) {
    return null;
  }
  return safeWorkspaceLocalId(userId, allowScopedPrefix: true);
}

String _presenceKey(String networkId, String localUserId) {
  return '${_canonicalPresenceNetworkId(networkId)}/$localUserId';
}

bool _sameFriendIdentity(
  FriendPreviewSeed existing,
  FriendPreviewSeed incoming,
) {
  if (existing.id == incoming.id) {
    return true;
  }
  return sameWorkspaceNetworkId(existing.networkId, incoming.networkId) &&
      existing.localUserId == incoming.localUserId;
}

String _canonicalPresenceNetworkId(String networkId) {
  return sameWorkspaceNetworkId(networkId, 'official') ? 'official' : networkId;
}

String? _safeLocalIdOrNull(String value) {
  try {
    return safeWorkspaceLocalId(value, allowScopedPrefix: true);
  } on FormatException {
    return null;
  }
}

String _normalizeRealtimeStatus(String rawStatus) {
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
