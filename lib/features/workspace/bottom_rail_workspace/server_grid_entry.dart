import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'rail_icon_button.dart';

class ServerGridEntryModule extends StatelessWidget {
  const ServerGridEntryModule({this.isOpen = false, this.onPressed, super.key});

  final bool isOpen;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return RailIconButton(
      key: const ValueKey('bottom-rail-server-grid-button'),
      icon: PhosphorIconsRegular.squaresFour,
      selected: isOpen,
      tooltip: 'All servers',
      onPressed: onPressed,
    );
  }
}
