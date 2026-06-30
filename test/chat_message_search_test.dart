import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/chat_message_search.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';

void main() {
  test('detects Tauri-style message search operators', () {
    expect(
      detectChatSearchOperatorSuggestion('fro'),
      const ChatSearchOperatorSuggestion(
        id: 'operator-from',
        label: 'from:',
        operator: 'from:',
        targetType: ChatSearchTargetType.user,
        targetLabel: 'user',
      ),
    );
    expect(
      detectChatSearchOperatorSuggestion('release i'),
      const ChatSearchOperatorSuggestion(
        id: 'operator-in',
        label: 'in:',
        operator: 'in:',
        targetType: ChatSearchTargetType.channel,
        targetLabel: 'channel',
      ),
    );
    expect(
      detectChatSearchPrefix('from:jo'),
      const ChatSearchPrefix.user('jo'),
    );
    expect(
      detectChatSearchPrefix('bug in:gen'),
      const ChatSearchPrefix.channel('gen'),
    );
  });

  test(
    'completes operator and target suggestions like the Tauri search bar',
    () {
      expect(completeChatSearchOperatorToken('fro', 'from:'), 'from:');
      expect(completeChatSearchOperatorToken('hello i', 'in:'), 'hello in:');

      const member = MemberSeed(
        id: 'official/user-joshy',
        name: 'Joshy',
        status: 'Online',
        initials: 'JO',
      );
      final selected = applyChatSearchSuggestion(
        query: 'status from:jos',
        suggestion: ChatSearchSuggestion.member(member),
        filters: const [],
      );

      expect(selected.query, 'status');
      expect(selected.filters, [
        const ChatSearchFilter(
          type: ChatSearchTargetType.user,
          id: 'official/user-joshy',
          label: 'Joshy',
        ),
      ]);
    },
  );

  test(
    'searches hydrated active-channel messages with text and from filters',
    () {
      const messages = [
        MessageSeed(
          id: 'official/message-1',
          authorId: 'official/user-joshy',
          author: 'Joshy',
          time: '1:00 PM',
          body: 'release notes are ready',
          initials: 'JO',
        ),
        MessageSeed(
          id: 'official/message-2',
          authorId: 'official/user-avery',
          author: 'Avery',
          time: '1:05 PM',
          body: 'release notes reviewed',
          initials: 'AV',
        ),
      ];

      final results = searchHydratedChatMessages(
        messages: messages,
        query: 'release',
        filters: const [
          ChatSearchFilter(
            type: ChatSearchTargetType.user,
            id: 'official/user-avery',
            label: 'Avery',
          ),
        ],
      );

      expect(results.map((message) => message.id), ['official/message-2']);
    },
  );
}
