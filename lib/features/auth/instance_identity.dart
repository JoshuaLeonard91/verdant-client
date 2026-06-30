import 'dart:async';
import 'dart:convert';

import 'auth_models.dart';
import 'network_profile_store.dart';

enum InstanceTrustStatus {
  official,
  verified,
  trustedByUser,
  unverified,
  warning,
}

enum InstanceTrustSource {
  pinnedOfficial,
  officialRegistry,
  manualTrust,
  selfReported,
}

enum InstanceIdentityWarning {
  apiOriginMismatch,
  publicKeyFingerprintChanged,
  fakeOfficialClaim,
  idnDomain,
  lookalikeDomain,
  manifestUnavailable,
}

final class InstanceManifestIdentity {
  const InstanceManifestIdentity({
    required this.instanceId,
    required this.registryTrust,
    required this.name,
    required this.domain,
    required this.mode,
    required this.apiUrl,
    this.publicKeyFingerprint,
  });

  factory InstanceManifestIdentity.fromJson(Map<String, Object?> json) {
    final instanceId = _requiredString(json['instanceId']);
    final registryTrust = _stringValue(json['registryTrust']);
    final name = _stringValue(json['name']);
    final domain = _stringValue(json['domain']);
    final mode = _stringValue(json['mode']).toLowerCase();
    final apiUrl = _requiredString(json['apiUrl']);
    final publicKeyFingerprint = _nullableString(json['publicKeyFingerprint']);

    return InstanceManifestIdentity(
      instanceId: instanceId,
      registryTrust: registryTrust,
      name: name,
      domain: domain,
      mode: mode,
      apiUrl: apiUrl,
      publicKeyFingerprint: publicKeyFingerprint,
    );
  }

  final String instanceId;
  final String registryTrust;
  final String name;
  final String domain;
  final String mode;
  final String apiUrl;
  final String? publicKeyFingerprint;
}

final class NetworkOriginSafety {
  const NetworkOriginSafety({
    required this.apiOrigin,
    required this.displayHost,
    required this.warnings,
  });

  final String apiOrigin;
  final String displayHost;
  final Set<InstanceIdentityWarning> warnings;
}

final class InstanceIdentity {
  const InstanceIdentity({
    required this.apiOrigin,
    required this.networkId,
    required this.instanceId,
    required this.instanceMode,
    required this.publicKeyFingerprint,
    required this.trustStatus,
    required this.trustSource,
    required this.warnings,
    required this.firstSeenAtMs,
    required this.lastSeenAtMs,
    this.verifiedAtMs,
  });

  factory InstanceIdentity.fromJson(Map<String, Object?> json) {
    final apiOrigin = _requiredString(json['apiOrigin']);
    final normalized = normalizeBackendApiOrigin(apiOrigin);
    final warnings = <InstanceIdentityWarning>{};
    for (final value in _listValue(json['warnings'])) {
      if (value is! String) {
        continue;
      }
      final warning = _warningFromWire(value);
      if (warning != null) {
        warnings.add(warning);
      }
    }

    return InstanceIdentity(
      apiOrigin: normalized,
      networkId: networkIdFromApiOrigin(normalized),
      instanceId: _requiredString(json['instanceId']),
      instanceMode: _normalizeInstanceMode(_stringValue(json['instanceMode'])),
      publicKeyFingerprint: _nullableString(json['publicKeyFingerprint']),
      trustStatus:
          _trustStatusFromWire(_stringValue(json['trustStatus'])) ??
          InstanceTrustStatus.unverified,
      trustSource:
          _trustSourceFromWire(_stringValue(json['trustSource'])) ??
          InstanceTrustSource.selfReported,
      warnings: warnings,
      firstSeenAtMs: _intValue(json['firstSeenAtMs']),
      lastSeenAtMs: _intValue(json['lastSeenAtMs']),
      verifiedAtMs: _nullableInt(json['verifiedAtMs']),
    );
  }

  final String apiOrigin;
  final String networkId;
  final String instanceId;
  final String instanceMode;
  final String? publicKeyFingerprint;
  final InstanceTrustStatus trustStatus;
  final InstanceTrustSource trustSource;
  final Set<InstanceIdentityWarning> warnings;
  final int firstSeenAtMs;
  final int lastSeenAtMs;
  final int? verifiedAtMs;

