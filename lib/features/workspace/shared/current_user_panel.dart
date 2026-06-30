import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_image.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../server_settings_workspace/server_settings_models.dart';
import 'member_profile_popover.dart';
import 'user_identity_labels.dart';

class WorkspaceCurrentUserPanel extends StatefulWidget {
  const WorkspaceCurrentUserPanel({
    required this.name,
    required this.username,
    required this.initials,
    required this.avatarUrl,
    required this.bannerUrl,
    required this.bannerBaseColor,
    required this.bannerCrop,
    required this.status,
    required this.userId,
    required this.bio,
    required this.mediaPolicy,
    required this.onLogout,
    required this.onOpenUserSettings,
    required this.onUpdateStatus,
    this.showLogout = true,
    super.key,
  });

  final String name;
  final String username;
  final String initials;
  final String? avatarUrl;
  final String? bannerUrl;
  final Color? bannerBaseColor;
  final BannerCrop? bannerCrop;
  final String status;
  final String? userId;
  final String? bio;
  final ServerMediaPolicy mediaPolicy;
  final VoidCallback onLogout;
  final VoidCallback onOpenUserSettings;
  final Future<void> Function(String status)? onUpdateStatus;
  final bool showLogout;

  @override
  State<WorkspaceCurrentUserPanel> createState() =>
      _WorkspaceCurrentUserPanelState();
}

class _WorkspaceCurrentUserPanelState extends State<WorkspaceCurrentUserPanel> {
  final _profileLink = LayerLink();
  OverlayEntry? _profileOverlay;
  double _profileWidth = 280;
  var _profileOpen = false;
  var _profileOverlayRefreshScheduled = false;

  @override
  void didUpdateWidget(covariant WorkspaceCurrentUserPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleProfileOverlayRefresh();
  }

  @override
  void dispose() {
    _profileOverlay?.remove();
    _profileOverlay = null;
    super.dispose();
  }

