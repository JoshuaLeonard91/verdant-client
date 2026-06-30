import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'rail_icon_button.dart';

class RailActionButtonsModule extends StatelessWidget {
  const RailActionButtonsModule({
    this.onCreateServer,
    this.onJoinServer,
    this.onJoinNetwork,
    super.key,
  });

  final VoidCallback? onCreateServer;
  final VoidCallback? onJoinServer;
  final VoidCallback? onJoinNetwork;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RailIconButton(
          key: const ValueKey('bottom-rail-create-server-button'),
          icon: PhosphorIconsRegular.plus,
          tooltip: 'Create a server',
          onPressed: onCreateServer,
        ),
        const SizedBox(width: 8),
        RailIconButton(
          key: const ValueKey('bottom-rail-join-server-button'),
          icon: PhosphorIconsRegular.arrowRight,
          tooltip: 'Join a server',
          onPressed: onJoinServer,
        ),
        const SizedBox(width: 8),
        RailIconButton(
          key: const ValueKey('bottom-rail-join-network-button'),
          icon: PhosphorIconsRegular.globeHemisphereEast,
          tooltip: 'Join a network',
          onPressed: onJoinNetwork,
        ),
      ],
    );
  }
}
