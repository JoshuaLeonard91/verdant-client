import '../../auth/auth_models.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../workspace_local_id.dart';

enum RailNetworkStatusTone { success, warning, danger, muted }

enum RailNetworkMode { official, standalone, linked, federated, unknown }

enum RailNetworkAvailability {
  checking,
  available,
  requiresAuth,
  unavailable,
  unsupported,
}

enum RailNetworkAuthStatus { unknown, authenticated, signedOut }

final class RailNetworkRecord {
  const RailNetworkRecord({
    required this.networkId,
    required this.networkName,
    required this.mode,
    required this.availability,
    required this.authStatus,
    this.apiOrigin,
    this.currentUserId,
    this.currentUsername,
    this.usernameSet,
    this.credentialKind,
  });

  final String networkId;
  final String networkName;
  final RailNetworkMode mode;
  final RailNetworkAvailability availability;
  final RailNetworkAuthStatus authStatus;
  final String? apiOrigin;
  final String? currentUserId;
  final String? currentUsername;
  final bool? usernameSet;
  final AuthCredentialKind? credentialKind;

  bool get hasFederatedClientCredential =>
      credentialKind == AuthCredentialKind.federatedClient;

  bool get usesFederatedAccess =>
      mode == RailNetworkMode.federated || hasFederatedClientCredential;
}

bool railNetworkRecordNeedsUsername(RailNetworkRecord record) {
  if (record.authStatus != RailNetworkAuthStatus.authenticated) {
    return false;
  }
  final userId = record.currentUserId;
  final username = record.currentUsername;
  if (userId == null || username == null) {
    return false;
  }
  if (record.usernameSet == false) {
    return true;
  }
  if (record.usernameSet == true) {
    return false;
  }
  return username == 'user_${railLocalUserId(userId)}';
}

String railNetworkSignedInLabel(RailNetworkRecord record, String fallback) {
  if (record.authStatus != RailNetworkAuthStatus.authenticated) {
    return fallback;
  }
  if (railNetworkRecordNeedsUsername(record)) {
    return 'Username needed';
  }
  final username = record.currentUsername;
  if (username == null || username.trim().isEmpty) {
    return record.usesFederatedAccess
        ? 'Connected with federated access'
        : 'Connected';
  }
  final label = '@$username';
  return record.usesFederatedAccess ? 'Connected as $label' : label;
}

String railLocalUserId(String userId) {
  final slash = userId.indexOf('/');
  if (slash < 0) {
    return userId;
  }
  return userId.substring(slash + 1);
}

final class RailServerItem {
  const RailServerItem({
    required this.networkId,
    required this.localServerId,
    required this.name,
    required this.mediaPolicy,
    this.iconUrl,
    this.memberCount,
    this.bannerUrl,
    this.isUnavailable = false,
    this.unreadCount = 0,
    this.mentionCount = 0,
  });

  factory RailServerItem.fromServer({
    required String networkId,
    required ServerSettingsServer server,
    required ServerMediaPolicy mediaPolicy,
  }) {
    return RailServerItem(
      networkId: networkId,
      localServerId: server.id,
      name: server.name,
      iconUrl: server.iconUrl,
      memberCount: server.memberCount,
      bannerUrl: server.bannerUrl,
      mediaPolicy: mediaPolicy,
    );
  }

  final String networkId;
  final String localServerId;
  final String name;
  final String? iconUrl;
  final int? memberCount;
  final String? bannerUrl;
  final bool isUnavailable;
  final int unreadCount;
  final int mentionCount;
  final ServerMediaPolicy mediaPolicy;

  String get scopedServerId => '$networkId/$localServerId';

  RailServerItem copyWith({
    String? networkId,
    String? localServerId,
    String? name,
    String? iconUrl,
    int? memberCount,
    String? bannerUrl,
    bool? isUnavailable,
    int? unreadCount,
    int? mentionCount,
    ServerMediaPolicy? mediaPolicy,
  }) {
    return RailServerItem(
      networkId: networkId ?? this.networkId,
      localServerId: localServerId ?? this.localServerId,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      memberCount: memberCount ?? this.memberCount,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      isUnavailable: isUnavailable ?? this.isUnavailable,
      unreadCount: unreadCount ?? this.unreadCount,
      mentionCount: mentionCount ?? this.mentionCount,
      mediaPolicy: mediaPolicy ?? this.mediaPolicy,
    );
  }
}

final class RailNetworkGroup {
  const RailNetworkGroup({
    required this.networkId,
    required this.networkName,
    required this.modeLabel,
    required this.statusLabel,
    required this.statusTone,
    required this.servers,
  });

  final String networkId;
  final String networkName;
  final String modeLabel;
  final String statusLabel;
  final RailNetworkStatusTone statusTone;
  final List<RailServerItem> servers;
}

