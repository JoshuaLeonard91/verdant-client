import 'package:flutter/foundation.dart';

abstract interface class UserSettingsSessionsRepository {
  Future<List<UserSettingsSession>> listSessions();

  Future<void> revokeSession({required String sessionId});

  Future<void> revokeAllOtherSessions();
}

final class UserSettingsSession {
  const UserSettingsSession({
    required this.id,
    required this.isCurrent,
    required this.device,
    required this.createdAt,
    required this.lastRefreshAt,
    this.city,
    this.country,
    this.lastCity,
    this.lastCountry,
  });

  factory UserSettingsSession.fromJson(Map<String, Object?> json) {
    final id = _stringValue(json['id']);
    if (id.isEmpty) {
      throw const FormatException('Session id is required');
    }
    return UserSettingsSession(
      id: id,
      isCurrent: json['isCurrent'] == true,
      device: _stringValue(json['device'], fallback: 'Unknown device'),
      city: _nullableString(json['city']) ?? _nullableString(json['city_name']),
      country:
          _nullableString(json['country']) ??
          _nullableString(json['country_code']),
      lastCity:
          _nullableString(json['lastCity']) ??
          _nullableString(json['last_city']),
      lastCountry:
          _nullableString(json['lastCountry']) ??
          _nullableString(json['last_country']),
      createdAt: _dateTimeValue(json['createdAt']),
      lastRefreshAt: _dateTimeValue(json['lastRefreshAt']),
    );
  }

  final String id;
  final bool isCurrent;
  final String device;
  final String? city;
  final String? country;
  final String? lastCity;
  final String? lastCountry;
  final DateTime createdAt;
  final DateTime lastRefreshAt;

  String? get locationLabel {
    final locationCity = lastCity ?? city;
    final locationCountry = lastCountry ?? country;
    if (locationCity != null && locationCountry != null) {
      return '$locationCity, $locationCountry';
    }
    return locationCountry ?? locationCity;
  }

  String get locationStatusLabel => locationLabel ?? 'Location unavailable';

  bool get isDesktop {
    final label = device.toLowerCase();
    return label.contains('desktop') ||
        label.contains('windows') ||
        label.contains('mac') ||
        label.contains('linux');
  }

  bool get isMobile {
    final label = device.toLowerCase();
    return label.contains('android') || label.contains('ios');
  }

  @override
  String toString() {
    return 'UserSettingsSession('
        'id: $id, '
        'isCurrent: $isCurrent, '
        'device: $device, '
        'createdAt: ${createdAt.toIso8601String()}, '
        'lastRefreshAt: ${lastRefreshAt.toIso8601String()}'
        ')';
  }
}

List<UserSettingsSession> sortUserSettingsSessions(
  Iterable<UserSettingsSession> sessions,
) {
  return [...sessions]..sort((left, right) {
    if (left.isCurrent != right.isCurrent) {
      return left.isCurrent ? -1 : 1;
    }
    return right.lastRefreshAt.compareTo(left.lastRefreshAt);
  });
}

final class UserSettingsSessionsController extends ChangeNotifier {
  UserSettingsSessionsController({required this.repository});

  final UserSettingsSessionsRepository? repository;

  List<UserSettingsSession> _sessions = const [];
  String? _error;
  bool _loading = false;
  String? _busySessionId;
  bool _revokeAllBusy = false;
  bool _disposed = false;
  int _loadGeneration = 0;

  List<UserSettingsSession> get sessions => _sessions;

  String? get error => _error;

  bool get loading => _loading;

  String? get busySessionId => _busySessionId;

  bool get revokeAllBusy => _revokeAllBusy;

  List<UserSettingsSession> get currentSessions =>
      _sessions.where((session) => session.isCurrent).toList(growable: false);

  List<UserSettingsSession> get otherSessions =>
      _sessions.where((session) => !session.isCurrent).toList(growable: false);

  @override
  void dispose() {
    _disposed = true;
    _loadGeneration++;
    super.dispose();
  }

  Future<void> load() async {
    final activeRepository = repository;
    final generation = ++_loadGeneration;
    if (activeRepository == null) {
      _sessions = const [];
      _error = 'Sessions are unavailable until this network is connected.';
      _loading = false;
      _notifyIfAlive();
      return;
    }

    _loading = true;
    _error = null;
    _notifyIfAlive();
    try {
      final loadedSessions = await activeRepository.listSessions();
      if (!_isCurrentLoad(generation)) {
        return;
      }
      _sessions = sortUserSettingsSessions(loadedSessions);
      _error = null;
    } catch (_) {
      if (!_isCurrentLoad(generation)) {
        return;
      }
      _error = 'Sessions could not be loaded';
    } finally {
      if (_isCurrentLoad(generation)) {
        _loading = false;
        _notifyIfAlive();
      }
    }
  }

  Future<void> revokeSession(String sessionId) async {
    final activeRepository = repository;
    if (activeRepository == null || sessionId.trim().isEmpty) {
      return;
    }
    _busySessionId = sessionId;
    _error = null;
    _notifyIfAlive();
    try {
      await activeRepository.revokeSession(sessionId: sessionId);
      if (_disposed) {
        return;
      }
      _sessions = [
        for (final session in _sessions)
          if (session.id != sessionId) session,
      ];
    } catch (_) {
      if (_disposed) {
        return;
      }
      _error = 'Session could not be revoked';
    } finally {
      if (!_disposed) {
        _busySessionId = null;
        _notifyIfAlive();
      }
    }
  }

  Future<void> revokeAllOtherSessions() async {
    final activeRepository = repository;
    if (activeRepository == null) {
      return;
    }
    _revokeAllBusy = true;
    _error = null;
    _notifyIfAlive();
    try {
      await activeRepository.revokeAllOtherSessions();
      if (_disposed) {
        return;
      }
      _sessions = [
        for (final session in _sessions)
          if (session.isCurrent) session,
      ];
    } catch (_) {
      if (_disposed) {
        return;
      }
      _error = 'Other sessions could not be revoked';
    } finally {
      if (!_disposed) {
        _revokeAllBusy = false;
        _notifyIfAlive();
      }
    }
  }

  bool _isCurrentLoad(int generation) {
    return !_disposed && generation == _loadGeneration;
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

String? _nullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

DateTime _dateTimeValue(Object? value) {
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed.toUtc();
    }
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
