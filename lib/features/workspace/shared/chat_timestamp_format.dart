import 'package:flutter/widgets.dart';

enum ChatDateOrder { monthDayYear, dayMonthYear, yearMonthDay }

final class ChatTimestampFormatOptions {
  const ChatTimestampFormatOptions({
    this.dateOrder = ChatDateOrder.monthDayYear,
    this.use24HourTime = false,
  });

  factory ChatTimestampFormatOptions.fromLocale(
    Locale locale, {
    bool? use24HourTime,
  }) {
    return ChatTimestampFormatOptions(
      dateOrder: _dateOrderForLocale(locale),
      use24HourTime: use24HourTime ?? _uses24HourTime(locale),
    );
  }

  final ChatDateOrder dateOrder;
  final bool use24HourTime;
}

String formatChatTimestamp({
  required String fallbackLabel,
  required DateTime now,
  DateTime? createdAt,
  ChatTimestampFormatOptions options = const ChatTimestampFormatOptions(),
}) {
  final timestamp = (createdAt ?? DateTime.tryParse(fallbackLabel))?.toLocal();
  if (timestamp == null) {
    return fallbackLabel;
  }
  final localNow = now.toLocal();
  final clock = formatClockLabel(timestamp, options: options);
  if (_sameDate(timestamp, localNow)) {
    return 'Today at $clock';
  }
  if (_sameDate(timestamp, localNow.subtract(const Duration(days: 1)))) {
    return 'Yesterday at $clock';
  }
  return '${_dateLabel(timestamp, options.dateOrder)} at $clock';
}

String formatClockLabel(
  DateTime value, {
  ChatTimestampFormatOptions options = const ChatTimestampFormatOptions(),
}) {
  final local = value.toLocal();
  if (options.use24HourTime) {
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String formatWorkspaceDateTimeLabel(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  final local = parsed.toLocal();
  return '${_dateLabel(local, ChatDateOrder.yearMonthDay)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String formatWorkspaceDateLabel(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  return _dateLabel(parsed.toLocal(), ChatDateOrder.yearMonthDay);
}

ChatDateOrder _dateOrderForLocale(Locale locale) {
  final country = locale.countryCode?.toUpperCase();
  if (country == 'US') {
    return ChatDateOrder.monthDayYear;
  }
  final language = locale.languageCode.toLowerCase();
  if (country == 'CN' ||
      country == 'JP' ||
      country == 'KR' ||
      language == 'zh' ||
      language == 'ja' ||
      language == 'ko') {
    return ChatDateOrder.yearMonthDay;
  }
  return ChatDateOrder.dayMonthYear;
}

bool _uses24HourTime(Locale locale) {
  final country = locale.countryCode?.toUpperCase();
  if (country == 'US' || country == 'CA' || country == 'AU') {
    return false;
  }
  return true;
}

bool _sameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _dateLabel(DateTime value, ChatDateOrder order) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return switch (order) {
    ChatDateOrder.monthDayYear => '$month/$day/$year',
    ChatDateOrder.dayMonthYear => '$day/$month/$year',
    ChatDateOrder.yearMonthDay => '$year/$month/$day',
  };
}