  Map<String, Object?> toJson() {
    return {
      'apiOrigin': apiOrigin,
      'networkId': networkId,
      'instanceId': instanceId,
      'instanceMode': instanceMode,
      if (publicKeyFingerprint != null)
        'publicKeyFingerprint': publicKeyFingerprint,
      'trustStatus': trustStatus.name,
      'trustSource': trustSource.name,
      if (warnings.isNotEmpty)
        'warnings': [for (final warning in warnings) warning.name],
      'firstSeenAtMs': firstSeenAtMs,
      'lastSeenAtMs': lastSeenAtMs,
      if (verifiedAtMs != null) 'verifiedAtMs': verifiedAtMs,
    };
  }
}

abstract interface class InstanceIdentityManifestService {
  Future<InstanceManifestIdentity?> fetchManifest({required String apiOrigin});
}

final class NoopInstanceIdentityManifestService
    implements InstanceIdentityManifestService {
  const NoopInstanceIdentityManifestService();

  @override
  Future<InstanceManifestIdentity?> fetchManifest({
    required String apiOrigin,
  }) async {
    return null;
  }
}

final class InstanceIdentityStore {
  InstanceIdentityStore({
    NetworkProfileStorage? storage,
    String storageNamespace = '',
    int Function()? clock,
  }) : _storage = storage ?? SharedPreferencesNetworkProfileStorage(),
       _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
       _storageKey = storageNamespace.trim().isEmpty
           ? _baseStorageKey
           : '$_baseStorageKey.profile.${storageNamespace.trim()}';

  static const _baseStorageKey = 'verdant.flutter.instanceIdentities.v1';

  final NetworkProfileStorage _storage;
  final int Function() _clock;
  final String _storageKey;

  Future<List<InstanceIdentity>> load() async {
    final raw = await _storage.readString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List<Object?>) {
      return const [];
    }

    final identities = <InstanceIdentity>[];
    for (final item in decoded) {
      if (item is! Map<String, Object?>) {
        continue;
      }
      try {
        identities.add(InstanceIdentity.fromJson(item));
      } on AuthException {
        continue;
      }
    }
    return identities;
  }

  Future<InstanceIdentity?> read(String apiOrigin) async {
    final normalized = normalizeBackendApiOrigin(apiOrigin);
    for (final identity in await load()) {
      if (identity.apiOrigin == normalized) {
        return identity;
      }
    }
    return null;
  }

  Future<InstanceIdentity> recordSelfReportedManifest({
    required String connectedApiOrigin,
    required InstanceManifestIdentity manifest,
  }) async {
    final normalizedOrigin = normalizeBackendApiOrigin(connectedApiOrigin);
    final previous = await read(normalizedOrigin);
    final now = _clock();
    final firstSeenAtMs = previous?.firstSeenAtMs ?? now;
    final safety = assessNetworkOriginSafety(normalizedOrigin);
    final warnings = <InstanceIdentityWarning>{...safety.warnings};

    final manifestApiOrigin = _tryNormalizeOrigin(manifest.apiUrl);
    if (manifestApiOrigin == null || manifestApiOrigin != normalizedOrigin) {
      warnings.add(InstanceIdentityWarning.apiOriginMismatch);
    }
    if (previous?.publicKeyFingerprint != null &&
        manifest.publicKeyFingerprint != null &&
        previous!.publicKeyFingerprint != manifest.publicKeyFingerprint) {
      warnings.add(InstanceIdentityWarning.publicKeyFingerprintChanged);
    }
    if (_claimsOfficialIdentity(
      manifest,
      connectedApiOrigin: normalizedOrigin,
    )) {
      warnings.add(InstanceIdentityWarning.fakeOfficialClaim);
    }

    final isOfficialOrigin = normalizedOrigin == officialApiOrigin;
    final trustSource = isOfficialOrigin
        ? InstanceTrustSource.pinnedOfficial
        : InstanceTrustSource.selfReported;
    final trustStatus = warnings.isNotEmpty
        ? InstanceTrustStatus.warning
        : isOfficialOrigin
        ? InstanceTrustStatus.official
        : InstanceTrustStatus.unverified;

    final identity = InstanceIdentity(
      apiOrigin: normalizedOrigin,
      networkId: networkIdFromApiOrigin(normalizedOrigin),
      instanceId: manifest.instanceId,
      instanceMode: _normalizeInstanceMode(manifest.mode),
      publicKeyFingerprint: manifest.publicKeyFingerprint,
      trustStatus: trustStatus,
      trustSource: trustSource,
      warnings: warnings,
      firstSeenAtMs: firstSeenAtMs,
      lastSeenAtMs: now,
    );
    await _upsert(identity);
    return identity;
  }

  Future<InstanceIdentity> recordManifestUnavailable({
    required String connectedApiOrigin,
  }) async {
    final normalizedOrigin = normalizeBackendApiOrigin(connectedApiOrigin);
    final previous = await read(normalizedOrigin);
    final now = _clock();
    final safety = assessNetworkOriginSafety(normalizedOrigin);
    final warnings = <InstanceIdentityWarning>{
      ...safety.warnings,
      InstanceIdentityWarning.manifestUnavailable,
    };
    final identity = InstanceIdentity(
      apiOrigin: normalizedOrigin,
      networkId: networkIdFromApiOrigin(normalizedOrigin),
      instanceId:
          previous?.instanceId ?? networkIdFromApiOrigin(normalizedOrigin),
      instanceMode: previous?.instanceMode ?? 'unknown',
      publicKeyFingerprint: previous?.publicKeyFingerprint,
      trustStatus: InstanceTrustStatus.warning,
      trustSource: previous?.trustSource ?? InstanceTrustSource.selfReported,
      warnings: warnings,
      firstSeenAtMs: previous?.firstSeenAtMs ?? now,
      lastSeenAtMs: now,
      verifiedAtMs: previous?.verifiedAtMs,
    );
    await _upsert(identity);
    return identity;
  }

  Future<void> _upsert(InstanceIdentity identity) async {
    final existing = await load();
    final next = [
      for (final item in existing)
        if (item.apiOrigin != identity.apiOrigin) item,
      identity,
    ];
    await _storage.writeString(
      _storageKey,
      jsonEncode([for (final item in next) item.toJson()]),
    );
  }
}

