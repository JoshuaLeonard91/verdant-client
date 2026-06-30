import '../auth/auth_models.dart';

final _encodedUnsafeLocalIdPattern = RegExp(
  r'%(?:0[0-9a-fA-F]|1[0-9a-fA-F]|2[fF]|5[cC]|7[fF])',
);

String safeWorkspaceLocalId(String value, {bool allowScopedPrefix = false}) {
  final raw = value.trim();
  final local = allowScopedPrefix ? _stripScopedPrefix(raw) : raw;
  if (local.isEmpty ||
      local.contains('/') ||
      local.contains('\\') ||
      local.contains(RegExp(r'\s')) ||
      _containsControlCharacter(local) ||
      _encodedUnsafeLocalIdPattern.hasMatch(local)) {
    throw const FormatException('Invalid workspace local id');
  }
  return local;
}

String _stripScopedPrefix(String value) {
  final slash = value.indexOf('/');
  if (slash < 0) {
    return value;
  }
  if (slash == 0 ||
      slash == value.length - 1 ||
      value.indexOf('/', slash + 1) >= 0) {
    throw const FormatException('Invalid workspace local id');
  }
  return value.substring(slash + 1).trim();
}

bool sameWorkspaceNetworkId(String left, String right) {
  final normalizedLeft = _normalizedNetworkOrigin(left);
  final normalizedRight = _normalizedNetworkOrigin(right);
  if (normalizedLeft != null && normalizedRight != null) {
    return normalizedLeft == normalizedRight;
  }
  return left.trim() == right.trim();
}

bool sameScopedWorkspaceId(String left, String right) {
  final leftParts = _splitScopedWorkspaceId(left);
  final rightParts = _splitScopedWorkspaceId(right);
  if (leftParts == null || rightParts == null) {
    return left.trim() == right.trim();
  }
  return sameWorkspaceNetworkId(leftParts.networkId, rightParts.networkId) &&
      leftParts.localId == rightParts.localId;
}

({String networkId, String localId})? _splitScopedWorkspaceId(String value) {
  final trimmed = value.trim();
  final slash = trimmed.indexOf('/');
  if (slash <= 0 ||
      slash == trimmed.length - 1 ||
      trimmed.indexOf('/', slash + 1) >= 0) {
    return null;
  }
  try {
    return (
      networkId: trimmed.substring(0, slash),
      localId: safeWorkspaceLocalId(trimmed.substring(slash + 1)),
    );
  } on FormatException {
    return null;
  }
}

String? _normalizedNetworkOrigin(String networkId) {
  return apiOriginFromNetworkId(networkId.trim());
}

bool _containsControlCharacter(String value) {
  for (final unit in value.codeUnits) {
    if (unit < 0x20 || unit == 0x7f) {
      return true;
    }
  }
  return false;
}
