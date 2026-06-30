const officialApiOrigin = 'https://api.verdant.chat';
const legacyOfficialNetworkId = 'official';

final _schemePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://');
const _localHosts = {'localhost', '127.0.0.1', '::1'};

String normalizeBackendApiOrigin(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw const AuthException('Enter an API origin');
  }

  final candidate = _schemePattern.hasMatch(trimmed)
      ? trimmed
      : 'https://$trimmed';
  final Uri uri;
  try {
    uri = Uri.parse(candidate);
  } on FormatException {
    throw const AuthException('Enter a valid API origin');
  }

  if (!uri.hasScheme || uri.host.isEmpty) {
    throw const AuthException('Enter a valid API origin');
  }
  if (uri.userInfo.isNotEmpty) {
    throw const AuthException('API origin must not include credentials');
  }
  if ((uri.path.isNotEmpty && uri.path != '/') ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw const AuthException('API origin must be a host, not a path');
  }

  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  if (scheme != 'https' && !(scheme == 'http' && _localHosts.contains(host))) {
    throw const AuthException(
      'API origin must use HTTPS unless it is localhost',
    );
  }

  final wrappedHost = host.contains(':') && !host.startsWith('[')
      ? '[$host]'
      : host;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '$scheme://$wrappedHost$port';
}

String networkIdFromApiOrigin(String apiOrigin) {
  final normalized = normalizeBackendApiOrigin(apiOrigin);
  return 'origin:${Uri.encodeComponent(normalized)}';
}

String? apiOriginFromNetworkId(String networkId) {
  final trimmed = networkId.trim();
  if (trimmed == legacyOfficialNetworkId) {
    return officialApiOrigin;
  }
  const prefix = 'origin:';
  if (!trimmed.startsWith(prefix)) {
    return null;
  }
  try {
    return normalizeBackendApiOrigin(
      Uri.decodeComponent(trimmed.substring(prefix.length)),
    );
  } on AuthException {
    return null;
  }
}

bool isLegacyOfficialNetworkId(String networkId) {
  return networkId.trim() == legacyOfficialNetworkId;
}

final class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class AuthRefreshException extends AuthException {
  const AuthRefreshException(
    super.message, {
    required this.shouldClearCredentials,
  });

  final bool shouldClearCredentials;
}

final class AuthRefreshResult {
  const AuthRefreshResult({required this.accessToken, this.sessionToken});

  final String accessToken;
  final String? sessionToken;

  String sessionTokenOr(String fallback) {
    final rotated = sessionToken;
    return rotated == null || rotated.isEmpty ? fallback : rotated;
  }
}

enum NetworkSessionActivationStatus { opened, requiresAuth, unavailable, busy }

final class NetworkSessionActivationResult {
  const NetworkSessionActivationResult._(this.status, [this.message]);

  const NetworkSessionActivationResult.opened()
    : this._(NetworkSessionActivationStatus.opened);
  const NetworkSessionActivationResult.requiresAuth([String? message])
    : this._(NetworkSessionActivationStatus.requiresAuth, message);
  const NetworkSessionActivationResult.unavailable([String? message])
    : this._(NetworkSessionActivationStatus.unavailable, message);
  const NetworkSessionActivationResult.busy([String? message])
    : this._(NetworkSessionActivationStatus.busy, message);

  final NetworkSessionActivationStatus status;
  final String? message;

  bool get opened => status == NetworkSessionActivationStatus.opened;
}

final class VerdantUser {
  const VerdantUser({
    required this.id,
    required this.username,
    required this.email,
    required this.status,
    required this.usernameSet,
    required this.emailVerified,
    required this.totpEnabled,
    this.displayName,
    this.avatarUrl,
    this.bannerUrl,
    this.bannerBaseColor,
    this.memberListBannerUrl,
    this.bio,
  });

  factory VerdantUser.fromJson(Map<String, Object?> json) {
    final id = _stringValue(json['id'], fallback: 'unknown');
    return VerdantUser(
      id: id,
      username: _stringValue(json['username'], fallback: id),
      displayName: _nullableString(json['displayName']),
      email: _stringValue(json['email'], fallback: ''),
      avatarUrl: _nullableString(json['avatarUrl']),
      bannerUrl: _nullableString(json['bannerUrl']),
      bannerBaseColor: _nullableString(json['bannerBaseColor']),
      memberListBannerUrl: _nullableString(json['memberListBannerUrl']),
      bio: _nullableString(json['bio']),
      status: _stringValue(json['status'], fallback: 'offline'),
      usernameSet: _boolValue(json['usernameSet'], fallback: true),
      emailVerified: _boolValue(json['emailVerified'], fallback: true),
      totpEnabled: _boolValue(json['totpEnabled'], fallback: false),
    );
  }

