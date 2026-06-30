part of 'message_item.dart';

class _MessageText extends StatelessWidget {
  const _MessageText({
    required this.body,
    required this.messageId,
    required this.networkId,
    required this.members,
    required this.mediaPolicy,
    required this.customEmojis,
    required this.customStickers,
    required this.customExpressionSources,
    required this.onOpenMention,
    required this.onMentionContextMenu,
    required this.onMentionSecondaryPointerDown,
    required this.onCustomExpressionSecondaryPointerDown,
  });

  final String body;
  final String messageId;
  final String? networkId;
  final List<MemberSeed> members;
  final ServerMediaPolicy mediaPolicy;
  final List<ServerCustomEmoji> customEmojis;
  final List<ServerCustomSticker> customStickers;
  final Map<String, CustomExpressionSource> customExpressionSources;
  final void Function(MessageMentionResolution mention, Rect anchorRect)
  onOpenMention;
  final void Function(MessageMentionResolution mention, Offset globalPosition)
  onMentionContextMenu;
  final VoidCallback onMentionSecondaryPointerDown;
  final VoidCallback onCustomExpressionSecondaryPointerDown;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(height: 1.34, color: colors.text);
    return SelectionArea(
      contextMenuBuilder: (context, selectableRegionState) {
        return const SizedBox.shrink();
      },
      child: Text.rich(
        TextSpan(
          children: messageBodyExpressionSpans(
            body: body,
            networkId: networkId,
            members: members,
            customEmojis: customEmojis,
            customStickers: customStickers,
            mentionStyle: style?.copyWith(
              color: _messageMentionTextColor,
              fontWeight: FontWeight.w800,
              backgroundColor: _messageMentionPressedBackgroundColor,
            ),
            mentionBuilder: (mention, mentionStyle) {
              final mentionKey = _mentionPillKey(messageId, mention);
              return WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: _MessageMentionPill(
                  key: ValueKey('message-mention-pill-$messageId-$mentionKey'),
                  mention: mention,
                  style: mentionStyle,
                  onOpen: onOpenMention,
                  onContextMenu: onMentionContextMenu,
                  onSecondaryPointerDown: onMentionSecondaryPointerDown,
                ),
              );
            },
            customEmojiFallbackStyle: style,
            customStickerFallbackStyle: style,
            customEmojiBuilder: (emoji, fallbackStyle) {
              final itemKey = 'message-custom-emoji-$messageId-${emoji.id}';
              return WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _MessageCustomEmojiGlyph(
                  key: ValueKey(itemKey),
                  itemKey: itemKey,
                  emoji: emoji,
                  source:
                      customExpressionSources[customExpressionSourceKey(emoji)],
                  mediaPolicy: mediaPolicy,
                  fallbackStyle: fallbackStyle,
                  onSecondaryPointerDown:
                      onCustomExpressionSecondaryPointerDown,
                ),
              );
            },
            customStickerBuilder: (sticker, fallbackStyle) {
              final itemKey = 'message-custom-sticker-$messageId-${sticker.id}';
              return WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _MessageCustomStickerGlyph(
                  key: ValueKey(itemKey),
                  itemKey: itemKey,
                  sticker: sticker,
                  source:
                      customExpressionSources[customExpressionSourceKey(
                        sticker,
                      )],
                  mediaPolicy: mediaPolicy,
                  fallbackStyle: fallbackStyle,
                  onSecondaryPointerDown:
                      onCustomExpressionSecondaryPointerDown,
                ),
              );
            },
          ),
        ),
        style: style,
      ),
    );
  }

  String _mentionPillKey(String messageId, MessageMentionResolution mention) {
    final localUserId = mention.localUserId;
    if (localUserId != null && localUserId.isNotEmpty) {
      return localUserId;
    }
    final text = mention.renderText.trim();
    if (text.startsWith('@') && text.length > 1) {
      return text.substring(1).toLowerCase();
    }
    return text.toLowerCase();
  }
}

class _MessageCustomEmojiGlyph extends StatelessWidget {
  static const double _inlineEmojiSize = 48;

  const _MessageCustomEmojiGlyph({
    required this.itemKey,
    required this.emoji,
    required this.source,
    required this.mediaPolicy,
    required this.fallbackStyle,
    required this.onSecondaryPointerDown,
    super.key,
  });

  final String itemKey;
  final ServerCustomEmoji emoji;
  final CustomExpressionSource? source;
  final ServerMediaPolicy mediaPolicy;
  final TextStyle? fallbackStyle;
  final VoidCallback onSecondaryPointerDown;

