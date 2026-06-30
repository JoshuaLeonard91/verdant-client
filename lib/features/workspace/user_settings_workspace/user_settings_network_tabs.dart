part of 'user_settings_workspace.dart';

class _SessionsSettingsTab extends StatelessWidget {
  const _SessionsSettingsTab({required this.controller});

  final UserSettingsSessionsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentSessions = controller.currentSessions;
        final otherSessions = controller.otherSessions;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: 'Sessions',
              trailing: controller.loading
                  ? 'Loading'
                  : '${controller.sessions.length} active',
            ),
            const SizedBox(height: 10),
            if (controller.error != null) ...[
              _SettingsError(message: controller.error!),
              const SizedBox(height: 10),
            ],
            if (controller.loading && controller.sessions.isEmpty)
              const _SessionsLoadingPanel()
            else ...[
              if (currentSessions.isEmpty)
                const _SettingsInfoBanner(
                  message:
                      'No current session was reported by this network. Refresh sessions or sign in again.',
                )
              else
                for (final session in currentSessions)
                  _SessionSettingsCard(
                    key: ValueKey('user-settings-session-${session.id}'),
                    session: session,
                    current: true,
                    busy: false,
                    onRevoke: null,
                  ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SettingsSectionLabel(
                      title: 'Other Sessions (${otherSessions.length})',
                    ),
                  ),
                  if (otherSessions.isNotEmpty)
                    _SmallSettingsButton(
                      key: const ValueKey(
                        'user-settings-revoke-all-sessions-button',
                      ),
                      label: 'Revoke All Other Sessions',
                      icon: Icons.logout,
                      busy: controller.revokeAllBusy,
                      onPressed: controller.revokeAllBusy
                          ? null
                          : controller.revokeAllOtherSessions,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (otherSessions.isEmpty)
                const _SettingsPanel(child: Text('No other active sessions.'))
              else
                for (var index = 0; index < otherSessions.length; index += 1)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == otherSessions.length - 1 ? 0 : 8,
                    ),
                    child: _SessionSettingsCard(
                      key: ValueKey(
                        'user-settings-session-${otherSessions[index].id}',
                      ),
                      session: otherSessions[index],
                      current: false,
                      busy: controller.busySessionId == otherSessions[index].id,
                      onRevoke: () =>
                          controller.revokeSession(otherSessions[index].id),
                    ),
                  ),
            ],
          ],
        );
      },
    );
  }
}

