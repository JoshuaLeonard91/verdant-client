import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/shared/chat_timestamp_format.dart';

void main() {
  test('formats today as a relative day with local time for US locale', () {
    final options = ChatTimestampFormatOptions.fromLocale(
      const Locale('en', 'US'),
    );

    expect(
      formatChatTimestamp(
        createdAt: DateTime(2026, 6, 4, 18, 7),
        fallbackLabel: '2026-06-04 18:07',
        now: DateTime(2026, 6, 4, 20, 30),
        options: options,
      ),
      'Today at 6:07 PM',
    );
  });

  test('formats yesterday as a relative label with local time', () {
    expect(
      formatChatTimestamp(
        createdAt: DateTime(2026, 6, 3, 9, 15),
        fallbackLabel: '2026-06-03 09:15',
        now: DateTime(2026, 6, 4, 20, 30),
      ),
      'Yesterday at 9:15 AM',
    );
  });

  test(
    'formats older dates with slash-separated locale date order and time',
    () {
      final us = ChatTimestampFormatOptions.fromLocale(
        const Locale('en', 'US'),
      );
      final gb = ChatTimestampFormatOptions.fromLocale(
        const Locale('en', 'GB'),
      );
      final jp = ChatTimestampFormatOptions.fromLocale(
        const Locale('ja', 'JP'),
      );
      final createdAt = DateTime(2026, 5, 1, 9, 15);
      final now = DateTime(2026, 6, 4, 20, 30);

      expect(
        formatChatTimestamp(
          createdAt: createdAt,
          fallbackLabel: '2026-05-01 09:15',
          now: now,
          options: us,
        ),
        '05/01/2026 at 9:15 AM',
      );
      expect(
        formatChatTimestamp(
          createdAt: createdAt,
          fallbackLabel: '2026-05-01 09:15',
          now: now,
          options: gb,
        ),
        '01/05/2026 at 09:15',
      );
      expect(
        formatChatTimestamp(
          createdAt: createdAt,
          fallbackLabel: '2026-05-01 09:15',
          now: now,
          options: jp,
        ),
        '2026/05/01 at 09:15',
      );
    },
  );

  test(
    'parses fallback timestamp strings and removes dash date formatting',
    () {
      expect(
        formatChatTimestamp(
          fallbackLabel: '2026-05-01 09:15',
          now: DateTime(2026, 6, 4, 20, 30),
          options: ChatTimestampFormatOptions.fromLocale(
            const Locale('en', 'US'),
          ),
        ),
        '05/01/2026 at 9:15 AM',
      );
    },
  );

  test('formats workspace fallback date labels with slash separators', () {
    expect(
      formatWorkspaceDateTimeLabel('2026-05-01T09:15:00Z'),
      isNot(contains('-')),
    );
    expect(formatWorkspaceDateLabel('2026-05-01T09:15:00Z'), contains('/'));
  });
}
