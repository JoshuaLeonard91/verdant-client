part of 'workspace_controller.dart';

final class _ServerPresenceProjection {
  const _ServerPresenceProjection({
    required this.settings,
    required this.activeChannelMembers,
    required this.activeTypingMembers,
  });

  final ServerSettingsData? settings;
  final List<MemberSeed> activeChannelMembers;
  final List<MemberSeed> activeTypingMembers;
}

String _normalizeRealtimePresenceStatus(String rawStatus) {
  final normalized = rawStatus.toLowerCase();
  if (normalized.contains('online')) {
    return 'Online';
  }
  if (normalized.contains('idle')) {
    return 'Idle';
  }
  if (normalized.contains('dnd') || normalized.contains('busy')) {
    return 'Busy';
  }
  return 'Offline';
}

String _effectiveCurrentUserPresenceStatus(
  String? profileStatus,
  String sessionStatus, {
  String? preferredStatus,
}) {
  final preferredPresence = _canonicalRealtimePresenceStatus(preferredStatus);
  if (preferredPresence != null) {
    return preferredPresence;
  }
  final sessionPresence = _canonicalRealtimePresenceStatus(sessionStatus);
  final profilePresence = _canonicalRealtimePresenceStatus(profileStatus);
  if (profilePresence == null) {
    return sessionPresence == 'offline'
        ? 'online'
        : sessionPresence ?? 'online';
  }
  if (profilePresence == 'offline') {
    return sessionPresence == 'offline'
        ? 'online'
        : sessionPresence ?? 'online';
  }
  return profilePresence;
}

String? _canonicalRealtimePresenceStatus(String? rawStatus) {
  final normalized = rawStatus?.toLowerCase().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized.contains('online')) {
    return 'online';
  }
  if (normalized.contains('idle')) {
    return 'idle';
  }
  if (normalized.contains('dnd') || normalized.contains('busy')) {
    return 'dnd';
  }
  if (normalized.contains('offline')) {
    return 'offline';
  }
  return null;
}

bool _statusLooksOffline(String status) {
  return status.toLowerCase().contains('offline');
}

bool _containsControlCharacter(String value) {
  for (final unit in value.codeUnits) {
    if (unit < 0x20 || unit == 0x7f) {
      return true;
    }
  }
  return false;
}

String _roleLabelForIds(
  List<String> roleIds,
  List<ServerSettingsListItemSeed> roles, {
  required String fallback,
}) {
  final names = _rolesForIds(roleIds, roles)
      .where((role) => !role.colorOnly)
      .where((role) => role.title.trim().isNotEmpty)
      .map((role) => role.title.trim())
      .toList(growable: false);
  if (names.isNotEmpty) {
    return names.join(', ');
  }
  final trimmedFallback = fallback.trim();
  return trimmedFallback.isEmpty ? 'Member' : trimmedFallback;
}

Color? _roleAccentForIds(
  List<String> roleIds,
  List<ServerSettingsListItemSeed> roles,
) {
  final nameColor = _nameColorRoleForIds(roleIds, roles);
  if (nameColor?.accent != null) {
    return nameColor!.accent;
  }
  for (final role in _rolesForIds(roleIds, roles)) {
    if (!role.colorOnly && role.accent != null) {
      return role.accent;
    }
  }
  return null;
}

ServerSettingsListItemSeed? _nameColorRoleForIds(
  List<String> roleIds,
  List<ServerSettingsListItemSeed> roles,
) {
  final colorRoles = _rolesForIds(roleIds, roles)
      .where((role) => role.colorOnly && role.accent != null)
      .toList(growable: false);
  if (colorRoles.isEmpty) {
    return null;
  }
  colorRoles.sort((left, right) {
    final priority = (right.colorPriority ?? 0).compareTo(
      left.colorPriority ?? 0,
    );
    if (priority != 0) {
      return priority;
    }
    return left.title.compareTo(right.title);
  });
  return colorRoles.first;
}

Color? _profileHexColor(String? value) {
  if (value == null || !value.startsWith('#') || value.length != 7) {
    return null;
  }
  final parsed = int.tryParse(value.substring(1), radix: 16);
  return parsed == null ? null : Color(0xFF000000 | parsed);
}

String? _colorHex(Color? value) {
  if (value == null) {
    return null;
  }
  final rgb = value.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

List<ServerSettingsListItemSeed> _rolesForIds(
  List<String> roleIds,
  List<ServerSettingsListItemSeed> roles,
) {
  if (roleIds.isEmpty || roles.isEmpty) {
    return const [];
  }
  final rolesById = <String, ServerSettingsListItemSeed>{};
  for (final role in roles) {
    final id = role.id;
    if (id != null && id.trim().isNotEmpty) {
      rolesById[_localRoleId(id)] = role;
    }
  }
  return [for (final roleId in roleIds) ?rolesById[_localRoleId(roleId)]];
}

String _localRoleId(String value) {
  final slash = value.indexOf('/');
  if (slash >= 0 && slash < value.length - 1) {
    return value.substring(slash + 1);
  }
  return value;
}
