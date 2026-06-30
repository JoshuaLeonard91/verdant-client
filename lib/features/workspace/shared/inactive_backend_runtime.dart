enum BackendRuntimeLifecycleState { active, warm, cold, unavailable, signedOut }

final class JoinedBackendRuntimeProfile {
  const JoinedBackendRuntimeProfile({
    required this.networkId,
    required this.apiOrigin,
    required this.authenticated,
    required this.available,
  });

  final String networkId;
  final String apiOrigin;
  final bool authenticated;
  final bool available;
}

final class SyncServerSummary {
  const SyncServerSummary({
    required this.serverId,
    required this.unreadCount,
    required this.mentionCount,
    required this.lastActivityAt,
  });

  factory SyncServerSummary.fromJson(Map<String, Object?> json) {
    return SyncServerSummary(
      serverId: _stringValue(json['serverId']),
      unreadCount: _intValue(json['unreadCount']),
      mentionCount: _intValue(json['mentionCount']),
      lastActivityAt: _nullableString(json['lastActivityAt']),
    );
  }

  final String serverId;
  final int unreadCount;
  final int mentionCount;
  final String? lastActivityAt;
}

final class SyncDmSummary {
  const SyncDmSummary({
    required this.channelId,
    required this.unreadCount,
    required this.mentionCount,
    required this.lastActivityAt,
  });

  factory SyncDmSummary.fromJson(Map<String, Object?> json) {
    return SyncDmSummary(
      channelId: _stringValue(json['channelId']),
      unreadCount: _intValue(json['unreadCount']),
      mentionCount: _intValue(json['mentionCount']),
      lastActivityAt: _nullableString(json['lastActivityAt']),
    );
  }

  final String channelId;
  final int unreadCount;
  final int mentionCount;
  final String? lastActivityAt;
}

final class SyncNotificationSummary {
  const SyncNotificationSummary({required this.kind, required this.count});

  factory SyncNotificationSummary.fromJson(Map<String, Object?> json) {
    return SyncNotificationSummary(
      kind: _stringValue(json['kind']),
      count: _intValue(json['count']),
    );
  }

  final String kind;
  final int count;
}

final class SyncSummarySnapshot {
  const SyncSummarySnapshot({
    required this.cursor,
    required this.servers,
    required this.dms,
    required this.notifications,
    required this.requiresReconnect,
  });

  factory SyncSummarySnapshot.fromJson(Map<String, Object?> json) {
    return SyncSummarySnapshot(
      cursor: _stringValue(json['cursor']),
      servers: _listOfMaps(
        json['servers'],
      ).map(SyncServerSummary.fromJson).toList(growable: false),
      dms: _listOfMaps(
        json['dms'],
      ).map(SyncDmSummary.fromJson).toList(growable: false),
      notifications: _listOfMaps(
        json['notifications'],
      ).map(SyncNotificationSummary.fromJson).toList(growable: false),
      requiresReconnect: json['requiresReconnect'] == true,
    );
  }

  final String cursor;
  final List<SyncServerSummary> servers;
  final List<SyncDmSummary> dms;
  final List<SyncNotificationSummary> notifications;
  final bool requiresReconnect;
}

abstract interface class InactiveBackendRuntimeDelegate {
  Future<void> connect(JoinedBackendRuntimeProfile profile);

  Future<void> disconnect(JoinedBackendRuntimeProfile profile);

  Future<SyncSummarySnapshot> fetchSummary(
    JoinedBackendRuntimeProfile profile, {
    String? since,
  });
}

abstract interface class SyncSummaryClient {
  Future<SyncSummarySnapshot> fetchSummary(
    JoinedBackendRuntimeProfile profile, {
    String? since,
  });
}

final class SyncSummaryClientException implements Exception {
  const SyncSummaryClientException(this.message, {this.isAuthExpired = false});

  final String message;
  final bool isAuthExpired;

  @override
  String toString() {
    return 'SyncSummaryClientException(message: $message, '
        'isAuthExpired: $isAuthExpired)';
  }
}

final class InactiveBackendRuntimeManager {
  InactiveBackendRuntimeManager({
    required this.delegate,
    required this.idleTimeout,
    required this.coldTimeout,
    required this.warmPollInterval,
    required this.coldPollInterval,
  });

  final InactiveBackendRuntimeDelegate delegate;
  final Duration idleTimeout;
  final Duration coldTimeout;
  final Duration warmPollInterval;
  final Duration coldPollInterval;
  final _entries = <String, _RuntimeEntry>{};
  String? _activeNetworkId;

  void register(JoinedBackendRuntimeProfile profile, {required DateTime now}) {
    final state = _stateForProfile(profile);
    _entries[profile.networkId] = _RuntimeEntry(
      profile: profile,
      state: state,
      lastActiveAt: now,
      nextPollAt: state == BackendRuntimeLifecycleState.warm ? now : null,
    );
  }