  @override
  Widget build(BuildContext context) {
    final uri = safeServerMediaUri(emoji.imageUrl, policy: mediaPolicy);
    final fallback = Text(
      emoji.shortcode,
      overflow: TextOverflow.ellipsis,
      style: fallbackStyle,
    );
    final child = uri == null
        ? fallback
        : SizedBox.square(
            dimension: _inlineEmojiSize,
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
    return _MessageCustomExpressionContextTarget(
      itemKey: itemKey,
      asset: emoji,
      source: source,
      mediaPolicy: mediaPolicy,
      onSecondaryPointerDown: onSecondaryPointerDown,
      child: child,
    );
  }
}

class _MessageCustomExpressionContextTarget extends StatelessWidget {
  const _MessageCustomExpressionContextTarget({
    required this.itemKey,
    required this.asset,
    required this.source,
    required this.mediaPolicy,
    required this.onSecondaryPointerDown,
    required this.child,
  });

  final String itemKey;
  final CustomExpressiveAsset asset;
  final CustomExpressionSource? source;
  final ServerMediaPolicy mediaPolicy;
  final VoidCallback onSecondaryPointerDown;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (event.buttons == kSecondaryMouseButton) {
            onSecondaryPointerDown();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapDown: (details) {
            onSecondaryPointerDown();
            showCustomExpressionMetadataMenu(
              context: context,
              globalPosition: details.globalPosition,
              asset: asset,
              source: source,
              mediaPolicy: mediaPolicy,
              itemKey: itemKey,
            );
          },
          child: MouseRegion(cursor: SystemMouseCursors.basic, child: child),
        ),
      ),
    );
  }
}

class _MessageCustomStickerGlyph extends StatelessWidget {
  static const double _inlineStickerSize = 96;

  const _MessageCustomStickerGlyph({
    required this.itemKey,
    required this.sticker,
    required this.source,
    required this.mediaPolicy,
    required this.fallbackStyle,
    required this.onSecondaryPointerDown,
    super.key,
  });

  final String itemKey;
  final ServerCustomSticker sticker;
  final CustomExpressionSource? source;
  final ServerMediaPolicy mediaPolicy;
  final TextStyle? fallbackStyle;
  final VoidCallback onSecondaryPointerDown;

  @override
  Widget build(BuildContext context) {
    final uri = safeServerMediaUri(sticker.imageUrl, policy: mediaPolicy);
    final fallback = Text(
      sticker.shortcode,
      overflow: TextOverflow.ellipsis,
      style: fallbackStyle,
    );
    final child = uri == null
        ? fallback
        : SizedBox.square(
            dimension: _inlineStickerSize,
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
                semanticLabel: sticker.name,
              ),
            ),
          );
    return _MessageCustomExpressionContextTarget(
      itemKey: itemKey,
      asset: sticker,
      source: source,
      mediaPolicy: mediaPolicy,
      onSecondaryPointerDown: onSecondaryPointerDown,
      child: child,
    );
  }
}

class _MessageMentionPill extends StatefulWidget {
  const _MessageMentionPill({
    required this.mention,
    required this.style,
    required this.onOpen,
    required this.onContextMenu,
    required this.onSecondaryPointerDown,
    super.key,
  });

  final MessageMentionResolution mention;
  final TextStyle? style;
  final void Function(MessageMentionResolution mention, Rect anchorRect) onOpen;
  final void Function(MessageMentionResolution mention, Offset globalPosition)
  onContextMenu;
  final VoidCallback onSecondaryPointerDown;

  @override
  State<_MessageMentionPill> createState() => _MessageMentionPillState();
}

class _MessageMentionPillState extends State<_MessageMentionPill> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    return SelectionContainer.disabled(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) {
          setState(() {
            _hovered = false;
            _pressed = false;
          });
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (event.buttons == kSecondaryMouseButton) {
              widget.onSecondaryPointerDown();
            }
            setState(() => _pressed = true);
          },
          onPointerCancel: (_) => setState(() => _pressed = false),
          onPointerUp: (_) => setState(() => _pressed = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (widget.mention.member == null) {
                return;
              }
              final rect = _globalRect();
              if (rect != null) {
                widget.onOpen(widget.mention, rect);
              }
            },
            onSecondaryTapDown: (details) {
              widget.onSecondaryPointerDown();
              widget.onContextMenu(widget.mention, details.globalPosition);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: _pressed
                    ? _messageMentionPressedBackgroundColor
                    : _hovered
                    ? _messageMentionHoverBackgroundColor
                    : _messageMentionBackgroundColor,
                borderRadius: const BorderRadius.all(Radius.circular(3)),
              ),
              child: Text(
                widget.mention.renderText,
                style: style?.copyWith(
                  color: _messageMentionTextColor,
                  backgroundColor: Colors.transparent,
                  decoration: _hovered ? TextDecoration.underline : null,
                  decorationColor: _messageMentionTextColor,
                  decorationThickness: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Rect? _globalRect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
