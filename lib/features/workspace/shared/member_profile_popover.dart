import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/window_focus_scope.dart';
import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_image.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../workspace_seed.dart';
import 'user_identity_labels.dart';

enum MemberIdentityPopoverSide { left, right }

typedef MemberProfilePopoverSide = MemberIdentityPopoverSide;
typedef MemberProfilePopoverOverlay = MemberIdentityPopoverOverlay;

class MemberIdentityPopoverOverlay extends StatelessWidget {
  const MemberIdentityPopoverOverlay({
    required this.member,
    required this.mediaPolicy,
    required this.anchorRect,
    required this.side,
    required this.onDismiss,
    this.viewportRect,
    super.key,
  });

  static const _width = 308.0;
  static const _gap = 10.0;
  static const _maxHeight = 420.0;

  final MemberSeed member;
  final ServerMediaPolicy mediaPolicy;
  final Rect anchorRect;
  final MemberIdentityPopoverSide side;
  final VoidCallback onDismiss;
  final Rect? viewportRect;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
            onSecondaryTapDown: (_) => onDismiss(),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bounds =
                    viewportRect ??
                    Rect.fromLTWH(
                      0,
                      0,
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                final width = bounds.width > 24
                    ? _width.clamp(240.0, bounds.width - 16).toDouble()
                    : _width;
                final minLeft = bounds.left + 8;
                final maxLeft = bounds.width > width + 16
                    ? bounds.right - width - 8
                    : minLeft;
                final preferredLeft = switch (side) {
                  MemberIdentityPopoverSide.left =>
                    anchorRect.left - width - _gap,
                  MemberIdentityPopoverSide.right => anchorRect.right + _gap,
                };
                final left = preferredLeft.clamp(minLeft, maxLeft).toDouble();
                final minTop = bounds.top + 8;
                final maxCardHeight = (bounds.height - 16)
                    .clamp(240.0, _maxHeight)
                    .toDouble();
                final maxTop = bounds.height > maxCardHeight + 16
                    ? bounds.bottom - maxCardHeight - 8
                    : minTop;
                final top = anchorRect.top.clamp(minTop, maxTop).toDouble();

                return Stack(
                  children: [
                    Positioned(
                      left: left,
                      top: top,
                      width: width,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxCardHeight),
                        child: _MemberProfileCard(
                          member: member,
                          mediaPolicy: mediaPolicy,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberProfileCard extends StatefulWidget {
  const _MemberProfileCard({required this.member, required this.mediaPolicy});

  final MemberSeed member;
  final ServerMediaPolicy mediaPolicy;

  @override
  State<_MemberProfileCard> createState() => _MemberProfileCardState();
}

class _MemberProfileCardState extends State<_MemberProfileCard> {
  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final member = widget.member;
    final memberKey = member.id ?? member.name;
    final userId = workspaceUserClipboardId(member.id, fallback: member.name);
    final originUserId = workspaceOriginClipboardId(member.originIdentity);
    final canCopyUserId = (member.id?.trim().isNotEmpty ?? false);
    final statusLabel = memberPresenceLabel(member.status);
    final fallbackVisualColor =
        member.bannerBaseColor ??
        member.displayColor ??
        avatarColorFor(member.name);
    final avatarColor = fallbackVisualColor;
    final roleColor = member.displayColor ?? avatarColor;

    return Material(
      key: ValueKey('member-profile-popover-$memberKey'),
      color: Colors.transparent,
      child: DecoratedBox(
        key: ValueKey('member-profile-popover-card-$memberKey'),
        decoration: BoxDecoration(
          color: colors.panelRaised,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: colors.borderStrong),
          boxShadow: [
            BoxShadow(
              color: colors.accentStrong.withValues(alpha: 0.2),
              blurRadius: 0,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: colors.accent.withValues(alpha: 0.09),
              blurRadius: 20,
              offset: Offset.zero,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  key: ValueKey('member-profile-banner-slot-$memberKey'),
                  height: 108,
                  child: ClipRect(
                    child: MemberMediaBanner(
                      member: member,
                      mediaPolicy: widget.mediaPolicy,
                      playAnimatedMedia: true,
                      imageKeyPrefix: 'member-profile-banner-image',
                      fallbackColorOverride: fallbackVisualColor,
                      fallbackOpacity: 1,
                      loadingPlaceholder: _ProfileBannerLoading(
                        key: ValueKey(
                          'member-profile-banner-loading-$memberKey',
                        ),
                        color: avatarColor,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        key: ValueKey('member-profile-identity-row-$memberKey'),
                        height: 112,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              top: 26,
                              child: DecoratedBox(
                                key: ValueKey(
                                  'member-profile-avatar-frame-$memberKey',
                                ),
                                decoration: BoxDecoration(
                                  color: colors.panelRaised,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  border: Border.all(
                                    color: colors.panelRaised,
                                    width: 4,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x66000000),
                                      blurRadius: 14,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: MemberMediaAvatar(
                                  member: member,
                                  mediaPolicy: widget.mediaPolicy,
                                  size: 72,
                                  playAnimatedMedia: true,
                                  imageKeyPrefix: 'member-profile-avatar-image',
                                  loadingPlaceholder: _ProfileAvatarLoading(
                                    key: ValueKey(
                                      'member-profile-avatar-loading-$memberKey',
                                    ),
                                    color: avatarColor,
                                    size: 72,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 92,
                              right: 0,
                              top: 42,
                              child: Column(
                                key: ValueKey(
                                  'member-profile-summary-column-$memberKey',
                                ),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color:
                                              member.displayColor ??
                                              colors.text,
                                          fontWeight: VerdantFontWeights.black,
                                          height: 1.0,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  MemberPresenceBadge(
                                    key: ValueKey(
                                      'member-profile-status-$memberKey',
                                    ),
                                    status: member.status,
                                    label: statusLabel,
                                    compact: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (member.role.isNotEmpty ||
                          (member.nameColorName?.trim().isNotEmpty ??
                              false)) ...[
                        Divider(height: 1, thickness: 1, color: colors.border),
                        const SizedBox(height: 10),
                        Text(
                          'ROLES',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.textMuted,
                                fontWeight: VerdantFontWeights.heavy,
                                letterSpacing: 0,
                              ),
                        ),
                        const SizedBox(height: 8),
                        if (member.role.isNotEmpty)
                          _ProfileRoleChip(role: member.role, color: roleColor),
                        if (member.nameColorName?.trim().isNotEmpty ??
                            false) ...[
                          if (member.role.isNotEmpty) const SizedBox(height: 8),
                          Text(
                            'Name Color',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.textMuted,
                                  fontWeight: VerdantFontWeights.heavy,
                                ),
                          ),
                          const SizedBox(height: 6),
                          _ProfileRoleChip(
                            role: member.nameColorName!.trim(),
                            color: roleColor,
                          ),
                        ],
                      ],
                      if (originUserId != null || canCopyUserId) ...[
                        const SizedBox(height: 12),
                        Divider(height: 1, thickness: 1, color: colors.border),
                        const SizedBox(height: 8),
                        if (originUserId != null) ...[
                          _ProfileIdentityAction(
                            key: ValueKey(
                              'member-profile-copy-origin-id-$memberKey',
                            ),
                            label: 'Copy Origin ID',
                            onPressed: () {
                              unawaited(
                                Clipboard.setData(
                                  ClipboardData(text: originUserId),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (canCopyUserId)
                          _ProfileIdentityAction(
                            key: ValueKey(
                              'member-profile-copy-user-id-$memberKey',
                            ),
                            label: workspaceUserCopyLabel(member.id),
                            onPressed: () {
                              unawaited(
                                Clipboard.setData(ClipboardData(text: userId)),
                              );
                            },
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRoleChip extends StatelessWidget {
  const _ProfileRoleChip({required this.role, required this.color});

  final String role;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: VerdantRadii.sharp,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 8),
            ),
            const SizedBox(width: 6),
            Text(
              role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: VerdantFontWeights.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileIdentityAction extends StatelessWidget {
  const _ProfileIdentityAction({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: VerdantRadii.sharp,
      child: InkWell(
        onTap: onPressed,
        borderRadius: VerdantRadii.sharp,
        hoverColor: colors.panelHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.copy_outlined, size: 16, color: colors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.text,
                    fontWeight: VerdantFontWeights.heavy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatarLoading extends StatelessWidget {
  const _ProfileAvatarLoading({
    required this.color,
    required this.size,
    super.key,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.28),
            colors.panelHover.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.textMuted.withValues(alpha: 0.18),
              borderRadius: VerdantRadii.sharp,
            ),
            child: SizedBox.square(dimension: size * 0.34),
          ),
        ),
      ),
    );
  }
}

class _ProfileBannerLoading extends StatelessWidget {
  const _ProfileBannerLoading({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.22),
            colors.panelRaised.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.textMuted.withValues(alpha: 0.12),
              borderRadius: VerdantRadii.sharp,
            ),
            child: const SizedBox(width: 116, height: 14),
          ),
        ),
      ),
    );
  }
}

class MemberMediaAvatar extends StatelessWidget {
  const MemberMediaAvatar({
    required this.member,
    required this.mediaPolicy,
    required this.size,
    required this.playAnimatedMedia,
    required this.imageKeyPrefix,
    this.loadingPlaceholder,
    super.key,
  });

  final MemberSeed member;
  final ServerMediaPolicy mediaPolicy;
  final double size;
  final bool playAnimatedMedia;
  final String imageKeyPrefix;
  final Widget? loadingPlaceholder;

  @override
  Widget build(BuildContext context) {
    final playLiveMedia =
        playAnimatedMedia && WindowFocusScope.isFocusedOf(context);
    final memberKey = member.id ?? member.name;
    final color = avatarColorFor(member.name);
    final fallback = _AvatarInitials(
      surfaceKey: ValueKey('member-avatar-fallback-$memberKey'),
      initials: member.initials,
      color: color,
      size: size,
    );
    final avatarUrl = member.avatarUrl;
    final avatarUri = safeServerMediaUri(avatarUrl, policy: mediaPolicy);
    if (avatarUri == null) {
      return fallback;
    }
    final memberMediaKey = '$imageKeyPrefix-$memberKey';
    final loading = loadingPlaceholder ?? const _AvatarMediaLoading();

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: SizedBox.square(
        dimension: size,
        child: SafeServerMediaImage(
          uri: avatarUri,
          policy: mediaPolicy,
          surface: ServerMediaSurface.image,
          retainWhenUnfocused: true,
          fallback: fallback,
          loading: loading,
          builder: (context, imageProvider) {
            if (_shouldFreezeMemberMedia(avatarUrl, playLiveMedia)) {
              return StaticFirstFrameImage(
                key: ValueKey('$imageKeyPrefix-static-$memberKey'),
                imageProvider: imageProvider,
                width: size,
                height: size,
              );
            }
            return Image(
              key: ValueKey(memberMediaKey),
              image: imageProvider,
              width: size,
              height: size,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => fallback,
            );
          },
        ),
      ),
    );
  }
}

class _AvatarMediaLoading extends StatelessWidget {
  const _AvatarMediaLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}

class MemberMediaBanner extends StatelessWidget {
  const MemberMediaBanner({
    required this.member,
    required this.mediaPolicy,
    required this.playAnimatedMedia,
    required this.imageKeyPrefix,
    this.fallbackOpacity = 0.72,
    this.loadingPlaceholder,
    this.bannerUrlOverride,
    this.bannerCropOverride,
    this.fallbackColorOverride,
    super.key,
  });

  final MemberSeed member;
  final ServerMediaPolicy mediaPolicy;
  final bool playAnimatedMedia;
  final String imageKeyPrefix;
  final double fallbackOpacity;
  final Widget? loadingPlaceholder;
  final String? bannerUrlOverride;
  final BannerCrop? bannerCropOverride;
  final Color? fallbackColorOverride;

  @override
  Widget build(BuildContext context) {
    final playLiveMedia =
        playAnimatedMedia && WindowFocusScope.isFocusedOf(context);
    final memberKey = member.id ?? member.name;
    final fallbackColor =
        fallbackColorOverride ??
        member.bannerBaseColor ??
        member.displayColor ??
        avatarColorFor(member.name);
    final fallback = _BannerFallback(
      key: ValueKey('member-banner-fallback-$memberKey'),
      color: fallbackColor,
      opacity: fallbackOpacity,
    );
    final bannerUrl = bannerUrlOverride ?? member.bannerUrl;
    final bannerCrop = bannerUrlOverride == null
        ? member.bannerCrop
        : bannerCropOverride;
    final bannerUri = safeServerMediaUri(bannerUrl, policy: mediaPolicy);
    if (bannerUri == null) {
      return fallback;
    }
    final memberMediaKey = '$imageKeyPrefix-$memberKey';

    return SafeServerMediaImage(
      uri: bannerUri,
      policy: mediaPolicy,
      surface: ServerMediaSurface.serverBanner,
      retainWhenUnfocused: true,
      fallback: fallback,
      loading: loadingPlaceholder,
      builder: (context, imageProvider) {
        if (_shouldFreezeMemberMedia(bannerUrl, playLiveMedia)) {
          return CroppedStaticFirstFrameBannerImage(
            key: ValueKey('$imageKeyPrefix-static-$memberKey'),
            imageProvider: imageProvider,
            crop: bannerCrop,
          );
        }
        return CroppedServerBannerImage(
          imageProvider: imageProvider,
          crop: bannerCrop,
          imageKey: ValueKey(memberMediaKey),
          animate: playLiveMedia,
        );
      },
    );
  }
}

class MemberPresenceBadge extends StatelessWidget {
  const MemberPresenceBadge({
    required this.status,
    this.label,
    this.compact = false,
    super.key,
  });

  final String status;
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = memberPresenceColor(status);
    final statusLabel = label ?? memberPresenceLabel(status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: VerdantRadii.sharp,
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 3 : 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: memberStatusIsOnline(status)
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.42),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: SizedBox.square(dimension: compact ? 7 : 8),
            ),
            const SizedBox(width: 6),
            Text(
              statusLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: VerdantFontWeights.heavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color avatarColorFor(String name) {
  const palette = [
    Color(0xFFE94560),
    Color(0xFF0F3460),
    Color(0xFF43B581),
    Color(0xFFFAA61A),
    Color(0xFF7289DA),
    Color(0xFFE67E22),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE74C3C),
    Color(0xFF3498DB),
  ];
  var hash = 0;
  for (final codeUnit in name.codeUnits) {
    hash = codeUnit + ((hash << 5) - hash);
  }
  return palette[hash.abs() % palette.length];
}

bool memberStatusIsOffline(String status) {
  return status.toLowerCase().contains('offline');
}

bool memberStatusIsOnline(String status) {
  final normalized = status.toLowerCase();
  return normalized.contains('online') || normalized.contains('dnd');
}

String memberPresenceLabel(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('online')) {
    return 'Online';
  }
  if (normalized.contains('idle')) {
    return 'Idle';
  }
  if (normalized.contains('busy') || normalized.contains('dnd')) {
    return 'Do Not Disturb';
  }
  return 'Offline';
}

Color memberPresenceColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('online')) {
    return VerdantColors.accentStrong;
  }
  if (normalized.contains('idle')) {
    return const Color(0xFFFFD166);
  }
  if (normalized.contains('busy') || normalized.contains('dnd')) {
    return const Color(0xFFFF6B78);
  }
  return VerdantColors.textMuted;
}

bool _shouldFreezeMemberMedia(String? url, bool playAnimatedMedia) {
  if (url == null || playAnimatedMedia) {
    return false;
  }
  final uri = Uri.tryParse(url);
  final path = uri != null && uri.path.isNotEmpty
      ? uri.path.toLowerCase()
      : url.toLowerCase();
  return path.endsWith('.gif') || path.endsWith('.webp');
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({
    required this.initials,
    required this.color,
    required this.size,
    this.surfaceKey,
  });

  final String initials;
  final Color color;
  final double size;
  final Key? surfaceKey;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: surfaceKey,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: DecoratedBox(
        decoration: BoxDecoration(color: color),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Text(
              initials,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: Colors.white,
                fontSize: size >= 60 ? 24 : 13,
                fontWeight: VerdantFontWeights.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerFallback extends StatelessWidget {
  const _BannerFallback({
    required this.color,
    required this.opacity,
    super.key,
  });

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final strongColor = Color.alphaBlend(
      color.withValues(alpha: opacity.clamp(0.0, 1.0)),
      colors.panelHover,
    );
    final softColor = Color.alphaBlend(
      color.withValues(alpha: (opacity * 0.48).clamp(0.0, 1.0)),
      colors.panel,
    );
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [strongColor, softColor, colors.panelRaised],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}
