import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/shared/server_message_projection.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';

void main() {
  test(
    'upsertServerMessage replaces scoped and raw ids by local message id',
    () {
      const existing = [
        MessageSeed(
          id: 'official/message-1',
          authorId: 'official/user-1',
          author: 'Avery',
          time: '10:00 AM',
          body: 'before',
          initials: 'AV',
        ),
      ];
      const incoming = MessageSeed(
        id: 'message-1',
        authorId: 'official/user-1',
        author: 'Avery',
        time: '10:01 AM',
        body: 'after',
        initials: 'AV',
      );

      final next = upsertServerMessage(existing, incoming);

      expect(next, hasLength(1));
      expect(next.single.body, 'after');
    },
  );

  test(
    'upsertServerMessage appends a new message when no local id matches',
    () {
      const existing = [
        MessageSeed(
          id: 'official/message-1',
          authorId: 'official/user-1',
          author: 'Avery',
          time: '10:00 AM',
          body: 'before',
          initials: 'AV',
        ),
      ];
      const incoming = MessageSeed(
        id: 'official/message-2',
        authorId: 'official/user-2',
        author: 'Morgan',
        time: '10:02 AM',
        body: 'new',
        initials: 'MO',
      );

      final next = upsertServerMessage(existing, incoming);

      expect(next.map((message) => message.body), ['before', 'new']);
    },
  );

  test(
    'removeServerMessage removes scoped and raw ids by local message id',
    () {
      const messages = [
        MessageSeed(
          id: 'official/message-1',
          authorId: 'official/user-1',
          author: 'Avery',
          time: '10:00 AM',
          body: 'keep',
          initials: 'AV',
        ),
        MessageSeed(
          id: 'official/message-2',
          authorId: 'official/user-2',
          author: 'Morgan',
          time: '10:02 AM',
          body: 'remove',
          initials: 'MO',
        ),
      ];

      final next = removeServerMessage(messages, 'message-2');

      expect(next.map((message) => message.body), ['keep']);
    },
  );

  test('replaceServerMessage updates matching messages without appending', () {
    const existing = [
      MessageSeed(
        id: 'official/message-1',
        authorId: 'official/user-1',
        author: 'Avery',
        time: '10:00 AM',
        body: 'before',
        initials: 'AV',
      ),
    ];
    const unmatched = MessageSeed(
      id: 'official/message-2',
      authorId: 'official/user-2',
      author: 'Morgan',
      time: '10:02 AM',
      body: 'new',
      initials: 'MO',
    );

    final next = replaceServerMessage(existing, unmatched);

    expect(next, hasLength(1));
    expect(next.single.body, 'before');
  });
}
