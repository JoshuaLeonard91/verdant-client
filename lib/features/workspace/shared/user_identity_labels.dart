import '../server_settings_workspace/server_settings_models.dart';

String workspaceUserLocalId(String userId) {
  final trimmed = userId.trim();
  final slash = trimmed.indexOf('/');
  if (slash >= 0 && slash < trimmed.length - 1) {
    return trimmed.substring(slash + 1);
  }
  return trimmed;
}

bool workspaceUserIsFederatedProjection(String userId) {
  return workspaceUserLocalId(userId).startsWith('fed_');
}

String workspaceUserCopyLabel(String? userId) {
  return 'Copy User ID';
}

String workspaceUserClipboardId(String? userId, {required String fallback}) {
  final trimmed = userId?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return fallback;
  }
  return trimmed;
}

String? workspaceOriginClipboardId(FederatedOriginIdentity? originIdentity) {
  final remoteUserId = originIdentity?.remoteUserId.trim();
  if (remoteUserId == null || remoteUserId.isEmpty) {
    return null;
  }
  final homePeerId = originIdentity?.homePeerId.trim();
  if (homePeerId == null || homePeerId.isEmpty) {
    return remoteUserId;
  }
  return '$homePeerId/$remoteUserId';
}
