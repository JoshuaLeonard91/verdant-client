import 'package:flutter/material.dart';

import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_image.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../shared/custom_expressive_asset.dart';
import '../shared/workspace_render_diagnostics.dart';
import '../workspace_seed.dart';
import 'server_custom_emojis.dart';

class MessageReactionChip extends StatefulWidget {
  const MessageReactionChip({
    required this.reaction,
    this.mediaPolicy = const ServerMediaPolicy(
      allowedOrigins: {},
      allowLocalHttp: false,
    ),
    this.customEmojis = const [],
    this.reactedByCurrentUser = false,
    this.onPressed,
    super.key,
  });

  final ReactionSeed reaction;
  final ServerMediaPolicy mediaPolicy;
  final List<ServerCustomEmoji> customEmojis;
  final bool reactedByCurrentUser;
  final VoidCallback? onPressed;

  @override
  State<MessageReactionChip> createState() => _MessageReactionChipState();
}

class _MessageReactionChipState extends State<MessageReactionChip> {
  var _hovered = false;
  var _pressed = false;

  void _setHovered(bool hovered) {
    if (_hovered == hovered) {
      return;
    }
    setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final active = _hovered || _pressed || widget.reactedByCurrentUser;
    final customEmoji = _resolveReactionCustomEmoji(
      widget.reaction,
      widget.customEmojis,
    );
    return WorkspaceRenderProbe(
      surface: 'messageReaction',
      id: widget.reaction.emojiId ?? widget.reaction.emoji,
      fields: {
        'customEmoji': customEmoji != null,
        'count': widget.reaction.count,
        'reactedByCurrentUser': widget.reactedByCurrentUser,
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.96, end: 1),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _setHovered(true),
          onExit: (_) {
            _setHovered(false);
            setState(() => _pressed = false);
          },
          child: Material(
            color: Colors.transparent,
            child: SizedBox.square(
              dimension: 38,
              child: InkWell(
                onTap: widget.onPressed,
                onHover: _setHovered,
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) => setState(() => _pressed = false),
                borderRadius: VerdantRadii.sharp,
                hoverColor: colors.accent.withValues(alpha: 0.10),
                splashColor: colors.accentStrong.withValues(alpha: 0.16),
                child: AnimatedScale(
                  scale: _pressed
                      ? 0.94
                      : _hovered
                      ? 1.08
                      : widget.reactedByCurrentUser
                      ? 1.03
                      : 1,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        key: ValueKey(
                          'message-reaction-surface-${widget.reaction.emoji}',
                        ),
                        duration: const Duration(milliseconds: 170),
                        curve: Curves.easeOutCubic,
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: widget.reactedByCurrentUser
                              ? colors.actionMuted
                              : active
                              ? colors.panelHover
                              : colors.background,
                          borderRadius: VerdantRadii.sharp,
                          border: Border.all(
                            color: widget.reactedByCurrentUser || active
                                ? colors.accentStrong
                                : colors.border,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _ReactionGlyph(
                              reaction: widget.reaction,
                              customEmoji: customEmoji,
                              mediaPolicy: widget.mediaPolicy,
                            ),
                            Positioned(
                              right: 3,
                              bottom: 2,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 160),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutBack,
                                    ),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: DecoratedBox(
                                  key: ValueKey(
                                    'reaction-count-${widget.reaction.emoji}-${widget.reaction.count}',
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.background.withValues(
                                      alpha: 0.82,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 1,
                                    ),
                                    child: Text(
                                      '${widget.reaction.count}',
                                      style: TextStyle(
                                        color: widget.reactedByCurrentUser
                                            ? colors.accentStrong
                                            : colors.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IgnorePointer(
                        child: AnimatedContainer(
                          key: ValueKey(
                            'message-reaction-hover-ring-${widget.reaction.emoji}',
                          ),
                          duration: const Duration(milliseconds: 170),
                          curve: Curves.easeOutCubic,
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: VerdantRadii.sharp,
                            border: Border.all(
                              color: _hovered
                                  ? colors.accentStrong
                                  : Colors.transparent,
                              width: _hovered ? 2 : 1,
                            ),
                            boxShadow: _hovered
                                ? const [
                                    BoxShadow(
                                      color: Color(0x442FFFD0),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
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
    );
  }
}

ServerCustomEmoji? _resolveReactionCustomEmoji(
  ReactionSeed reaction,
  List<ServerCustomEmoji> customEmojis,
) {
  final emojiId = reaction.emojiId;
  if (emojiId != null && emojiId.trim().isNotEmpty) {
    final match = resolveServerCustomEmoji(emojiId, customEmojis);
    if (match != null) {
      return match;
    }
  }
  return resolveServerCustomEmoji(reaction.emoji, customEmojis);
}

class _ReactionGlyph extends StatelessWidget {
  const _ReactionGlyph({
    required this.reaction,
    required this.customEmoji,
    required this.mediaPolicy,
  });

  final ReactionSeed reaction;
  final ServerCustomEmoji? customEmoji;
  final ServerMediaPolicy mediaPolicy;

  @override
  Widget build(BuildContext context) {
    final emoji = customEmoji;
    if (emoji == null) {
      return Text(
        reaction.emoji,
        style: const TextStyle(fontSize: 23, height: 1),
      );
    }
    final uri = safeServerMediaUri(emoji.imageUrl, policy: mediaPolicy);
    final fallback = Text(
      reaction.emoji,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall,
    );
    if (uri == null) {
      return fallback;
    }
    return SizedBox.square(
      key: ValueKey('message-reaction-custom-emoji-${emoji.id}'),
      dimension: 25,
      child: SafeServerMediaImage(
        uri: uri,
        policy: mediaPolicy,
        surface: ServerMediaSurface.image,
        fallback: fallback,
        builder: (context, imageProvider) => Image(
          image: imageProvider,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          semanticLabel: emoji.name,
        ),
      ),
    );
  }
}