List<RailNetworkGroup> buildRailNetworkGroups({
  required List<RailServerItem> servers,
  required String activeNetworkId,
  List<RailNetworkRecord> networkRecords = const [],
  List<String> networkOrder = const [],
}) {
  final preferredNetworkIds = <String>[
    ...networkOrder,
    for (final record in networkRecords) record.networkId,
    activeNetworkId,
  ];
  final grouped = <String, List<RailServerItem>>{};
  for (final server in servers) {
    final groupNetworkId = _canonicalRailNetworkId(
      server.networkId,
      preferredNetworkIds,
    );
    grouped.putIfAbsent(groupNetworkId, () => []).add(server);
  }

  final recordsByNetworkId = <String, RailNetworkRecord>{};
  for (final record in networkRecords) {
    final groupNetworkId = _canonicalRailNetworkId(
      record.networkId,
      preferredNetworkIds,
    );
    recordsByNetworkId.putIfAbsent(groupNetworkId, () => record);
  }
  final allNetworkIds = <String>{
    ...grouped.keys,
    ...recordsByNetworkId.keys,
    activeNetworkId,
  };
  final orderedNetworkIds = <String>[];
  void addNetwork(String networkId) {
    final groupNetworkId = _canonicalRailNetworkId(
      networkId,
      preferredNetworkIds,
    );
    if (allNetworkIds.contains(groupNetworkId) &&
        !orderedNetworkIds.contains(groupNetworkId)) {
      orderedNetworkIds.add(groupNetworkId);
    }
  }

  for (final networkId in networkOrder) {
    addNetwork(networkId);
  }
  for (final record in networkRecords) {
    addNetwork(record.networkId);
  }
  addNetwork(activeNetworkId);
  final remainingNetworkIds =
      allNetworkIds
          .where((networkId) => !orderedNetworkIds.contains(networkId))
          .toList(growable: false)
        ..sort();
  orderedNetworkIds.addAll(remainingNetworkIds);

  return [
    for (final networkId in orderedNetworkIds)
      _buildNetworkGroup(
        networkId: networkId,
        record:
            recordsByNetworkId[networkId] ??
            _fallbackNetworkRecord(
              networkId,
              isActive: sameWorkspaceNetworkId(networkId, activeNetworkId),
            ),
        servers: grouped[networkId] ?? const [],
      ),
  ];
}

String _canonicalRailNetworkId(
  String networkId,
  List<String> preferredNetworkIds,
) {
  for (final preferredNetworkId in preferredNetworkIds) {
    if (sameWorkspaceNetworkId(networkId, preferredNetworkId)) {
      return preferredNetworkId;
    }
  }
  return networkId;
}

RailNetworkGroup _buildNetworkGroup({
  required String networkId,
  required RailNetworkRecord record,
  required List<RailServerItem> servers,
}) {
  final resolvedRecord = record;
  final status = _networkStatus(resolvedRecord);
  final blocked = status.blocked;
  return RailNetworkGroup(
    networkId: networkId,
    networkName: resolvedRecord.networkName,
    modeLabel: _modeLabel(resolvedRecord.mode),
    statusLabel: status.label,
    statusTone: status.tone,
    servers: [
      for (final server in servers)
        blocked && !server.isUnavailable
            ? server.copyWith(isUnavailable: true)
            : server,
    ],
  );
}

RailNetworkRecord _fallbackNetworkRecord(
  String networkId, {
  required bool isActive,
}) {
  return RailNetworkRecord(
    networkId: networkId,
    networkName: 'Saved Network',
    mode: RailNetworkMode.unknown,
    availability: isActive
        ? RailNetworkAvailability.available
        : RailNetworkAvailability.unavailable,
    authStatus: isActive
        ? RailNetworkAuthStatus.authenticated
        : RailNetworkAuthStatus.unknown,
  );
}

String _modeLabel(RailNetworkMode mode) {
  return switch (mode) {
    RailNetworkMode.official => 'Network',
    RailNetworkMode.standalone => 'Federated',
    RailNetworkMode.linked => 'Federated',
    RailNetworkMode.federated => 'Federated',
    RailNetworkMode.unknown => 'Network',
  };
}

({String label, RailNetworkStatusTone tone, bool blocked}) _networkStatus(
  RailNetworkRecord record,
) {
  if (record.availability == RailNetworkAvailability.unsupported) {
    return (
      label: 'Unsupported',
      tone: RailNetworkStatusTone.danger,
      blocked: true,
    );
  }
  if (record.availability == RailNetworkAvailability.unavailable) {
    return (
      label: 'Unavailable',
      tone: RailNetworkStatusTone.danger,
      blocked: true,
    );
  }
  if (record.availability == RailNetworkAvailability.checking) {
    return (
      label: 'Checking',
      tone: RailNetworkStatusTone.warning,
      blocked: true,
    );
  }
  if (record.availability == RailNetworkAvailability.requiresAuth ||
      record.authStatus == RailNetworkAuthStatus.signedOut) {
    return (
      label: 'Sign in required',
      tone: RailNetworkStatusTone.warning,
      blocked: true,
    );
  }
  if (record.authStatus == RailNetworkAuthStatus.authenticated) {
    return (
      label: 'Signed in',
      tone: RailNetworkStatusTone.success,
      blocked: false,
    );
  }
  return (label: 'Saved', tone: RailNetworkStatusTone.muted, blocked: true);
}
