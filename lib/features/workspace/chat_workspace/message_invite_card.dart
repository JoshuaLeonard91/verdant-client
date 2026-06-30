import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../theme/verdant_theme.dart';
import '../../auth/auth_models.dart';
import '../server_settings_workspace/server_media_image.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../server_settings_workspace/server_settings_models.dart';
import 'chat_invite_link.dart';

typedef ChatInvitePreviewHandler =
    Future<ServerInvitePreview> Function(ChatInviteTarget target);
typedef ChatInviteAcceptHandler =
    Future<ServerSettingsServer> Function(
      ChatInviteTarget target,
      ServerInvitePreview preview,
    );

class MessageInviteCard extends StatefulWidget {
  const MessageInviteCard({
    required this.messageId,
    required this.target,
    required this.mediaPolicy,
    this.onPreview,
    this.onAccept,
    this.onLayoutSettled,
    super.key,
  });

  final String messageId;
  final ChatInviteTarget target;
  final ServerMediaPolicy mediaPolicy;
  final ChatInvitePreviewHandler? onPreview;
  final ChatInviteAcceptHandler? onAccept;
  final VoidCallback? onLayoutSettled;

  @override
  State<MessageInviteCard> createState() => _MessageInviteCardState();
}

class _MessageInviteCardState extends State<MessageInviteCard> {
  ServerInvitePreview? _preview;
  Object? _error;
  var _isLoading = false;
  var _isJoining = false;
  var _joined = false;
  var _copied = false;
  Timer? _copyTimer;

  @override
  void didUpdateWidget(covariant MessageInviteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target ||
        oldWidget.onPreview == null && widget.onPreview != null) {
      _preview = null;
      _error = null;
      _joined = false;
      _copied = false;
      _copyTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    const cardRadius = BorderRadius.all(Radius.circular(8));
    if (widget.onPreview == null) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      key: ValueKey('message-invite-card-surface-${widget.messageId}'),
      constraints: const BoxConstraints(maxWidth: 392, minHeight: 120),
      child: SizedBox(
        height: 120,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: VerdantColors.background,
            border: Border.all(color: VerdantColors.border),
            borderRadius: cardRadius,
          ),
          child: ClipRRect(
            borderRadius: cardRadius,
            child: preview == null
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: _InvitePlaceholder(
                      target: widget.target,
                      isLoading: _isLoading,
                      hasError: _error != null,
                      onPreview: _isLoading ? null : _loadPreview,
                      onCopy: _copyInviteLink,
                    ),
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: _InviteBannerBackground(
                          preview: preview,
                          mediaPolicy: widget.mediaPolicy,
                          messageId: widget.messageId,
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.44),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            ServerMediaIcon(
                              name: preview.server.name,
                              iconUrl: preview.server.iconUrl,
                              mediaPolicy: widget.mediaPolicy,
                              size: 64,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(8),
                              ),
                              imageKey: ValueKey(
                                'message-invite-icon-${widget.messageId}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 92),
                                child: _InviteCopy(
                                  preview: preview,
                                  target: widget.target,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 14,
                        child: _CopyInviteButton(
                          key: ValueKey(
                            'message-invite-copy-${widget.messageId}',
                          ),
                          copied: _copied,
                          onPressed: _copyInviteLink,
                        ),
                      ),
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: _JoinInviteButton(
                          key: ValueKey(
                            'message-invite-join-${widget.messageId}',
                          ),
                          preview: preview,
                          isJoining: _isJoining,
                          joined: _joined || preview.isMember,
                          onPressed:
                              _isJoining || widget.onAccept == null || _joined
                              ? null
                              : _joinInvite,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadPreview() async {
    final previewHandler = widget.onPreview;
    if (previewHandler == null || _isLoading || _preview != null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final preview = await previewHandler(widget.target);
      if (!mounted) {
        return;
      }
      setState(() {
        _preview = preview;
        _isLoading = false;
      });
      _notifyLayoutSettled();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _isLoading = false;
      });
      _notifyLayoutSettled();
    }
  }

  void _notifyLayoutSettled() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onLayoutSettled?.call();
        }
      });
    });
  }

  Future<void> _joinInvite() async {
    final accept = widget.onAccept;
    if (accept == null) {
      return;
    }
    setState(() {
      _isJoining = true;
      _error = null;
    });
    try {
      final preview = _preview;
      if (preview == null) {
        return;
      }
      await accept(widget.target, preview);
      if (!mounted) {
        return;
      }
      setState(() {
        _isJoining = false;
        _joined = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isJoining = false;
        _error = error;
      });
    }
  }

  Future<void> _copyInviteLink() async {
    final link = buildChatInviteShareLink(
      _preview?.code ?? widget.target.code,
      apiOrigin: widget.target.apiOrigin,
    );
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) {
      return;
    }
    _copyTimer?.cancel();
    setState(() => _copied = true);
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }
}

