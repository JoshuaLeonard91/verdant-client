import '../../auth/auth_models.dart';

final class ServerMediaPolicy {
  const ServerMediaPolicy({
    required this.allowedOrigins,
    required this.allowLocalHttp,
    this.apiOrigin,
  });

  factory ServerMediaPolicy.fromOrigins({
    required String apiOrigin,
    String? apiUrl,
    String? publicUrl,
    String? cdnUrl,
  }) {
    final normalizedApiOrigin = normalizeBackendApiOrigin(apiOrigin);
    final origins = <String>{
      _originForUri(Uri.parse(normalizedApiOrigin)),
      if (normalizedApiOrigin == officialApiOrigin) ..._officialMediaOrigins,
    };
    for (final origin in [
      _safeOrigin(apiUrl),
      _safeOrigin(publicUrl),
      _safeOrigin(cdnUrl),
    ]) {
      if (origin != null) {
        origins.add(origin);
      }
    }

    return ServerMediaPolicy(
      allowedOrigins: origins,
      allowLocalHttp: _isLocalOrigin(normalizedApiOrigin),
      apiOrigin: normalizedApiOrigin,
    );
  }

  final Set<String> allowedOrigins;
  final bool allowLocalHttp;
  final String? apiOrigin;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServerMediaPolicy &&
            allowLocalHttp == other.allowLocalHttp &&
            apiOrigin == other.apiOrigin &&
            _sameStringSet(allowedOrigins, other.allowedOrigins);
  }

  @override
  int get hashCode {
    return Object.hash(
      allowLocalHttp,
      apiOrigin,
      Object.hashAllUnordered(allowedOrigins),
    );
  }
}

bool _sameStringSet(Set<String> left, Set<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (final value in left) {
    if (!right.contains(value)) {
      return false;
    }
  }
  return true;
}

const _officialMediaOrigins = {
  'https://verdant.chat',
  'https://pryzmapp.com',
  'https://cdn.verdant.chat',
  'https://cdn.pryzmapp.com',
  'https://media.verdant.chat',
  'https://verdant-media.nyc3.cdn.digitaloceanspaces.com',
  'https://verdant-media.nyc3.digitaloceanspaces.com',
};

const _publicRelativeMediaRoots = {
  'avatars',
  'banners',
  'bot-avatars',
  'bot-banners',
  'emojis',
  'stickers',
  'member-list-banners',
  'server-icons',
  'server-banners',
};

Uri? safeServerMediaUri(String? value, {required ServerMediaPolicy policy}) {
  final raw = value?.trim();
  if (raw == null ||
      raw.isEmpty ||
      raw.contains('\\') ||
      raw.contains('\u0000')) {
    return null;
  }

  final uri = _absoluteMediaUri(raw, policy);
  if (uri == null ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      _hasUnsafePath(uri)) {
    return null;
  }

  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  final loopback = _isLoopbackHost(host);
  final privateHost = _isPrivateHost(host);
  if (scheme == 'http') {
    if (!policy.allowLocalHttp || !loopback) {
      return null;
    }
  } else if (scheme != 'https') {
    return null;
  } else if (loopback || privateHost) {
    return null;
  }

  final origin = _originForUri(uri);
  return policy.allowedOrigins.contains(origin) ? uri : null;
}

Uri? _absoluteMediaUri(String raw, ServerMediaPolicy policy) {
  final uri = Uri.tryParse(raw);
  if (uri == null) {
    return null;
  }
  if (uri.hasScheme || uri.host.isNotEmpty) {
    return uri;
  }
  if (raw.startsWith('//') ||
      uri.hasQuery ||
      uri.hasFragment ||
      policy.apiOrigin == null) {
    return null;
  }

  final segments = uri.path
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  if (segments.isEmpty ||
      !_publicRelativeMediaRoots.contains(segments.first.toLowerCase())) {
    return null;
  }

  final relativePath = segments.map(Uri.encodeComponent).join('/');
  return Uri.parse(policy.apiOrigin!).resolve('/$relativePath');
}

String? _safeOrigin(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(raw.trim());
  if (uri == null ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'https' && !(scheme == 'http' && _isLoopbackHost(uri.host))) {
    return null;
  }
  return _originForUri(uri);
}

String _originForUri(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  final wrappedHost = host.contains(':') && !host.startsWith('[')
      ? '[$host]'
      : host;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '$scheme://$wrappedHost$port';
}

bool _isLocalOrigin(String origin) {
  final uri = Uri.parse(origin);
  return uri.scheme == 'http' && _isLoopbackHost(uri.host.toLowerCase());
}

