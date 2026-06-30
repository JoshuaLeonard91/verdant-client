import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/client_version.dart';
import '../../../shared/verdant_input_sanitizer.dart';
import '../../auth/auth_credentials.dart';
import '../../auth/auth_models.dart';
import '../../auth/auth_service.dart';
import '../../auth/transport_security.dart';
import '../shared/chat_timestamp_format.dart';
import '../shared/json_value.dart';
import '../shared/custom_expressive_asset.dart';
import '../shared/workspace_entitlements.dart';
import '../shared/workspace_credential_refresher.dart';
import '../shared/workspace_message_mutation_repository.dart';
import '../chat_workspace/announcement_feed/announcement_content_models.dart';
import '../chat_workspace/announcement_feed/announcement_feed_service.dart';
import '../user_settings_workspace/user_settings_notifications.dart';
import '../user_settings_workspace/user_settings_sessions.dart';
import '../workspace_local_id.dart';
import '../workspace_seed.dart';
import 'server_media_url_policy.dart';
import 'server_settings_models.dart';

abstract interface class ServerSettingsRepository {
  Future<List<ServerSettingsServer>> listServers();

  Future<ServerSettingsData> loadServerSettings(ServerSettingsServer server);

  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  });

  Future<ServerSettingsServer> createServer({required String name});

  Future<ServerSettingsListItemSeed> createInvite({
    required String serverId,
    int? maxUses,
    Duration? expiresIn,
  });

  Future<void> revokeInvite({required String serverId, required String code});

  Future<void> leaveServer({required String serverId});

  Future<ServerInvitePreview> previewInvite({required String code});

  Future<ServerSettingsServer> acceptInvite({required String code});

  Future<ServerSettingsServer> updateServer({
    required String serverId,
    required ServerSettingsPatch patch,
  });

  Future<ServerSettingsServer> uploadServerIcon({
    required String serverId,
    required ServerSettingsUpload upload,
  });

  Future<ServerSettingsServer> deleteServerIcon({required String serverId});

  Future<ServerSettingsServer> uploadServerBanner({
    required String serverId,
    required ServerSettingsUpload upload,
  });

  Future<ServerSettingsServer> updateBannerCrop({
    required String serverId,
    required BannerCrop crop,
  });

  Future<ServerSettingsServer> deleteServerBanner({required String serverId});
}

abstract interface class FullServerSettingsRepository {
  Future<ServerSettingsData> loadFullServerSettings(
    ServerSettingsServer server,
  );
}

abstract interface class ChannelSettingsRepository {
  Future<ServerSettingsChannelSeed> updateChannel({
    required String channelId,
    required ChannelSettingsPatch patch,
  });
}

abstract interface class ServerSettingsRoleRepository {
  Future<ServerSettingsListItemSeed> createRole({
    required String serverId,
    required ServerRolePatch patch,
  });

  Future<ServerSettingsListItemSeed> updateRole({
    required String serverId,
    required String roleId,
    required ServerRolePatch patch,
  });

  Future<void> deleteRole({required String serverId, required String roleId});
}

abstract interface class ServerSettingsFeedRepository {
  Future<ServerSettingsListItemSeed> createFeed({
    required String serverId,
    required ServerFeedPatch patch,
  });

  Future<ServerSettingsListItemSeed> updateFeed({
    required String serverId,
    required String feedId,
    required ServerFeedPatch patch,
  });

  Future<void> deleteFeed({required String serverId, required String feedId});
}

abstract interface class ServerSettingsModerationRepository {
  Future<void> kickMember({
    required String serverId,
    required String userId,
    String? reason,
  });

  Future<void> banMember({
    required String serverId,
    required String userId,
    String? reason,
  });

  Future<void> unbanMember({required String serverId, required String userId});

  Future<List<ServerSettingsListItemSeed>> listBans({required String serverId});
}

abstract interface class ServerSettingsAuditRepository {
  Future<ServerSettingsAuditPage> listAuditEvents({
    required String serverId,
    int limit = 50,
    String? beforeEventId,
  });
}

abstract interface class ServerSettingsBotRepository {
  Future<ServerSettingsListItemSeed> createBot({
    required String serverId,
    required ServerBotPatch patch,
  });

  Future<ServerSettingsListItemSeed> updateBot({
    required String serverId,
    required String botId,
    required ServerBotPatch patch,
  });

  Future<void> deleteBot({required String serverId, required String botId});

  Future<BotTokenResult> generateBotToken({
    required String serverId,
    required String botId,
    required BotTokenPatch patch,
  });
}

abstract interface class ServerSettingsEmojiRepository {
  Future<ServerSettingsUploadPreview> loadEmojiUploadPreview({
    required ServerSettingsUpload upload,
  });

  Future<ServerSettingsUploadPreview> loadStickerUploadPreview({
    required ServerSettingsUpload upload,
  });

  Future<ServerSettingsListItemSeed> uploadEmoji({
    required String serverId,
    required String name,
    required ServerSettingsUpload upload,
  });

  Future<ServerSettingsListItemSeed> uploadSticker({
    required String serverId,
    required String name,
    required ServerSettingsUpload upload,
  });

  Future<ServerSettingsListItemSeed> renameEmoji({
    required String serverId,
    required String emojiId,
    required String name,
  });

  Future<ServerSettingsListItemSeed> renameSticker({
    required String serverId,
    required String stickerId,
    required String name,
  });

  Future<void> deleteEmoji({required String serverId, required String emojiId});

  Future<void> deleteSticker({
    required String serverId,
    required String stickerId,
  });
}

abstract interface class ServerSettingsNameColorRepository {
  Future<List<String>> setOwnNameColor({
    required String serverId,
    required String? roleId,
  });
}

abstract interface class ServerSettingsCurrentUserMediaRepository {
  Future<ServerSettingsCurrentUserMedia?> loadCurrentUserMedia();
}

abstract interface class UserSettingsRepository
    implements
        UserSettingsNotificationsRepository,
        UserSettingsSessionsRepository {
  Future<TwoFactorStatus> loadTwoFactorStatus();

  Future<TwoFactorSetup> startTwoFactorSetup({required String currentPassword});

  Future<TwoFactorVerification> verifyTwoFactorSetup({required String code});

  Future<TwoFactorBackupCodes> regenerateTwoFactorBackupCodes({
    required String currentPassword,
    required String totpCode,
  });

  Future<void> disableTwoFactor({
    required String currentPassword,
    required String code,
  });

  Future<ServerSettingsCurrentUserMedia> updateCurrentUserProfile({
    required UserProfilePatch patch,
  });

  Future<ServerSettingsCurrentUserMedia> changeCurrentUserPassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<VerdantUser> setCurrentUsername({required String username});

  Future<EmailChangeStartResult> startCurrentUserEmailChange({
    required String currentEmail,
    required String newEmail,
    required String currentPassword,
  });

  Future<void> confirmCurrentUserEmailChange({required String code});

  Future<UserAvatarUpdate> uploadUserAvatar({
    required ServerSettingsUpload upload,
  });

  Future<UserAvatarUpdate> deleteUserAvatar();

  Future<UserProfileBannerUpdate> uploadUserProfileBanner({
    required ServerSettingsUpload upload,
  });

  Future<UserProfileBannerUpdate> updateUserProfileBannerCrop({
    required BannerCrop crop,
  });

  Future<UserProfileBannerUpdate> deleteUserProfileBanner();

  Future<UserMemberListBannerUpdate> uploadMemberListBanner({
    required ServerSettingsUpload upload,
  });

  Future<UserMemberListBannerUpdate> updateMemberListBannerCrop({
    required BannerCrop crop,
  });

  Future<UserMemberListBannerUpdate> deleteMemberListBanner();
}

abstract interface class ServerSettingsChannelActivityRepository {
  Future<List<MemberSeed>> loadChannelActivity({required String channelId});
}

abstract interface class ServerWorkspaceBootstrapRepository {
  Future<ServerWorkspaceBootstrap?> loadServerWorkspaceBootstrap(
    ServerSettingsServer server, {
    required String currentUserId,
    int messageLimit = 50,
  });
}

abstract interface class ServerSettingsUserMediaRepository {
  Future<ServerSettingsCurrentUserMedia?> loadUserMedia({
    required String localUserId,
  });
}

final class ServerSettingsException implements Exception {
  const ServerSettingsException(
    this.message, {
    this.isAuthExpired = false,
    this.statusCode,
  });

  final String message;
  final bool isAuthExpired;
  final int? statusCode;

  @override
  String toString() => message;
}

final class ServerWorkspaceBootstrap {
  const ServerWorkspaceBootstrap({
    required this.settings,
    required this.currentUserMedia,
    required this.activeChannelId,
    required this.messages,
    required this.activity,
  });

  final ServerSettingsData settings;
  final ServerSettingsCurrentUserMedia? currentUserMedia;
  final String? activeChannelId;
  final List<MessageSeed> messages;
  final ({bool available, List<MemberSeed> members}) activity;
}

var _serverSettingsHttpRequestSequence = 0;
var _serverSettingsHttpInFlight = 0;

final class ServerSettingsPatch {
  const ServerSettingsPatch({
    this.name,
    this.welcomeChannelId = _unsetPatchValue,
  });

  final String? name;
  final Object? welcomeChannelId;

  bool get _hasWelcomeChannelId =>
      !identical(welcomeChannelId, _unsetPatchValue);

  Map<String, Object?> toJson() {
    final payload = <String, Object?>{};
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      payload['name'] = trimmedName;
    }
    if (_hasWelcomeChannelId) {
      payload['welcomeChannelId'] = welcomeChannelId as String?;
    }
    return payload;
  }
}

final class ChannelSettingsPatch {
  const ChannelSettingsPatch({
    this.name,
    this.topic = unset,
    this.readOnly,
    this.slowmodeSeconds,
  });

  static const Object unset = Object();

  final String? name;
  final Object? topic;
  final bool? readOnly;
  final int? slowmodeSeconds;

  bool get _hasTopic => !identical(topic, unset);

  Map<String, Object?> toJson() {
    final payload = <String, Object?>{};
    final normalizedName = _normalizeChannelName(name);
    if (normalizedName != null) {
      payload['name'] = normalizedName;
    }
    if (_hasTopic) {
      payload['topic'] = _normalizedOptionalText(topic);
    }
    if (readOnly != null) {
      payload['readOnly'] = readOnly;
    }
    final slowmode = slowmodeSeconds;
    if (slowmode != null) {
      payload['slowmodeSeconds'] = slowmode.clamp(0, 21600);
    }
    return payload;
  }
}

final class ServerRolePatch {
  const ServerRolePatch({
    this.name,
    this.color = unset,
    this.permissions,
    this.position,
    this.colorOnly,
    this.showAsSection,
    this.colorPriority,
  });

  static const Object unset = Object();

  final String? name;
  final Object? color;
  final int? permissions;
  final int? position;
  final bool? colorOnly;
  final bool? showAsSection;
  final int? colorPriority;

  bool get _hasColor => !identical(color, unset);

  Map<String, Object?> toJson() {
    final payload = <String, Object?>{};
    final normalizedName = name?.trim();
    if (normalizedName != null && normalizedName.isNotEmpty) {
      payload['name'] = normalizedName;
    }
    if (_hasColor) {
      payload['color'] = _normalizedHexColor(color);
    }
    final nextPermissions = permissions;
    if (nextPermissions != null) {
      payload['permissions'] = nextPermissions.toString();
    }
    final nextPosition = position;
    if (nextPosition != null) {
      payload['position'] = nextPosition.clamp(0, 10000);
    }
    final nextColorOnly = colorOnly;
    if (nextColorOnly != null) {
      payload['colorOnly'] = nextColorOnly;
    }
    final nextShowAsSection = showAsSection;
    if (nextShowAsSection != null) {
      payload['showAsSection'] = nextShowAsSection;
    }
    final nextColorPriority = colorPriority;
    if (nextColorPriority != null) {
      payload['colorPriority'] = nextColorPriority.clamp(0, 10000);
    }
    return payload;
  }
}

final class ServerFeedPatch {
  const ServerFeedPatch({
    this.name,
    this.description = unset,
    this.icon = unset,
    this.publishRoleIds = unset,
    this.visibleRoleIds = unset,
  });

  static const Object unset = Object();

  final String? name;
  final Object? description;
  final Object? icon;
  final Object? publishRoleIds;
  final Object? visibleRoleIds;

  bool get _hasDescription => !identical(description, unset);
  bool get _hasIcon => !identical(icon, unset);
  bool get _hasPublishRoleIds => !identical(publishRoleIds, unset);
  bool get _hasVisibleRoleIds => !identical(visibleRoleIds, unset);

  Map<String, Object?> toJson({String Function(String roleId)? localRoleId}) {
    final payload = <String, Object?>{};
    final normalizedName = name?.trim();
    if (normalizedName != null && normalizedName.isNotEmpty) {
      payload['name'] = normalizedName;
    }
    if (_hasDescription) {
      payload['description'] = _normalizedOptionalText(description);
    }
    if (_hasIcon) {
      payload['icon'] = _normalizedOptionalText(icon);
    }
    if (_hasPublishRoleIds) {
      payload['publishRoleIds'] = _normalizedFeedRoleIds(
        publishRoleIds,
        localRoleId,
      );
    }
    if (_hasVisibleRoleIds) {
      payload['visibleRoleIds'] = _normalizedFeedRoleIds(
        visibleRoleIds,
        localRoleId,
      );
    }
    return payload;
  }
}

final class ServerBotPatch {
  const ServerBotPatch({
    this.name,
    this.description = unset,
    this.avatarPreset,
    this.bannerPreset,
  });

  static const Object unset = Object();

  final String? name;
  final Object? description;
  final String? avatarPreset;
  final String? bannerPreset;

  bool get _hasDescription => !identical(description, unset);

  Map<String, Object?> toJson() {
    final payload = <String, Object?>{};
    final normalizedName = name?.trim();
    if (normalizedName != null && normalizedName.isNotEmpty) {
      payload['name'] = normalizedName;
    }
    if (_hasDescription) {
      payload['description'] = _normalizedOptionalText(description);
    }
    final normalizedAvatarPreset = avatarPreset?.trim();
    if (normalizedAvatarPreset != null && normalizedAvatarPreset.isNotEmpty) {
      payload['avatarPreset'] = normalizedAvatarPreset;
    }
    final normalizedBannerPreset = bannerPreset?.trim();
    if (normalizedBannerPreset != null && normalizedBannerPreset.isNotEmpty) {
      payload['bannerPreset'] = normalizedBannerPreset;
    }
    return payload;
  }
}

