import 'json_value.dart';

final class WorkspaceEntitlements {
  const WorkspaceEntitlements({
    required this.officialSubscriptionActive,
    required this.officialSubscriptionTier,
    required this.imageUploads,
    required this.fileSharing,
    required this.messageAttachments,
    required this.voiceChat,
    required this.videoStreaming,
    required this.crossServerEmoji,
    required this.animatedAvatar,
    required this.animatedBanner,
    required this.memberListBanner,
    required this.maxUploadBytes,
    required this.maxVoiceBitrate,
    required this.officialBadge,
  });

  const WorkspaceEntitlements.disabled()
    : officialSubscriptionActive = false,
      officialSubscriptionTier = null,
      imageUploads = false,
      fileSharing = false,
      messageAttachments = false,
      voiceChat = false,
      videoStreaming = false,
      crossServerEmoji = false,
      animatedAvatar = false,
      animatedBanner = false,
      memberListBanner = false,
      maxUploadBytes = null,
      maxVoiceBitrate = null,
      officialBadge = false;

  factory WorkspaceEntitlements.fromJson(Map<String, Object?> json) {
    return WorkspaceEntitlements(
      officialSubscriptionActive: jsonBool(json['officialSubscriptionActive']),
      officialSubscriptionTier: jsonNullableString(
        json['officialSubscriptionTier'],
      ),
      imageUploads: jsonBool(json['imageUploads']),
      fileSharing: jsonBool(json['fileSharing']),
      messageAttachments: jsonBool(json['messageAttachments']),
      voiceChat: jsonBool(json['voiceChat']),
      videoStreaming: jsonBool(json['videoStreaming']),
      crossServerEmoji: jsonBool(json['crossServerEmoji']),
      animatedAvatar: jsonBool(json['animatedAvatar']),
      animatedBanner: jsonBool(json['animatedBanner']),
      memberListBanner: jsonBool(json['memberListBanner']),
      maxUploadBytes: jsonNullableNonNegativeInt(json['maxUploadBytes']),
      maxVoiceBitrate: jsonNullableNonNegativeInt(json['maxVoiceBitrate']),
      officialBadge: jsonBool(json['officialBadge']),
    );
  }

  factory WorkspaceEntitlements.fromJsonString(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const WorkspaceEntitlements.disabled();
    }
    final decoded = jsonObjectFromString(trimmed);
    if (decoded != null) {
      return WorkspaceEntitlements.fromJson(decoded);
    }
    return const WorkspaceEntitlements.disabled();
  }

  static WorkspaceEntitlements fromReadyJsonValue(Object? value) {
    if (value is Map<String, Object?>) {
      return WorkspaceEntitlements.fromJson(value);
    }
    if (value is Map) {
      return WorkspaceEntitlements.fromJson(Map<String, Object?>.from(value));
    }
    if (value is String) {
      return WorkspaceEntitlements.fromJsonString(value);
    }
    return const WorkspaceEntitlements.disabled();
  }

  static WorkspaceEntitlements fromInstanceJsonValue(Object? value) {
    final map = value is String ? jsonObjectFromString(value) : jsonMap(value);
    final capabilities = jsonMap(map?['capabilities']);
    if (capabilities == null) {
      return const WorkspaceEntitlements.disabled();
    }
    return WorkspaceEntitlements(
      officialSubscriptionActive: false,
      officialSubscriptionTier: null,
      imageUploads: jsonBool(capabilities['imageUploads']),
      fileSharing: jsonBool(capabilities['fileSharing']),
      messageAttachments: jsonBool(capabilities['messageAttachments']),
      voiceChat: jsonBool(capabilities['voiceChat']),
      videoStreaming: jsonBool(capabilities['videoStreaming']),
      crossServerEmoji: jsonBool(capabilities['crossServerEmoji']),
      animatedAvatar: jsonBool(capabilities['animatedAvatar']),
      animatedBanner: jsonBool(capabilities['animatedBanner']),
      memberListBanner: jsonBool(capabilities['memberListBanner']),
      maxUploadBytes: jsonNullableNonNegativeInt(
        capabilities['maxUploadBytes'],
      ),
      maxVoiceBitrate: jsonNullableNonNegativeInt(
        capabilities['maxVoiceBitrate'],
      ),
      officialBadge: false,
    );
  }

  final bool officialSubscriptionActive;
  final String? officialSubscriptionTier;
  final bool imageUploads;
  final bool fileSharing;
  final bool messageAttachments;
  final bool voiceChat;
  final bool videoStreaming;
  final bool crossServerEmoji;
  final bool animatedAvatar;
  final bool animatedBanner;
  final bool memberListBanner;
  final int? maxUploadBytes;
  final int? maxVoiceBitrate;
  final bool officialBadge;

  WorkspaceEntitlements mergeCapabilityFallback(
    WorkspaceEntitlements fallback,
  ) {
    return WorkspaceEntitlements(
      officialSubscriptionActive:
          officialSubscriptionActive || fallback.officialSubscriptionActive,
      officialSubscriptionTier:
          officialSubscriptionTier ?? fallback.officialSubscriptionTier,
      imageUploads: imageUploads || fallback.imageUploads,
      fileSharing: fileSharing || fallback.fileSharing,
      messageAttachments: messageAttachments || fallback.messageAttachments,
      voiceChat: voiceChat || fallback.voiceChat,
      videoStreaming: videoStreaming || fallback.videoStreaming,
      crossServerEmoji: crossServerEmoji || fallback.crossServerEmoji,
      animatedAvatar: animatedAvatar || fallback.animatedAvatar,
      animatedBanner: animatedBanner || fallback.animatedBanner,
      memberListBanner: memberListBanner || fallback.memberListBanner,
      maxUploadBytes: maxUploadBytes ?? fallback.maxUploadBytes,
      maxVoiceBitrate: maxVoiceBitrate ?? fallback.maxVoiceBitrate,
      officialBadge: officialBadge || fallback.officialBadge,
    );
  }
}