bool _hasUnsafePath(Uri uri) {
  var path = uri.path;
  for (var pass = 0; pass < 5; pass += 1) {
    if (_pathCandidateIsUnsafe(path)) {
      return true;
    }
    if (!path.contains('%')) {
      return false;
    }
    try {
      final decoded = Uri.decodeComponent(path);
      if (decoded == path) {
        return true;
      }
      path = decoded;
    } on FormatException {
      return true;
    }
  }
  return true;
}

bool _pathCandidateIsUnsafe(String path) {
  final lowerPath = path.toLowerCase();
  if (lowerPath.contains('%2e') ||
      lowerPath.contains('%2f') ||
      lowerPath.contains('%5c') ||
      lowerPath.contains('\\')) {
    return true;
  }

  final segments = lowerPath
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  if (segments.any(
    (segment) => segment == 'attachments' || segment == '..' || segment == '.',
  )) {
    return true;
  }
  if (segments.length >= 3 &&
      segments[0] == 'api' &&
      segments[1] == 'media' &&
      segments[2] == 'attachments') {
    return true;
  }
  final extension = segments.isEmpty ? '' : segments.last.split('.').last;
  return extension == 'svg' || extension == 'svgz';
}

bool _isLoopbackHost(String host) {
  return host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '::1' ||
      host.endsWith('.localhost');
}

bool _isPrivateHost(String host) {
  final normalized = _normalizedIpLiteralHost(host);
  final ipv4 = _parseIpv4Literal(normalized);
  if (ipv4 != null) {
    return _isPrivateIpv4(ipv4[0], ipv4[1], ipv4[2]);
  }
  if (normalized.contains(':')) {
    return _isPrivateIpv6Literal(normalized);
  }

  if (host.startsWith('10.') ||
      host.startsWith('192.168.') ||
      host.startsWith('169.254.')) {
    return true;
  }

  final parts = host.split('.');
  if (parts.length == 4 && parts[0] == '172') {
    final second = int.tryParse(parts[1]);
    if (second != null && second >= 16 && second <= 31) {
      return true;
    }
  }

  return host.startsWith('fc') ||
      host.startsWith('fd') ||
      host.startsWith('fe80:');
}

String _normalizedIpLiteralHost(String host) {
  var normalized = host.toLowerCase();
  if (normalized.startsWith('[') && normalized.endsWith(']')) {
    normalized = normalized.substring(1, normalized.length - 1);
  }
  final zoneIndex = normalized.indexOf('%');
  if (zoneIndex >= 0) {
    normalized = normalized.substring(0, zoneIndex);
  }
  return normalized;
}

List<int>? _parseIpv4Literal(String host) {
  final parts = host.split('.');
  if (parts.length != 4) {
    return null;
  }
  final octets = <int>[];
  for (final part in parts) {
    if (part.isEmpty || part.length > 3 || !_allAsciiDigits(part)) {
      return null;
    }
    final value = int.tryParse(part);
    if (value == null || value > 255) {
      return null;
    }
    octets.add(value);
  }
  return octets;
}

bool _allAsciiDigits(String value) {
  for (var index = 0; index < value.length; index += 1) {
    final code = value.codeUnitAt(index);
    if (code < 0x30 || code > 0x39) {
      return false;
    }
  }
  return true;
}

bool _isPrivateIpv6Literal(String host) {
  if (host.isEmpty ||
      host == '::' ||
      host == '::1' ||
      host.startsWith('fc') ||
      host.startsWith('fd') ||
      host.startsWith('ff') ||
      host.startsWith('2001:db8')) {
    return true;
  }

  final firstGroupEnd = host.indexOf(':');
  if (firstGroupEnd > 0) {
    final firstGroup = int.tryParse(
      host.substring(0, firstGroupEnd),
      radix: 16,
    );
    if (firstGroup == null) {
      return true;
    }
    if (firstGroup >= 0xfe80 && firstGroup <= 0xfebf) {
      return true;
    }
  }

  if (host.contains('.')) {
    final lastSeparator = host.lastIndexOf(':');
    final mapped = lastSeparator >= 0
        ? _parseIpv4Literal(host.substring(lastSeparator + 1))
        : null;
    if (mapped == null) {
      return true;
    }
    if (host.contains(':ffff:') || host.startsWith('::ffff:')) {
      return _isPrivateIpv4(mapped[0], mapped[1], mapped[2]);
    }
  }

  return false;
}

bool _isPrivateIpv4(int first, int second, int third) {
  return first == 0 ||
      first == 10 ||
      first == 100 && second >= 64 && second <= 127 ||
      first == 127 ||
      first == 169 && second == 254 ||
      first == 172 && second >= 16 && second <= 31 ||
      first == 192 && second == 0 ||
      first == 192 && second == 168 ||
      first == 198 && (second == 18 || second == 19) ||
      first == 203 && second == 0 && third == 113 ||
      first >= 224;
}