final class BotTokenPatch {
  const BotTokenPatch({
    this.name,
    this.scopes = const [],
    this.allowedFeedIds = const [],
    this.allowedChannelIds = const [],
  });

  final String? name;
  final List<String> scopes;
  final List<String> allowedFeedIds;
  final List<String> allowedChannelIds;

  Map<String, Object?> toJson({
    String Function(String feedId)? localFeedId,
    String Function(String channelId)? localChannelId,
  }) {
    final payload = <String, Object?>{};
    final normalizedName = name?.trim();
    if (normalizedName != null && normalizedName.isNotEmpty) {
      payload['name'] = normalizedName;
    }
    final normalizedScopes = _normalizedStringList(scopes);
    if (normalizedScopes.isNotEmpty) {
      payload['scopes'] = normalizedScopes;
    }
    final normalizedFeedIds = _normalizedRouteStringList(
      allowedFeedIds,
      localFeedId,
    );
    if (normalizedFeedIds.isNotEmpty) {
      payload['allowedFeedIds'] = normalizedFeedIds;
    }
    final normalizedChannelIds = _normalizedRouteStringList(
      allowedChannelIds,
      localChannelId,
    );
    if (normalizedChannelIds.isNotEmpty) {
      payload['allowedChannelIds'] = normalizedChannelIds;
    }
    return payload;
  }
}

final class BotTokenResult {
  const BotTokenResult({
    required this.tokenId,
    required this.token,
    required this.name,
    required this.scopes,
    required this.allowedFeedIds,
    required this.allowedChannelIds,
  });

  factory BotTokenResult.fromJson(Map<String, Object?> json) {
    return BotTokenResult(
      tokenId: _stringValue(json['tokenId'], fallback: ''),
      token: _stringValue(json['token'], fallback: ''),
      name: _stringValue(json['name'], fallback: 'default'),
      scopes: _stringList(json['scopes']),
      allowedFeedIds: _stringList(json['allowedFeedIds']),
      allowedChannelIds: _stringList(json['allowedChannelIds']),
    );
  }

  final String tokenId;
  final String token;
  final String name;
  final List<String> scopes;
  final List<String> allowedFeedIds;
  final List<String> allowedChannelIds;
}

final class UserProfilePatch {
  const UserProfilePatch({
    this.displayName = _unsetPatchValue,
    this.bio = _unsetPatchValue,
    this.bannerBaseColor = _unsetPatchValue,
  });

  final Object? displayName;
  final Object? bio;
  final Object? bannerBaseColor;

  bool get _hasDisplayName => !identical(displayName, _unsetPatchValue);
  bool get _hasBio => !identical(bio, _unsetPatchValue);
  bool get _hasBannerBaseColor => !identical(bannerBaseColor, _unsetPatchValue);

  Map<String, Object?> toJson() {
    final payload = <String, Object?>{};
    if (_hasDisplayName) {
      payload['displayName'] = _normalizedOptionalText(displayName);
    }
    if (_hasBio) {
      payload['bio'] = _normalizedOptionalText(bio);
    }
    if (_hasBannerBaseColor) {
      payload['bannerBaseColor'] = _normalizedOptionalText(bannerBaseColor);
    }
    return payload;
  }
}

final class EmailChangeStartResult {
  const EmailChangeStartResult({required this.codeSent, required this.has2fa});

  factory EmailChangeStartResult.fromJson(Map<String, Object?> json) {
    return EmailChangeStartResult(
      codeSent: _boolValue(json['codeSent'], fallback: false),
      has2fa: _boolValue(json['has2fa'], fallback: false),
    );
  }

  final bool codeSent;
  final bool has2fa;
}

final class TwoFactorStatus {
  const TwoFactorStatus({
    required this.enabled,
    required this.enabledAt,
    required this.remainingBackupCodes,
  });

  factory TwoFactorStatus.fromJson(Map<String, Object?> json) {
    return TwoFactorStatus(
      enabled: _boolValue(json['enabled'], fallback: false),
      enabledAt: _dateTimeValue(json['enabledAt']),
      remainingBackupCodes: _intValue(
        json['remainingBackupCodes'],
        fallback: 0,
      ),
    );
  }

  final bool enabled;
  final DateTime? enabledAt;
  final int remainingBackupCodes;
}

final class TwoFactorSetup {
  const TwoFactorSetup({required this.secret, required this.qrDataUrl});

  factory TwoFactorSetup.fromJson(Map<String, Object?> json) {
    final qrDataUrl = _stringValue(json['qrDataUrl'], fallback: '');
    if (!qrDataUrl.startsWith('data:image/')) {
      throw const FormatException('Invalid two factor QR data URL');
    }
    return TwoFactorSetup(
      secret: _stringValue(json['secret'], fallback: ''),
      qrDataUrl: qrDataUrl,
    );
  }

  final String secret;
  final String qrDataUrl;
}

final class TwoFactorVerification {
  const TwoFactorVerification({
    required this.enabled,
    required this.backupCodes,
  });

  factory TwoFactorVerification.fromJson(Map<String, Object?> json) {
    return TwoFactorVerification(
      enabled: _boolValue(json['enabled'], fallback: false),
      backupCodes: _stringList(json['backupCodes']),
    );
  }

  final bool enabled;
  final List<String> backupCodes;
}

final class TwoFactorBackupCodes {
  const TwoFactorBackupCodes({required this.backupCodes});

  factory TwoFactorBackupCodes.fromJson(Map<String, Object?> json) {
    return TwoFactorBackupCodes(backupCodes: _stringList(json['backupCodes']));
  }

  final List<String> backupCodes;
}

final class ServerSettingsUpload {
  const ServerSettingsUpload({required this.path, required this.fileName});

  final String path;
  final String fileName;
}

final class ServerSettingsUploadPreview {
  const ServerSettingsUploadPreview({
    required this.previewBytes,
    required this.sizeBytes,
  });

  final Uint8List previewBytes;
  final int sizeBytes;
}

final class ServerCreationRequest {
  ServerCreationRequest({
    required this.name,
    required String apiOrigin,
    required this.networkId,
    this.iconUpload,
    this.bannerUpload,
    this.bannerCrop,
  }) : apiOrigin = normalizeBackendApiOrigin(apiOrigin);

  final String name;
  final String apiOrigin;
  final String networkId;
  final ServerSettingsUpload? iconUpload;
  final ServerSettingsUpload? bannerUpload;
  final BannerCrop? bannerCrop;
}

final class ServerCreationResult {
  const ServerCreationResult({required this.server, this.warning});

  final ServerSettingsServer server;
  final String? warning;
}

