part of 'message_item.dart';

class MessageAvatar extends StatefulWidget {
  const MessageAvatar({
    required this.mediaPolicy,
    required this.member,
    this.onOpenProfile,
    super.key,
  });

  final ServerMediaPolicy mediaPolicy;
  final MemberSeed member;
  final ValueChanged<Rect>? onOpenProfile;

  @override
  State<MessageAvatar> createState() => _MessageAvatarState();
}

class _MessageAvatarState extends State<MessageAvatar> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final memberKey = widget.member.id ?? widget.member.name;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        setState(() {
          _hovered = false;
          _pressed = false;
        });
      },
      child: GestureDetector(
        key: ValueKey('message-avatar-$memberKey'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          final rect = _globalRect();
          if (rect != null) {
            widget.onOpenProfile?.call(rect);
          }
        },
        child: AnimatedScale(
          scale: _pressed
              ? 0.96
              : _hovered
              ? 1.03
              : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: VerdantRadii.sharp),
            child: MemberMediaAvatar(
              member: widget.member,
              mediaPolicy: widget.mediaPolicy,
              size: 42,
              playAnimatedMedia: _hovered,
              imageKeyPrefix: 'message-avatar-image',
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

class MessageMeta extends StatelessWidget {
  const MessageMeta({
    required this.authorKey,
    required this.author,
    required this.time,
    required this.isOwnMessage,
    this.authorColor,
    this.onOpenProfile,
    super.key,
  });

  final String authorKey;
  final String author;
  final String time;
  final bool isOwnMessage;
  final Color? authorColor;
  final ValueChanged<Rect>? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [
        _MessageAuthorName(
          key: ValueKey('message-author-name-$authorKey'),
          author: author,
          color: authorColor ?? (isOwnMessage ? colors.name : colors.accent),
          onOpenProfile: onOpenProfile,
        ),
        Text(time, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MessageAuthorName extends StatefulWidget {
  const _MessageAuthorName({
    required this.author,
    required this.color,
    this.onOpenProfile,
    super.key,
  });

  final String author;
  final Color color;
  final ValueChanged<Rect>? onOpenProfile;

  @override
  State<_MessageAuthorName> createState() => _MessageAuthorNameState();
}

class _MessageAuthorNameState extends State<_MessageAuthorName> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final canOpen = widget.onOpenProfile != null;
    return MouseRegion(
      cursor: canOpen ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: canOpen ? (_) => setState(() => _hovered = true) : null,
      onExit: canOpen ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canOpen
            ? () {
                final rect = _globalRect();
                if (rect != null) {
                  widget.onOpenProfile?.call(rect);
                }
              }
            : null,
        child: Text(
          widget.author,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: widget.color,
            fontWeight: FontWeight.w900,
            decoration: _hovered ? TextDecoration.underline : null,
            decorationColor: widget.color,
            decorationThickness: 1.5,
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
