import '../../auth/auth_models.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../server_settings_workspace/server_settings_service.dart';
import '../shared/workspace_entitlements.dart';

final class UserSettingsContext {
  const UserSettingsContext({
    required this.networkId,
    required this.networkName,
    required this.apiOrigin,
    required this.currentUser,
    required this.currentUserMedia,
    required this.mediaPolicy,
    required this.entitlements,
    required this.repository,
    required this.signedIn,
  });

  final String networkId;
  final String networkName;
  final String apiOrigin;
  final VerdantUser currentUser;
  final ServerSettingsCurrentUserMedia? currentUserMedia;
  final ServerMediaPolicy mediaPolicy;
  final WorkspaceEntitlements entitlements;
  final UserSettingsRepository? repository;
  final bool signedIn;

  String get usernameLabel {
    if (!signedIn) {
      return 'Signed out';
    }
    final mediaUsername = currentUserMedia?.username?.trim();
    final username = mediaUsername != null && mediaUsername.isNotEmpty
        ? mediaUsername
        : currentUser.username.trim();
    if (username.isEmpty) {
      return 'Connected';
    }
    return '@$username';
  }

  String get displayLabel {
    final displayName = currentUserMedia?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return currentUser.displayLabel;
  }

  bool get backendAvailable => signedIn && repository != null;
}
