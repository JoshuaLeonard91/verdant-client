import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/app/client_version.dart';

void main() {
  test('client version is semver and used in the Flutter user agent', () {
    expect(verdantClientVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    expect(
      verdantFlutterUserAgent,
      equals('VerdantFlutter/$verdantClientVersion'),
    );
  });
}
