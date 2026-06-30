import 'dart:ui';

import '../../auth/auth_models.dart';
import '../direct_messages_workspace/direct_messages_models.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../workspace_local_id.dart';
import '../workspace_seed.dart';

typedef MemberUserMatcher =
    bool Function(MemberSeed member, String scopedUserId, String localUserId);
typedef SettingsMemberUserMatcher =
    bool Function(
      ServerSettingsListItemSeed member,
      String scopedUserId,
      String localUserId,
    );
typedef ScopedUserIdBuilder = String? Function(String networkId, String userId);
typedef LocalUserIdReader = String? Function(String userId);

final class MemberProfileProjection {
  const MemberProfileProjection({
    required this.currentUser,
    required this.networkId,
    required this.memberMatchesUser,
    required this.settingsMemberMatchesUser,
    required this.safeScopedUserId,
    required this.safeLocalUserId,
  });

  final VerdantUser currentUser;
  final String networkId;
  final MemberUserMatcher memberMatchesUser;
  final SettingsMemberUserMatcher settingsMemberMatchesUser;
  final ScopedUserIdBuilder safeScopedUserId;
  final LocalUserIdReader safeLocalUserId;

  MemberSeed applyProfileToMember(
    MemberSeed member,
    ServerSettingsCurrentUserMedia? profile,
  ) {
    if (profile == null) {
      return member;
    }
    final displayName = _nonEmptyProfileText(profile.displayName);
    final username = _nonEmptyProfileText(profile.username);
    final name = displayName ?? username;
    final status = _profileStatusForMember(member.status, profile.status);
    return member.copyWith(
      name: name ?? member.name,
      username: username ?? member.username,
      status: status,
      initials: name == null ? member.initials : initialsForDisplayName(name),
      avatarUrl: profile.avatarUrl ?? member.avatarUrl,
      bannerUrl: profile.bannerUrl ?? member.bannerUrl,
      bannerBaseColor: profile.bannerBaseColor ?? member.bannerBaseColor,
      bannerCrop: profile.bannerCrop ?? member.bannerCrop,
      memberListBannerUrl:
          profile.memberListBannerUrl ?? member.memberListBannerUrl,
      memberListBannerCrop:
          profile.memberListBannerCrop ?? member.memberListBannerCrop,
    );
  }

  List<MemberSeed> applyRealtimeUpdateToMembers(
    List<MemberSeed> members, {
    required String scopedUserId,
    required String localUserId,
    DirectMessagesUserProfileUpdateEvent? event,
    ServerSettingsCurrentUserMedia? profile,
  }) {
    return [
      for (final member in members)
        if (memberMatchesUser(member, scopedUserId, localUserId))
          applyRealtimeUpdateToMember(member, event: event, profile: profile)
        else
          member,
    ];
  }

  MemberSeed applyRealtimeUpdateToMember(
    MemberSeed member, {
    DirectMessagesUserProfileUpdateEvent? event,
    ServerSettingsCurrentUserMedia? profile,
  }) {
    var next = applyProfileToMember(member, profile);
    if (event == null) {
      return next;
    }
    final displayName = _eventString(event.displayName);
    return next.copyWith(
      name: displayName ?? next.name,
      initials: displayName == null
          ? next.initials
          : initialsForDisplayName(displayName),
      avatarUrl: _eventStringOrExisting(event.avatarUrl, next.avatarUrl),
      bannerUrl: _eventStringOrExisting(event.bannerUrl, next.bannerUrl),
      bannerBaseColor: _eventColorOrExisting(
        event.bannerBaseColor,
        next.bannerBaseColor,
      ),
    );
  }

  ServerSettingsData? applyRealtimeUpdateToSettingsMembers(
    ServerSettingsData? settings, {
    required String scopedUserId,
    required String localUserId,
    required DirectMessagesUserProfileUpdateEvent event,
  }) {
    if (settings == null) {
      return null;
    }
    final displayName = _eventString(event.displayName);
    final members = [
      for (final member in settings.members)
        if (settingsMemberMatchesUser(member, scopedUserId, localUserId))
          ServerSettingsListItemSeed(
            title: displayName ?? member.title,
            subtitle: member.subtitle,
            trailing: member.trailing,
            accent: member.accent,
            id: member.id,
            userId: member.userId,
            username: member.username,
            roleIds: member.roleIds,
            permissions: member.permissions,
            position: member.position,
            colorOnly: member.colorOnly,
            avatarUrl: _eventStringOrExisting(
              event.avatarUrl,
              member.avatarUrl,
            ),
            bannerUrl: _eventStringOrExisting(
              event.bannerUrl,
              member.bannerUrl,
            ),
            bannerBaseColor: _eventColorOrExisting(
              event.bannerBaseColor,
              member.bannerBaseColor,
            ),
            bannerCrop: member.bannerCrop,
            memberListBannerUrl: member.memberListBannerUrl,
            memberListBannerCrop: member.memberListBannerCrop,
            originIdentity: member.originIdentity,
          )
        else
          member,
    ];
    return settings.copyWith(members: members);
  }

