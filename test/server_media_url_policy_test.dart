import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';

void main() {
  final officialPolicy = ServerMediaPolicy.fromOrigins(
    apiOrigin: 'https://api.verdant.chat',
  );

  test('accepts https public server media URLs', () {
    final uri = safeServerMediaUri(
      'https://media.verdant.chat/server-banners/123/banner.webp',
      policy: officialPolicy,
    );

    expect(
      uri?.toString(),
      'https://media.verdant.chat/server-banners/123/banner.webp',
    );
  });

  test(
    'rejects off-policy, credentialed, private, and attachment media URLs',
    () {
      expect(
        safeServerMediaUri(
          'https://evil.example/server-icons/123/icon.png',
          policy: officialPolicy,
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'https://user:pass@media.verdant.chat/server-icons/123/icon.png',
          policy: officialPolicy,
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'http://192.168.1.10/server-banners/123/banner.webp',
          policy: officialPolicy,
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'https://[::ffff:127.0.0.1]/server-icons/123/icon.png',
          policy: ServerMediaPolicy.fromOrigins(
            apiOrigin: 'https://api.example.com',
            cdnUrl: 'https://[::ffff:127.0.0.1]',
          ),
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'https://[::ffff:10.0.0.12]/server-icons/123/icon.png',
          policy: ServerMediaPolicy.fromOrigins(
            apiOrigin: 'https://api.example.com',
            cdnUrl: 'https://[::ffff:10.0.0.12]',
          ),
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'https://[::ffff:192.168.1.1]/server-icons/123/icon.png',
          policy: ServerMediaPolicy.fromOrigins(
            apiOrigin: 'https://api.example.com',
            cdnUrl: 'https://[::ffff:192.168.1.1]',
          ),
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'https://media.verdant.chat/attachments/private-key',
          policy: officialPolicy,
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'https://media.verdant.chat/%61ttachments/private-key',
          policy: officialPolicy,
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'https://media.verdant.chat/server-icons/%2e%2e/attachments/key.png',
          policy: officialPolicy,
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'https://media.verdant.chat/server-icons/safe%2fattachments/key.png',
          policy: officialPolicy,
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'https://media.verdant.chat/server-icons/safe%5cattachments/key.png',
          policy: officialPolicy,
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'https://media.verdant.chat/server-icons/safe%252fattachments/key.png',
          policy: officialPolicy,
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'https://media.verdant.chat/server-icons/%252e%252e/icon.png',
          policy: officialPolicy,
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'https://media.verdant.chat/%2561ttachments/private-key',
          policy: officialPolicy,
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'https://media.verdant.chat/server-icons/123/icon.svg',
          policy: officialPolicy,
        ),
        isNull,
      );
    },
  );

  test('allows loopback http media only for local development networks', () {
    expect(
      safeServerMediaUri(
        'http://localhost:8787/server-icons/123/icon.png',
        policy: officialPolicy,
      ),
      isNull,
    );

    final localPolicy = ServerMediaPolicy.fromOrigins(
      apiOrigin: 'http://localhost:8787',
    );
    final uri = safeServerMediaUri(
      'http://localhost:8787/server-icons/123/icon.png',
      policy: localPolicy,
    );

    expect(uri?.host, 'localhost');
  });

  test('accepts selected network public and cdn origins only', () {
    final selfHostPolicy = ServerMediaPolicy.fromOrigins(
      apiOrigin: 'https://api.example.com',
      publicUrl: 'https://example.com',
      cdnUrl: 'https://cdn.example.com/media',
    );

    expect(
      safeServerMediaUri(
        'https://cdn.example.com/media/server-icons/123/icon.webp',
        policy: selfHostPolicy,
      )?.host,
      'cdn.example.com',
    );
    expect(
      safeServerMediaUri(
        'https://other.example.com/server-icons/123/icon.webp',
        policy: selfHostPolicy,
      ),
      isNull,
    );
  });

  test(
    'resolves backend-relative public media keys against the API origin',
    () {
      final selfHostPolicy = ServerMediaPolicy.fromOrigins(
        apiOrigin: 'https://api.example.com',
        publicUrl: 'https://example.com',
        cdnUrl: 'https://cdn.example.com/media',
      );

      expect(
        safeServerMediaUri(
          'server-banners/123/banner.webp',
          policy: selfHostPolicy,
        )?.toString(),
        'https://api.example.com/server-banners/123/banner.webp',
      );
      expect(
        safeServerMediaUri(
          'attachments/123/private.webp',
          policy: selfHostPolicy,
        ),
        isNull,
      );
      expect(
        safeServerMediaUri(
          'server-banners/123/%2e%2e/attachments/private.webp',
          policy: selfHostPolicy,
        ),
        isNull,
      );
    },
  );

  test(
    'accepts public IPv4-mapped IPv6 media literals only when allowlisted',
    () {
      final mappedPublicPolicy = ServerMediaPolicy.fromOrigins(
        apiOrigin: 'https://api.example.com',
        cdnUrl: 'https://[::ffff:93.184.216.34]',
      );

      expect(
        safeServerMediaUri(
          'https://[::ffff:93.184.216.34]/server-icons/123/icon.webp',
          policy: mappedPublicPolicy,
        ),
        isNotNull,
      );
    },
  );
}
