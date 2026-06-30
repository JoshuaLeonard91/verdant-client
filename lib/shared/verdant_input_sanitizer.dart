final _htmlTagPattern = RegExp(r'<[^>]*>');
final _hiddenUnicodePattern = RegExp(
  r'[\u200B-\u200F\u202A-\u202E\u2066-\u2069]',
);
final _oneLineControlPattern = RegExp(r'[\x00-\x1F\x7F-\x9F]');
final _multiSpacePattern = RegExp(r'\s+');

String sanitizeDisplayNameInput(String input, {int maxLength = 80}) {
  return _sanitizeOneLine(
    input,
    maxLength: maxLength,
    collapseWhitespace: true,
  );
}

String sanitizeUsernameInput(String input, {int maxLength = 80}) {
  return _sanitizeOneLine(
    input,
    maxLength: maxLength,
    collapseWhitespace: true,
  );
}

String sanitizeEmailInput(String input, {int maxLength = 254}) {
  return _sanitizeOneLine(
    input,
    maxLength: maxLength,
    collapseWhitespace: false,
  );
}

String sanitizeInviteCodeInput(String input, {int maxLength = 160}) {
  return _sanitizeOneLine(
    input,
    maxLength: maxLength,
    collapseWhitespace: false,
  );
}

String sanitizeSearchInput(String input, {int maxLength = 200}) {
  return _sanitizeOneLine(
    input,
    maxLength: maxLength,
    collapseWhitespace: true,
  );
}

String sanitizeUrlInput(String input, {int maxLength = 2048}) {
  return _sanitizeOneLine(
    input,
    maxLength: maxLength,
    collapseWhitespace: false,
  );
}

String _sanitizeOneLine(
  String input, {
  required int maxLength,
  required bool collapseWhitespace,
}) {
  var value = input
      .replaceAll(_htmlTagPattern, '')
      .replaceAll(_hiddenUnicodePattern, '')
      .replaceAll(_oneLineControlPattern, '')
      .trim();
  if (collapseWhitespace) {
    value = value.replaceAll(_multiSpacePattern, ' ');
  }
  if (value.length <= maxLength) {
    return value;
  }
  return value.substring(0, maxLength).trimRight();
}
