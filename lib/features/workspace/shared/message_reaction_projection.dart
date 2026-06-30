import '../workspace_seed.dart';

List<MessageSeed> applyServerReactionAdd(
  List<MessageSeed> messages, {
  required String messageId,
  required String emoji,
  required String? emojiId,
  required String? currentLocalUserId,
  required String eventLocalUserId,
}) {
  final messageKey = _messageIdKey(messageId);
  final isCurrentUser =
      currentLocalUserId != null && currentLocalUserId == eventLocalUserId;
  return [
    for (final message in messages)
      _messageKey(message) == messageKey
          ? message.copyWith(
              reactions: _addReactionToSnapshot(
                message.reactions,
                emoji: emoji,
                emojiId: emojiId,
                isCurrentUser: isCurrentUser,
              ),
            )
          : message,
  ];
}

List<MessageSeed> applyServerReactionRemove(
  List<MessageSeed> messages, {
  required String messageId,
  required String emoji,
  required String? currentLocalUserId,
  required String eventLocalUserId,
}) {
  final messageKey = _messageIdKey(messageId);
  final isCurrentUser =
      currentLocalUserId != null && currentLocalUserId == eventLocalUserId;
  return [
    for (final message in messages)
      _messageKey(message) == messageKey
          ? message.copyWith(
              reactions: _removeReactionFromSnapshot(
                message.reactions,
                emoji: emoji,
                isCurrentUser: isCurrentUser,
              ),
            )
          : message,
  ];
}

String _messageKey(MessageSeed message) => _messageIdKey(message.id);

String _messageIdKey(String rawMessageId) {
  final trimmed = rawMessageId.trim();
  final slash = trimmed.indexOf('/');
  if (slash >= 0 && slash < trimmed.length - 1) {
    return trimmed.substring(slash + 1);
  }
  return trimmed;
}

List<ReactionSeed> _addReactionToSnapshot(
  List<ReactionSeed> reactions, {
  required String emoji,
  required String? emojiId,
  required bool isCurrentUser,
}) {
  var found = false;
  final next = <ReactionSeed>[
    for (final reaction in reactions)
      if (reaction.emoji == emoji)
        () {
          found = true;
          return ReactionSeed(
            emoji: reaction.emoji,
            emojiId: reaction.emojiId ?? emojiId,
            count:
                reaction.count +
                (isCurrentUser && reaction.reactedByCurrentUser ? 0 : 1),
            reactedByCurrentUser:
                reaction.reactedByCurrentUser || isCurrentUser,
          );
        }()
      else
        reaction,
  ];
  if (!found) {
    next.add(
      ReactionSeed(
        emoji: emoji,
        emojiId: emojiId,
        count: 1,
        reactedByCurrentUser: isCurrentUser,
      ),
    );
  }
  return next;
}

List<ReactionSeed> _removeReactionFromSnapshot(
  List<ReactionSeed> reactions, {
  required String emoji,
  required bool isCurrentUser,
}) {
  final next = <ReactionSeed>[];
  for (final reaction in reactions) {
    if (reaction.emoji != emoji) {
      next.add(reaction);
      continue;
    }
    if (reaction.count <= 1) {
      continue;
    }
    next.add(
      ReactionSeed(
        emoji: reaction.emoji,
        emojiId: reaction.emojiId,
        count: reaction.count - 1,
        reactedByCurrentUser: isCurrentUser
            ? false
            : reaction.reactedByCurrentUser,
      ),
    );
  }
  return next;
}
