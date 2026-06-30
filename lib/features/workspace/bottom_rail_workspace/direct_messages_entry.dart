import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'rail_icon_button.dart';

class DirectMessagesEntryModule extends StatelessWidget {
  const DirectMessagesEntryModule({
    required this.isOpen,
    this.onPressed,
    this.pendingCount = 0,
    this.hasUnread = false,
    super.key,
  });

  final bool isOpen;
  final VoidCallback? onPressed;
  final int pendingCount;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return RailIconButton(
      key: const ValueKey('bottom-rail-dm-button'),
      icon: isOpen
          ? PhosphorIconsRegular.arrowLeft
          : PhosphorIconsFill.chatCircleDots,
      selected: isOpen,
      tooltip: isOpen ? 'Back to server' : 'Direct messages',
      badgeLabel: pendingCount > 0
          ? pendingCount.toString()
          : hasUnread
          ? '!'
          : null,
      onPressed: onPressed,
    );
  }
}