  final String id;
  final String username;
  final String? displayName;
  final String email;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? bannerBaseColor;
  final String? memberListBannerUrl;
  final String? bio;
  final String status;
  final bool usernameSet;
  final bool emailVerified;
  final bool totpEnabled;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'username': username,
      if (displayName != null) 'displayName': displayName,
      'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (bannerUrl != null) 'bannerUrl': bannerUrl,
      if (bannerBaseColor != null) 'bannerBaseColor': bannerBaseColor,
      if (memberListBannerUrl != null)
        'memberListBannerUrl': memberListBannerUrl,
      if (bio != null) 'bio': bio,
      'status': status,
      'usernameSet': usernameSet,
      'emailVerified': emailVerified,
      'totpEnabled': totpEnabled,
    };
  }

  String get displayLabel =>
      displayName?.trim().isNotEmpty == true ? displayName! : username;

  VerdantUser copyWith({
    String? id,
    String? username,
    Object? displayName = _sentinel,
    String? email,
    Object? avatarUrl = _sentinel,
    Object? bannerUrl = _sentinel,
    Object? bannerBaseColor = _sentinel,
    Object? memberListBannerUrl = _sentinel,
    Object? bio = _sentinel,
    String? status,
    bool? usernameSet,
    bool? emailVerified,
    bool? totpEnabled,
  }) {
    return VerdantUser(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: identical(displayName, _sentinel)
          ? this.displayName
          : displayName as String?,
      email: email ?? this.email,
      avatarUrl: identical(avatarUrl, _sentinel)
          ? this.avatarUrl
          : avatarUrl as String?,
      bannerUrl: identical(bannerUrl, _sentinel)
          ? this.bannerUrl
          : bannerUrl as String?,
      bannerBaseColor: identical(bannerBaseColor, _sentinel)
          ? this.bannerBaseColor
          : bannerBaseColor as String?,
      memberListBannerUrl: identical(memberListBannerUrl, _sentinel)
          ? this.memberListBannerUrl
          : memberListBannerUrl as String?,
      bio: identical(bio, _sentinel) ? this.bio : bio as String?,
      status: status ?? this.status,
      usernameSet: usernameSet ?? this.usernameSet,
      emailVerified: emailVerified ?? this.emailVerified,
      totpEnabled: totpEnabled ?? this.totpEnabled,
    );
  }

  String get initials {
    final source = displayLabel.trim().isNotEmpty ? displayLabel : username;
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final compact = source.replaceAll(RegExp(r'\s+'), '');
    if (compact.length >= 2) {
      return compact.substring(0, 2).toUpperCase();
    }
    return compact.toUpperCase();
  }
}

const Object _sentinel = Object();

final class AuthCredentialBundle {
  const AuthCredentialBundle({
    required this.apiOrigin,
    required this.accessToken,
    required this.sessionToken,
    this.user,
    this.kind = AuthCredentialKind.userSession,
    this.expiresAt,
  });

  factory AuthCredentialBundle.fromJson(Map<String, Object?> json) {
    final apiOrigin = json['apiOrigin'];
    final accessToken = json['accessToken'];
    final sessionToken = json['sessionToken'];
    final kind = AuthCredentialKind.fromJson(
      json['credentialKind'] ?? json['tokenType'] ?? json['kind'],
    );
    final expiresAt = _optionalCredentialExpiry(json['expiresAt']);
    if (apiOrigin is! String || apiOrigin.isEmpty) {
      throw const AuthException('Stored credentials were missing API origin');
    }
    if (accessToken is! String || accessToken.isEmpty) {
      throw const AuthException('Stored credentials were missing access token');
    }
    if (kind == AuthCredentialKind.userSession &&
        (sessionToken is! String || sessionToken.isEmpty)) {
      throw const AuthException(
        'Stored credentials were missing session token',
      );
    }
    final rawUser = json['user'];
    final user = rawUser is Map<String, Object?>
        ? VerdantUser.fromJson(rawUser)
        : rawUser is Map
        ? VerdantUser.fromJson(Map<String, Object?>.from(rawUser))
        : null;
    return AuthCredentialBundle(
      apiOrigin: apiOrigin,
      accessToken: accessToken,
      sessionToken: sessionToken is String ? sessionToken : '',
      user: user,
      kind: kind,
      expiresAt: expiresAt,
    );
  }

  final String apiOrigin;
  final String accessToken;
  final String sessionToken;
  final VerdantUser? user;
  final AuthCredentialKind kind;
  final DateTime? expiresAt;

  String get normalizedApiOrigin => normalizeBackendApiOrigin(apiOrigin);
  String get networkId => networkIdFromApiOrigin(normalizedApiOrigin);

