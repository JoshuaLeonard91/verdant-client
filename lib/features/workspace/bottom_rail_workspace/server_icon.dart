import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../theme/verdant_theme.dart';
import '../shared/user_context_menu.dart';
import '../server_settings_workspace/server_media_image.dart';
import 'bottom_rail_models.dart';

class ServerIconModule extends StatefulWidget {
  const ServerIconModule({
    required this.server,
    required this.networkName,
    required this.isSelected,
    required this.onPressed,
    this.networkModeLabel = 'Network',
    this.networkStatusLabel = 'Signed in',
    this.networkStatusTone = RailNetworkStatusTone.success,
    this.onCreateInvite,
    this.onLeaveServer,
    super.key,
  });

  final RailServerItem server;
  final String networkName;
  final String networkModeLabel;
  final String networkStatusLabel;
  final RailNetworkStatusTone networkStatusTone;
  final bool isSelected;
  final VoidCallback onPressed;
  final VoidCallback? onCreateInvite;
  final VoidCallback? onLeaveServer;

  @override
  State<ServerIconModule> createState() => _ServerIconModuleState();
}

class _ServerIconModuleState extends State<ServerIconModule> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final server = widget.server;
    final isInteractive = _isHovered || widget.isSelected;
    final iconSize = isInteractive ? 48.0 : 46.0;
    final showMention = !server.isUnavailable && server.mentionCount > 0;
    final showUnread =
        !server.isUnavailable && !showMention && server.unreadCount > 0;
    final showNetworkBadge =
        widget.networkModeLabel != 'Network' ||
        widget.networkStatusTone != RailNetworkStatusTone.success;
    Widget iconMedia = ServerMediaIcon(
      name: server.name,
      iconUrl: server.iconUrl,
      mediaPolicy: server.mediaPolicy,
      size: iconSize,
      showBorder: false,
      animate: _isHovered,
      imageKey: ValueKey('server-rail-icon-media-${server.scopedServerId}'),
    );
    if (server.isUnavailable) {
      iconMedia = ImageFiltered(
        key: ValueKey('server-rail-unavailable-blur-${server.scopedServerId}'),
        imageFilter: ui.ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
        child: Opacity(opacity: 0.54, child: iconMedia),
      );
    }

    return Tooltip(
      message: _tooltipMessage(server),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPressed,
              onSecondaryTapUp: _showContextMenu,
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: ValueKey('server-rail-item-${server.scopedServerId}'),
                    customBorder: const RoundedRectangleBorder(
                      borderRadius: VerdantRadii.sharp,
                    ),
                    hoverColor: colors.desktopHoverOverlay,
                    splashColor: Colors.transparent,
                    highlightColor: colors.desktopPressedOverlay,
                    child: Center(
                      child: AnimatedScale(
                        scale: isInteractive ? 1.045 : 1,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            color: server.iconUrl == null
                                ? colors.actionMuted
                                : colors.background,
                            borderRadius: VerdantRadii.sharp,
                            boxShadow: widget.isSelected
                                ? [
                                    BoxShadow(
                                      color: colors.accent.withValues(
                                        alpha: 0.34,
                                      ),
                                      blurRadius: 14,
                                    ),
                                  ]
                                : [
                                    if (_isHovered)
                                      BoxShadow(
                                        color: colors.accent.withValues(
                                          alpha: 0.16,
                                        ),
                                        blurRadius: 10,
                                      ),
                                  ],
                          ),
                          child: Stack(
                            children: [
                              iconMedia,
                              if (server.isUnavailable)
                                _UnavailableOverlay(
                                  scopedServerId: server.scopedServerId,
                                ),
                              if (showNetworkBadge)
                                _NetworkModeBadge(
                                  key: ValueKey(
                                    'server-rail-network-badge-${server.scopedServerId}',
                                  ),
                                  tone: widget.networkStatusTone,
                                ),
                              if (showMention)
                                _CountBadge(count: server.mentionCount)
                              else if (showUnread)
                                const _UnreadBadge(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: widget.isSelected
                  ? 26
                  : showUnread || showMention
                  ? 10
                  : 0,
              height: 2,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tooltipMessage(RailServerItem server) {
    final networkLabel = widget.networkModeLabel == 'Network'
        ? widget.networkName
        : '${widget.networkModeLabel} via ${widget.networkName}';
    if (widget.networkStatusLabel == 'Signed in') {
      return '${server.name} - $networkLabel';
    }
    return '${server.name} - $networkLabel (${widget.networkStatusLabel})';
  }

  Future<void> _showContextMenu(TapUpDetails details) async {
    final selected = await showWorkspaceUserContextMenu(
      context: context,
      globalPosition: details.globalPosition,
      entries: [
        WorkspaceUserContextMenuItem(
          id: 'server-rail-create-invite',
          label: 'Create Invite Link',
          icon: PhosphorIconsRegular.linkSimple,
          enabled: widget.onCreateInvite != null,
        ),
        const WorkspaceUserContextMenuDivider(),
        WorkspaceUserContextMenuItem(
          id: 'server-rail-leave-server',
          label: 'Leave Server',
          icon: PhosphorIconsRegular.signOut,
          tone: WorkspaceUserContextMenuTone.danger,
          enabled: widget.onLeaveServer != null,
        ),
      ],
    );
    switch (selected) {
      case 'server-rail-create-invite':
        widget.onCreateInvite?.call();
      case 'server-rail-leave-server':
        widget.onLeaveServer?.call();
      case null:
        break;
      default:
        break;
    }
  }
}

class _NetworkModeBadge extends StatelessWidget {
  const _NetworkModeBadge({required this.tone, super.key});

  final RailNetworkStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final color = _toneColor(tone, colors);
    return Positioned(
      left: 2,
      bottom: 2,
      child: Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.94),
          border: Border.all(color: color, width: 1.5),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: PhosphorIcon(
          PhosphorIconsRegular.linkSimple,
          size: 8,
          color: color,
        ),
      ),
    );
  }
}

class _UnavailableOverlay extends StatelessWidget {
  const _UnavailableOverlay({required this.scopedServerId});

  final String scopedServerId;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      key: ValueKey('server-rail-unavailable-overlay-$scopedServerId'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.34),
            ),
          ),
          Center(
            child: Container(
              key: ValueKey('server-rail-unavailable-badge-$scopedServerId'),
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFDC3F4D),
                border: Border.all(color: Colors.white, width: 1.4),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Color(0x88000000), blurRadius: 8),
                ],
              ),
              child: const Text(
                '!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _toneColor(RailNetworkStatusTone tone, VerdantThemeColors colors) {
  return switch (tone) {
    RailNetworkStatusTone.danger => const Color(0xFFEF4444),
    RailNetworkStatusTone.warning => const Color(0xFFF59E0B),
    RailNetworkStatusTone.success => colors.accent,
    RailNetworkStatusTone.muted => colors.textMuted,
  };
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 3,
      top: 3,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFFDC3F4D),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 1,
      top: 1,
      child: Container(
        height: 18,
        constraints: const BoxConstraints(minWidth: 18),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: const BoxDecoration(
          color: Color(0xFFDC3F4D),
          borderRadius: BorderRadius.all(Radius.circular(9)),
        ),
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
