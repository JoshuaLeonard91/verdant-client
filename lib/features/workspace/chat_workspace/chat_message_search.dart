import '../workspace_local_id.dart';
import '../workspace_seed.dart';

enum ChatSearchTargetType { channel, user }

final class ChatSearchPrefix {
  const ChatSearchPrefix._(this.type, this.partial);

  const ChatSearchPrefix.channel(String partial)
    : this._(ChatSearchTargetType.channel, partial);

  const ChatSearchPrefix.user(String partial)
    : this._(ChatSearchTargetType.user, partial);

  final ChatSearchTargetType type;
  final String partial;

  @override
  bool operator ==(Object other) {
    return other is ChatSearchPrefix &&
        other.type == type &&
        other.partial == partial;
  }

  @override
  int get hashCode => Object.hash(type, partial);
}

final class ChatSearchOperatorSuggestion {
  const ChatSearchOperatorSuggestion({
    required this.id,
    required this.label,
    required this.operator,
    required this.targetType,
    required this.targetLabel,
  });

  final String id;
  final String label;
  final String operator;
  final ChatSearchTargetType targetType;
  final String targetLabel;

  @override
  bool operator ==(Object other) {
    return other is ChatSearchOperatorSuggestion &&
        other.id == id &&
        other.label == label &&
        other.operator == operator &&
        other.targetType == targetType &&
        other.targetLabel == targetLabel;
  }

  @override
  int get hashCode => Object.hash(id, label, operator, targetType, targetLabel);
}

final class ChatSearchFilter {
  const ChatSearchFilter({
    required this.type,
    required this.id,
    required this.label,
  });

  final ChatSearchTargetType type;
  final String id;
  final String label;

  @override
  bool operator ==(Object other) {
    return other is ChatSearchFilter &&
        other.type == type &&
        other.id == id &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(type, id, label);
}

final class ChatSearchSuggestion {
  const ChatSearchSuggestion._({
    required this.type,
    required this.id,
    required this.label,
    this.username,
    this.avatarUrl,
    this.operator,
    this.targetLabel,
  });

  factory ChatSearchSuggestion.channel(ChannelSeed channel) {
    return ChatSearchSuggestion._(
      type: ChatSearchTargetType.channel,
      id: channel.id,
      label: channel.name,
    );
  }

  factory ChatSearchSuggestion.member(MemberSeed member) {
    return ChatSearchSuggestion._(
      type: ChatSearchTargetType.user,
      id: member.id ?? member.name,
      label: member.name,
      username: member.name,
      avatarUrl: member.avatarUrl,
    );
  }

  factory ChatSearchSuggestion.operator(
    ChatSearchOperatorSuggestion suggestion,
  ) {
    return ChatSearchSuggestion._(
      type: suggestion.targetType,
      id: suggestion.id,
      label: suggestion.label,
      operator: suggestion.operator,
      targetLabel: suggestion.targetLabel,
    );
  }

  final ChatSearchTargetType type;
  final String id;
  final String label;
  final String? username;
  final String? avatarUrl;
  final String? operator;
  final String? targetLabel;

  bool get isOperator => operator != null;
}

final class ChatSearchSelection {
  const ChatSearchSelection({required this.query, required this.filters});

