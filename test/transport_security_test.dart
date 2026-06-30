import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/auth/transport_security.dart';

void main() {
  test('normalizes hex and base64 SHA-256 certificate pins', () {
    final bytes = List<int>.generate(32, (index) => index);
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    expect(normalizeCertificateSha256Pin(hex.toUpperCase()), hex);
    expect(normalizeCertificateSha256Pin('sha256:$hex'), hex);
    expect(
      normalizeCertificateSha256Pin(
        hex.replaceAllMapped(RegExp(r'.{2}'), (match) => '${match[0]}:'),
      ),
      hex,
    );
    expect(
      normalizeCertificateSha256Pin(
        'sha256/AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=',
      ),
      hex,
    );
    expect(normalizeCertificateSha256Pin('not-a-pin'), isNull);
  });

  test('matches configured certificate pins by normalized API origin', () {
    final cert = _FakeCertificate(Uint8List.fromList([1, 2, 3, 4]));
    final pin = certificateSha256Fingerprint(cert);
    final policy = CertificatePinningPolicy(
      pinsByApiOrigin: {
        'api.verdant.chat': [pin],
      },
    );

    expect(policy.hasPinsForApiOrigin(officialApiOrigin), isTrue);
    expect(
      policy.acceptsCertificate(apiOrigin: officialApiOrigin, cert: cert),
      isTrue,
    );
    expect(
      () => policy.requireMatchingCertificate(
        apiOrigin: officialApiOrigin,
        cert: _FakeCertificate(Uint8List.fromList([9, 9, 9])),
      ),
      throwsA(
        isA<CertificatePinningException>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('certificate mismatch'), isNot(contains(pin))),
        ),
      ),
    );
  });

  test('disabled certificate policy accepts certificates without pins', () {
    final cert = _FakeCertificate(Uint8List.fromList([1, 2, 3]));

    expect(
      CertificatePinningPolicy.disabled.acceptsCertificate(
        apiOrigin: 'https://selfhost.example',
        cert: cert,
      ),
      isTrue,
    );
  });
}

final class _FakeCertificate implements X509Certificate {
  _FakeCertificate(this.der);

  @override
  final Uint8List der;

  @override
  DateTime get endValidity => DateTime.utc(2030);

  @override
  String get issuer => 'CN=issuer';

  @override
  String get pem => '-----BEGIN CERTIFICATE----- redacted';

  @override
  Uint8List get sha1 => Uint8List(20);

  @override
  DateTime get startValidity => DateTime.utc(2026);

  @override
  String get subject => 'CN=api.verdant.chat';
}
