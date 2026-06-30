import 'package:flutter/material.dart';

import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../server_settings_workspace/server_settings_models.dart';
import 'bottom_rail_models.dart';
import 'server_icon.dart';

class ServerDrawerModule extends StatelessWidget {
  const ServerDrawerModule({
    required this.networkId,
    required this.networkName,
    required this.servers,
    required this.activeServerId,
    required this.mediaPolicy,
    required this.onSelectServer,
    required this.onClose,
    super.key,
  });

  final String networkId;
  final String networkName;
  final List<ServerSettingsServer> servers;
  final String? activeServerId;
  final ServerMediaPolicy mediaPolicy;
  final ValueChanged<ServerSettingsServer> onSelectServer;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final railServers = [
      for (final server in servers)
        RailServerItem.fromServer(
          networkId: networkId,
          server: server,
          mediaPolicy: mediaPolicy,
        ),
    ];
    final serversByLocalId = {for (final server in servers) server.id: server};
    final selectedScopedServerId = activeServerId == null
        ? null
        : '$networkId/$activeServerId';

    return Material(
      key: const ValueKey('server-drawer-module'),
      color: Colors.transparent,
      child: Container(
        width: 330,
        constraints: const BoxConstraints(maxHeight: 380),
        decoration: BoxDecoration(
          color: VerdantColors.panel,
          border: Border.all(color: VerdantColors.borderStrong),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'All Servers',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('server-drawer-close-button'),
                    tooltip: 'Close',
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 18),
                    color: VerdantColors.textMuted,
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            const Divider(color: VerdantColors.border, height: 1),
            Flexible(
              child: ListView.builder(
                key: const ValueKey('server-drawer-list'),
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: railServers.length,
                itemBuilder: (context, index) {
                  final railServer = railServers[index];
                  final server = serversByLocalId[railServer.localServerId];
                  return _ServerDrawerRow(
                    server: railServer,
                    networkName: networkName,
                    selected:
                        railServer.scopedServerId == selectedScopedServerId,
                    onPressed: server == null
                        ? null
                        : () {
                            onSelectServer(server);
                          },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerDrawerRow extends StatelessWidget {
  const _ServerDrawerRow({
    required this.server,
    required this.networkName,
    required this.selected,
    required this.onPressed,
  });

  final RailServerItem server;
  final String networkName;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? VerdantColors.panelHover : Colors.transparent,
        child: InkWell(
          key: ValueKey('server-drawer-item-${server.scopedServerId}'),
          onTap: onPressed,
          hoverColor: VerdantColors.desktopHoverOverlay,
          splashColor: Colors.transparent,
          highlightColor: VerdantColors.desktopPressedOverlay,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: ServerIconModule(
                    server: server,
                    networkName: networkName,
                    isSelected: selected,
                    onPressed: onPressed ?? () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        networkName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: VerdantColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
