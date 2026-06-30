import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/shared/verdant_input_sanitizer.dart';

void main() {
  test('sanitizes one-line identity and navigation inputs', () {
    expect(
      sanitizeDisplayNameInput('  <b>Verdant\u202e Server</b>\u200b  '),
      'Verdant Server',
    );
    expect(
      sanitizeEmailInput('  <b>new@example.com</b>\u202e  '),
      'new@example.com',
    );
    expect(
      sanitizeInviteCodeInput('  <span>abc123</span>\u2069  '),
      'abc123',
    );
    expect(
      sanitizeUrlInput('  https://api.community.example/\u200b  '),
      'https://api.community.example/',
    );
  });

  test('sanitizes search text without preserving hidden controls', () {
    expect(
      sanitizeSearchInput('  <img src=x>from:avery\u202e  '),
      'from:avery',
    );
  });

  test('bounds user supplied one-line fields', () {
    final longName = List.filled(200, 'a').join();
    final longSearch = List.filled(400, 'b').join();

    expect(sanitizeDisplayNameInput(longName), hasLength(80));
    expect(sanitizeSearchInput(longSearch), hasLength(200));
  });
}
