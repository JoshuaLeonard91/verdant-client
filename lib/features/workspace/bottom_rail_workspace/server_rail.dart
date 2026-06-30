import 'package:flutter/material.dart';

import '../../../shared/smooth_single_child_scroll_view.dart';
import '../workspace_local_id.dart';
import 'bottom_rail_models.dart';
import 'server_icon.dart';

class NetworkServerRailModule extends StatelessWidget {
  const NetworkServerRailModule({
    required this.groups,
    required this.servers,
    required this.selectedScopedServerId,
    required this.onSelectServer,
    this.onCreateInvite,
    this.onLeaveServer,
    super.key,
  });

  final List<RailNetworkGroup> groups;
  final List<RailServerItem> servers;
  final String? selectedScopedServerId;
  final ValueChanged<RailServerItem> onSelectServer;
  final ValueChanged<RailServerItem>? onCreateInvite;
  final ValueChanged<RailServerItem>? onLeaveServer;

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (final server in servers)
        if (_railGroupForServer(groups, server) case final group?)
          _RailServerEntry(
            group: group,
            server: _railServerForGroup(group, server),
          ),
    ];
    if (entries.isEmpty) {
      return const _EmptyRail();
    }

    return SmoothSingleChildScrollView(
      key: const ValueKey('server-rail-scroll'),
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: [
          for (final entry in entries)
            ServerIconModule(
              key: ValueKey('server-rail-icon-${entry.server.scopedServerId}'),
              server: entry.server,
              networkName: entry.group.networkName,
              networkModeLabel: entry.group.modeLabel,
              networkStatusLabel: entry.group.statusLabel,
              networkStatusTone: entry.group.statusTone,
              isSelected:
                  selectedScopedServerId != null &&
                  sameScopedWorkspaceId(
                    entry.server.scopedServerId,
                    selectedScopedServerId!,
                  ),
              onCreateInvite: onCreateInvite == null
                  ? null
                  : () => onCreateInvite!(entry.server),
              onLeaveServer: onLeaveServer == null
                  ? null
                  : () => onLeaveServer!(entry.server),
              onPressed: () {
                if (!entry.server.isUnavailable) {
                  onSelectServer(entry.server);
                }
              },
            ),
        ],
      ),
    );
  }
}

final class _RailServerEntry {
  const _RailServerEntry({required this.group, required this.server});
  final RailNetworkGroup group;
  final RailServerItem server;
}

RailNetworkGroup? _railGroupForServer(
  List<RailNetworkGroup> groups,
  RailServerItem server,
) {
  for (final group in groups) {
    if (sameWorkspaceNetworkId(group.networkId, server.networkId)) {
      return group;
    }
  }
  return null;
}

RailServerItem _railServerForGroup(
  RailNetworkGroup group,
  RailServerItem server,
) {
  for (final groupedServer in group.servers) {
    if (sameScopedWorkspaceId(
      groupedServer.scopedServerId,
      server.scopedServerId,
    )) {
      return groupedServer;
    }
  }
  return server;
}

class _EmptyRail extends StatelessWidget {
  const _EmptyRail();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No pinned servers',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