  void _scheduleProfileOverlayRefresh() {
    if (_profileOverlay == null || _profileOverlayRefreshScheduled) {
      return;
    }
    _profileOverlayRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profileOverlayRefreshScheduled = false;
      if (!mounted) {
        return;
      }
      final overlay = _profileOverlay;
      if (overlay == null || !overlay.mounted) {
        return;
      }
      overlay.markNeedsBuild();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final panelHeight = math.max(68.0, textScaler.scale(40) + 28);
    final totalHeight = panelHeight + 24;

    return SizedBox(
      height: totalHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _profileWidth = math.max(0, constraints.maxWidth - 24);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                height: panelHeight,
                child: CompositedTransformTarget(
                  link: _profileLink,
                  child: _CurrentUserPanelSurface(
                    name: widget.name,
                    username: widget.username,
                    initials: widget.initials,
                    avatarUrl: widget.avatarUrl,
                    status: widget.status,
                    mediaPolicy: widget.mediaPolicy,
                    onProfilePressed: _toggleProfile,
                    onLogout: widget.onLogout,
                    showLogout: widget.showLogout,
                    onOpenUserSettings: widget.onOpenUserSettings,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleProfile() {
    if (_profileOpen) {
      _closeProfile();
    } else {
      _openProfile();
    }
  }

  void _openProfile() {
    if (_profileOpen) {
      return;
    }
    setState(() => _profileOpen = true);
    _profileOverlay = OverlayEntry(builder: _buildProfileOverlay);
    Overlay.of(context, rootOverlay: true).insert(_profileOverlay!);
  }

  void _closeProfile() {
    final overlay = _profileOverlay;
    _profileOverlay = null;
    overlay?.remove();
    if (mounted && _profileOpen) {
      setState(() => _profileOpen = false);
    } else {
      _profileOpen = false;
    }
  }

  Widget _buildProfileOverlay(BuildContext context) {
    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeProfile,
              child: const SizedBox.expand(),
            ),
            CompositedTransformFollower(
              link: _profileLink,
              targetAnchor: Alignment.topLeft,
              followerAnchor: Alignment.bottomLeft,
              offset: const Offset(0, -10),
              showWhenUnlinked: false,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: _profileWidth + _currentUserStatusFlyoutWidth + 14,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.98, end: 1),
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        alignment: Alignment.bottomLeft,
                        child: Opacity(
                          opacity: scale.clamp(0, 1).toDouble(),
                          child: child,
                        ),
                      );
                    },
                    child: _CurrentUserProfilePopover(
                      cardWidth: _profileWidth,
                      name: widget.name,
                      username: widget.username,
                      initials: widget.initials,
                      avatarUrl: widget.avatarUrl,
                      bannerUrl: widget.bannerUrl,
                      bannerBaseColor: widget.bannerBaseColor,
                      bannerCrop: widget.bannerCrop,
                      status: widget.status,
                      userId: widget.userId,
                      bio: widget.bio,
                      mediaPolicy: widget.mediaPolicy,
                      onEditProfile: () {
                        _closeProfile();
                        widget.onOpenUserSettings();
                      },
                      onUpdateStatus: widget.onUpdateStatus,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentUserPanelSurface extends StatelessWidget {
  const _CurrentUserPanelSurface({
    required this.name,
    required this.username,
    required this.initials,
    required this.avatarUrl,
    required this.status,
    required this.mediaPolicy,
    required this.onProfilePressed,
    required this.onLogout,
    required this.showLogout,
    required this.onOpenUserSettings,
  });

  final String name;
  final String username;
  final String initials;
  final String? avatarUrl;
  final String status;
  final ServerMediaPolicy mediaPolicy;
  final VoidCallback onProfilePressed;
  final VoidCallback onLogout;
  final bool showLogout;
  final VoidCallback onOpenUserSettings;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final typography = VerdantThemeTypography.of(context);
    final usernameLabel = _currentUserUsernameLabel(username, name);
    return Container(
      key: const ValueKey('workspace-current-user-panel'),
      padding: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        borderRadius: VerdantRadii.sharp,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Tooltip(
              message: 'View Profile',
              child: SizedBox(
                height: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: VerdantRadii.sharp,
                  child: InkWell(
                    key: const ValueKey(
                      'workspace-current-user-profile-button',
                    ),
                    onTap: onProfilePressed,
                    borderRadius: VerdantRadii.sharp,
                    hoverColor: colors.panelHover.withValues(alpha: 0.76),
                    splashColor: colors.accent.withValues(alpha: 0.12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          _CurrentUserAvatar(
                            name: name,
                            initials: initials,
                            avatarUrl: avatarUrl,
                            mediaPolicy: mediaPolicy,
                            size: 44,
                            showPresence: true,
                            status: status,
                            animate: true,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: typography.buttonLabel.copyWith(
                                    fontWeight: VerdantFontWeights.heavy,
                                  ),
                                ),
                                Text(
                                  usernameLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: typography.workspaceCaption.copyWith(
                                    color: colors.accentStrong,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            key: const ValueKey('workspace-user-settings-button'),
            tooltip: 'User settings',
            onPressed: onOpenUserSettings,
            icon: const Icon(Icons.tune, size: 18),
            color: colors.textMuted,
            splashRadius: 18,
          ),
          if (showLogout)
            IconButton(
              key: const ValueKey('workspace-logout-button'),
              tooltip: 'Logout',
              onPressed: onLogout,
              icon: const Icon(Icons.logout, size: 18),
              color: colors.textMuted,
              splashRadius: 18,
            ),
        ],
      ),
    );
  }
}

String _currentUserUsernameLabel(String username, String fallbackName) {
  final trimmed = username.trim();
  final label = trimmed.isNotEmpty ? trimmed : fallbackName.trim();
  if (label.isEmpty) {
    return '@unknown';
  }
  return label.startsWith('@') ? label : '@$label';
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.size,
    this.borderRadius = VerdantRadii.sharp,
  });

  final String initials;
  final double size;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.orange,
        borderRadius: borderRadius,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size >= 64 ? 22 : 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CurrentUserAvatar extends StatelessWidget {
  const _CurrentUserAvatar({
    required this.name,
    required this.initials,
    required this.avatarUrl,
    required this.mediaPolicy,
    required this.size,
    required this.showPresence,
    required this.status,
    this.animate = false,
    super.key,
  });

  final String name;
  final String initials;
  final String? avatarUrl;
  final ServerMediaPolicy mediaPolicy;
  final double size;
  final bool showPresence;
  final String status;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final avatar = avatarUrl == null
        ? _Avatar(
            initials: initials,
            size: size,
            borderRadius: const BorderRadius.all(Radius.circular(7)),
          )
        : ServerMediaIcon(
            name: name,
            iconUrl: avatarUrl,
            mediaPolicy: mediaPolicy,
            size: size,
            showBorder: false,
            animate: animate,
            borderRadius: const BorderRadius.all(Radius.circular(7)),
            imageKey: ValueKey('current-user-avatar-media-$name'),
          );
    if (!showPresence) {
      return avatar;
    }
    final color = memberPresenceColor(status);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -1,
          bottom: -1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.panelRaised,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: 9),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrentUserProfilePopover extends StatefulWidget {
  const _CurrentUserProfilePopover({
    required this.cardWidth,
    required this.name,
    required this.username,
    required this.initials,
    required this.avatarUrl,
    required this.bannerUrl,
    required this.bannerBaseColor,
    required this.bannerCrop,
    required this.status,
    required this.userId,
    required this.bio,
    required this.mediaPolicy,
    required this.onEditProfile,
    required this.onUpdateStatus,
  });

  final double cardWidth;
  final String name;
  final String username;
  final String initials;
  final String? avatarUrl;
  final String? bannerUrl;
  final Color? bannerBaseColor;
  final BannerCrop? bannerCrop;
  final String status;
  final String? userId;
  final String? bio;
  final ServerMediaPolicy mediaPolicy;
  final VoidCallback onEditProfile;
  final Future<void> Function(String status)? onUpdateStatus;

  @override
  State<_CurrentUserProfilePopover> createState() =>
      _CurrentUserProfilePopoverState();
}

const _currentUserStatusFlyoutWidth = 212.0;
const _currentUserStatusFlyoutGap = 10.0;

class _CurrentUserProfilePopoverState
    extends State<_CurrentUserProfilePopover> {
  String? _optimisticStatus;
  var _statusFlyoutOpen = false;
  bool _statusBusy = false;
  bool _avatarHovered = false;

  String get _status => _optimisticStatus ?? widget.status;

  @override
  void didUpdateWidget(covariant _CurrentUserProfilePopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_optimisticStatus != null &&
        _statusEquals(widget.status, _optimisticStatus!)) {
      _optimisticStatus = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.cardWidth + _currentUserStatusFlyoutWidth + 14,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(width: widget.cardWidth, child: _buildProfileCard(context)),
          if (_statusFlyoutOpen)
            Positioned(
              left: widget.cardWidth + _currentUserStatusFlyoutGap,
              top: 214,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(10 * (1 - value), 0),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: _CurrentUserStatusFlyout(
                  currentStatus: _status,
                  busy: _statusBusy,
                  onSelect: widget.onUpdateStatus == null
                      ? null
                      : (status) => _selectStatus(status),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final statusLabel = memberPresenceLabel(_status);
    return Material(
      key: const ValueKey('current-user-profile-popover'),
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.panelRaised,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: colors.borderStrong),
          boxShadow: [
            BoxShadow(
              color: colors.accentStrong.withValues(alpha: 0.26),
              blurRadius: 0,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: colors.accent.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CurrentUserProfileBanner(
                name: widget.name,
                bannerUrl: widget.bannerUrl,
                bannerBaseColor: widget.bannerBaseColor,
                bannerCrop: widget.bannerCrop,
                mediaPolicy: widget.mediaPolicy,
                onPressed: widget.onEditProfile,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -25),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Semantics(
                            button: true,
                            label: 'Change avatar',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: const ValueKey(
                                  'current-user-profile-avatar-button',
                                ),
                                onTap: widget.onEditProfile,
                                onHover: (hovered) {
                                  setState(() => _avatarHovered = hovered);
                                },
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(11),
                                ),
                                hoverColor: colors.panelHover.withValues(
                                  alpha: 0.22,
                                ),
                                splashColor: colors.accent.withValues(
                                  alpha: 0.14,
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors.panelRaised,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(11),
                                    ),
                                    border: Border.all(
                                      color: colors.panelRaised,
                                      width: 4,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      _CurrentUserAvatar(
                                        key: const ValueKey(
                                          'current-user-profile-avatar-media-root',
                                        ),
                                        name: widget.name,
                                        initials: widget.initials,
                                        avatarUrl: widget.avatarUrl,
                                        mediaPolicy: widget.mediaPolicy,
                                        size: 72,
                                        showPresence: true,
                                        status: _status,
                                        animate: true,
                                      ),
                                      Positioned.fill(
                                        child: AnimatedContainer(
                                          key: const ValueKey(
                                            'current-user-profile-avatar-hover-surface',
                                          ),
                                          duration: const Duration(
                                            milliseconds: 140,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.all(
                                                  Radius.circular(7),
                                                ),
                                            border: Border.all(
                                              color: _avatarHovered
                                                  ? colors.accentStrong
                                                  : Colors.transparent,
                                            ),
                                            boxShadow: _avatarHovered
                                                ? [
                                                    BoxShadow(
                                                      color: colors.accentStrong
                                                          .withValues(
                                                            alpha: 0.22,
                                                          ),
                                                      blurRadius: 12,
                                                    ),
                                                  ]
                                                : const [],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          if (widget.username != widget.name)
                            Text(
                              '@${widget.username}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (widget.bio != null &&
                              widget.bio!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.bio!.trim(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Divider(height: 1, color: colors.border),
                    const SizedBox(height: 8),
                    _CurrentUserStatusSummaryButton(
                      status: _status,
                      label: statusLabel,
                      busy: _statusBusy,
                      expanded: _statusFlyoutOpen,
                      onPressed: () {
                        setState(() => _statusFlyoutOpen = !_statusFlyoutOpen);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (widget.userId != null &&
                        widget.userId!.trim().isNotEmpty) ...[
                      _CurrentUserProfileAction(
                        key: const ValueKey(
                          'current-user-profile-copy-user-id-button',
                        ),
                        icon: Icons.copy_outlined,
                        label: workspaceUserCopyLabel(widget.userId),
                        onPressed: _copyUserId,
                      ),
                      const SizedBox(height: 2),
                    ],
                    _CurrentUserProfileAction(
                      key: const ValueKey('current-user-profile-edit-button'),
                      icon: Icons.edit_outlined,
                      label: 'Edit Profile',
                      onPressed: widget.onEditProfile,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectStatus(String status) async {
    final onUpdateStatus = widget.onUpdateStatus;
    if (onUpdateStatus == null || _statusBusy) {
      return;
    }
    final previous = _status;
    setState(() {
      _optimisticStatus = status;
      _statusBusy = true;
    });
    try {
      await onUpdateStatus(status);
      if (!mounted) {
        return;
      }
      setState(() {
        _statusBusy = false;
        _statusFlyoutOpen = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (_isRetryableStatusError(error)) {
        setState(() {
          _statusBusy = false;
          _statusFlyoutOpen = false;
        });
        return;
      }
      setState(() {
        _optimisticStatus = previous;
        _statusBusy = false;
      });
    }
  }

  bool _isRetryableStatusError(Object error) {
    final message = error.toString();
    return message.contains('Realtime is reconnecting') ||
        message.contains('Realtime commands are unavailable') ||
        message.contains('Realtime session closed before READY') ||
        message.contains('Realtime session is not ready') ||
        message.contains('Realtime connection timed out') ||
        message.contains('Realtime session timed out') ||
        message.contains('WebSocket') ||
        message.contains('SocketException');
  }

  void _copyUserId() {
    final userId = widget.userId?.trim();
    if (userId == null || userId.isEmpty) {
      return;
    }
    unawaited(
      Clipboard.setData(
        ClipboardData(
          text: workspaceUserClipboardId(userId, fallback: widget.name),
        ),
      ),
    );
  }
}

class _CurrentUserProfileBanner extends StatefulWidget {
  const _CurrentUserProfileBanner({
    required this.name,
    required this.bannerUrl,
    required this.bannerBaseColor,
    required this.bannerCrop,
    required this.mediaPolicy,
    required this.onPressed,
  });

  final String name;
  final String? bannerUrl;
  final Color? bannerBaseColor;
  final BannerCrop? bannerCrop;
  final ServerMediaPolicy mediaPolicy;
  final VoidCallback onPressed;

  @override
  State<_CurrentUserProfileBanner> createState() =>
      _CurrentUserProfileBannerState();
}

class _CurrentUserProfileBannerState extends State<_CurrentUserProfileBanner> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final bannerUri = safeServerMediaUri(
      widget.bannerUrl,
      policy: widget.mediaPolicy,
    );
    final fallbackColor = widget.bannerBaseColor ?? avatarColorFor(widget.name);
    return Semantics(
      button: true,
      label: bannerUri == null ? 'Add profile banner' : 'Position banner',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('current-user-profile-banner-button'),
          onTap: widget.onPressed,
          onHover: (hovered) {
            setState(() => _hovered = hovered);
          },
          hoverColor: colors.panelHover.withValues(alpha: 0.22),
          focusColor: colors.panelHover.withValues(alpha: 0.22),
          splashColor: colors.accent.withValues(alpha: 0.14),
          child: SizedBox(
            height: 110,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bannerUri == null)
                  _CurrentUserBannerFallback(color: fallbackColor)
                else
                  SafeServerMediaImage(
                    key: const ValueKey(
                      'current-user-profile-banner-media-root',
                    ),
                    uri: bannerUri,
                    policy: widget.mediaPolicy,
                    surface: ServerMediaSurface.serverBanner,
                    retainWhenUnfocused: true,
                    fallback: _CurrentUserBannerFallback(color: fallbackColor),
                    builder: (context, imageProvider) {
                      return CroppedServerBannerImage(
                        imageProvider: imageProvider,
                        crop: widget.bannerCrop,
                        animate: true,
                        imageKey: const ValueKey(
                          'current-user-profile-banner-media',
                        ),
                      );
                    },
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x0A000000), Color(0x57000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedContainer(
                    key: const ValueKey(
                      'current-user-profile-banner-hover-surface',
                    ),
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _hovered
                            ? colors.accentStrong
                            : Colors.transparent,
                      ),
                      boxShadow: _hovered
                          ? [
                              BoxShadow(
                                color: colors.accentStrong.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 14,
                                spreadRadius: -1,
                              ),
                            ]
                          : const [],
                    ),
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

class _CurrentUserBannerFallback extends StatelessWidget {
  const _CurrentUserBannerFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.76),
            colors.panelHover.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _CurrentUserStatusOption {
  const _CurrentUserStatusOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

const _currentUserStatusOptions = [
  _CurrentUserStatusOption(
    value: 'online',
    label: 'Online',
    icon: Icons.circle,
  ),
  _CurrentUserStatusOption(
    value: 'idle',
    label: 'Idle',
    icon: Icons.nightlight_round,
  ),
  _CurrentUserStatusOption(
    value: 'dnd',
    label: 'Do Not Disturb',
    icon: Icons.do_disturb_on_outlined,
  ),
  _CurrentUserStatusOption(
    value: 'offline',
    label: 'Invisible',
    icon: Icons.circle_outlined,
  ),
];

class _CurrentUserStatusSummaryButton extends StatelessWidget {
  const _CurrentUserStatusSummaryButton({
    required this.status,
    required this.label,
    required this.busy,
    required this.expanded,
    required this.onPressed,
  });

  final String status;
  final String label;
  final bool busy;
  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final color = memberPresenceColor(status);
    return Material(
      color: Colors.transparent,
      borderRadius: VerdantRadii.sharp,
      child: InkWell(
        key: const ValueKey('current-user-profile-status-current'),
        onTap: busy ? null : onPressed,
        borderRadius: VerdantRadii.sharp,
        hoverColor: colors.panelHover,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            color: colors.panel.withValues(alpha: 0.7),
            border: Border.all(color: colors.border),
            borderRadius: VerdantRadii.sharp,
          ),
          child: Row(
            children: [
              if (busy)
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.circle, size: 13, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                expanded ? Icons.chevron_left : Icons.chevron_right,
                size: 18,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentUserStatusFlyout extends StatelessWidget {
  const _CurrentUserStatusFlyout({
    required this.currentStatus,
    required this.busy,
    required this.onSelect,
  });

  final String currentStatus;
  final bool busy;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Material(
      key: const ValueKey('current-user-profile-status-flyout'),
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.panelRaised,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: colors.borderStrong),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: SizedBox(
          width: _currentUserStatusFlyoutWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in _currentUserStatusOptions)
                  _CurrentUserStatusButton(
                    option: option,
                    selected: _statusEquals(currentStatus, option.value),
                    busy: busy,
                    onPressed: onSelect == null
                        ? null
                        : () => onSelect!(option.value),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentUserStatusButton extends StatelessWidget {
  const _CurrentUserStatusButton({
    required this.option,
    required this.selected,
    required this.busy,
    required this.onPressed,
  });

  final _CurrentUserStatusOption option;
  final bool selected;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final color = memberPresenceColor(option.value);
    return Material(
      color: Colors.transparent,
      borderRadius: VerdantRadii.sharp,
      child: InkWell(
        key: ValueKey('current-user-profile-status-${option.value}'),
        onTap: busy ? null : onPressed,
        borderRadius: VerdantRadii.sharp,
        hoverColor: colors.panelHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              Icon(option.icon, size: 15, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected ? colors.text : colors.textMuted,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check, size: 15, color: colors.accentStrong),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentUserProfileAction extends StatelessWidget {
  const _CurrentUserProfileAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
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
              Icon(icon, size: 16, color: colors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
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

bool _statusEquals(String left, String right) {
  final normalizedLeft = left.toLowerCase();
  final normalizedRight = right.toLowerCase();
  if (normalizedRight == 'dnd') {
    return normalizedLeft == 'dnd' || normalizedLeft.contains('busy');
  }
  return normalizedLeft == normalizedRight ||
      normalizedLeft.contains(normalizedRight);
}