class _SessionsLoadingPanel extends StatelessWidget {
  const _SessionsLoadingPanel();

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return _SettingsPanel(
      child: Row(
        children: [
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.accentStrong,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading active sessions...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SessionSettingsCard extends StatelessWidget {
  const _SessionSettingsCard({
    required this.session,
    required this.current,
    required this.busy,
    required this.onRevoke,
    super.key,
  });

  final UserSettingsSession session;
  final bool current;
  final bool busy;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final icon = session.isMobile
        ? Icons.phone_iphone
        : session.isDesktop
        ? Icons.desktop_windows_outlined
        : Icons.language_outlined;
    final location = session.locationStatusLabel;
    return _SettingsPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: current ? colors.actionMuted : colors.panelHover,
              border: Border.all(
                color: current ? colors.accent : colors.borderStrong,
              ),
              borderRadius: VerdantRadii.sharp,
            ),
            child: Icon(
              current ? Icons.verified_user_outlined : icon,
              size: 20,
              color: current ? colors.accentStrong : colors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.device,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (current) ...[
                      const SizedBox(width: 8),
                      const _SessionCurrentBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _SessionMeta(
                      icon: session.locationLabel == null
                          ? Icons.public_off_outlined
                          : Icons.public_outlined,
                      label: location,
                    ),
                    _SessionMeta(
                      icon: Icons.schedule,
                      label:
                          'Active ${_relativeSessionTime(session.lastRefreshAt)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!current) ...[
            const SizedBox(width: 12),
            IconButton(
              key: ValueKey('user-settings-revoke-session-${session.id}'),
              tooltip: 'Revoke session',
              onPressed: busy ? null : onRevoke,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, size: 18),
              color: const Color(0xFFFF7A9C),
              splashRadius: 18,
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionCurrentBadge extends StatelessWidget {
  const _SessionCurrentBadge();

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.actionMuted,
        border: Border.all(color: colors.accent),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Text(
        'Current Session',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.accentStrong,
          fontWeight: VerdantFontWeights.semibold,
        ),
      ),
    );
  }
}

class _SessionMeta extends StatelessWidget {
  const _SessionMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

String _relativeSessionTime(DateTime date) {
  final now = DateTime.now().toUtc();
  final diff = now.difference(date.toUtc());
  if (diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }
  return '${date.month}/${date.day}/${date.year}';
}

class _NetworkSettingsTab extends StatelessWidget {
  const _NetworkSettingsTab({
    required this.mediaPolicy,
    required this.networkRecords,
    required this.activeNetworkId,
    required this.homeNetworkId,
    required this.onSetNetworkUsername,
    required this.onRetryNetwork,
    required this.onRemoveNetwork,
  });

  final ServerMediaPolicy mediaPolicy;
  final List<RailNetworkRecord> networkRecords;
  final String activeNetworkId;
  final String homeNetworkId;
  final ValueChanged<RailNetworkRecord> onSetNetworkUsername;
  final ValueChanged<RailNetworkRecord> onRetryNetwork;
  final ValueChanged<RailNetworkRecord> onRemoveNetwork;

  @override
  Widget build(BuildContext context) {
    final networks = _settingsNetworkRecords();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Networks', trailing: '${networks.length} saved'),
        const SizedBox(height: 10),
        _SettingsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Joined Networks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < networks.length; index += 1) ...[
                if (index > 0) const _SettingsDivider(),
                _NetworkSettingsRow(
                  record: networks[index],
                  active: sameWorkspaceNetworkId(
                    networks[index].networkId,
                    activeNetworkId,
                  ),
                  homeNetworkId: homeNetworkId,
                  mediaOriginCount: mediaPolicy.allowedOrigins.length,
                  onSetNetworkUsername: onSetNetworkUsername,
                  onRetryNetwork: onRetryNetwork,
                  onRemoveNetwork: onRemoveNetwork,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<RailNetworkRecord> _settingsNetworkRecords() {
    if (networkRecords.isNotEmpty) {
      return networkRecords;
    }
    return [
      RailNetworkRecord(
        networkId: activeNetworkId,
        networkName: _hostLabelFor(mediaPolicy.apiOrigin),
        mode: RailNetworkMode.unknown,
        availability: RailNetworkAvailability.available,
        authStatus: RailNetworkAuthStatus.authenticated,
        apiOrigin: mediaPolicy.apiOrigin,
      ),
    ];
  }
}

class _NetworkSettingsRow extends StatefulWidget {
  const _NetworkSettingsRow({
    required this.record,
    required this.active,
    required this.homeNetworkId,
    required this.mediaOriginCount,
    required this.onSetNetworkUsername,
    required this.onRetryNetwork,
    required this.onRemoveNetwork,
  });

  final RailNetworkRecord record;
  final bool active;
  final String homeNetworkId;
  final int mediaOriginCount;
  final ValueChanged<RailNetworkRecord> onSetNetworkUsername;
  final ValueChanged<RailNetworkRecord> onRetryNetwork;
  final ValueChanged<RailNetworkRecord> onRemoveNetwork;

  @override
  State<_NetworkSettingsRow> createState() => _NetworkSettingsRowState();
}

class _NetworkSettingsRowState extends State<_NetworkSettingsRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final isHomeNetwork = _isHomeNetwork(widget.record, widget.homeNetworkId);
    final status = _networkStatusLabel(
      widget.record,
      isHomeNetwork: isHomeNetwork,
    );
    final statusColor = _networkStatusColor(widget.record, colors);
    final needsUsername = _networkRecordNeedsUsername(widget.record);
    final usesFederationAccess =
        !isHomeNetwork && _usesFederationAccess(widget.record);
    final needsFederatedReconnect =
        !isHomeNetwork && _needsFederatedReconnect(widget.record);
    final displayName = _networkDisplayName(
      widget.record,
      isHomeNetwork: isHomeNetwork,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _expanded ? colors.panelHover.withValues(alpha: 0.45) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('user-settings-network-row-${widget.record.networkId}'),
          borderRadius: BorderRadius.circular(6),
          hoverColor: colors.panelHover.withValues(alpha: 0.55),
          splashColor: colors.accent.withValues(alpha: 0.12),
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: statusColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 140),
                      turns: _expanded ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 10),
                  _ReadOnlySettingsRow(
                    label: 'Network Type',
                    value: isHomeNetwork ? 'Home Network' : 'Federated Network',
                  ),
                  const _SettingsDivider(),
                  _ReadOnlySettingsRow(
                    label: 'Network Origin',
                    value: widget.record.apiOrigin ?? 'Unknown origin',
                  ),
                  const _SettingsDivider(),
                  _ReadOnlySettingsRow(
                    label: 'Connected As',
                    value: _networkConnectionLabel(
                      widget.record,
                      status,
                      isHomeNetwork: isHomeNetwork,
                    ),
                  ),
                  if (usesFederationAccess) ...[
                    const SizedBox(height: 10),
                    const _SettingsInfoBanner(
                      message: 'Federated access from your home network.',
                    ),
                  ] else if (needsFederatedReconnect) ...[
                    const SizedBox(height: 10),
                    const _SettingsInfoBanner(
                      message:
                          'Rejoin a federated server invite to restore access on this network.',
                    ),
                  ],
                  if (needsUsername) ...[
                    const SizedBox(height: 10),
                    _SettingsInfoBanner(
                      message:
                          'Choose a username for this network account. This does not change other networks.',
                    ),
                    const SizedBox(height: 10),
                    _SmallSettingsButton(
                      key: ValueKey(
                        'user-settings-network-set-username-${widget.record.networkId}',
                      ),
                      label: 'Set Username',
                      icon: Icons.alternate_email,
                      busy: false,
                      onPressed: () =>
                          widget.onSetNetworkUsername(widget.record),
                    ),
                  ],
                  const _SettingsDivider(),
                  _ReadOnlySettingsRow(
                    label: 'Media Origins',
                    value: widget.active
                        ? '${widget.mediaOriginCount} allowed origins'
                        : 'Loaded when this network is opened',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (_canRetry(widget.record))
                        _SmallSettingsButton(
                          key: ValueKey(
                            'user-settings-network-retry-${widget.record.networkId}',
                          ),
                          label: 'Retry',
                          icon: Icons.refresh,
                          busy: false,
                          onPressed: () => widget.onRetryNetwork(widget.record),
                        ),
                      if (_canRemove(widget.record, widget.homeNetworkId))
                        _SmallSettingsButton(
                          key: ValueKey(
                            'user-settings-network-remove-${widget.record.networkId}',
                          ),
                          label: 'Remove',
                          icon: Icons.delete_outline,
                          busy: false,
                          onPressed: () =>
                              widget.onRemoveNetwork(widget.record),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _canRetry(RailNetworkRecord record) {
  return record.apiOrigin != null &&
      record.authStatus == RailNetworkAuthStatus.authenticated &&
      record.availability != RailNetworkAvailability.available;
}

bool _canRemove(RailNetworkRecord record, String homeNetworkId) {
  if (_isHomeNetwork(record, homeNetworkId)) {
    return false;
  }
  final apiOrigin = record.apiOrigin;
  if (apiOrigin == null) {
    return false;
  }
  try {
    normalizeBackendApiOrigin(apiOrigin);
    return true;
  } catch (_) {
    return false;
  }
}

bool _networkRecordNeedsUsername(RailNetworkRecord record) {
  return railNetworkRecordNeedsUsername(record);
}

String _networkConnectionLabel(
  RailNetworkRecord record,
  String fallback, {
  required bool isHomeNetwork,
}) {
  if (record.authStatus != RailNetworkAuthStatus.authenticated) {
    return fallback;
  }
  if (railNetworkRecordNeedsUsername(record)) {
    return 'Username needed';
  }
  final username = record.currentUsername;
  if (username == null || username.trim().isEmpty) {
    return record.usesFederatedAccess && !isHomeNetwork
        ? 'Connected with federated access'
        : 'Connected';
  }
  return 'Connected as @$username';
}

String _networkStatusLabel(
  RailNetworkRecord record, {
  required bool isHomeNetwork,
}) {
  if (!isHomeNetwork && _needsFederatedReconnect(record)) {
    return 'Reconnect needed';
  }
  if (record.authStatus == RailNetworkAuthStatus.signedOut) {
    return 'Disconnected';
  }
  return switch (record.availability) {
    RailNetworkAvailability.available =>
      record.authStatus == RailNetworkAuthStatus.authenticated
          ? isHomeNetwork
                ? 'Home Network'
                : 'Federated Network'
          : 'Disconnected',
    RailNetworkAvailability.checking => 'Checking',
    RailNetworkAvailability.requiresAuth => 'Disconnected',
    RailNetworkAvailability.unavailable => 'Unavailable',
    RailNetworkAvailability.unsupported => 'Unavailable',
  };
}

bool _usesFederationAccess(RailNetworkRecord record) {
  return record.usesFederatedAccess &&
      record.authStatus == RailNetworkAuthStatus.authenticated;
}

bool _needsFederatedReconnect(RailNetworkRecord record) {
  return record.usesFederatedAccess &&
      (record.authStatus == RailNetworkAuthStatus.signedOut ||
          record.availability == RailNetworkAvailability.requiresAuth);
}

bool _isHomeNetwork(RailNetworkRecord record, String homeNetworkId) {
  return sameWorkspaceNetworkId(record.networkId, homeNetworkId);
}

String _networkDisplayName(
  RailNetworkRecord record, {
  required bool isHomeNetwork,
}) {
  if (isHomeNetwork) {
    return 'Home Network';
  }
  return record.networkName.trim().isEmpty
      ? 'Federated Network'
      : record.networkName;
}

Color _networkStatusColor(RailNetworkRecord record, VerdantThemeColors colors) {
  return switch (record.availability) {
    RailNetworkAvailability.available =>
      record.authStatus == RailNetworkAuthStatus.authenticated
          ? colors.accent
          : const Color(0xFFF59E0B),
    RailNetworkAvailability.checking => const Color(0xFFF59E0B),
    RailNetworkAvailability.requiresAuth => const Color(0xFFF59E0B),
    RailNetworkAvailability.unavailable => const Color(0xFFEF4444),
    RailNetworkAvailability.unsupported => const Color(0xFFEF4444),
  };
}

String _hostLabelFor(String? apiOrigin) {
  if (apiOrigin == null || apiOrigin.trim().isEmpty) {
    return 'Current Network';
  }
  final parsed = Uri.tryParse(apiOrigin);
  return parsed?.host.isNotEmpty == true ? parsed!.host : 'Current Network';
}