  BackendRuntimeLifecycleState? stateOf(String networkId) {
    return _entries[networkId]?.state;
  }

  SyncSummarySnapshot? summaryOf(String networkId) {
    return _entries[networkId]?.summary;
  }

  Future<void> setActiveNetwork(
    String? networkId, {
    required DateTime now,
  }) async {
    final previousActive = _activeNetworkId;
    if (previousActive != null && previousActive != networkId) {
      final previous = _entries[previousActive];
      if (previous != null) {
        previous.lastActiveAt = now;
      }
    }
    _activeNetworkId = networkId;
    if (networkId == null) {
      return;
    }
    final entry = _entries[networkId];
    if (entry == null || !_canRunLive(entry.profile)) {
      return;
    }
    if (entry.state != BackendRuntimeLifecycleState.active) {
      await delegate.connect(entry.profile);
    }
    entry
      ..state = BackendRuntimeLifecycleState.active
      ..lastActiveAt = now
      ..nextPollAt = null;
  }

  Future<void> advance(DateTime now) async {
    for (final networkId in List<String>.of(_entries.keys)) {
      final entry = _entries[networkId];
      if (entry == null) {
        continue;
      }
      final profileState = _stateForProfile(entry.profile);
      if (profileState == BackendRuntimeLifecycleState.signedOut ||
          profileState == BackendRuntimeLifecycleState.unavailable) {
        if (entry.state == BackendRuntimeLifecycleState.active) {
          await delegate.disconnect(entry.profile);
        }
        entry
          ..state = profileState
          ..nextPollAt = null;
        continue;
      }
      if (networkId == _activeNetworkId) {
        continue;
      }

      final lastActiveAt = entry.lastActiveAt;
      if (entry.state == BackendRuntimeLifecycleState.active &&
          lastActiveAt != null &&
          !now.difference(lastActiveAt).isNegative &&
          now.difference(lastActiveAt) >= idleTimeout) {
        await delegate.disconnect(entry.profile);
        entry
          ..state = BackendRuntimeLifecycleState.warm
          ..nextPollAt = now;
      }

      if (entry.state == BackendRuntimeLifecycleState.warm &&
          lastActiveAt != null &&
          !now.difference(lastActiveAt).isNegative &&
          now.difference(lastActiveAt) >= coldTimeout) {
        entry.state = BackendRuntimeLifecycleState.cold;
      }

      if (entry.state == BackendRuntimeLifecycleState.warm ||
          entry.state == BackendRuntimeLifecycleState.cold) {
        await _pollIfDue(entry, now);
      }
    }
  }

  Future<void> _pollIfDue(_RuntimeEntry entry, DateTime now) async {
    final nextPollAt = entry.nextPollAt;
    if (nextPollAt != null && now.isBefore(nextPollAt)) {
      return;
    }
    final snapshot = await delegate.fetchSummary(
      entry.profile,
      since: entry.cursor,
    );
    entry
      ..summary = snapshot
      ..cursor = snapshot.cursor
      ..nextPollAt = now.add(
        entry.state == BackendRuntimeLifecycleState.cold
            ? coldPollInterval
            : warmPollInterval,
      );
  }

  static BackendRuntimeLifecycleState _stateForProfile(
    JoinedBackendRuntimeProfile profile,
  ) {
    if (!profile.authenticated) {
      return BackendRuntimeLifecycleState.signedOut;
    }
    if (!profile.available) {
      return BackendRuntimeLifecycleState.unavailable;
    }
    return BackendRuntimeLifecycleState.warm;
  }

  static bool _canRunLive(JoinedBackendRuntimeProfile profile) {
    return profile.authenticated && profile.available;
  }
}

final class _RuntimeEntry {
  _RuntimeEntry({
    required this.profile,
    required this.state,
    required this.lastActiveAt,
    required this.nextPollAt,
  });

  final JoinedBackendRuntimeProfile profile;
  BackendRuntimeLifecycleState state;
  DateTime? lastActiveAt;
  DateTime? nextPollAt;
  String? cursor;
  SyncSummarySnapshot? summary;
}

String _stringValue(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  if (value is num) {
    return value.toString();
  }
  throw const FormatException('Invalid sync summary payload');
}

String? _nullableString(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

int _intValue(Object? value) {
  if (value is int && value >= 0) {
    return value;
  }
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 0) {
      return parsed;
    }
  }
  throw const FormatException('Invalid sync summary payload');
}

List<Map<String, Object?>> _listOfMaps(Object? value) {
  if (value == null) {
    return const [];
  }
  if (value is! List) {
    throw const FormatException('Invalid sync summary payload');
  }
  return [
    for (final item in value)
      if (item is Map<String, Object?>)
        item
      else if (item is Map)
        Map<String, Object?>.from(item)
      else
        throw const FormatException('Invalid sync summary payload'),
  ];
}