NetworkOriginSafety assessNetworkOriginSafety(String apiOrigin) {
  final normalized = normalizeBackendApiOrigin(apiOrigin);
  final host = Uri.parse(normalized).host.toLowerCase();
  final rawHasNonAscii = apiOrigin.codeUnits.any((unit) => unit > 0x7f);
  final hostLooksPunycode =
      host == 'xn--' || host.startsWith('xn--') || host.contains('.xn--');
  final warnings = <InstanceIdentityWarning>{};

  if (rawHasNonAscii || hostLooksPunycode) {
    warnings.add(InstanceIdentityWarning.idnDomain);
  }
  if (host != Uri.parse(officialApiOrigin).host &&
      (host.contains('verdant') || host.contains('api.verdant.chat'))) {
    warnings.add(InstanceIdentityWarning.lookalikeDomain);
  }

  return NetworkOriginSafety(
    apiOrigin: normalized,
    displayHost: host,
    warnings: warnings,
  );
}

String? _tryNormalizeOrigin(String value) {
  try {
    return normalizeBackendApiOrigin(value);
  } on AuthException {
    return null;
  }
}

bool _claimsOfficialIdentity(
  InstanceManifestIdentity manifest, {
  required String connectedApiOrigin,
}) {
  if (connectedApiOrigin == officialApiOrigin) {
    return false;
  }
  final manifestApiOrigin = _tryNormalizeOrigin(manifest.apiUrl);
  final lowerName = manifest.name.toLowerCase();
  final lowerDomain = manifest.domain.toLowerCase();

  return manifest.mode == 'official' ||
      manifestApiOrigin == officialApiOrigin ||
      lowerDomain == Uri.parse(officialApiOrigin).host ||
      lowerName.contains('official') ||
      lowerName.contains('verdant');
}

String _normalizeInstanceMode(String mode) {
  final normalized = mode.trim().toLowerCase();
  return switch (normalized) {
    'official' || 'standalone' || 'linked' || 'federated' => normalized,
    _ => 'unknown',
  };
}

String _requiredString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  throw const AuthException('Instance identity metadata was invalid');
}

String _stringValue(Object? value) {
  return value is String ? value.trim() : '';
}

String? _nullableString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int _intValue(Object? value) {
  final parsed = _nullableInt(value);
  if (parsed == null) {
    throw const AuthException('Instance identity metadata was invalid');
  }
  return parsed;
}

int? _nullableInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

List<Object?> _listValue(Object? value) {
  return value is List ? value.cast<Object?>() : const [];
}

InstanceIdentityWarning? _warningFromWire(String value) {
  for (final warning in InstanceIdentityWarning.values) {
    if (warning.name == value) {
      return warning;
    }
  }
  return null;
}

InstanceTrustStatus? _trustStatusFromWire(String value) {
  for (final status in InstanceTrustStatus.values) {
    if (status.name == value) {
      return status;
    }
  }
  return null;
}

InstanceTrustSource? _trustSourceFromWire(String value) {
  for (final source in InstanceTrustSource.values) {
    if (source.name == value) {
      return source;
    }
  }
  return null;
}
