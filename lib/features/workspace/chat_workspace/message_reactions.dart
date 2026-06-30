part of 'message_item.dart';

class MessageReactionBar extends StatefulWidget {
  const MessageReactionBar({
    required this.messageId,
    required this.initialReactions,
    required this.mediaPolicy,
    this.customEmojis = const [],
    this.onSetReaction,
    this.onChanged,
    super.key,
  });

  final String messageId;
  final List<ReactionSeed> initialReactions;
  final ServerMediaPolicy mediaPolicy;
  final List<ServerCustomEmoji> customEmojis;
  final ServerReactionChangeHandler? onSetReaction;
  final ValueChanged<List<ReactionSeed>>? onChanged;

  @override
  State<MessageReactionBar> createState() => _MessageReactionBarState();
}

class _MessageReactionBarState extends State<MessageReactionBar> {
  late List<ReactionSeed> _reactions;
  final _addReactionKey = GlobalKey();
  OverlayEntry? _reactionPickerEntry;

  @override
  void initState() {
    super.initState();
    _reactions = [...widget.initialReactions];
  }

  @override
  void didUpdateWidget(covariant MessageReactionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageId != widget.messageId ||
        !_sameReactionSnapshot(
          oldWidget.initialReactions,
          widget.initialReactions,
        )) {
      _reactions = [...widget.initialReactions];
    }
  }

  @override
  void dispose() {
    _removeReactionPicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reactions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final reaction in _reactions)
          MessageReactionChip(
            key: ValueKey(
              'message-reaction-${widget.messageId}-${reaction.emoji}',
            ),
            reaction: reaction,
            mediaPolicy: widget.mediaPolicy,
            customEmojis: widget.customEmojis,
            reactedByCurrentUser: reaction.reactedByCurrentUser,
            onPressed: () => _toggleReaction(reaction.emoji),
          ),
        _AddReactionButton(
          key: _addReactionKey,
          messageId: widget.messageId,
          onPressed: _showReactionPicker,
        ),
      ],
    );
  }

  void _toggleReaction(String emoji) {
    final existing = _reactions.firstWhere(
      (reaction) => reaction.emoji == emoji,
    );
    final selected = !existing.reactedByCurrentUser;
    setState(() {
      _reactions = [
        for (final reaction in _reactions)
          if (reaction.emoji == emoji) _toggledReaction(reaction) else reaction,
      ].where((reaction) => reaction.count > 0).toList(growable: false);
    });
    unawaited(
      widget.onSetReaction?.call(
            messageId: widget.messageId,
            emoji: emoji,
            emojiId: existing.emojiId,
            selected: selected,
          ) ??
          Future<void>.value(),
    );
    widget.onChanged?.call(_reactions);
  }

  void _addReaction(String emoji) {
    final index = _reactions.indexWhere((reaction) => reaction.emoji == emoji);
    if (index >= 0) {
      _toggleReaction(emoji);
      return;
    }
    setState(() {
      _reactions = [
        ..._reactions,
        ReactionSeed(emoji: emoji, count: 1, reactedByCurrentUser: true),
      ];
    });
    unawaited(
      widget.onSetReaction?.call(
            messageId: widget.messageId,
            emoji: emoji,
            selected: true,
          ) ??
          Future<void>.value(),
    );
    widget.onChanged?.call(_reactions);
  }

  void _showReactionPicker() {
    _removeReactionPicker();
    final box =
        _addReactionKey.currentContext?.findRenderObject() as RenderBox?;
    final anchorRect = box == null || !box.hasSize
        ? Rect.zero
        : box.localToGlobal(Offset.zero) & box.size;
    final entry = OverlayEntry(
      builder: (context) {
        return _ReactionPickerOverlay(
          anchorRect: anchorRect,
          mediaPolicy: widget.mediaPolicy,
          customEmojis: widget.customEmojis,
          onDismiss: _removeReactionPicker,
          onSelected: (emoji) {
            _removeReactionPicker();
            _addReaction(emoji);
          },
        );
      },
    );
    _reactionPickerEntry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _removeReactionPicker() {
    _reactionPickerEntry?.remove();
    _reactionPickerEntry = null;
  }
}

ReactionSeed _toggledReaction(ReactionSeed reaction) {
  final count = reaction.reactedByCurrentUser
      ? reaction.count - 1
      : reaction.count + 1;
  return ReactionSeed(
    emoji: reaction.emoji,
    emojiId: reaction.emojiId,
    count: count < 0 ? 0 : count,
    reactedByCurrentUser: !reaction.reactedByCurrentUser,
  );
}

class _AddReactionButton extends StatelessWidget {
  const _AddReactionButton({
    required this.messageId,
    required this.onPressed,
    super.key,
  });

  final String messageId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        key: ValueKey('add-reaction-$messageId'),
        padding: EdgeInsets.zero,
        tooltip: 'Add reaction',
        icon: const Icon(Icons.add, size: 15),
        color: colors.textMuted,
        onPressed: onPressed,
      ),
    );
  }
}

class _ReactionPickerOverlay extends StatelessWidget {
  const _ReactionPickerOverlay({
    required this.anchorRect,
    required this.mediaPolicy,
    required this.customEmojis,
    required this.onSelected,
    required this.onDismiss,
  });

  static const _width = 376.0;
  static const _height = 382.0;
  static const _gap = 8.0;

  final Rect anchorRect;
  final ServerMediaPolicy mediaPolicy;
  final List<ServerCustomEmoji> customEmojis;
  final ValueChanged<String> onSelected;
  final VoidCallback onDismiss;

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
                final maxLeft = constraints.maxWidth > _width + 16
                    ? constraints.maxWidth - _width - 8
                    : 8.0;
                final maxTop = constraints.maxHeight > _height + 16
                    ? constraints.maxHeight - _height - 8
                    : 8.0;
                final left = (anchorRect.right - _width)
                    .clamp(8.0, maxLeft)
                    .toDouble();
                final top = (anchorRect.top - _height - _gap)
                    .clamp(8.0, maxTop)
                    .toDouble();
                return Stack(
                  children: [
                    Positioned(
                      left: left,
                      top: top,
                      width: _width,
                      height: _height,
                      child: Material(
                        color: Colors.transparent,
                        child: EmojiPickerPopover(
                          mediaPolicy: mediaPolicy,
                          customEmojis: customEmojis,
                          onSelected: onSelected,
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
