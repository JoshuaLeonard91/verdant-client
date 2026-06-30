part of 'message_item.dart';

sealed class _MessageContextMenuEntry {
  const _MessageContextMenuEntry();
}

final class _MessageContextMenuDivider extends _MessageContextMenuEntry {
  const _MessageContextMenuDivider();
}

final class _MessageContextMenuItem extends _MessageContextMenuEntry {
  const _MessageContextMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    this.danger = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool danger;
}

class _MessageContextMenuOverlay extends StatelessWidget {
  const _MessageContextMenuOverlay({
    required this.messageId,
    required this.anchorRect,
    required this.entries,
    required this.onSelected,
    required this.onDismiss,
    this.menuKey,
  });

  static const _width = 218.0;
  static const _anchorGap = 6.0;

  final String messageId;
  final Rect anchorRect;
  final List<_MessageContextMenuEntry> entries;
  final ValueChanged<String> onSelected;
  final VoidCallback onDismiss;
  final String? menuKey;

  @override
  Widget build(BuildContext context) {
    final dividerCount = entries.whereType<_MessageContextMenuDivider>().length;
    final itemCount = entries.length - dividerCount;
    final estimatedHeight = 10 + itemCount * 38.0 + dividerCount * 9.0;

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
                final maxTop = constraints.maxHeight > estimatedHeight + 16
                    ? constraints.maxHeight - estimatedHeight - 8
                    : 8.0;
                final left = (anchorRect.right - _width)
                    .clamp(8.0, maxLeft)
                    .toDouble();
                final belowTop = anchorRect.bottom + _anchorGap;
                final aboveTop = anchorRect.top - estimatedHeight - _anchorGap;
                final preferAbove =
                    belowTop + estimatedHeight > constraints.maxHeight - 8;
                final rawTop = preferAbove && aboveTop >= 8
                    ? aboveTop
                    : belowTop;
                final top = rawTop.clamp(8.0, maxTop).toDouble();

                return Stack(
                  children: [
                    Positioned(
                      left: left,
                      top: top,
                      width: _width,
                      child: _MessageContextMenuPanel(
                        messageId: messageId,
                        menuKey: menuKey,
                        entries: entries,
                        onSelected: onSelected,
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

class _MessageContextMenuPanel extends StatelessWidget {
  const _MessageContextMenuPanel({
    required this.messageId,
    required this.entries,
    required this.onSelected,
    this.menuKey,
  });

  final String messageId;
  final List<_MessageContextMenuEntry> entries;
  final ValueChanged<String> onSelected;
  final String? menuKey;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Material(
      key: ValueKey(menuKey ?? 'message-context-menu-$messageId'),
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.panelRaised,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: colors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x77000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in entries)
                switch (entry) {
                  _MessageContextMenuDivider() => Divider(
                    color: colors.border,
                    height: 9,
                    thickness: 1,
                    indent: 10,
                    endIndent: 10,
                  ),
                  _MessageContextMenuItem() => _MessageContextMenuRow(
                    item: entry,
                    onSelected: onSelected,
                  ),
                },
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageContextMenuRow extends StatefulWidget {
  const _MessageContextMenuRow({required this.item, required this.onSelected});

  final _MessageContextMenuItem item;
  final ValueChanged<String> onSelected;

  @override
  State<_MessageContextMenuRow> createState() => _MessageContextMenuRowState();
}

class _MessageContextMenuRowState extends State<_MessageContextMenuRow> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final active = _hovered || _pressed;
    final dangerColor = Theme.of(context).colorScheme.error;
    final background = _pressed
        ? (widget.item.danger
              ? dangerColor.withValues(alpha: 0.20)
              : colors.accent.withValues(alpha: 0.22))
        : active
        ? (widget.item.danger
              ? dangerColor.withValues(alpha: 0.12)
              : colors.panelHover)
        : Colors.transparent;
    final borderColor = _pressed
        ? (widget.item.danger
              ? dangerColor.withValues(alpha: 0.36)
              : colors.accent.withValues(alpha: 0.42))
        : active
        ? (widget.item.danger
              ? dangerColor.withValues(alpha: 0.28)
              : colors.accent.withValues(alpha: 0.28))
        : Colors.transparent;
    final foregroundColor = widget.item.danger
        ? active
              ? dangerColor
              : dangerColor.withValues(alpha: 0.78)
        : active
        ? colors.text
        : colors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: MouseRegion(
        opaque: true,
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
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerCancel: (_) => setState(() => _pressed = false),
          onPointerUp: (_) => setState(() => _pressed = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onSelected(widget.item.id),
            child: AnimatedContainer(
              key: ValueKey(
                'message-context-menu-item-surface-${widget.item.id}',
              ),
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOutCubic,
              height: 38,
              decoration: BoxDecoration(
                color: background,
                border: Border.all(color: borderColor),
                borderRadius: const BorderRadius.all(Radius.circular(6)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 7),
                  PhosphorIcon(
                    widget.item.icon,
                    size: 16,
                    color: foregroundColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foregroundColor,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageActionBar extends StatelessWidget {
  const _MessageActionBar({
    required this.messageId,
    required this.isOwnMessage,
    required this.onReact,
    required this.onReply,
    required this.onMore,
    this.onEdit,
  });

  final String messageId;
  final bool isOwnMessage;
  final VoidCallback onReact;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final ValueChanged<Offset> onMore;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Material(
      key: ValueKey('message-action-bar-$messageId'),
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.panelRaised,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: colors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MessageActionButton(
              key: ValueKey('message-action-react-$messageId'),
              tooltip: 'Add reaction',
              icon: PhosphorIcons.smiley,
              onPressed: onReact,
              roundedLeft: true,
            ),
            const _ActionDivider(),
            _MessageActionButton(
              key: ValueKey('message-action-reply-$messageId'),
              tooltip: 'Reply',
              icon: PhosphorIcons.arrowBendUpLeft,
              onPressed: onReply,
            ),
            if (isOwnMessage) ...[
              const _ActionDivider(),
              _MessageActionButton(
                key: ValueKey('message-action-edit-$messageId'),
                tooltip: 'Edit message',
                icon: PhosphorIcons.pencilSimple,
                onPressed: onEdit ?? () {},
              ),
            ],
            const _ActionDivider(),
            Builder(
              builder: (buttonContext) {
                return _MessageActionButton(
                  key: ValueKey('message-action-more-$messageId'),
                  tooltip: 'More',
                  icon: PhosphorIcons.dotsThree,
                  isAccent: true,
                  roundedRight: true,
                  onPressed: () {
                    final box = buttonContext.findRenderObject() as RenderBox?;
                    final topLeft =
                        box?.localToGlobal(Offset.zero) ?? Offset.zero;
                    onMore(topLeft.translate(-12, 0));
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageActionButton extends StatefulWidget {
  const _MessageActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isAccent = false,
    this.roundedLeft = false,
    this.roundedRight = false,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isAccent;
  final bool roundedLeft;
  final bool roundedRight;

  @override
  State<_MessageActionButton> createState() => _MessageActionButtonState();
}

class _MessageActionButtonState extends State<_MessageActionButton> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final radius = BorderRadius.horizontal(
      left: widget.roundedLeft ? const Radius.circular(7) : Radius.zero,
      right: widget.roundedRight ? const Radius.circular(7) : Radius.zero,
    );
    final active = _hovered || _pressed;
    final surfaceKey = switch (widget.key) {
      ValueKey<String>(:final value) => '$value-surface',
      _ => 'message-action-${widget.tooltip}-surface',
    };
    final backgroundColor = _pressed
        ? colors.accent.withValues(alpha: 0.26)
        : active
        ? colors.accent.withValues(alpha: 0.18)
        : widget.isAccent
        ? colors.accent.withValues(alpha: 0.16)
        : Colors.transparent;
    final iconColor = active || widget.isAccent
        ? colors.accentStrong
        : colors.textMuted;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) {
          setState(() {
            _hovered = false;
            _pressed = false;
          });
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              key: ValueKey(surfaceKey),
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              width: 43,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: radius,
              ),
              child: PhosphorIcon(widget.icon, size: 18, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return SizedBox(
      height: 36,
      child: VerticalDivider(width: 1, thickness: 1, color: colors.border),
    );
  }
}