  bool get hasAccessToken => accessToken.isNotEmpty;
  bool get hasSessionToken => sessionToken.isNotEmpty;
  bool get isFederatedClient => kind == AuthCredentialKind.federatedClient;

  bool expiresWithin(Duration skew, {DateTime? now}) {
    final expiry = expiresAt;
    if (expiry == null) {
      return false;
    }
    final reference = (now ?? DateTime.now()).toUtc().add(skew);
    return !expiry.toUtc().isAfter(reference);
  }

  Map<String, Object?> toJson() {
    return {
      'apiOrigin': normalizedApiOrigin,
      'networkId': networkId,
      'credentialKind': kind.wireName,
      'accessToken': accessToken,
      'sessionToken': sessionToken,
      if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  AuthCredentialBundle withUser(VerdantUser user) {
    return AuthCredentialBundle(
      apiOrigin: normalizedApiOrigin,
      accessToken: accessToken,
      sessionToken: sessionToken,
      user: user,
      kind: kind,
      expiresAt: expiresAt,
    );
  }

  @override
  String toString() {
    return 'AuthCredentialBundle(apiOrigin: $normalizedApiOrigin, '
        'networkId: $networkId, accessToken: redacted, '
        'sessionToken: redacted, kind: ${kind.wireName})';
  }
}

DateTime? _optionalCredentialExpiry(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! String || value.trim().isEmpty) {
    throw const AuthException('Stored credentials had invalid expiry');
  }
  final parsed = DateTime.tryParse(value.trim());
  if (parsed == null) {
    throw const AuthException('Stored credentials had invalid expiry');
  }
  return parsed.toUtc();
}

enum AuthCredentialKind {
  userSession('user_session'),
  federatedClient('federated_client');

  const AuthCredentialKind(this.wireName);

  final String wireName;

  static AuthCredentialKind fromJson(Object? value) {
    if (value == federatedClient.wireName) {
      return federatedClient;
    }
    return userSession;
  }
}

final class AuthSession {
  AuthSession._({
    required this.apiOrigin,
    required this.networkId,
    required this.user,
    required this.hasAccessToken,
    required this.hasSessionToken,
    required this.credentialKind,
  });

  factory AuthSession.authenticated({
    required String apiOrigin,
    required VerdantUser user,
    bool hasAccessToken = true,
    bool hasSessionToken = true,
    AuthCredentialKind credentialKind = AuthCredentialKind.userSession,
  }) {
    final normalized = normalizeBackendApiOrigin(apiOrigin);
    return AuthSession._(
      apiOrigin: normalized,
      networkId: networkIdFromApiOrigin(normalized),
      user: user,
      hasAccessToken: hasAccessToken,
      hasSessionToken: hasSessionToken,
      credentialKind: credentialKind,
    );
  }

  factory AuthSession.inMemory({
    required String apiOrigin,
    required String accessToken,
    required String sessionToken,
    required VerdantUser user,
  }) {
    return AuthSession.authenticated(
      apiOrigin: apiOrigin,
      user: user,
      hasAccessToken: accessToken.isNotEmpty,
      hasSessionToken: sessionToken.isNotEmpty,
    );
  }

  final String apiOrigin;
  final String networkId;
  final VerdantUser user;
  final bool hasAccessToken;
  final bool hasSessionToken;
  final AuthCredentialKind credentialKind;

  AuthSession withCredentialKind(AuthCredentialKind kind) {
    return AuthSession._(
      apiOrigin: apiOrigin,
      networkId: networkId,
      user: user,
      hasAccessToken: hasAccessToken,
      hasSessionToken: hasSessionToken,
      credentialKind: kind,
    );
  }

  @override
  String toString() {
    return 'AuthSession(apiOrigin: $apiOrigin, networkId: $networkId, '
        'userId: ${user.id}, accessToken: redacted, sessionToken: redacted, '
        'credentialKind: ${credentialKind.wireName})';
  }
}

sealed class AuthLoginOutcome {
  const AuthLoginOutcome();
}

final class AuthLoginSuccess extends AuthLoginOutcome {
  const AuthLoginSuccess({
    required this.session,
    required this.credentials,
    this.accountRestored = false,
  });

  final AuthSession session;
  final AuthCredentialBundle credentials;
  final bool accountRestored;
}

final class AuthLoginRequiresTwoFactor extends AuthLoginOutcome {
  const AuthLoginRequiresTwoFactor({required this.ticket});

  final String ticket;
}

final class AuthLoginRequiresVerification extends AuthLoginOutcome {
  const AuthLoginRequiresVerification({required this.sessionToken});

  final String sessionToken;
}

String _stringValue(Object? value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

String? _nullableString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : value;
}

bool _boolValue(Object? value, {required bool fallback}) {
  return value is bool ? value : fallback;
}