final class ServerSettingsService
    implements
        ServerSettingsRepository,
        ServerSettingsCurrentUserMediaRepository,
        ServerWorkspaceBootstrapRepository,
        UserSettingsRepository,
        ServerSettingsChannelActivityRepository,
        ServerSettingsUserMediaRepository,
        FullServerSettingsRepository,
        ChannelSettingsRepository,
        ServerSettingsRoleRepository,
        ServerSettingsFeedRepository,
        ServerSettingsModerationRepository,
        ServerSettingsAuditRepository,
        ServerSettingsBotRepository,
        ServerSettingsEmojiRepository,
        AnnouncementFeedRepository,
        ServerSettingsNameColorRepository,
        WorkspaceMessageMutationRepository {
  ServerSettingsService({
    required String apiOrigin,
    required this.credentialStore,
    AuthService? authService,
    HttpClient? httpClient,
    CertificatePinningPolicy? certificatePinningPolicy,
    this.timeout = const Duration(seconds: 15),
    this.maxResponseBytes = 1024 * 1024,
    this.minRequestInterval = Duration.zero,
  }) : _certificatePinningPolicy =
           certificatePinningPolicy ??
           CertificatePinningPolicy.fromEnvironment(),
       _httpClient =
           httpClient ??
           (certificatePinningPolicy ??
                   CertificatePinningPolicy.fromEnvironment())
               .createHttpClient(),
       _credentialRefresher = WorkspaceCredentialRefresher(
         apiOrigin: apiOrigin,
         credentialStore: credentialStore,
         authService: authService,
         certificatePinningPolicy: certificatePinningPolicy,
         timeout: timeout,
       ),
       _requestPacer = _ServerSettingsRequestPacer.forOrigin(
         normalizeBackendApiOrigin(apiOrigin),
       ),
       apiOrigin = normalizeBackendApiOrigin(apiOrigin);

  final String apiOrigin;
  final AuthCredentialStore credentialStore;
  final HttpClient _httpClient;
  final CertificatePinningPolicy _certificatePinningPolicy;
  final WorkspaceCredentialRefresher _credentialRefresher;
  final _ServerSettingsRequestPacer _requestPacer;
  final Duration timeout;
  final int maxResponseBytes;
  final Duration minRequestInterval;

  @override
  Future<List<ServerSettingsServer>> listServers() async {
    final decoded = await _jsonRequest('GET', '/api/servers');
    if (decoded is! Map<String, Object?>) {
      throw const ServerSettingsException('Invalid server list response');
    }
    final servers = decoded['servers'];
    if (servers is! List) {
      throw const ServerSettingsException(
        'Server list response was missing servers',
      );
    }
    return [
      for (final item in servers)
        if (_mapValue(item) != null)
          ServerSettingsServer.fromJson(_mapValue(item)!),
    ];
  }

  @override
  Future<ServerSettingsData> loadServerSettings(
    ServerSettingsServer server,
  ) async {
    return _loadServerSettings(server, includeSettingsTabs: false);
  }

  @override
  Future<ServerWorkspaceBootstrap?> loadServerWorkspaceBootstrap(
    ServerSettingsServer server, {
    required String currentUserId,
    int messageLimit = 50,
  }) async {
    final safeLimit = messageLimit.clamp(1, 50).toInt();
    final query = Uri(
      queryParameters: {
        'messageLimit': safeLimit.toString(),
        'includeActivity': 'true',
      },
    ).query;
    final path =
        '/api/servers/${Uri.encodeComponent(server.id)}/workspace?$query';
    Object? decoded;
    try {
      decoded = await _jsonRequest('GET', path);
    } on ServerSettingsException catch (error) {
      if (error.statusCode == HttpStatus.notFound ||
          error.statusCode == HttpStatus.methodNotAllowed) {
        return null;
      }
      rethrow;
    }
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException(
        'Server workspace response was invalid',
      );
    }
    final bootstrap = _workspaceBootstrapFromJson(
      map,
      fallbackServer: server,
      currentUserId: currentUserId,
    );
    final needsEmojiFallback =
        map['emojis'] is! List || bootstrap.settings.emojis.isEmpty;
    final needsStickerFallback = map['stickers'] is! List;
    if (!needsEmojiFallback && !needsStickerFallback) {
      return bootstrap;
    }

    var fallbackEmojis = bootstrap.settings.emojis;
    if (needsEmojiFallback) {
      debugPrint(
        'verdant.http server_settings.workspace.emojis.fallback '
        '{reason: ${map['emojis'] is List ? 'empty_or_invalid' : 'missing'}, '
        'batchCount: ${bootstrap.settings.emojis.length}}',
      );
      fallbackEmojis = await _loadListItems(
        '/api/servers/${Uri.encodeComponent(bootstrap.settings.server.id)}/emojis',
        _emojiItem,
      );
    }
    var fallbackStickers = bootstrap.settings.stickers;
    if (needsStickerFallback) {
      debugPrint(
        'verdant.http server_settings.workspace.stickers.fallback '
        '{reason: ${map['stickers'] is List ? 'empty_or_invalid' : 'missing'}, '
        'batchCount: ${bootstrap.settings.stickers.length}}',
      );
      fallbackStickers = await _loadListItems(
        '/api/servers/${Uri.encodeComponent(bootstrap.settings.server.id)}/stickers',
        _stickerItem,
      );
    }

    if (fallbackEmojis.isEmpty && fallbackStickers.isEmpty) {
      return bootstrap;
    }
    return ServerWorkspaceBootstrap(
      settings: bootstrap.settings.copyWith(
        emojis: fallbackEmojis,
        stickers: fallbackStickers,
      ),
      currentUserMedia: bootstrap.currentUserMedia,
      activeChannelId: bootstrap.activeChannelId,
      messages: bootstrap.messages,
      activity: bootstrap.activity,
    );
  }

  @override
  Future<ServerSettingsData> loadFullServerSettings(
    ServerSettingsServer server,
  ) async {
    return _loadServerSettings(server, includeSettingsTabs: true);
  }

  Future<ServerSettingsData> _loadServerSettings(
    ServerSettingsServer server, {
    required bool includeSettingsTabs,
  }) async {
    final serverId = server.id;
    final channels = await _loadChannels(serverId);
    // Start independent reads together. A non-zero minRequestInterval can still
    // pace injected repositories, but normal workspace hydration relies on the
    // 429 retry-after path instead of pre-delaying every healthy request.
    final instanceMetadataFuture = _loadInstanceMetadata();
    final rolesFuture = _loadListItems(
      '/api/servers/${Uri.encodeComponent(serverId)}/roles',
      _roleItem,
    );
    final membersFuture = _loadListItems(
      '/api/servers/${Uri.encodeComponent(serverId)}/members?limit=100',
      _memberItem,
    );
    final feedsFuture = _loadListItems(
      '/api/servers/${Uri.encodeComponent(serverId)}/feeds',
      _feedItem,
    );
    final botsFuture = _loadListItems(
      '/api/servers/${Uri.encodeComponent(serverId)}/bots',
      _botItem,
    );
    final emojisFuture = _loadListItems(
      '/api/servers/${Uri.encodeComponent(serverId)}/emojis',
      _emojiItem,
    );
    final stickersFuture = _loadListItems(
      '/api/servers/${Uri.encodeComponent(serverId)}/stickers',
      _stickerItem,
    );
    final invitesFuture = includeSettingsTabs
        ? _loadListItems(
            '/api/servers/${Uri.encodeComponent(serverId)}/invites',
            _inviteItem,
          )
        : Future<List<ServerSettingsListItemSeed>>.value(
            const <ServerSettingsListItemSeed>[],
          );
    final auditEventsFuture = includeSettingsTabs
        ? _loadAuditItems(serverId)
        : Future<List<ServerSettingsListItemSeed>>.value(
            const <ServerSettingsListItemSeed>[],
          );

    final hydrated = await Future.wait<Object>([
      instanceMetadataFuture,
      rolesFuture,
      membersFuture,
      feedsFuture,
      botsFuture,
      emojisFuture,
      stickersFuture,
      invitesFuture,
      auditEventsFuture,
    ]);
    final instanceMetadata = hydrated[0] as _InstanceMetadata;
    final roles = hydrated[1] as List<ServerSettingsListItemSeed>;
    final members = hydrated[2] as List<ServerSettingsListItemSeed>;
    final feeds = hydrated[3] as List<ServerSettingsListItemSeed>;
    final bots = hydrated[4] as List<ServerSettingsListItemSeed>;
    final emojis = hydrated[5] as List<ServerSettingsListItemSeed>;
    final stickers = hydrated[6] as List<ServerSettingsListItemSeed>;
    final invites = hydrated[7] as List<ServerSettingsListItemSeed>;
    final auditEvents = hydrated[8] as List<ServerSettingsListItemSeed>;

    return ServerSettingsData(
      networkId: networkIdFromApiOrigin(apiOrigin),
      server: server,
      channels: channels,
      emojis: emojis,
      stickers: stickers,
      invites: invites,
      roles: roles,
      members: members,
      auditEvents: auditEvents,
      feeds: feeds,
      bots: bots,
      mediaPolicy: instanceMetadata.mediaPolicy,
      entitlements: instanceMetadata.entitlements,
    );
  }

  ServerWorkspaceBootstrap _workspaceBootstrapFromJson(
    Map<String, Object?> json, {
    required ServerSettingsServer fallbackServer,
    required String currentUserId,
  }) {
    final layout = _mapValue(json['layout']);
    final channels = layout?['channels'];
    final server = _mapValue(json['server']) == null
        ? fallbackServer
        : ServerSettingsServer.fromJson(_mapValue(json['server'])!);
    final instanceMetadata = _instanceMetadataFromJson(
      _mapValue(json['instance']),
    );
    final currentUser = _mapValue(json['currentUser']);
    final currentUserMedia = currentUser == null
        ? null
        : ServerSettingsCurrentUserMedia.fromJson(currentUser);
    final mediaUserId = currentUserMedia?.id.trim();
    final effectiveCurrentUserId = mediaUserId != null && mediaUserId.isNotEmpty
        ? mediaUserId
        : currentUserId;

    final messageRows = <({int index, Map<String, Object?> map})>[];
    final rawMessages = json['messages'];
    if (rawMessages is List) {
      for (var index = 0; index < rawMessages.length; index += 1) {
        final map = _mapValue(rawMessages[index]);
        if (map != null) {
          messageRows.add((index: index, map: map));
        }
      }
    }
    messageRows.sort(_messageRowOldestFirst);

    final networkId = networkIdFromApiOrigin(apiOrigin);
    final activity = _mapValue(json['activity']);
    final rawActivityMembers = activity?['members'];
    final activityMembers = rawActivityMembers is List
        ? [
            for (final item in rawActivityMembers)
              if (_mapValue(item) case final map?)
                _channelActivityMemberItem(networkId, map),
          ]
        : const <MemberSeed>[];

    return ServerWorkspaceBootstrap(
      settings: ServerSettingsData(
        networkId: networkId,
        server: server,
        channels: channels is List
            ? [
                    for (final item in channels)
                      if (_mapValue(item) case final channel?)
                        _channelFromJson(channel),
                  ]
                  .where((channel) => channel.id.isNotEmpty)
                  .toList(growable: false)
            : const <ServerSettingsChannelSeed>[],
        emojis: _listItemsFromJson(json['emojis'], _emojiItem),
        stickers: _listItemsFromJson(json['stickers'], _stickerItem),
        invites: _listItemsFromJson(json['invites'], _inviteItem),
        roles: _listItemsFromJson(json['roles'], _roleItem),
        members: _listItemsFromJson(json['members'], _memberItem),
        auditEvents: const <ServerSettingsListItemSeed>[],
        feeds: _listItemsFromJson(json['feeds'], _feedItem),
        bots: _listItemsFromJson(json['bots'], _botItem),
        mediaPolicy: instanceMetadata.mediaPolicy,
        entitlements: instanceMetadata.entitlements,
      ),
      currentUserMedia: currentUserMedia,
      activeChannelId: _nullableString(json['activeChannelId']),
      messages: [
        for (final row in messageRows)
          _messageFromJson(row.map, currentUserId: effectiveCurrentUserId),
      ],
      activity: (
        available: activity?['available'] != false,
        members: activityMembers,
      ),
    );
  }

  List<ServerSettingsListItemSeed> _listItemsFromJson(
    Object? value,
    ServerSettingsListItemSeed Function(Map<String, Object?> json) convert,
  ) {
    if (value is! List) {
      return const [];
    }
    return [
      for (final item in value)
        if (_mapValue(item) case final map?) convert(map),
    ];
  }

  @override
  Future<ServerSettingsCurrentUserMedia?> loadCurrentUserMedia() async {
    final decoded = await _jsonRequest('GET', '/api/users/me');
    if (decoded is! Map<String, Object?>) {
      throw const ServerSettingsException('Current user response was invalid');
    }
    return ServerSettingsCurrentUserMedia.fromJson(decoded);
  }

  @override
  Future<ServerSettingsCurrentUserMedia?> loadUserMedia({
    required String localUserId,
  }) async {
    final id = _safeRouteLocalId(
      localUserId,
      expectedNetworkId: networkIdFromApiOrigin(apiOrigin),
      entityLabel: 'User',
    );
    final decoded = await _jsonRequest(
      'GET',
      '/api/users/${Uri.encodeComponent(id)}',
    );
    if (decoded is! Map<String, Object?>) {
      throw const ServerSettingsException('User profile response was invalid');
    }
    return ServerSettingsCurrentUserMedia.fromJson(decoded);
  }

  @override
  Future<List<UserSettingsSession>> listSessions() async {
    final decoded = await _jsonRequest('GET', '/api/users/me/sessions');
    if (decoded is! List) {
      throw const ServerSettingsException('Sessions response was invalid');
    }
    return sortUserSettingsSessions([
      for (final item in decoded)
        if (_mapValue(item) != null)
          UserSettingsSession.fromJson(_mapValue(item)!),
    ]);
  }

  @override
  Future<void> revokeSession({required String sessionId}) async {
    final id = _safeRouteLocalId(
      sessionId,
      expectedNetworkId: networkIdFromApiOrigin(apiOrigin),
      entityLabel: 'Session',
    );
    await _jsonRequest(
      'DELETE',
      '/api/users/me/sessions/${Uri.encodeComponent(id)}',
    );
  }

  @override
  Future<void> revokeAllOtherSessions() async {
    await _jsonRequest('POST', '/api/users/me/sessions/revoke-all');
  }

  @override
  Future<List<UserSettingsNotificationPreference>>
  listNotificationPreferences() async {
    final decoded = await _jsonRequest('GET', '/api/users/me/notifications');
    if (decoded is! List) {
      throw const ServerSettingsException(
        'Notification preferences response was invalid',
      );
    }
    return [
      for (final item in decoded)
        if (_mapValue(item) != null)
          UserSettingsNotificationPreference.fromJson(_mapValue(item)!),
    ];
  }

  @override
  Future<void> saveNotificationPreference({
    required UserSettingsNotificationPreference preference,
  }) async {
    await _jsonRequest(
      'PUT',
      '/api/users/me/notifications',
      body: preference.toJson(),
    );
  }

  @override
  Future<TwoFactorStatus> loadTwoFactorStatus() async {
    final decoded = await _jsonRequest('GET', '/api/2fa/status');
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Two factor status was invalid');
    }
    return TwoFactorStatus.fromJson(map);
  }

  @override
  Future<TwoFactorSetup> startTwoFactorSetup({
    required String currentPassword,
  }) async {
    if (currentPassword.isEmpty) {
      throw const ServerSettingsException('Enter your password');
    }
    final decoded = await _jsonRequest(
      'POST',
      '/api/2fa/setup',
      body: {'currentPassword': currentPassword},
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Two factor setup was invalid');
    }
    try {
      return TwoFactorSetup.fromJson(map);
    } on FormatException {
      throw const ServerSettingsException('Two factor setup was invalid');
    }
  }

  @override
  Future<TwoFactorVerification> verifyTwoFactorSetup({
    required String code,
  }) async {
    final trimmedCode = code.trim();
    if (trimmedCode.length != 6) {
      throw const ServerSettingsException('Enter the 6-digit code');
    }
    final decoded = await _jsonRequest(
      'POST',
      '/api/2fa/verify-setup',
      body: {'code': trimmedCode},
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException(
        'Two factor verification was invalid',
      );
    }
    return TwoFactorVerification.fromJson(map);
  }

  @override
  Future<TwoFactorBackupCodes> regenerateTwoFactorBackupCodes({
    required String currentPassword,
    required String totpCode,
  }) async {
    final trimmedCode = totpCode.trim();
    if (currentPassword.isEmpty || trimmedCode.length != 6) {
      throw const ServerSettingsException(
        'Enter your password and authenticator code',
      );
    }
    final decoded = await _jsonRequest(
      'POST',
      '/api/2fa/backup-codes/regenerate',
      body: {'currentPassword': currentPassword, 'totpCode': trimmedCode},
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Backup code response was invalid');
    }
    return TwoFactorBackupCodes.fromJson(map);
  }

  @override
  Future<void> disableTwoFactor({
    required String currentPassword,
    required String code,
  }) async {
    final trimmedCode = code.trim();
    if (currentPassword.isEmpty || trimmedCode.isEmpty) {
      throw const ServerSettingsException('Enter your password and code');
    }
    await _jsonRequest(
      'POST',
      '/api/2fa/disable',
      body: {'currentPassword': currentPassword, 'code': trimmedCode},
    );
  }

  @override
  Future<ServerSettingsCurrentUserMedia> updateCurrentUserProfile({
    required UserProfilePatch patch,
  }) async {
    final body = patch.toJson();
    if (body.isEmpty) {
      throw const ServerSettingsException('No profile changes to save');
    }
    final decoded = await _jsonRequest('PATCH', '/api/users/me', body: body);
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Profile response was invalid');
    }
    return ServerSettingsCurrentUserMedia.fromJson(map);
  }

  @override
  Future<ServerSettingsCurrentUserMedia> changeCurrentUserPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      throw const ServerSettingsException(
        'Enter your current and new password',
      );
    }
    final decoded = await _jsonRequest(
      'PATCH',
      '/api/users/me',
      body: {'currentPassword': currentPassword, 'password': newPassword},
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Password response was invalid');
    }
    return ServerSettingsCurrentUserMedia.fromJson(map);
  }

  @override
  Future<VerdantUser> setCurrentUsername({required String username}) async {
    final sanitized = sanitizeUsernameInput(username, maxLength: 32);
    if (sanitized.isEmpty) {
      throw const ServerSettingsException('Enter a username');
    }
    final decoded = await _jsonRequest(
      'POST',
      '/api/users/me/username',
      body: {'username': sanitized},
    );
    final user = _mapValue(decoded)?['user'];
    final map = _mapValue(user);
    if (map == null) {
      throw const ServerSettingsException('Username response was invalid');
    }
    return VerdantUser.fromJson(map);
  }

  @override
  Future<EmailChangeStartResult> startCurrentUserEmailChange({
    required String currentEmail,
    required String newEmail,
    required String currentPassword,
  }) async {
    final decoded = await _jsonRequest(
      'POST',
      '/api/users/me/change-email',
      body: {
        'currentEmail': currentEmail.trim(),
        'newEmail': newEmail.trim(),
        'currentPassword': currentPassword,
      },
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Email change response was invalid');
    }
    return EmailChangeStartResult.fromJson(map);
  }

  @override
  Future<void> confirmCurrentUserEmailChange({required String code}) async {
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      throw const ServerSettingsException('Enter the verification code');
    }
    await _jsonRequest(
      'POST',
      '/api/users/me/change-email/confirm',
      body: {'code': trimmedCode},
    );
  }

  @override
  Future<UserAvatarUpdate> uploadUserAvatar({
    required ServerSettingsUpload upload,
  }) async {
    final decoded = await _multipartFileRequest(
      'POST',
      '/api/users/me/avatar',
      upload,
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Avatar response was invalid');
    }
    return UserAvatarUpdate.fromJson(map);
  }

  @override
  Future<UserAvatarUpdate> deleteUserAvatar() async {
    final decoded = await _jsonRequest('DELETE', '/api/users/me/avatar');
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Avatar response was invalid');
    }
    return UserAvatarUpdate.fromJson(map);
  }

  @override
  Future<UserProfileBannerUpdate> uploadUserProfileBanner({
    required ServerSettingsUpload upload,
  }) async {
    final decoded = await _multipartFileRequest(
      'POST',
      '/api/users/me/banner',
      upload,
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException(
        'Profile banner response was invalid',
      );
    }
    return UserProfileBannerUpdate.fromJson(map);
  }

  @override
  Future<UserProfileBannerUpdate> updateUserProfileBannerCrop({
    required BannerCrop crop,
  }) async {
    final decoded = await _jsonRequest(
      'PATCH',
      '/api/users/me/banner/crop',
      body: {'bannerCrop': crop.normalized().toJson()},
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException(
        'Profile banner crop response was invalid',
      );
    }
    return UserProfileBannerUpdate.fromJson(map);
  }

  @override
  Future<UserProfileBannerUpdate> deleteUserProfileBanner() async {
    final decoded = await _jsonRequest('DELETE', '/api/users/me/banner');
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException(
        'Profile banner response was invalid',
      );
    }
    return UserProfileBannerUpdate.fromJson(map);
  }

  @override
  Future<UserMemberListBannerUpdate> uploadMemberListBanner({
    required ServerSettingsUpload upload,
  }) async {
    final decoded = await _multipartFileRequest(
      'POST',
      '/api/users/me/member-list-banner',
      upload,
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException(
        'Member list banner response was invalid',
      );
    }
    return UserMemberListBannerUpdate.fromJson(map);
  }

  @override
  Future<UserMemberListBannerUpdate> updateMemberListBannerCrop({
    required BannerCrop crop,
  }) async {
    final decoded = await _jsonRequest(
      'PATCH',
      '/api/users/me/member-list-banner/crop',
      body: {'bannerCrop': crop.normalized().toJson()},
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException(
        'Member list banner crop response was invalid',
      );
    }
    return UserMemberListBannerUpdate.fromJson(map);
  }

  @override
  Future<UserMemberListBannerUpdate> deleteMemberListBanner() async {
    final decoded = await _jsonRequest(
      'DELETE',
      '/api/users/me/member-list-banner',
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException(
        'Member list banner response was invalid',
      );
    }
    return UserMemberListBannerUpdate.fromJson(map);
  }

  @override
  Future<List<MemberSeed>> loadChannelActivity({
    required String channelId,
  }) async {
    final id = _safeRouteLocalId(
      channelId,
      expectedNetworkId: networkIdFromApiOrigin(apiOrigin),
      entityLabel: 'Channel',
    );
    final decoded = await _jsonRequest(
      'GET',
      '/api/channels/${Uri.encodeComponent(id)}/activity',
    );
    if (decoded is! List) {
      throw const ServerSettingsException(
        'Channel activity response was invalid',
      );
    }
    final networkId = networkIdFromApiOrigin(apiOrigin);
    return [
      for (final item in decoded)
        if (_mapValue(item) case final map?)
          _channelActivityMemberItem(networkId, map),
    ];
  }

  @override
  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final id = _safeRouteLocalId(
      channelId,
      expectedNetworkId: expectedNetworkId,
      entityLabel: 'Channel',
    );
    final before = beforeMessageId == null
        ? null
        : _safeRouteLocalId(
            beforeMessageId,
            expectedNetworkId: expectedNetworkId,
            entityLabel: 'Message',
          );
    final safeLimit = limit.clamp(1, 50).toInt();
    final query = <String, String>{'limit': safeLimit.toString()};
    if (before != null) {
      query['before'] = before;
    }
    final queryString = Uri(queryParameters: query).query;
    final decoded = await _jsonRequest(
      'GET',
      '/api/channels/${Uri.encodeComponent(id)}/messages?$queryString',
    );
    if (decoded is! List) {
      throw const ServerSettingsException('Message response was invalid');
    }
    final rows = <({int index, Map<String, Object?> map})>[];
    for (var index = 0; index < decoded.length; index += 1) {
      final map = _mapValue(decoded[index]);
      if (map != null) {
        rows.add((index: index, map: map));
      }
    }
    rows.sort(_messageRowOldestFirst);
    return [
      for (final row in rows)
        _messageFromJson(row.map, currentUserId: currentUserId),
    ];
  }

  @override
  Future<void> deleteChannelMessage({
    required String channelId,
    required String messageId,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final channel = _safeMessageMutationRouteLocalId(
      channelId,
      expectedNetworkId,
      entityLabel: 'Channel',
    );
    final message = _safeMessageMutationRouteLocalId(
      messageId,
      expectedNetworkId,
      entityLabel: 'Message',
    );
    await _jsonRequest(
      'DELETE',
      '/api/channels/${Uri.encodeComponent(channel)}/messages/${Uri.encodeComponent(message)}',
    );
  }

  @override
  Future<ServerSettingsServer> createServer({required String name}) async {
    final trimmed = sanitizeDisplayNameInput(name);
    if (trimmed.length < 2) {
      throw const ServerSettingsException('Enter a server name');
    }
    final decoded = await _jsonRequest(
      'POST',
      '/api/servers',
      body: {'name': trimmed},
    );
    return _serverFromDecoded(decoded);
  }

  @override
  Future<ServerSettingsListItemSeed> createInvite({
    required String serverId,
    int? maxUses,
    Duration? expiresIn,
  }) async {
    final id = _safeRouteLocalId(
      serverId,
      expectedNetworkId: networkIdFromApiOrigin(apiOrigin),
      entityLabel: 'Server',
    );
    final body = <String, Object?>{};
    if (maxUses != null) {
      body['maxUses'] = maxUses;
    }
    if (expiresIn != null) {
      body['expiresIn'] = expiresIn.inSeconds;
    }
    final decoded = await _jsonRequest(
      'POST',
      '/api/servers/${Uri.encodeComponent(id)}/invites',
      body: body,
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Invite response was invalid');
    }
    return _inviteItem(map);
  }

  @override
  Future<void> revokeInvite({
    required String serverId,
    required String code,
  }) async {
    final id = _safeRouteLocalId(
      serverId,
      expectedNetworkId: networkIdFromApiOrigin(apiOrigin),
      entityLabel: 'Server',
    );
    final inviteCode = _safeInviteCode(code);
    await _jsonRequest(
      'DELETE',
      '/api/servers/${Uri.encodeComponent(id)}/invites/${Uri.encodeComponent(inviteCode)}',
    );
  }

  @override
  Future<void> leaveServer({required String serverId}) async {
    final id = _safeRouteLocalId(
      serverId,
      expectedNetworkId: networkIdFromApiOrigin(apiOrigin),
      entityLabel: 'Server',
    );
    await _jsonRequest(
      'DELETE',
      '/api/servers/${Uri.encodeComponent(id)}/leave',
    );
  }

  @override
  Future<ServerInvitePreview> previewInvite({required String code}) async {
    final inviteCode = _safeInviteCode(code);
    final decoded = await _jsonRequest(
      'GET',
      '/api/invites/${Uri.encodeComponent(inviteCode)}',
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Invite response was invalid');
    }
    try {
      return ServerInvitePreview.fromJson(map);
    } on FormatException {
      throw const ServerSettingsException('Invite response was invalid');
    }
  }

  @override
  Future<ServerSettingsServer> acceptInvite({required String code}) async {
    final inviteCode = _safeInviteCode(code);
    final decoded = await _jsonRequest(
      'POST',
      '/api/invites/${Uri.encodeComponent(inviteCode)}/accept',
    );
    return _serverFromDecoded(decoded);
  }

  @override
  Future<ServerSettingsServer> updateServer({
    required String serverId,
    required ServerSettingsPatch patch,
  }) async {
    final body = patch.toJson();
    if (body.isEmpty) {
      throw const ServerSettingsException('No server changes to save');
    }
    final decoded = await _jsonRequest(
      'PATCH',
      '/api/servers/${Uri.encodeComponent(serverId)}',
      body: body,
    );
    return _serverFromDecoded(decoded);
  }

  @override
  Future<ServerSettingsServer> uploadServerIcon({
    required String serverId,
    required ServerSettingsUpload upload,
  }) async {
    final decoded = await _multipartFileRequest(
      'POST',
      '/api/servers/${Uri.encodeComponent(serverId)}/icon',
      upload,
    );
    return _serverFromDecoded(decoded);
  }

  @override
  Future<ServerSettingsServer> deleteServerIcon({
    required String serverId,
  }) async {
    final decoded = await _jsonRequest(
      'DELETE',
      '/api/servers/${Uri.encodeComponent(serverId)}/icon',
    );
    return _serverFromDecoded(decoded);
  }

  @override
  Future<ServerSettingsServer> uploadServerBanner({
    required String serverId,
    required ServerSettingsUpload upload,
  }) async {
    final decoded = await _multipartFileRequest(
      'POST',
      '/api/servers/${Uri.encodeComponent(serverId)}/banner',
      upload,
    );
    return _serverFromDecoded(decoded);
  }

  @override
  Future<ServerSettingsServer> updateBannerCrop({
    required String serverId,
    required BannerCrop crop,
  }) async {
    final decoded = await _jsonRequest(
      'PATCH',
      '/api/servers/${Uri.encodeComponent(serverId)}/banner/crop',
      body: {'bannerCrop': crop.normalized().toJson()},
    );
    return _serverFromDecoded(decoded);
  }

  @override
  Future<ServerSettingsServer> deleteServerBanner({
    required String serverId,
  }) async {
    final decoded = await _jsonRequest(
      'DELETE',
      '/api/servers/${Uri.encodeComponent(serverId)}/banner',
    );
    return _serverFromDecoded(decoded);
  }

  @override
  Future<ServerSettingsChannelSeed> updateChannel({
    required String channelId,
    required ChannelSettingsPatch patch,
  }) async {
    final body = patch.toJson();
    if (body.isEmpty) {
      throw const ServerSettingsException('No channel changes to save');
    }
    final id = _safeChannelWriteLocalId(
      channelId,
      networkIdFromApiOrigin(apiOrigin),
    );
    final decoded = await _jsonRequest(
      'PATCH',
      '/api/channels/${Uri.encodeComponent(id)}',
      body: body,
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Channel response was invalid');
    }
    return _channelFromJson(map);
  }

  @override
  Future<ServerSettingsListItemSeed> createRole({
    required String serverId,
    required ServerRolePatch patch,
  }) async {
    final body = patch.toJson();
    if (body['name'] is! String) {
      throw const ServerSettingsException('Enter a role name');
    }
    final id = _safeRoleRouteLocalId(
      serverId,
      networkIdFromApiOrigin(apiOrigin),
      entityLabel: 'Server',
    );
    final decoded = await _jsonRequest(
      'POST',
      '/api/servers/${Uri.encodeComponent(id)}/roles',
      body: body,
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Role response was invalid');
    }
    return _roleItem(map);
  }

  @override
  Future<ServerSettingsListItemSeed> updateRole({
    required String serverId,
    required String roleId,
    required ServerRolePatch patch,
  }) async {
    final body = patch.toJson();
    if (body.isEmpty) {
      throw const ServerSettingsException('No role changes to save');
    }
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final roleLocalId = _safeRoleRouteLocalId(
      roleId,
      expectedNetworkId,
      entityLabel: 'Role',
    );
    final decoded = await _jsonRequest(
      'PATCH',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/roles/${Uri.encodeComponent(roleLocalId)}',
      body: body,
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Role response was invalid');
    }
    return _roleItem(map);
  }

  @override
  Future<void> deleteRole({
    required String serverId,
    required String roleId,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final roleLocalId = _safeRoleRouteLocalId(
      roleId,
      expectedNetworkId,
      entityLabel: 'Role',
    );
    await _jsonRequest(
      'DELETE',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/roles/${Uri.encodeComponent(roleLocalId)}',
    );
  }

  @override
  Future<ServerSettingsListItemSeed> createFeed({
    required String serverId,
    required ServerFeedPatch patch,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final body = patch.toJson(
      localRoleId: (roleId) => _safeRoleRouteLocalId(
        roleId,
        expectedNetworkId,
        entityLabel: 'Feed role',
      ),
    );
    if (body['name'] is! String) {
      throw const ServerSettingsException('Enter a feed name');
    }
    final decoded = await _jsonRequest(
      'POST',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/feeds',
      body: body,
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Feed response was invalid');
    }
    return _feedItem(map);
  }

  @override
  Future<ServerSettingsListItemSeed> updateFeed({
    required String serverId,
    required String feedId,
    required ServerFeedPatch patch,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final feedLocalId = _safeRoleRouteLocalId(
      feedId,
      expectedNetworkId,
      entityLabel: 'Feed',
    );
    final body = patch.toJson(
      localRoleId: (roleId) => _safeRoleRouteLocalId(
        roleId,
        expectedNetworkId,
        entityLabel: 'Feed role',
      ),
    );
    if (body.isEmpty) {
      throw const ServerSettingsException('No feed changes to save');
    }
    final decoded = await _jsonRequest(
      'PATCH',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/feeds/${Uri.encodeComponent(feedLocalId)}',
      body: body,
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Feed response was invalid');
    }
    return _feedItem(map);
  }

  @override
  Future<void> deleteFeed({
    required String serverId,
    required String feedId,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final feedLocalId = _safeRoleRouteLocalId(
      feedId,
      expectedNetworkId,
      entityLabel: 'Feed',
    );
    await _jsonRequest(
      'DELETE',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/feeds/${Uri.encodeComponent(feedLocalId)}',
    );
  }

  @override
  Future<void> kickMember({
    required String serverId,
    required String userId,
    String? reason,
  }) async {
    await _moderateMember(
      method: 'POST',
      serverId: serverId,
      userId: userId,
      routeSuffix: 'kick',
      reason: reason,
    );
  }

  @override
  Future<void> banMember({
    required String serverId,
    required String userId,
    String? reason,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final userLocalId = _safeRoleRouteLocalId(
      userId,
      expectedNetworkId,
      entityLabel: 'Member',
    );
    await _jsonRequest(
      'POST',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/bans/${Uri.encodeComponent(userLocalId)}',
      body: {'reason': _normalizedOptionalText(reason)},
    );
  }

  @override
  Future<void> unbanMember({
    required String serverId,
    required String userId,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final userLocalId = _safeRoleRouteLocalId(
      userId,
      expectedNetworkId,
      entityLabel: 'Member',
    );
    await _jsonRequest(
      'DELETE',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/bans/${Uri.encodeComponent(userLocalId)}',
    );
  }

  Future<void> _moderateMember({
    required String method,
    required String serverId,
    required String userId,
    required String routeSuffix,
    String? reason,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final userLocalId = _safeRoleRouteLocalId(
      userId,
      expectedNetworkId,
      entityLabel: 'Member',
    );
    await _jsonRequest(
      method,
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/members/${Uri.encodeComponent(userLocalId)}/$routeSuffix',
      body: {'reason': _normalizedOptionalText(reason)},
    );
  }

  @override
  Future<List<ServerSettingsListItemSeed>> listBans({
    required String serverId,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final decoded = await _jsonRequest(
      'GET',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/bans',
    );
    if (decoded is! List) {
      throw const ServerSettingsException('Ban list response was invalid');
    }
    return [
      for (final item in decoded)
        if (_mapValue(item) case final map?) _banItem(expectedNetworkId, map),
    ];
  }

  @override
  Future<ServerSettingsAuditPage> listAuditEvents({
    required String serverId,
    int limit = 50,
    String? beforeEventId,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final cappedLimit = limit.clamp(1, 100);
    final beforeLocalId = beforeEventId == null
        ? null
        : _safeRoleRouteLocalId(
            beforeEventId,
            expectedNetworkId,
            entityLabel: 'Audit event',
          );
    final query = StringBuffer('?limit=$cappedLimit');
    if (beforeLocalId != null) {
      query.write('&before=${Uri.encodeQueryComponent(beforeLocalId)}');
    }
    final decoded = await _jsonRequest(
      'GET',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/audit-log$query',
    );
    final map = _mapValue(decoded);
    final entries = map?['entries'];
    if (entries is! List) {
      throw const ServerSettingsException('Audit log response was invalid');
    }
    return ServerSettingsAuditPage(
      entries: [
        for (final item in entries)
          if (_mapValue(item) case final itemMap?)
            _auditItem(expectedNetworkId, itemMap),
      ],
      hasMore: map?['hasMore'] == true,
    );
  }

  @override
  Future<ServerSettingsListItemSeed> createBot({
    required String serverId,
    required ServerBotPatch patch,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final body = patch.toJson();
    if (body['name'] is! String) {
      throw const ServerSettingsException('Enter a bot name');
    }
    final decoded = await _jsonRequest(
      'POST',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/bots',
      body: body,
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Bot response was invalid');
    }
    return _botItem(map);
  }

  @override
  Future<ServerSettingsListItemSeed> updateBot({
    required String serverId,
    required String botId,
    required ServerBotPatch patch,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final botLocalId = _safeRoleRouteLocalId(
      botId,
      expectedNetworkId,
      entityLabel: 'Bot',
    );
    final body = patch.toJson();
    if (body.isEmpty) {
      throw const ServerSettingsException('No bot changes to save');
    }
    final decoded = await _jsonRequest(
      'PATCH',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/bots/${Uri.encodeComponent(botLocalId)}',
      body: body,
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Bot response was invalid');
    }
    return _botItem(map);
  }

  @override
  Future<void> deleteBot({
    required String serverId,
    required String botId,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final botLocalId = _safeRoleRouteLocalId(
      botId,
      expectedNetworkId,
      entityLabel: 'Bot',
    );
    await _jsonRequest(
      'DELETE',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/bots/${Uri.encodeComponent(botLocalId)}',
    );
  }

  @override
  Future<BotTokenResult> generateBotToken({
    required String serverId,
    required String botId,
    required BotTokenPatch patch,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final botLocalId = _safeRoleRouteLocalId(
      botId,
      expectedNetworkId,
      entityLabel: 'Bot',
    );
    final body = patch.toJson(
      localFeedId: (feedId) =>
          _safeRoleRouteLocalId(feedId, expectedNetworkId, entityLabel: 'Feed'),
      localChannelId: (channelId) => _safeRoleRouteLocalId(
        channelId,
        expectedNetworkId,
        entityLabel: 'Channel',
      ),
    );
    final decoded = await _jsonRequest(
      'POST',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/bots/${Uri.encodeComponent(botLocalId)}/tokens',
      body: body,
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Bot token response was invalid');
    }
    return BotTokenResult.fromJson(map);
  }

  @override
  Future<ServerSettingsUploadPreview> loadEmojiUploadPreview({
    required ServerSettingsUpload upload,
  }) async {
    return _loadCustomExpressionUploadPreview(
      upload: upload,
      kind: CustomExpressiveAssetKind.emoji,
    );
  }

  @override
  Future<ServerSettingsUploadPreview> loadStickerUploadPreview({
    required ServerSettingsUpload upload,
  }) async {
    return _loadCustomExpressionUploadPreview(
      upload: upload,
      kind: CustomExpressiveAssetKind.sticker,
    );
  }

  Future<ServerSettingsUploadPreview> _loadCustomExpressionUploadPreview({
    required ServerSettingsUpload upload,
    required CustomExpressiveAssetKind kind,
  }) async {
    try {
      final file = File(upload.path);
      final size = await file.length();
      final maxBytes = customExpressionMaxBytes(kind);
      final bytes = size <= maxBytes ? await file.readAsBytes() : Uint8List(0);
      return ServerSettingsUploadPreview(previewBytes: bytes, sizeBytes: size);
    } on FileSystemException {
      throw const ServerSettingsException('Selected file could not be read.');
    }
  }

  @override
  Future<ServerSettingsListItemSeed> uploadEmoji({
    required String serverId,
    required String name,
    required ServerSettingsUpload upload,
  }) async {
    return _uploadCustomExpression(
      serverId: serverId,
      name: name,
      upload: upload,
      kind: CustomExpressiveAssetKind.emoji,
    );
  }

  @override
  Future<ServerSettingsListItemSeed> uploadSticker({
    required String serverId,
    required String name,
    required ServerSettingsUpload upload,
  }) async {
    return _uploadCustomExpression(
      serverId: serverId,
      name: name,
      upload: upload,
      kind: CustomExpressiveAssetKind.sticker,
    );
  }

  Future<ServerSettingsListItemSeed> _uploadCustomExpression({
    required String serverId,
    required String name,
    required ServerSettingsUpload upload,
    required CustomExpressiveAssetKind kind,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final nameError = validateCustomExpressionName(kind: kind, value: name);
    if (nameError != null) {
      throw ServerSettingsException(nameError);
    }
    final normalizedName = normalizeCustomExpressionName(name);
    final decoded = await _multipartFileRequest(
      'POST',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/${kind.label}s',
      upload,
      fields: {'name': normalizedName},
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw ServerSettingsException('${kind.titleLabel} response was invalid');
    }
    return kind == CustomExpressiveAssetKind.emoji
        ? _emojiItem(map)
        : _stickerItem(map);
  }

  @override
  Future<ServerSettingsListItemSeed> renameEmoji({
    required String serverId,
    required String emojiId,
    required String name,
  }) async {
    return _renameCustomExpression(
      serverId: serverId,
      expressionId: emojiId,
      name: name,
      kind: CustomExpressiveAssetKind.emoji,
    );
  }

  @override
  Future<ServerSettingsListItemSeed> renameSticker({
    required String serverId,
    required String stickerId,
    required String name,
  }) async {
    return _renameCustomExpression(
      serverId: serverId,
      expressionId: stickerId,
      name: name,
      kind: CustomExpressiveAssetKind.sticker,
    );
  }

  Future<ServerSettingsListItemSeed> _renameCustomExpression({
    required String serverId,
    required String expressionId,
    required String name,
    required CustomExpressiveAssetKind kind,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final expressionLocalId = _safeRoleRouteLocalId(
      expressionId,
      expectedNetworkId,
      entityLabel: kind.titleLabel,
    );
    final nameError = validateCustomExpressionName(kind: kind, value: name);
    if (nameError != null) {
      throw ServerSettingsException(nameError);
    }
    final normalizedName = normalizeCustomExpressionName(name);
    final decoded = await _jsonRequest(
      'PATCH',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/${kind.label}s/${Uri.encodeComponent(expressionLocalId)}',
      body: {'name': normalizedName},
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw ServerSettingsException('${kind.titleLabel} response was invalid');
    }
    return kind == CustomExpressiveAssetKind.emoji
        ? _emojiItem(map)
        : _stickerItem(map);
  }

  @override
  Future<void> deleteEmoji({
    required String serverId,
    required String emojiId,
  }) async {
    await _deleteCustomExpression(
      serverId: serverId,
      expressionId: emojiId,
      kind: CustomExpressiveAssetKind.emoji,
    );
  }

  @override
  Future<void> deleteSticker({
    required String serverId,
    required String stickerId,
  }) async {
    await _deleteCustomExpression(
      serverId: serverId,
      expressionId: stickerId,
      kind: CustomExpressiveAssetKind.sticker,
    );
  }

  Future<void> _deleteCustomExpression({
    required String serverId,
    required String expressionId,
    required CustomExpressiveAssetKind kind,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final expressionLocalId = _safeRoleRouteLocalId(
      expressionId,
      expectedNetworkId,
      entityLabel: kind.titleLabel,
    );
    await _jsonRequest(
      'DELETE',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/${kind.label}s/${Uri.encodeComponent(expressionLocalId)}',
    );
  }

  @override
  Future<List<FeedAnnouncementRecord>> listFeedAnnouncements({
    required String serverId,
    required String feedId,
    int limit = 25,
    String? beforeAnnouncementId,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    _safeRoleRouteLocalId(serverId, expectedNetworkId, entityLabel: 'Server');
    final feedLocalId = _safeRoleRouteLocalId(
      feedId,
      expectedNetworkId,
      entityLabel: 'Feed',
    );
    final cappedLimit = limit.clamp(1, 50);
    final beforeLocalId = beforeAnnouncementId == null
        ? null
        : _safeRoleRouteLocalId(
            beforeAnnouncementId,
            expectedNetworkId,
            entityLabel: 'Announcement',
          );
    final query = StringBuffer('?limit=$cappedLimit');
    if (beforeLocalId != null) {
      query.write('&before=${Uri.encodeQueryComponent(beforeLocalId)}');
    }
    final decoded = await _jsonRequest(
      'GET',
      '/api/feeds/${Uri.encodeComponent(feedLocalId)}/announcements$query',
    );
    if (decoded is! List) {
      throw const ServerSettingsException(
        'Announcement list response was invalid',
      );
    }
    return [
      for (final item in decoded)
        if (_mapValue(item) case final map?) _announcementRecord(map),
    ];
  }

  @override
  Future<FeedAnnouncementRecord> createFeedAnnouncement({
    required String serverId,
    required String feedId,
    required FeedAnnouncementDraft draft,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    _safeRoleRouteLocalId(serverId, expectedNetworkId, entityLabel: 'Server');
    final feedLocalId = _safeRoleRouteLocalId(
      feedId,
      expectedNetworkId,
      entityLabel: 'Feed',
    );
    final decoded = await _jsonRequest(
      'POST',
      '/api/feeds/${Uri.encodeComponent(feedLocalId)}/announcements',
      body: draft.toJson(),
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Announcement response was invalid');
    }
    return _announcementRecord(map);
  }

  @override
  Future<FeedAnnouncementRecord> updateFeedAnnouncement({
    required String serverId,
    required String feedId,
    required String announcementId,
    required FeedAnnouncementDraft draft,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    _safeRoleRouteLocalId(serverId, expectedNetworkId, entityLabel: 'Server');
    final feedLocalId = _safeRoleRouteLocalId(
      feedId,
      expectedNetworkId,
      entityLabel: 'Feed',
    );
    final announcementLocalId = _safeRoleRouteLocalId(
      announcementId,
      expectedNetworkId,
      entityLabel: 'Announcement',
    );
    final decoded = await _jsonRequest(
      'PATCH',
      '/api/feeds/${Uri.encodeComponent(feedLocalId)}/announcements/${Uri.encodeComponent(announcementLocalId)}',
      body: draft.toJson(),
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Announcement response was invalid');
    }
    return _announcementRecord(map);
  }

  @override
  Future<void> deleteFeedAnnouncement({
    required String serverId,
    required String feedId,
    required String announcementId,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    _safeRoleRouteLocalId(serverId, expectedNetworkId, entityLabel: 'Server');
    final feedLocalId = _safeRoleRouteLocalId(
      feedId,
      expectedNetworkId,
      entityLabel: 'Feed',
    );
    final announcementLocalId = _safeRoleRouteLocalId(
      announcementId,
      expectedNetworkId,
      entityLabel: 'Announcement',
    );
    await _jsonRequest(
      'DELETE',
      '/api/feeds/${Uri.encodeComponent(feedLocalId)}/announcements/${Uri.encodeComponent(announcementLocalId)}',
    );
  }

  @override
  Future<List<String>> setOwnNameColor({
    required String serverId,
    required String? roleId,
  }) async {
    final expectedNetworkId = networkIdFromApiOrigin(apiOrigin);
    final serverLocalId = _safeRoleRouteLocalId(
      serverId,
      expectedNetworkId,
      entityLabel: 'Server',
    );
    final roleLocalId = roleId == null
        ? null
        : _safeRoleRouteLocalId(roleId, expectedNetworkId, entityLabel: 'Role');
    final decoded = await _jsonRequest(
      'PATCH',
      '/api/servers/${Uri.encodeComponent(serverLocalId)}/members/@me/name-color',
      body: {'roleId': roleLocalId},
    );
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Name color response was invalid');
    }
    return _stringList(map['roleIds']);
  }

  Future<List<ServerSettingsChannelSeed>> _loadChannels(String serverId) async {
    try {
      final decoded = await _jsonRequest(
        'GET',
        '/api/servers/${Uri.encodeComponent(serverId)}/layout',
      );
      final map = _mapValue(decoded);
      final channels = map?['channels'];
      if (channels is! List) {
        return const [];
      }
      return [
        for (final item in channels)
          if (_mapValue(item) case final channel?) _channelFromJson(channel),
      ].where((channel) => channel.id.isNotEmpty).toList(growable: false);
    } on ServerSettingsException catch (error) {
      if (_isServerAccessDeniedMessage(error.message)) {
        rethrow;
      }
      return const [];
    }
  }

  bool _isServerAccessDeniedMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('not have permission') ||
        normalized.contains('forbidden') ||
        normalized.contains('do not have access') ||
        normalized.contains("don't have access") ||
        normalized.contains('server was not found');
  }

  Future<_InstanceMetadata> _loadInstanceMetadata() async {
    try {
      final decoded = await _publicJsonRequest('GET', '/api/instance');
      return _instanceMetadataFromJson(_mapValue(decoded));
    } on ServerSettingsException {
      return _InstanceMetadata(
        mediaPolicy: ServerMediaPolicy.fromOrigins(apiOrigin: apiOrigin),
        entitlements: const WorkspaceEntitlements.disabled(),
      );
    }
  }

  _InstanceMetadata _instanceMetadataFromJson(Map<String, Object?>? map) {
    return _InstanceMetadata(
      mediaPolicy: ServerMediaPolicy.fromOrigins(
        apiOrigin: apiOrigin,
        apiUrl: _nullableString(map?['apiUrl']),
        publicUrl: _nullableString(map?['publicUrl']),
        cdnUrl: _nullableString(map?['cdnUrl']),
      ),
      entitlements: WorkspaceEntitlements.fromInstanceJsonValue(map),
    );
  }

  Future<List<ServerSettingsListItemSeed>> _loadListItems(
    String path,
    ServerSettingsListItemSeed Function(Map<String, Object?> json) convert,
  ) async {
    try {
      final decoded = await _jsonRequest('GET', path);
      if (decoded is! List) {
        return const [];
      }
      return [
        for (final item in decoded)
          if (_mapValue(item) case final map?) convert(map),
      ];
    } on ServerSettingsException {
      return const [];
    }
  }

  Future<List<ServerSettingsListItemSeed>> _loadAuditItems(
    String serverId,
  ) async {
    try {
      return (await listAuditEvents(serverId: serverId)).entries;
    } on ServerSettingsException {
      return const [];
    }
  }

  void close() {
    _httpClient.close(force: true);
    _credentialRefresher.close();
  }

  Future<Object?> _jsonRequest(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final totalWatch = Stopwatch()..start();
    final endpoint = _diagnosticEndpoint(path);
    var credentials = await _readCredentials();
    var refreshedCredentials = false;
    var retriedRateLimit = false;
    var attempt = 0;
    while (true) {
      attempt += 1;
      final attemptWatch = Stopwatch()..start();
      await _paceJsonRequest(method, endpoint);
      final requestId = _beginServerSettingsHttpDiagnostic(
        method: method,
        endpoint: endpoint,
        attempt: attempt,
      );
      try {
        final request = await _openRequest(method, path, credentials);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (body != null) {
          request.headers.set(
            HttpHeaders.contentTypeHeader,
            'application/json',
          );
          request.write(jsonEncode(body));
        }

        final response = await request.close().timeout(timeout);
        _certificatePinningPolicy.verifyResponseCertificate(
          apiOrigin: apiOrigin,
          response: response,
        );
        final decoded = await _decodeJsonResponse(response);
        if (response.statusCode == HttpStatus.unauthorized &&
            !refreshedCredentials) {
          debugPrint(
            'verdant.http server_settings.request.retry '
            '{method: $method, endpoint: $endpoint, reason: unauthorized, '
            'statusCode: ${response.statusCode}, requestId: $requestId, '
            'attempt: $attempt, ms: ${attemptWatch.elapsedMilliseconds}'
            '${_serverSettingsResponseDiagnosticSuffix(response)}}',
          );
          refreshedCredentials = true;
          credentials = await _refreshCredentials(credentials);
          continue;
        }
        if (method.toUpperCase() == 'GET' &&
            response.statusCode == HttpStatus.tooManyRequests &&
            !retriedRateLimit) {
          final retryDelay = _rateLimitRetryDelay(response, decoded);
          debugPrint(
            'verdant.http server_settings.request.retry '
            '{method: $method, endpoint: $endpoint, reason: rate_limited, '
            'statusCode: ${response.statusCode}, requestId: $requestId, '
            'attempt: $attempt, retryDelayMs: ${retryDelay.inMilliseconds}, '
            'ms: ${attemptWatch.elapsedMilliseconds}'
            '${_serverSettingsResponseDiagnosticSuffix(response)}}',
          );
          retriedRateLimit = true;
          await Future<void>.delayed(retryDelay);
          continue;
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          debugPrint(
            'verdant.http server_settings.request.result '
            '{method: $method, endpoint: $endpoint, status: failed, '
            'statusCode: ${response.statusCode}, requestId: $requestId, '
            'attempt: $attempt, ms: ${totalWatch.elapsedMilliseconds}'
            '${_serverSettingsResponseDiagnosticSuffix(response)}}',
          );
          throw ServerSettingsException(
            _errorMessage(response.statusCode, decoded, 'Request failed'),
            isAuthExpired: response.statusCode == HttpStatus.unauthorized,
            statusCode: response.statusCode,
          );
        }
        debugPrint(
          'verdant.http server_settings.request.result '
          '{method: $method, endpoint: $endpoint, status: ok, '
          'statusCode: ${response.statusCode}, requestId: $requestId, '
          'attempt: $attempt, ms: ${totalWatch.elapsedMilliseconds}'
          '${_serverSettingsResponseDiagnosticSuffix(response)}}',
        );
        return decoded;
      } catch (error) {
        if (error is ServerSettingsException) {
          rethrow;
        }
        debugPrint(
          'verdant.http server_settings.request.error '
          '{method: $method, endpoint: $endpoint, requestId: $requestId, '
          'attempt: $attempt, errorType: ${error.runtimeType}, '
          'ms: ${attemptWatch.elapsedMilliseconds}}',
        );
        rethrow;
      } finally {
        _endServerSettingsHttpDiagnostic();
      }
    }
  }

  Future<Object?> _publicJsonRequest(String method, String path) async {
    _assertApiPath(path);
    await _paceJsonRequest(method, _diagnosticEndpoint(path));
    await _certificatePinningPolicy.verifyPinnedHost(
      httpClient: _httpClient,
      apiOrigin: apiOrigin,
      timeout: timeout,
    );
    final request = await _httpClient
        .openUrl(method, Uri.parse('$apiOrigin$path'))
        .timeout(timeout);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.userAgentHeader, verdantFlutterUserAgent);
    request.headers.set('X-Client-Version', verdantClientVersion);

    final response = await request.close().timeout(timeout);
    _certificatePinningPolicy.verifyResponseCertificate(
      apiOrigin: apiOrigin,
      response: response,
    );
    final decoded = await _decodeJsonResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServerSettingsException(
        _errorMessage(response.statusCode, decoded, 'Request failed'),
        isAuthExpired: response.statusCode == HttpStatus.unauthorized,
      );
    }
    return decoded;
  }

  Future<void> _paceJsonRequest(String method, String endpoint) async {
    final delay = await _requestPacer.wait(minRequestInterval);
    if (delay <= Duration.zero) {
      return;
    }
    debugPrint(
      'verdant.http server_settings.request.paced '
      '{method: $method, endpoint: $endpoint, delayMs: ${delay.inMilliseconds}}',
    );
  }

  int _beginServerSettingsHttpDiagnostic({
    required String method,
    required String endpoint,
    required int attempt,
  }) {
    final requestId = ++_serverSettingsHttpRequestSequence;
    _serverSettingsHttpInFlight += 1;
    debugPrint(
      'verdant.http server_settings.request.start '
      '{method: $method, endpoint: $endpoint, requestId: $requestId, '
      'attempt: $attempt, inFlight: $_serverSettingsHttpInFlight}',
    );
    return requestId;
  }

  void _endServerSettingsHttpDiagnostic() {
    if (_serverSettingsHttpInFlight > 0) {
      _serverSettingsHttpInFlight -= 1;
    }
  }

  String _serverSettingsResponseDiagnosticSuffix(HttpClientResponse response) {
    final fields = <String, String>{};
    void addHeader(String field, String header) {
      final value = response.headers.value(header);
      if (value == null || value.trim().isEmpty) {
        return;
      }
      fields[field] = _shortDiagnosticHeaderValue(value);
    }

    addHeader('retryAfter', HttpHeaders.retryAfterHeader);
    addHeader('rateLimitLimit', 'ratelimit-limit');
    addHeader('rateLimitRemaining', 'ratelimit-remaining');
    addHeader('rateLimitReset', 'ratelimit-reset');
    addHeader('xRateLimitLimit', 'x-ratelimit-limit');
    addHeader('xRateLimitRemaining', 'x-ratelimit-remaining');
    addHeader('xRateLimitReset', 'x-ratelimit-reset');
    addHeader('cfCacheStatus', 'cf-cache-status');
    if (fields.isEmpty) {
      return '';
    }
    return ', headers: $fields';
  }

  Future<Object?> _multipartFileRequest(
    String method,
    String path,
    ServerSettingsUpload upload, {
    Map<String, String> fields = const {},
  }) async {
    late final File file;
    try {
      file = File(upload.path);
      if (!await file.exists()) {
        throw const ServerSettingsException('Selected file was not found');
      }
    } on FileSystemException {
      throw const ServerSettingsException('Selected file could not be read.');
    }

    var credentials = await _readCredentials();
    for (var attempt = 0; attempt < 2; attempt += 1) {
      final request = await _openRequest(method, path, credentials);
      final boundary = _multipartBoundary();
      request.headers.contentType = ContentType(
        'multipart',
        'form-data',
        parameters: {'boundary': boundary},
      );

      for (final field in fields.entries) {
        request.write('--$boundary\r\n');
        request.write(
          'Content-Disposition: form-data; '
          'name="${_safeMultipartFieldName(field.key)}"\r\n',
        );
        request.write('Content-Type: text/plain; charset=utf-8\r\n');
        request.write('\r\n');
        request.write(field.value);
        request.write('\r\n');
      }
      request.write('--$boundary\r\n');
      request.write(
        'Content-Disposition: form-data; name="file"; '
        'filename="${_safeMultipartFilename(upload.fileName)}"\r\n',
      );
      request.write('Content-Type: ${_imageContentType(upload.fileName)}\r\n');
      request.write('\r\n');
      try {
        await request.addStream(file.openRead());
      } on FileSystemException {
        throw const ServerSettingsException('Selected file could not be read.');
      }
      request.write('\r\n--$boundary--\r\n');

      final response = await request.close().timeout(timeout);
      _certificatePinningPolicy.verifyResponseCertificate(
        apiOrigin: apiOrigin,
        response: response,
      );
      final decoded = await _decodeJsonResponse(response);
      if (response.statusCode == HttpStatus.unauthorized && attempt == 0) {
        credentials = await _refreshCredentials(credentials);
        continue;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ServerSettingsException(
          _errorMessage(response.statusCode, decoded, 'Upload failed'),
          isAuthExpired: response.statusCode == HttpStatus.unauthorized,
        );
      }
      return decoded;
    }
    throw const ServerSettingsException('Upload failed');
  }

  Future<HttpClientRequest> _openRequest(
    String method,
    String path,
    AuthCredentialBundle credentials,
  ) async {
    _assertApiPath(path);

    await _certificatePinningPolicy.verifyPinnedHost(
      httpClient: _httpClient,
      apiOrigin: apiOrigin,
      timeout: timeout,
    );
    final request = await _httpClient
        .openUrl(method, Uri.parse('$apiOrigin$path'))
        .timeout(timeout);
    request.followRedirects = false;
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${credentials.accessToken}',
    );
    request.headers.set(HttpHeaders.userAgentHeader, verdantFlutterUserAgent);
    request.headers.set('X-Client-Version', verdantClientVersion);
    return request;
  }

  Future<AuthCredentialBundle> _readCredentials() async {
    try {
      return await _credentialRefresher.readCredentials();
    } on WorkspaceCredentialRefreshException catch (error) {
      throw ServerSettingsException(
        error.message,
        isAuthExpired: error.isAuthExpired,
      );
    }
  }

  Future<AuthCredentialBundle> _refreshCredentials(
    AuthCredentialBundle credentials,
  ) async {
    try {
      return await _credentialRefresher.refresh(credentials);
    } on WorkspaceCredentialRefreshException catch (error) {
      throw ServerSettingsException(
        error.message,
        isAuthExpired: error.isAuthExpired,
      );
    }
  }

  Future<Object?> _decodeJsonResponse(HttpClientResponse response) async {
    final buffer = StringBuffer();
    var length = 0;
    await for (final chunk in utf8.decoder.bind(response)) {
      length += chunk.length;
      if (length > maxResponseBytes) {
        throw const ServerSettingsException('Server response was too large');
      }
      buffer.write(chunk);
    }

    final text = buffer.toString();
    if (text.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(text);
    } on FormatException {
      if (response.statusCode >= 400) {
        return {'error': text.trim()};
      }
      throw const ServerSettingsException('Invalid server response');
    }
  }

  ServerSettingsServer _serverFromDecoded(Object? decoded) {
    final map = _mapValue(decoded);
    if (map == null) {
      throw const ServerSettingsException('Invalid server response');
    }
    return ServerSettingsServer.fromJson(map);
  }

  String _errorMessage(int statusCode, Object? decoded, String fallback) {
    if (decoded is Map<String, Object?>) {
      final error = decoded['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return switch (statusCode) {
      401 => 'Sign in again to continue',
      403 => 'You do not have permission for this server',
      404 => 'Server was not found',
      429 => 'Too many requests. Try again shortly.',
      _ => fallback,
    };
  }

  Duration _rateLimitRetryDelay(HttpClientResponse response, Object? decoded) {
    final retryAfterHeader = response.headers.value(
      HttpHeaders.retryAfterHeader,
    );
    final retryAfterSeconds = double.tryParse(retryAfterHeader ?? '');
    if (retryAfterSeconds != null && retryAfterSeconds >= 0) {
      final milliseconds = (retryAfterSeconds * 1000)
          .round()
          .clamp(0, 10000)
          .toInt();
      return Duration(milliseconds: milliseconds);
    }
    if (decoded is Map<String, Object?>) {
      final retryAfter = decoded['retryAfter'];
      if (retryAfter is num && retryAfter >= 0) {
        final milliseconds = (retryAfter * 1000)
            .round()
            .clamp(0, 10000)
            .toInt();
        return Duration(milliseconds: milliseconds);
      }
    }
    return const Duration(seconds: 1);
  }

  void _assertApiPath(String path) {
    final uri = Uri.tryParse(path);
    if (uri == null ||
        !path.startsWith('/api/') ||
        uri.hasScheme ||
        uri.host.isNotEmpty ||
        uri.hasFragment ||
        path.contains('\\') ||
        path.contains('\u0000')) {
      throw const ServerSettingsException('Invalid API path');
    }
  }

  @override
  String toString() {
    return 'ServerSettingsService(apiOrigin: $apiOrigin, token: redacted)';
  }
}

const Object _unsetPatchValue = Object();

ServerSettingsChannelSeed _channelFromJson(Map<String, Object?> json) {
  return ServerSettingsChannelSeed(
    id: _stringValue(json['id'], fallback: ''),
    name: _stringValue(json['name'], fallback: 'unnamed'),
    type: _intValue(json['type'], fallback: 0),
    topic: _nullableString(json['topic']),
    readOnly:
        json['readOnly'] == true ||
        json['read_only'] == true ||
        json['readonly'] == true,
    slowmodeSeconds: _intValue(
      json['slowmodeSeconds'] ?? json['slowmode_seconds'],
      fallback: 0,
    ).clamp(0, 21600),
  );
}

ServerSettingsListItemSeed _emojiItem(Map<String, Object?> json) {
  final name = _stringValue(json['name'], fallback: 'emoji');
  final createdBy = _stringValue(json['createdBy'], fallback: 'unknown');
  return ServerSettingsListItemSeed(
    title: ':$name:',
    subtitle: 'Created by $createdBy',
    trailing: _createdLabel(json['createdAt']),
    id: _stringValue(json['id'], fallback: ''),
    avatarUrl: _nullableString(json['url']),
  );
}

ServerSettingsListItemSeed _stickerItem(Map<String, Object?> json) {
  final name = _stringValue(json['name'], fallback: 'sticker');
  final createdBy = _stringValue(json['createdBy'], fallback: 'unknown');
  return ServerSettingsListItemSeed(
    title: ':$name:',
    subtitle: 'Created by $createdBy',
    trailing: _createdLabel(json['createdAt']),
    id: _stringValue(json['id'], fallback: ''),
    avatarUrl: _nullableString(json['url']),
  );
}

ServerSettingsListItemSeed _inviteItem(Map<String, Object?> json) {
  final uses = _intValue(json['uses'], fallback: 0);
  final maxUses = json['maxUses'] is num
      ? (json['maxUses'] as num).toInt()
      : null;
  final maxLabel = maxUses == null || maxUses == 0 ? 'unlimited' : '$maxUses';
  final code = _stringValue(json['code'], fallback: 'unknown');
  final inviterUsername = _stringValue(
    json['inviterUsername'],
    fallback: 'unknown',
  );
  return ServerSettingsListItemSeed(
    id: code,
    title: 'Invite $code',
    subtitle: 'Created by $inviterUsername',
    trailing: '$uses / $maxLabel',
    inviteCode: code,
    inviterUsername: inviterUsername,
    inviteUses: uses,
    inviteMaxUses: maxUses,
    inviteExpiresAt: _nullableString(json['expiresAt']),
    inviteCreatedAt: _nullableString(json['createdAt']),
  );
}

ServerSettingsListItemSeed _roleItem(Map<String, Object?> json) {
  final permissionLabel = _stringValue(json['permissions'], fallback: '0');
  return ServerSettingsListItemSeed(
    title: _stringValue(json['name'], fallback: 'Role'),
    subtitle: '$permissionLabel permissions',
    trailing: _nullableString(json['color']) ?? 'default',
    accent: _colorValue(json['color']),
    id: _stringValue(json['id'], fallback: ''),
    permissions: int.tryParse(permissionLabel) ?? 0,
    position: _intValue(json['position'], fallback: 0),
    colorOnly: json['colorOnly'] == true,
    showAsSection: json['showAsSection'] == true,
    colorPriority: _intValue(json['colorPriority'], fallback: 0),
  );
}

ServerSettingsListItemSeed _memberItem(Map<String, Object?> json) {
  final roleIds = json['roleIds'];
  final bannerCrop = _mapValue(json['bannerCrop']);
  final memberListBannerCrop = _mapValue(json['memberListBannerCrop']);
  final parsedRoleIds = roleIds is List
      ? [
          for (final roleId in roleIds)
            if (roleId is String && roleId.trim().isNotEmpty) roleId,
        ]
      : const <String>[];
  final roleCount = parsedRoleIds.length;
  return ServerSettingsListItemSeed(
    title: _stringValue(
      json['displayName'],
      fallback: _stringValue(json['username'], fallback: 'Member'),
    ),
    subtitle:
        '${_stringValue(json['status'], fallback: 'offline')} - joined ${_createdLabel(json['joinedAt'])}',
    trailing: roleCount == 1 ? '1 role' : '$roleCount roles',
    userId: _stringValue(json['userId'], fallback: ''),
    username: _nullableString(json['username']),
    roleIds: parsedRoleIds,
    avatarUrl: _nullableString(json['avatarUrl']),
    bannerUrl:
        _nullableString(json['bannerUrl']) ??
        _nullableString(json['profileBannerUrl']),
    bannerBaseColor: _colorValue(json['bannerBaseColor']),
    bannerCrop: bannerCrop == null
        ? null
        : BannerCrop.fromJson(bannerCrop).normalized(),
    memberListBannerUrl: _nullableString(json['memberListBannerUrl']),
    memberListBannerCrop: memberListBannerCrop == null
        ? null
        : BannerCrop.fromJson(memberListBannerCrop).normalized(),
    originIdentity: _federatedOriginIdentity(json['federation']),
  );
}

MemberSeed _channelActivityMemberItem(
  String networkId,
  Map<String, Object?> json,
) {
  final roleIds = json['roleIds'];
  final bannerCrop = _mapValue(json['bannerCrop']);
  final memberListBannerCrop = _mapValue(json['memberListBannerCrop']);
  final parsedRoleIds = roleIds is List
      ? [
          for (final roleId in roleIds)
            if (roleId is String && roleId.trim().isNotEmpty) roleId,
        ]
      : const <String>[];
  final localUserId = _stringValue(json['userId'], fallback: '');
  final name = _stringValue(
    json['displayName'],
    fallback: _stringValue(json['username'], fallback: 'Member'),
  );
  final status = _stringValue(json['status'], fallback: 'offline');
  final lastMessageAt = _nullableString(json['lastMessageAt']);
  return MemberSeed(
    id: _safeScopedId(networkId, localUserId),
    name: name,
    username: _nullableString(json['username']),
    status: status,
    initials: _initialsForDisplayName(name),
    role: _roleCountLabel(parsedRoleIds.length),
    roleIds: parsedRoleIds,
    avatarUrl: _nullableString(json['avatarUrl']),
    bannerUrl:
        _nullableString(json['bannerUrl']) ??
        _nullableString(json['profileBannerUrl']),
    bannerBaseColor: _colorValue(json['bannerBaseColor']),
    bannerCrop: bannerCrop == null
        ? null
        : BannerCrop.fromJson(bannerCrop).normalized(),
    memberListBannerUrl: _nullableString(json['memberListBannerUrl']),
    memberListBannerCrop: memberListBannerCrop == null
        ? null
        : BannerCrop.fromJson(memberListBannerCrop).normalized(),
    lastMessageAt: lastMessageAt,
    isActive:
        _hasRecentChannelMessageActivity(lastMessageAt) &&
        _memberStatusLooksChannelActive(status),
    originIdentity: _federatedOriginIdentity(json['federation']),
  );
}

FederatedOriginIdentity? _federatedOriginIdentity(Object? value) {
  final json = _mapValue(value);
  if (json == null) {
    return null;
  }
  final homePeerId = _nullableString(json['homePeerId']);
  final remoteUserId = _nullableString(json['remoteUserId']);
  if (homePeerId == null || remoteUserId == null) {
    return null;
  }
  return FederatedOriginIdentity(
    homePeerId: homePeerId,
    remoteUserId: remoteUserId,
    remoteUsername: _nullableString(json['remoteUsername']),
  );
}

ServerSettingsListItemSeed _banItem(
  String networkId,
  Map<String, Object?> json,
) {
  final localUserId = _stringValue(
    json['userId'],
    fallback: _stringValue(json['id'], fallback: ''),
  );
  final username = _stringValue(json['username'], fallback: 'Banned user');
  final reason = _nullableString(json['reason']);
  final createdAt = _nullableString(json['createdAt']);
  final bannedBy = _nullableString(json['bannedBy']);
  return ServerSettingsListItemSeed(
    title: username,
    subtitle: reason == null || reason.isEmpty ? 'No reason provided' : reason,
    trailing: _createdLabel(createdAt),
    id: _safeScopedId(networkId, localUserId),
    userId: _safeScopedId(networkId, localUserId),
    username: username,
    avatarUrl: _nullableString(json['avatarUrl']),
    actorId: bannedBy == null ? null : _safeScopedId(networkId, bannedBy),
    reason: reason,
    createdAt: createdAt,
  );
}

ServerSettingsListItemSeed _auditItem(
  String networkId,
  Map<String, Object?> json,
) {
  final action = _stringValue(json['action'], fallback: 'UNKNOWN');
  final actorUsername = _stringValue(json['actorUsername'], fallback: 'System');
  final targetType = _stringValue(json['targetType'], fallback: 'server');
  final targetLocalId = _nullableString(json['targetId']);
  final metadata = _safeAuditMetadata(_mapValue(json['metadata']));
  final reason = _nullableString(metadata['reason']);
  final createdAt = _nullableString(json['createdAt']);
  return ServerSettingsListItemSeed(
    title: '$actorUsername ${_auditActionLabel(action)}',
    subtitle: _auditSubtitle(
      action: action,
      targetType: targetType,
      targetId: targetLocalId,
      reason: reason,
    ),
    trailing: _createdLabel(createdAt),
    id: _safeScopedId(networkId, _stringValue(json['id'], fallback: '')),
    action: action,
    actorId: _safeScopedId(
      networkId,
      _stringValue(json['actorId'], fallback: ''),
    ),
    actorUsername: actorUsername,
    actorAvatarUrl:
        _nullableString(json['actorAvatarUrl']) ??
        _nullableString(json['actorAvatar']),
    targetType: targetType,
    targetId: targetLocalId == null
        ? null
        : _safeScopedId(networkId, targetLocalId),
    reason: reason,
    createdAt: createdAt,
    metadata: metadata,
  );
}

String _auditActionLabel(String action) {
  return switch (action) {
    'KICK_MEMBER' || 'MEMBER_KICK' => 'kicked a member',
    'BAN_MEMBER' || 'MEMBER_BAN' => 'banned a member',
    'UNBAN_MEMBER' || 'MEMBER_UNBAN' => 'removed a ban',
    'CREATE_ROLE' || 'ROLE_CREATE' => 'created a role',
    'UPDATE_ROLE' || 'ROLE_UPDATE' => 'updated a role',
    'DELETE_ROLE' || 'ROLE_DELETE' => 'deleted a role',
    'ASSIGN_ROLE' || 'ROLE_ASSIGN' => 'assigned a role',
    'REMOVE_ROLE' || 'ROLE_REMOVE' => 'removed a role',
    'SET_NAME_COLOR' => 'updated a name color',
    _ => action.toLowerCase().replaceAll('_', ' '),
  };
}

String _auditSubtitle({
  required String action,
  required String targetType,
  required String? targetId,
  required String? reason,
}) {
  final target = targetId == null || targetId.isEmpty
      ? targetType
      : '$targetType $targetId';
  if (reason == null || reason.isEmpty) {
    return target;
  }
  return '$target - $reason';
}

Map<String, Object?> _safeAuditMetadata(Map<String, Object?>? metadata) {
  if (metadata == null) {
    return const {};
  }
  const allowedKeys = {
    'reason',
    'roleId',
    'roleName',
    'channelId',
    'channelName',
    'botId',
    'botName',
    'feedId',
    'feedName',
    'emojiId',
    'emojiName',
    'messageId',
    'username',
    'displayName',
    'color',
  };
  final safe = <String, Object?>{};
  for (final entry in metadata.entries) {
    if (!allowedKeys.contains(entry.key)) {
      continue;
    }
    final value = entry.value;
    if (value == null || value is String || value is num || value is bool) {
      safe[entry.key] = value;
    }
  }
  return Map.unmodifiable(safe);
}

ServerSettingsListItemSeed _feedItem(Map<String, Object?> json) {
  final position = _intValue(json['position'], fallback: 0);
  final description = _nullableString(json['description']);
  return ServerSettingsListItemSeed(
    title: _stringValue(json['name'], fallback: 'Feed'),
    subtitle: description == null || description.isEmpty
        ? 'No description'
        : description,
    trailing: '#$position',
    id: _stringValue(json['id'], fallback: ''),
    feedServerId: _nullableString(json['serverId']),
    feedIcon: _nullableString(json['icon']),
    publishRoleIds: _stringList(json['publishRoleIds']),
    visibleRoleIds: _stringList(json['visibleRoleIds']),
    feedCreatedAt: _nullableString(json['createdAt']),
  );
}

FeedAnnouncementRecord _announcementRecord(Map<String, Object?> json) {
  try {
    return FeedAnnouncementRecord.fromJson(json);
  } on FormatException {
    throw const ServerSettingsException('Announcement response was invalid');
  }
}

ServerSettingsListItemSeed _botItem(Map<String, Object?> json) {
  final bannerCrop = _mapValue(json['bannerCrop']);
  return ServerSettingsListItemSeed(
    title: _stringValue(json['name'], fallback: 'Bot'),
    subtitle: _stringValue(json['description'], fallback: 'No description'),
    trailing: _stringValue(json['status'], fallback: 'offline'),
    id: _stringValue(json['id'], fallback: ''),
    roleIds: _stringList(json['roleIds']),
    avatarUrl: _nullableString(json['avatarUrl']),
    bannerUrl: _nullableString(json['bannerUrl']),
    bannerBaseColor: _colorValue(json['bannerBaseColor']),
    bannerCrop: bannerCrop == null
        ? null
        : BannerCrop.fromJson(bannerCrop).normalized(),
  );
}

Map<String, Object?>? _mapValue(Object? value) {
  return jsonMap(value);
}

int _intValue(Object? value, {required int fallback}) {
  return jsonInt(value, fallback: fallback);
}

String _stringValue(Object? value, {required String fallback}) {
  return jsonString(value, fallback: fallback);
}

String? _nullableString(Object? value) {
  return jsonNullableString(value);
}

bool _boolValue(Object? value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }
  return fallback;
}

DateTime? _dateTimeValue(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return [
    for (final item in value)
      if (item is String && item.trim().isNotEmpty) item.trim(),
  ];
}

List<String> _normalizedStringList(Iterable<String> values) {
  final normalized = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || normalized.contains(trimmed)) {
      continue;
    }
    normalized.add(trimmed);
  }
  return normalized;
}

List<String> _normalizedRouteStringList(
  Iterable<String> values,
  String Function(String value)? localId,
) {
  final normalized = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    final next = localId == null ? trimmed : localId(trimmed);
    if (!normalized.contains(next)) {
      normalized.add(next);
    }
  }
  return normalized;
}

String? _normalizedOptionalText(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String>? _normalizedFeedRoleIds(
  Object? value,
  String Function(String roleId)? localRoleId,
) {
  if (value == null) {
    return null;
  }
  if (value is! Iterable<String>) {
    return null;
  }
  final ids = <String>[];
  for (final item in value) {
    final trimmed = item.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    ids.add(localRoleId == null ? trimmed : localRoleId(trimmed));
  }
  return ids.isEmpty ? null : ids;
}

String? _normalizedHexColor(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final prefixed = trimmed.startsWith('#') ? trimmed : '#$trimmed';
  if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(prefixed)) {
    throw const ServerSettingsException('Color must be a 6-digit hex value');
  }
  return prefixed.toLowerCase();
}

String? _normalizeChannelName(String? value) {
  if (value == null) {
    return null;
  }
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '')
      .replaceAll(RegExp(r'-{2,}'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? null : normalized;
}

final class _ServerSettingsRequestPacer {
  _ServerSettingsRequestPacer();

  static final _byOrigin = <String, _ServerSettingsRequestPacer>{};

  static _ServerSettingsRequestPacer forOrigin(String apiOrigin) {
    return _byOrigin.putIfAbsent(apiOrigin, _ServerSettingsRequestPacer.new);
  }

  Future<void> _tail = Future<void>.value();
  DateTime? _lastStartedAt;

  Future<Duration> wait(Duration minInterval) {
    if (minInterval <= Duration.zero) {
      return Future<Duration>.value(Duration.zero);
    }
    final previous = _tail;
    final next = previous.then(
      (_) => _waitAfterPrevious(minInterval),
      onError: (_) => _waitAfterPrevious(minInterval),
    );
    _tail = next.then<void>((_) {});
    return next;
  }

  Future<Duration> _waitAfterPrevious(Duration minInterval) async {
    final lastStartedAt = _lastStartedAt;
    var delay = Duration.zero;
    if (lastStartedAt != null) {
      final elapsed = DateTime.now().difference(lastStartedAt);
      if (elapsed < minInterval) {
        delay = minInterval - elapsed;
      }
    }
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    _lastStartedAt = DateTime.now();
    return delay;
  }
}

final class _InstanceMetadata {
  const _InstanceMetadata({
    required this.mediaPolicy,
    required this.entitlements,
  });

  final ServerMediaPolicy mediaPolicy;
  final WorkspaceEntitlements entitlements;
}

MessageSeed _messageFromJson(
  Map<String, Object?> json, {
  required String currentUserId,
}) {
  final localMessageId = _stringValue(json['id'], fallback: 'unknown-message');
  final localAuthorId = _stringValue(
    json['authorId'],
    fallback: _stringValue(json['author_id'], fallback: 'unknown-user'),
  );
  final author = _mapValue(json['author']);
  final displayName = _stringValue(
    author?['displayName'],
    fallback: _stringValue(author?['username'], fallback: localAuthorId),
  );
  final createdAt = _stringValue(
    json['createdAt'],
    fallback: _stringValue(json['created_at'], fallback: ''),
  );
  return MessageSeed(
    id: localMessageId,
    authorId: localAuthorId,
    author: displayName,
    time: formatWorkspaceDateTimeLabel(createdAt),
    createdAt: createdAt,
    body: _stringValue(
      json['content'],
      fallback: _stringValue(json['body'], fallback: ''),
    ),
    initials: _initialsForDisplayName(displayName),
    avatarUrl: _nullableString(author?['avatarUrl']),
    authorColor: parseVerdantColor(
      author?['nameColor'] ??
          author?['displayColor'] ??
          author?['nicknameColor'] ??
          json['nameColor'],
    ),
    authorBannerBaseColor: parseVerdantColor(
      author?['bannerBaseColor'] ?? json['bannerBaseColor'],
    ),
    media: _messageMediaFromJson(json),
    reactions: _reactionsFromJson(json['reactions']),
    isOwnMessage: localAuthorId == currentUserId,
  );
}

int _messageRowOldestFirst(
  ({int index, Map<String, Object?> map}) a,
  ({int index, Map<String, Object?> map}) b,
) {
  final aCreatedAt = _messageCreatedAt(a.map);
  final bCreatedAt = _messageCreatedAt(b.map);
  if (aCreatedAt != null && bCreatedAt != null) {
    return aCreatedAt.compareTo(bCreatedAt);
  }
  if (aCreatedAt != null) {
    return -1;
  }
  if (bCreatedAt != null) {
    return 1;
  }
  return b.index.compareTo(a.index);
}

DateTime? _messageCreatedAt(Map<String, Object?> json) {
  final value =
      _nullableString(json['createdAt']) ?? _nullableString(json['created_at']);
  return value == null ? null : DateTime.tryParse(value);
}

List<ReactionSeed> _reactionsFromJson(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  return [
    for (final item in raw)
      if (_mapValue(item) case final reaction?)
        ReactionSeed(
          emoji: _stringValue(reaction['emoji'], fallback: '?'),
          emojiId: _nullableString(reaction['emojiId']),
          count: _intValue(reaction['count'], fallback: 1),
          reactedByCurrentUser: reaction['me'] == true,
        ),
  ];
}

MessageMediaSeed? _messageMediaFromJson(Map<String, Object?> json) {
  final rawAttachments = json['attachments'];
  if (rawAttachments is! List) {
    return null;
  }
  for (final rawAttachment in rawAttachments) {
    final attachment = _mapValue(rawAttachment);
    if (attachment == null) {
      continue;
    }
    final contentType =
        _nullableString(attachment['contentType']) ??
        _nullableString(attachment['content_type']);
    final url = _nullableString(attachment['url']);
    if (!_isImageContentType(contentType) && !_imageUrlLooksRenderable(url)) {
      continue;
    }
    return MessageMediaSeed(
      id: _stringValue(attachment['id'], fallback: url ?? 'unknown-media'),
      label: _stringValue(
        attachment['filename'],
        fallback: _stringValue(
          attachment['name'],
          fallback: 'Image attachment',
        ),
      ),
      kind: _mediaKindFor(contentType: contentType, url: url),
      width: _intValue(attachment['width'], fallback: 360),
      height: _intValue(attachment['height'], fallback: 240),
      url: url,
      contentType: contentType,
      sizeBytes: _nullableInt(attachment['size']),
    );
  }
  return null;
}

bool _isImageContentType(String? contentType) {
  return switch (contentType?.toLowerCase()) {
    'image/png' ||
    'image/jpeg' ||
    'image/jpg' ||
    'image/gif' ||
    'image/webp' => true,
    _ => false,
  };
}

bool _imageUrlLooksRenderable(String? url) {
  final lower = url?.toLowerCase();
  if (lower == null) {
    return false;
  }
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.webp');
}

MessageMediaKind _mediaKindFor({String? contentType, String? url}) {
  final normalizedType = contentType?.toLowerCase();
  final normalizedUrl = url?.toLowerCase() ?? '';
  if (normalizedType == 'image/gif' || normalizedUrl.endsWith('.gif')) {
    return MessageMediaKind.gif;
  }
  if (normalizedType == 'image/webp' || normalizedUrl.endsWith('.webp')) {
    return MessageMediaKind.webp;
  }
  return MessageMediaKind.image;
}

int? _nullableInt(Object? value) {
  return value is num ? value.toInt() : null;
}

String _initialsForDisplayName(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  final compact = value.replaceAll(RegExp(r'\s+'), '');
  if (compact.length >= 2) {
    return compact.substring(0, 2).toUpperCase();
  }
  return compact.toUpperCase();
}

String _roleCountLabel(int count) {
  return count == 1 ? '1 role' : '$count roles';
}

bool _memberStatusLooksChannelActive(String value) {
  final normalized = value.toLowerCase();
  return normalized.contains('online') ||
      normalized.contains('available') ||
      normalized.contains('dnd') ||
      normalized.contains('busy');
}

bool _hasRecentChannelMessageActivity(String? value) {
  if (value == null) {
    return false;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return false;
  }
  final elapsed = DateTime.now().toUtc().difference(parsed.toUtc());
  return !elapsed.isNegative && elapsed <= const Duration(minutes: 15);
}

String? _safeScopedId(String networkId, String localId) {
  if (localId.trim().isEmpty) {
    return null;
  }
  try {
    final network = _safeWorkspaceNetworkId(networkId);
    final raw = localId.trim();
    final slash = raw.indexOf('/');
    if (slash >= 0) {
      if (slash == 0 ||
          slash == raw.length - 1 ||
          raw.indexOf('/', slash + 1) >= 0 ||
          safeWorkspaceLocalId(raw.substring(0, slash)) != network) {
        return null;
      }
      final local = safeWorkspaceLocalId(raw.substring(slash + 1));
      return '$network/$local';
    }
    final local = safeWorkspaceLocalId(raw);
    return '$network/$local';
  } on FormatException {
    return null;
  }
}

String _safeWorkspaceNetworkId(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty ||
      trimmed.contains('/') ||
      trimmed.contains('\\') ||
      trimmed.contains(RegExp(r'\s')) ||
      _containsControlCharacter(trimmed)) {
    throw const FormatException('Invalid workspace network id');
  }
  return trimmed;
}

bool _containsControlCharacter(String value) {
  for (final unit in value.codeUnits) {
    if (unit < 0x20 || unit == 0x7f) {
      return true;
    }
  }
  return false;
}

String _safeRouteLocalId(
  String value, {
  required String expectedNetworkId,
  required String entityLabel,
}) {
  try {
    return _safeScopedRouteLocalId(
      value,
      expectedNetworkId,
      entityLabel: entityLabel,
    );
  } on ServerSettingsException {
    rethrow;
  } on FormatException {
    throw ServerSettingsException('Invalid ${entityLabel.toLowerCase()} id');
  }
}

String _safeChannelWriteLocalId(String value, String expectedNetworkId) {
  try {
    return _safeScopedRouteLocalId(
      value,
      expectedNetworkId,
      entityLabel: 'Channel',
    );
  } on ServerSettingsException {
    rethrow;
  } on FormatException {
    throw const ServerSettingsException('Invalid channel id');
  }
}

String _safeRoleRouteLocalId(
  String value,
  String expectedNetworkId, {
  required String entityLabel,
}) {
  try {
    return _safeScopedRouteLocalId(
      value,
      expectedNetworkId,
      entityLabel: entityLabel,
    );
  } on ServerSettingsException {
    rethrow;
  } on FormatException {
    throw ServerSettingsException('Invalid ${entityLabel.toLowerCase()} id');
  }
}

String _safeMessageMutationRouteLocalId(
  String value,
  String expectedNetworkId, {
  required String entityLabel,
}) {
  try {
    return _safeScopedRouteLocalId(
      value,
      expectedNetworkId,
      entityLabel: entityLabel,
    );
  } on ServerSettingsException {
    rethrow;
  } on FormatException {
    throw ServerSettingsException('Invalid ${entityLabel.toLowerCase()} id');
  }
}

String _safeScopedRouteLocalId(
  String value,
  String expectedNetworkId, {
  required String entityLabel,
}) {
  final raw = value.trim();
  final slash = raw.indexOf('/');
  if (slash < 0) {
    return safeWorkspaceLocalId(raw);
  }
  if (slash == 0 ||
      slash == raw.length - 1 ||
      raw.indexOf('/', slash + 1) >= 0) {
    throw const FormatException('Invalid scoped workspace id');
  }
  final routeNetworkId = raw.substring(0, slash);
  if (!sameWorkspaceNetworkId(routeNetworkId, expectedNetworkId)) {
    throw ServerSettingsException('$entityLabel route did not match network');
  }
  return safeWorkspaceLocalId(raw.substring(slash + 1));
}

String _createdLabel(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    }
    return value;
  }
  return 'unknown';
}

Color? _colorValue(Object? value) {
  if (value is! String || !value.startsWith('#') || value.length != 7) {
    return null;
  }
  final parsed = int.tryParse(value.substring(1), radix: 16);
  return parsed == null ? null : Color(0xFF000000 | parsed);
}

String _multipartBoundary() {
  return 'verdant-flutter-${DateTime.now().microsecondsSinceEpoch}';
}

String _diagnosticEndpoint(String path) {
  final route = path.split('?').first;
  if (RegExp(r'^/api/invites/[^/]+$').hasMatch(route)) {
    return '/api/invites/:code';
  }
  if (RegExp(r'^/api/channels/[^/]+/messages$').hasMatch(route)) {
    return '/api/channels/:id/messages';
  }
  if (RegExp(r'^/api/channels/[^/]+/activity$').hasMatch(route)) {
    return '/api/channels/:id/activity';
  }
  return _redactDiagnosticPathIds(route);
}

String _redactDiagnosticPathIds(String route) {
  final segments = route.split('/');
  for (var index = 0; index < segments.length; index += 1) {
    final previous = index == 0 ? '' : segments[index - 1];
    final segment = segments[index];
    if (segment.isEmpty) {
      continue;
    }
    if (segment == 'announcements') {
      continue;
    }
    if (previous == 'servers' ||
        previous == 'channels' ||
        previous == 'users' ||
        previous == 'members' ||
        previous == 'messages' ||
        previous == 'roles' ||
        previous == 'feeds' ||
        previous == 'announcements' ||
        previous == 'invites' ||
        previous == 'bans' ||
        previous == 'bots' ||
        previous == 'emojis') {
      segments[index] = ':id';
      continue;
    }
    if (RegExp(r'^[0-9]{6,}$').hasMatch(segment)) {
      segments[index] = ':id';
      continue;
    }
    if (RegExp(r'^[A-Za-z0-9_-]{10,}$').hasMatch(segment)) {
      segments[index] = ':id';
    }
  }
  return segments.join('/');
}

String _safeMultipartFilename(String value) {
  final parts = value
      .replaceAll(RegExp(r'[\r\n"\\]'), '_')
      .split(RegExp(r'[/\\]'))
      .where((part) => part.trim().isNotEmpty)
      .toList(growable: false);
  final sanitized = parts.isEmpty ? null : parts.last.trim();
  return sanitized == null || sanitized.isEmpty ? 'upload.png' : sanitized;
}

String _safeMultipartFieldName(String value) {
  final sanitized = value.trim();
  if (!RegExp(r'^[A-Za-z0-9_-]{1,48}$').hasMatch(sanitized)) {
    throw const ServerSettingsException('Upload field was invalid');
  }
  return sanitized;
}

String _shortDiagnosticHeaderValue(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 80) {
    return trimmed;
  }
  return '${trimmed.substring(0, 77)}...';
}

String _imageContentType(String fileName) {
  final parts = fileName.split('.');
  final ext = parts.isEmpty ? '' : parts.last.toLowerCase();
  return switch (ext) {
    'gif' => 'image/gif',
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    _ => 'image/png',
  };
}

String _safeInviteCode(String value) {
  final trimmed = sanitizeInviteCodeInput(value, maxLength: 128);
  if (trimmed.isEmpty ||
      trimmed.length > 128 ||
      trimmed.contains('/') ||
      trimmed.contains('\\') ||
      trimmed.contains('\u0000')) {
    throw const ServerSettingsException('Enter a valid invite code');
  }
  return trimmed;
}