class _InvitePlaceholder extends StatelessWidget {
  const _InvitePlaceholder({
    required this.target,
    required this.isLoading,
    required this.hasError,
    required this.onPreview,
    required this.onCopy,
  });

  final ChatInviteTarget target;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onPreview;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PhosphorIcon(
          PhosphorIconsRegular.linkSimple,
          size: 18,
          color: VerdantColors.textMuted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasError
                    ? 'Invite unavailable'
                    : isLoading
                    ? 'Loading invite'
                    : 'Invite link',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                _inviteBackendLabel(target),
                key: const ValueKey('message-invite-placeholder-backend'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: VerdantColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        _InviteActionButton(
          key: const ValueKey('message-invite-copy-link-button'),
          onPressed: onCopy,
          icon: const PhosphorIcon(PhosphorIconsRegular.copy, size: 14),
          label: '',
          width: 30,
        ),
        const SizedBox(width: 6),
        if (isLoading)
          const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          _InviteActionButton(
            key: const ValueKey('message-invite-preview-button'),
            onPressed: onPreview,
            icon: const PhosphorIcon(PhosphorIconsRegular.eye, size: 14),
            label: '',
            width: 30,
          ),
      ],
    );
  }
}

class _InviteBannerBackground extends StatelessWidget {
  const _InviteBannerBackground({
    required this.preview,
    required this.mediaPolicy,
    required this.messageId,
  });

  final ServerInvitePreview preview;
  final ServerMediaPolicy mediaPolicy;
  final String messageId;

  @override
  Widget build(BuildContext context) {
    final bannerUri = safeServerMediaUri(
      preview.server.bannerUrl,
      policy: mediaPolicy,
    );
    final iconUri = safeServerMediaUri(
      preview.server.iconUrl,
      policy: mediaPolicy,
    );
    if (bannerUri == null) {
      if (iconUri != null) {
        return SafeServerMediaImage(
          uri: iconUri,
          policy: mediaPolicy,
          surface: ServerMediaSurface.serverIcon,
          retainWhenUnfocused: true,
          fallback: const _InviteFallbackGradient(),
          builder: (context, imageProvider) {
            return _InviteIconBackdrop(
              imageProvider: imageProvider,
              imageKey: ValueKey('message-invite-fallback-banner-$messageId'),
            );
          },
        );
      }
      return const _InviteFallbackGradient();
    }
    return SafeServerMediaImage(
      uri: bannerUri,
      policy: mediaPolicy,
      surface: ServerMediaSurface.serverBanner,
      retainWhenUnfocused: true,
      fallback: iconUri == null
          ? const _InviteFallbackGradient()
          : SafeServerMediaImage(
              uri: iconUri,
              policy: mediaPolicy,
              surface: ServerMediaSurface.serverIcon,
              retainWhenUnfocused: true,
              fallback: const _InviteFallbackGradient(),
              builder: (context, imageProvider) {
                return _InviteIconBackdrop(
                  imageProvider: imageProvider,
                  imageKey: ValueKey(
                    'message-invite-fallback-banner-$messageId',
                  ),
                );
              },
            ),
      builder: (context, imageProvider) {
        return CroppedServerBannerImage(
          imageProvider: imageProvider,
          crop: preview.server.bannerCrop,
          imageKey: ValueKey('message-invite-banner-$messageId'),
        );
      },
    );
  }
}

