import 'package:flutter/material.dart';

import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../workspace_local_id.dart';
import 'bottom_rail_models.dart';
import 'direct_messages_entry.dart';
import 'rail_action_buttons.dart';
import 'server_grid_entry.dart';
import 'server_rail.dart';

class BottomRailWorkspace extends StatelessWidget {
  const BottomRailWorkspace({
    required this.networkId,
    required this.servers,
    required this.activeServerId,
    required this.mediaPolicy,
    required this.onSelectServer,
    this.directMessagesOpen = false,
    this.serverGridOpen = false,
    this.railServers,
    this.networkRecords = const [],
    this.networkOrder = const [],
    this.onToggleDirectMessages,
    this.onToggleServerGrid,
    this.onCreateServer,
    this.onJoinServer,
    this.onJoinNetwork,
    this.onSelectRailServer,
    this.onCreateInviteForServer,
    this.onLeaveServer,
    super.key,
  });

  final String networkId;
  final List<ServerSettingsServer> servers;
  final String? activeServerId;
  final ServerMediaPolicy mediaPolicy;
  final ValueChanged<ServerSettingsServer> onSelectServer;
  final bool directMessagesOpen;
  final bool serverGridOpen;
  final List<RailServerItem>? railServers;
  final List<RailNetworkRecord> networkRecords;
  final List<String> networkOrder;
  final VoidCallback? onToggleDirectMessages;
  final VoidCallback? onToggleServerGrid;
  final VoidCallback? onCreateServer;
  final VoidCallback? onJoinServer;
  final VoidCallback? onJoinNetwork;
  final ValueChanged<RailServerItem>? onSelectRailServer;
  final ValueChanged<RailServerItem>? onCreateInviteForServer;
  final ValueChanged<ServerSettingsServer>? onLeaveServer;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final activeNetworkServers = [
      for (final server in servers)
        RailServerItem.fromServer(
          networkId: networkId,
          server: server,
          mediaPolicy: mediaPolicy,
        ),
    ];
    final effectiveRailServers = railServers ?? activeNetworkServers;
    final groups = buildRailNetworkGroups(
      servers: effectiveRailServers,
      activeNetworkId: networkId,
      networkRecords: networkRecords,
      networkOrder: networkOrder,
    );
    final selectedScopedServerId = activeServerId == null
        ? null
        : '$networkId/$activeServerId';
    final serversByLocalId = {for (final server in servers) server.id: server};

    return Container(
      key: const ValueKey('bottom-rail-workspace'),
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          DirectMessagesEntryModule(
            isOpen: directMessagesOpen,
            onPressed: onToggleDirectMessages,
          ),
          const SizedBox(width: 8),
          ServerGridEntryModule(
            isOpen: serverGridOpen,
            onPressed: onToggleServerGrid,
          ),
          const _RailSeparator(),
          Expanded(
            child: NetworkServerRailModule(
              groups: groups,
              servers: effectiveRailServers,
              selectedScopedServerId: selectedScopedServerId,
              onSelectServer: (railServer) {
                if (onSelectRailServer != null) {
                  onSelectRailServer!(railServer);
                  return;
                }
                if (!sameWorkspaceNetworkId(railServer.networkId, networkId)) {
                  return;
                }
                final server = serversByLocalId[railServer.localServerId];
                if (server != null) {
                  onSelectServer(server);
                }
              },
              onCreateInvite: (railServer) {
                onCreateInviteForServer?.call(railServer);
              },
              onLeaveServer: (railServer) {
                if (!sameWorkspaceNetworkId(railServer.networkId, networkId)) {
                  return;
                }
                final server = serversByLocalId[railServer.localServerId];
                if (server != null) {
                  onLeaveServer?.call(server);
                }
              },
            ),
          ),
          const _RailSeparator(),
          RailActionButtonsModule(
            onCreateServer: onCreateServer,
            onJoinServer: onJoinServer,
            onJoinNetwork: onJoinNetwork,
          ),
        ],
      ),
    );
  }
}

class _RailSeparator extends StatelessWidget {
  const _RailSeparator();

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return SizedBox(
      width: 18,
      child: Center(
        child: SizedBox(
          width: 1,
          height: 26,
          child: ColoredBox(color: colors.border),
        ),
      ),
    );
  }
}
