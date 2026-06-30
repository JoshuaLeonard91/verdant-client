import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/shared/message_reaction_projection.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';

void main() {
  test(
    'adds a current-user reaction without double counting an optimistic chip',
    () {
      const messages = [
        MessageSeed(
          id: 'official/message-1',
          authorId: 'official/user-1',
          author: 'Avery',
          time: '10:00 AM',
          body: 'hello',
          initials: 'AV',
          reactions: [
            ReactionSeed(emoji: '👍', count: 1, reactedByCurrentUser: true),
          ],
        ),
      ];

      final next = applyServerReactionAdd(
        messages,
        messageId: 'official/message-1',
        emoji: '👍',
        emojiId: null,
        currentLocalUserId: '42',
        eventLocalUserId: '42',
      );

      expect(next.single.reactions.single.count, 1);
      expect(next.single.reactions.single.reactedByCurrentUser, isTrue);
    },
  );

  test('removes a current-user reaction and drops empty chips', () {
    const messages = [
      MessageSeed(
        id: 'official/message-1',
        authorId: 'official/user-1',
        author: 'Avery',
        time: '10:00 AM',
        body: 'hello',
        initials: 'AV',
        reactions: [
          ReactionSeed(emoji: '👍', count: 1, reactedByCurrentUser: true),
        ],
      ),
    ];

    final next = applyServerReactionRemove(
      messages,
      messageId: 'message-1',
      emoji: '👍',
      currentLocalUserId: '42',
      eventLocalUserId: '42',
    );

    expect(next.single.reactions, isEmpty);
  });

  test('leaves unrelated messages unchanged', () {
    const messages = [
      MessageSeed(
        id: 'official/message-1',
        authorId: 'official/user-1',
        author: 'Avery',
        time: '10:00 AM',
        body: 'hello',
        initials: 'AV',
      ),
    ];

    final next = applyServerReactionAdd(
      messages,
      messageId: 'message-2',
      emoji: '🔥',
      emojiId: null,
      currentLocalUserId: '42',
      eventLocalUserId: '181',
    );

    expect(identical(next.single, messages.single), isTrue);
  });
}