class _InviteIconBackdrop extends StatelessWidget {
  const _InviteIconBackdrop({
    required this.imageProvider,
    required this.imageKey,
  });

  final ImageProvider imageProvider;
  final Key imageKey;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _InviteFallbackGradient(),
        Opacity(
          opacity: 0.42,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return StaticFirstFrameImage(
                  key: imageKey,
                  imageProvider: imageProvider,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.centerRight,
                );
              },
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.18),
                Colors.transparent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ],
    );
  }
}

class _InviteFallbackGradient extends StatelessWidget {
  const _InviteFallbackGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF083428), Color(0xFF10161B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _InviteCopy extends StatelessWidget {
  const _InviteCopy({required this.preview, required this.target});

  final ServerInvitePreview preview;
  final ChatInviteTarget target;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Server invite',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: VerdantColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          preview.server.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Text(
          _inviteBackendLabel(target),
          key: const ValueKey('message-invite-preview-backend'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: VerdantColors.textMuted),
        ),
      ],
    );
  }
}

String _inviteBackendLabel(ChatInviteTarget target) {
  final apiOrigin = target.apiOrigin;
  if (apiOrigin == null || apiOrigin.trim().isEmpty) {
    return 'Backend: current network';
  }
  final normalized = normalizeBackendApiOrigin(apiOrigin);
  final host = Uri.parse(normalized).host;
  return 'Backend: ${host.isEmpty ? normalized : host}';
}

class _CopyInviteButton extends StatelessWidget {
  const _CopyInviteButton({
    required this.copied,
    required this.onPressed,
    super.key,
  });

  final bool copied;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: copied ? 'Copied' : 'Copy invite link',
      child: IconButton(
        onPressed: onPressed,
        color: copied ? VerdantColors.accentStrong : VerdantColors.text,
        icon: PhosphorIcon(
          copied ? PhosphorIconsRegular.check : PhosphorIconsRegular.copy,
          size: 18,
        ),
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _JoinInviteButton extends StatelessWidget {
  const _JoinInviteButton({
    required this.preview,
    required this.isJoining,
    required this.joined,
    required this.onPressed,
    super.key,
  });

  final ServerInvitePreview preview;
  final bool isJoining;
  final bool joined;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _InviteActionButton(
      width: 88,
      height: 34,
      onPressed: onPressed,
      backgroundColor: joined ? VerdantColors.panelHover : VerdantColors.accent,
      foregroundColor: joined
          ? VerdantColors.textMuted
          : VerdantColors.background,
      disabledBackgroundColor: joined
          ? VerdantColors.panelHover
          : VerdantColors.actionMuted,
      disabledForegroundColor: VerdantColors.textMuted,
      label: joined ? 'Joined' : 'Join',
      busy: isJoining,
    );
  }
}

class _InviteActionButton extends StatefulWidget {
  const _InviteActionButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.width,
    this.height = 30,
    this.backgroundColor,
    this.foregroundColor = VerdantColors.accentStrong,
    this.disabledBackgroundColor = Colors.transparent,
    this.disabledForegroundColor = VerdantColors.textMuted,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color foregroundColor;
  final Color disabledBackgroundColor;
  final Color disabledForegroundColor;
  final bool busy;

  @override
  State<_InviteActionButton> createState() => _InviteActionButtonState();
}

class _InviteActionButtonState extends State<_InviteActionButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    final foreground = enabled
        ? widget.foregroundColor
        : widget.disabledForegroundColor;
    final background =
        (enabled ? widget.backgroundColor : widget.disabledBackgroundColor) ??
        (_hovered && enabled
            ? VerdantColors.panelHover.withValues(alpha: 0.72)
            : Colors.transparent);
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? widget.onPressed : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: VerdantRadii.sharp,
            border: Border.all(
              color: _hovered && enabled
                  ? foreground.withValues(alpha: 0.24)
                  : Colors.transparent,
            ),
          ),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.width == null ? 8 : 0,
              ),
              child: Center(
                child: widget.busy
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            widget.icon!,
                            const SizedBox(width: 5),
                          ],
                          Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: VerdantFontWeights.bold,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