  ServerSettingsCurrentUserMedia? applyRealtimeUpdateToCurrentUserMedia(
    ServerSettingsCurrentUserMedia? currentUserMedia, {
    required String scopedUserId,
    required String localUserId,
    required DirectMessagesUserProfileUpdateEvent event,
  }) {
    if (currentUserMedia == null) {
      return null;
    }
    if (!settingsMemberMatchesUser(
      ServerSettingsListItemSeed(
        title: '',
        subtitle: '',
        id: currentUserMedia.id,
        userId: currentUserMedia.id,
      ),
      scopedUserId,
      localUserId,
    )) {
      return currentUserMedia;
    }
    return currentUserMedia.copyWith(
      displayName: _eventStringOrExisting(
        event.displayName,
        currentUserMedia.displayName,
      ),
      avatarUrl: _eventStringOrExisting(
        event.avatarUrl,
        currentUserMedia.avatarUrl,
      ),
      bannerUrl: _eventStringOrExisting(
        event.bannerUrl,
        currentUserMedia.bannerUrl,
      ),
      bannerBaseColor: _eventColorOrExisting(
        event.bannerBaseColor,
        currentUserMedia.bannerBaseColor,
      ),
      bio: _eventStringOrExisting(event.bio, currentUserMedia.bio),
    );
  }

  VerdantUser applyRealtimeUpdateToCurrentUser(
    VerdantUser existing, {
    required String scopedUserId,
    required DirectMessagesUserProfileUpdateEvent event,
    required ServerSettingsCurrentUserMedia? currentUserMedia,
  }) {
    final currentScopedUserId = safeScopedUserId(
      networkId,
      safeLocalUserId(existing.id) ?? existing.id,
    );
    if (currentScopedUserId == null ||
        !sameScopedWorkspaceId(currentScopedUserId, scopedUserId)) {
      return existing;
    }
    return existing.copyWith(
      displayName: _eventStringOrExisting(
        event.displayName,
        currentUserMedia?.displayName ?? existing.displayName,
      ),
      avatarUrl: _eventStringOrExisting(
        event.avatarUrl,
        currentUserMedia?.avatarUrl ?? existing.avatarUrl,
      ),
      bannerUrl: _eventStringOrExisting(
        event.bannerUrl,
        currentUserMedia?.bannerUrl ?? existing.bannerUrl,
      ),
      bannerBaseColor: identical(event.bannerBaseColor, workspaceEventUnset)
          ? _colorHex(currentUserMedia?.bannerBaseColor) ??
                existing.bannerBaseColor
          : event.bannerBaseColor as String?,
      bio: _eventStringOrExisting(
        event.bio,
        currentUserMedia?.bio ?? existing.bio,
      ),
    );
  }
}

String _profileStatusForMember(String currentStatus, String? profileStatus) {
  final nextStatus = _nonEmptyProfileText(profileStatus);
  if (nextStatus == null) {
    return currentStatus;
  }
  if (_statusLooksOffline(nextStatus) && !_statusLooksOffline(currentStatus)) {
    return currentStatus;
  }
  return nextStatus;
}

String? _nonEmptyProfileText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String? _eventString(Object? value) {
  if (identical(value, workspaceEventUnset)) {
    return null;
  }
  return value as String?;
}

String? _eventStringOrExisting(Object? value, String? existing) {
  if (identical(value, workspaceEventUnset)) {
    return existing;
  }
  return value as String?;
}

Color? _eventColorOrExisting(Object? value, Color? existing) {
  if (identical(value, workspaceEventUnset)) {
    return existing;
  }
  return _profileHexColor(value as String?);
}

bool _statusLooksOffline(String status) {
  return status.toLowerCase().contains('offline');
}

Color? _profileHexColor(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  final hex = normalized.startsWith('#') ? normalized.substring(1) : normalized;
  if (hex.length != 6) {
    return null;
  }
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) {
    return null;
  }
  return Color(0xff000000 | parsed);
}

String? _colorHex(Color? value) {
  if (value == null) {
    return null;
  }
  final rgb = value.toARGB32() & 0x00ffffff;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