  final String query;
  final List<ChatSearchFilter> filters;
}

ChatSearchPrefix? detectChatSearchPrefix(String text) {
  final channelMatch = RegExp(
    r'\bin:(\S*)$',
    caseSensitive: false,
  ).firstMatch(text);
  if (channelMatch != null) {
    return ChatSearchPrefix.channel(
      (channelMatch.group(1) ?? '').toLowerCase(),
    );
  }

  final userMatch = RegExp(
    r'\bfrom:(\S*)$',
    caseSensitive: false,
  ).firstMatch(text);
  if (userMatch != null) {
    return ChatSearchPrefix.user((userMatch.group(1) ?? '').toLowerCase());
  }

  return null;
}

ChatSearchOperatorSuggestion? detectChatSearchOperatorSuggestion(String text) {
  final match = RegExp(
    r'(^|\s)([a-z]*)$',
    caseSensitive: false,
  ).firstMatch(text);
  final partial = match?.group(2)?.toLowerCase();
  if (partial == null || partial.isEmpty) {
    return null;
  }

  if ('from'.startsWith(partial)) {
    return const ChatSearchOperatorSuggestion(
      id: 'operator-from',
      label: 'from:',
      operator: 'from:',
      targetType: ChatSearchTargetType.user,
      targetLabel: 'user',
    );
  }

  if ('in'.startsWith(partial)) {
    return const ChatSearchOperatorSuggestion(
      id: 'operator-in',
      label: 'in:',
      operator: 'in:',
      targetType: ChatSearchTargetType.channel,
      targetLabel: 'channel',
    );
  }

  return null;
}

String completeChatSearchOperatorToken(String text, String operator) {
  return text.replaceFirstMapped(
    RegExp(r'(^|\s)([a-z]*)$', caseSensitive: false),
    (match) => '${match.group(1) ?? ''}$operator',
  );
}

List<ChatSearchSuggestion> chatChannelSearchSuggestions({
  required Iterable<ChannelSeed> channels,
  required String partial,
  int max = 6,
}) {
  final query = partial.trim().toLowerCase();
  return channels
      .where((channel) => channel.type == 0)
      .where(
        (channel) =>
            query.isEmpty || channel.name.toLowerCase().contains(query),
      )
      .take(max)
      .map(ChatSearchSuggestion.channel)
      .toList(growable: false);
}

List<ChatSearchSuggestion> chatMemberSearchSuggestions({
  required Iterable<MemberSeed> members,
  required String partial,
  int max = 6,
}) {
  final query = partial.trim().toLowerCase();
  return members
      .where(
        (member) => query.isEmpty || member.name.toLowerCase().contains(query),
      )
      .take(max)
      .map(ChatSearchSuggestion.member)
      .toList(growable: false);
}

ChatSearchSelection applyChatSearchSuggestion({
  required String query,
  required ChatSearchSuggestion suggestion,
  required List<ChatSearchFilter> filters,
}) {
  if (suggestion.isOperator) {
    return ChatSearchSelection(
      query: completeChatSearchOperatorToken(query, suggestion.operator!),
      filters: filters,
    );
  }

  final updatedFilters = [
    for (final filter in filters)
      if (filter.type != suggestion.type) filter,
    ChatSearchFilter(
      type: suggestion.type,
      id: suggestion.id,
      label: suggestion.label,
    ),
  ];
  final cleaned = query
      .replaceFirst(RegExp(r'\b(in|from):\S*$', caseSensitive: false), '')
      .trimRight();

  return ChatSearchSelection(query: cleaned, filters: updatedFilters);
}

List<MessageSeed> searchHydratedChatMessages({
  required List<MessageSeed> messages,
  required String query,
  required List<ChatSearchFilter> filters,
  int limit = 20,
}) {
  final text = query.trim().toLowerCase();
  final userFilter = filters
      .where((filter) => filter.type == ChatSearchTargetType.user)
      .firstOrNull;
  if (text.isEmpty && userFilter == null) {
    return const [];
  }

  final filtered = messages
      .where((message) {
        if (userFilter != null &&
            safeWorkspaceLocalId(message.authorId, allowScopedPrefix: true) !=
                safeWorkspaceLocalId(userFilter.id, allowScopedPrefix: true)) {
          return false;
        }
        return text.isEmpty || message.body.toLowerCase().contains(text);
      })
      .toList(growable: false);

  filtered.sort((left, right) {
    final rightTime = DateTime.tryParse(right.createdAt ?? '');
    final leftTime = DateTime.tryParse(left.createdAt ?? '');
    final byTime =
        (rightTime?.millisecondsSinceEpoch ?? 0) -
        (leftTime?.millisecondsSinceEpoch ?? 0);
    if (byTime != 0) {
      return byTime;
    }
    return right.id.compareTo(left.id);
  });

  return filtered.take(limit).toList(growable: false);
}
