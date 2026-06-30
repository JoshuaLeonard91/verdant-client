import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/smooth_single_child_scroll_view.dart';
import '../../../theme/verdant_theme.dart';
import 'server_settings_models.dart';
import 'server_settings_permissions.dart';
import 'server_settings_service.dart';

class ServerSettingsRolesTab extends StatefulWidget {
  const ServerSettingsRolesTab({
    required this.roles,
    required this.canManageRoles,
    this.serverId,
    this.roleRepository,
    this.onRolesChanged,
    super.key,
  });

  final List<ServerSettingsListItemSeed> roles;
  final bool canManageRoles;
  final String? serverId;
  final ServerSettingsRoleRepository? roleRepository;
  final ValueChanged<List<ServerSettingsListItemSeed>>? onRolesChanged;

  @override
  State<ServerSettingsRolesTab> createState() => _ServerSettingsRolesTabState();
}

class _ServerSettingsRolesTabState extends State<ServerSettingsRolesTab> {
  String? _selectedRoleId;
  late List<ServerSettingsListItemSeed> _roles = [...widget.roles];
  bool _saving = false;
  String? _error;
  bool _showingEditor = false;

  @override
  void initState() {
    super.initState();
    _selectedRoleId = _initialRoleIdentity(widget.roles);
  }

  @override
  void didUpdateWidget(covariant ServerSettingsRolesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roles != widget.roles) {
      _roles = [...widget.roles];
      if (!_roles.any((role) => _roleIdentity(role) == _selectedRoleId)) {
        _selectedRoleId = _initialRoleIdentity(_roles);
        _showingEditor = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedRoles = [..._roles]..sort(_compareRolesForTauri);
    final permissionRoles = [
      for (final role in sortedRoles)
        if (!role.colorOnly) role,
    ];
    final colorRoles = [
      for (final role in sortedRoles)
        if (role.colorOnly) role,
    ];
    final selectedRole = _selectedRole(sortedRoles);
    final bodyHeight = (MediaQuery.sizeOf(context).height - 116).clamp(
      420.0,
      720.0,
    );

    final showingEditor = _showingEditor && selectedRole != null;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: SizedBox(
        height: bodyHeight,
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            reverseDuration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                children: [
                  for (final child in previousChildren)
                    Positioned.fill(child: child),
                  if (currentChild != null)
                    Positioned.fill(child: currentChild),
                ],
              );
            },
            transitionBuilder: (child, animation) {
              final isEditor =
                  child.key == const ValueKey('server-role-editor-route');
              final offset = Tween<Offset>(
                begin: isEditor ? const Offset(1, 0) : const Offset(-0.08, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: showingEditor
                ? _RoleEditorRoute(
                    key: const ValueKey('server-role-editor-route'),
                    role: selectedRole,
                    canManageRoles: widget.canManageRoles,
                    canWrite: _canWrite && !_isEveryoneRole(selectedRole),
                    saving: _saving,
                    error: _error,
                    onBack: () => setState(() => _showingEditor = false),
                    onPatch: _updateRole,
                  )
                : _RoleRail(
                    key: const ValueKey('server-role-list-route'),
                    permissionRoles: permissionRoles,
                    colorRoles: colorRoles,
                    selectedRoleId: _selectedRoleId,
                    canManageRoles: widget.canManageRoles,
                    onSelected: (role) => setState(() {
                      _selectedRoleId = _roleIdentity(role);
                      _showingEditor = true;
                    }),
                    onCreatePermissionRole: () => _createRole(colorOnly: false),
                    onCreateColorRole: () => _createRole(colorOnly: true),
                    canWrite: _canWrite,
                    saving: _saving,
                  ),
          ),
        ),
      ),
    );
  }

  ServerSettingsListItemSeed? _selectedRole(
    List<ServerSettingsListItemSeed> roles,
  ) {
    if (roles.isEmpty) {
      return null;
    }
    if (_selectedRoleId == null) {
      return null;
    }
    for (final role in roles) {
      if (_roleIdentity(role) == _selectedRoleId) {
        return role;
      }
    }
    return null;
  }

  bool get _canWrite =>
      widget.canManageRoles &&
      widget.serverId != null &&
      widget.roleRepository != null &&
      !_saving;

  Future<void> _createRole({required bool colorOnly}) async {
    final repository = widget.roleRepository;
    final serverId = widget.serverId;
    if (!_canWrite || repository == null || serverId == null) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created = await repository.createRole(
        serverId: serverId,
        patch: ServerRolePatch(
          name: colorOnly ? 'New Name Color' : 'New Access Role',
          color: colorOnly ? '#22c55e' : ServerRolePatch.unset,
          permissions: 0,
          colorOnly: colorOnly,
          showAsSection: false,
        ),
      );
      if (!mounted) {
        return;
      }
      _setRoles([created, ..._roles]);
      setState(() {
        _selectedRoleId = _roleIdentity(created);
        _showingEditor = true;
        _saving = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = _roleErrorMessage(error);
      });
    }
  }

  Future<void> _updateRole(
    ServerSettingsListItemSeed role,
    ServerRolePatch patch,
  ) async {
    final repository = widget.roleRepository;
    final serverId = widget.serverId;
    final roleId = role.id;
    if (!_canWrite ||
        repository == null ||
        serverId == null ||
        roleId == null ||
        _isEveryoneRole(role)) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await repository.updateRole(
        serverId: serverId,
        roleId: roleId,
        patch: patch,
      );
      if (!mounted) {
        return;
      }
      _replaceRole(role, updated);
      setState(() => _saving = false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = _roleErrorMessage(error);
      });
    }
  }

  void _replaceRole(
    ServerSettingsListItemSeed oldRole,
    ServerSettingsListItemSeed updated,
  ) {
    final oldId = oldRole.id ?? _stableRoleKey(oldRole);
    _setRoles([
      for (final role in _roles)
        if ((role.id ?? _stableRoleKey(role)) == oldId) updated else role,
    ]);
  }

  void _setRoles(List<ServerSettingsListItemSeed> roles) {
    _roles = [...roles]..sort(_compareRolesForTauri);
    widget.onRolesChanged?.call(List.unmodifiable(_roles));
  }
}

class _RoleEditorRoute extends StatelessWidget {
  const _RoleEditorRoute({
    required this.role,
    required this.canManageRoles,
    required this.canWrite,
    required this.saving,
    required this.error,
    required this.onBack,
    required this.onPatch,
    super.key,
  });

  final ServerSettingsListItemSeed role;
  final bool canManageRoles;
  final bool canWrite;
  final bool saving;
  final String? error;
  final VoidCallback onBack;
  final Future<void> Function(
    ServerSettingsListItemSeed role,
    ServerRolePatch patch,
  )
  onPatch;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 38,
          child: Row(
            children: [
              TextButton.icon(
                key: const ValueKey('server-role-editor-back-button'),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 15),
                label: const Text('Back'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  role.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: VerdantFontWeights.black,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                role.colorOnly ? 'Name Color' : 'Access Role',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                  fontWeight: VerdantFontWeights.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _RoleDetails(
            role: role,
            canManageRoles: canManageRoles,
            canWrite: canWrite,
            saving: saving,
            error: error,
            onPatch: onPatch,
          ),
        ),
      ],
    );
  }
}

class _RoleRail extends StatelessWidget {
  const _RoleRail({
    required this.permissionRoles,
    required this.colorRoles,
    required this.selectedRoleId,
    required this.canManageRoles,
    required this.onSelected,
    required this.onCreatePermissionRole,
    required this.onCreateColorRole,
    required this.canWrite,
    required this.saving,
    super.key,
  });

  final List<ServerSettingsListItemSeed> permissionRoles;
  final List<ServerSettingsListItemSeed> colorRoles;
  final String? selectedRoleId;
  final bool canManageRoles;
  final ValueChanged<ServerSettingsListItemSeed> onSelected;
  final VoidCallback onCreatePermissionRole;
  final VoidCallback onCreateColorRole;
  final bool canWrite;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _RoleRailSection(
            title: 'Access Roles',
            description: 'Permissions and member-list grouping.',
            actionLabel: 'Create Access Role',
            actionIcon: Icons.add,
            scrollKey: const ValueKey('server-permission-roles-scroll'),
            createButtonKey: const ValueKey(
              'server-create-permission-role-button',
            ),
            canManageRoles: canManageRoles,
            roles: permissionRoles,
            selectedRoleId: selectedRoleId,
            onSelected: onSelected,
            onCreate: onCreatePermissionRole,
            canWrite: canWrite,
            saving: saving,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _RoleRailSection(
            title: 'Name Colors',
            description: 'Member-selectable display colors only.',
            actionLabel: 'Create Name Color',
            actionIcon: Icons.add,
            scrollKey: const ValueKey('server-color-roles-scroll'),
            createButtonKey: const ValueKey('server-create-color-role-button'),
            canManageRoles: canManageRoles,
            roles: colorRoles,
            selectedRoleId: selectedRoleId,
            onSelected: onSelected,
            onCreate: onCreateColorRole,
            canWrite: canWrite,
            saving: saving,
          ),
        ),
      ],
    );
  }
}

class _RoleRailSection extends StatelessWidget {
  const _RoleRailSection({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    required this.scrollKey,
    required this.createButtonKey,
    required this.canManageRoles,
    required this.roles,
    required this.selectedRoleId,
    required this.onSelected,
    required this.onCreate,
    required this.canWrite,
    required this.saving,
  });

  final String title;
  final String description;
  final String actionLabel;
  final IconData actionIcon;
  final Key scrollKey;
  final Key createButtonKey;
  final bool canManageRoles;
  final List<ServerSettingsListItemSeed> roles;
  final String? selectedRoleId;
  final ValueChanged<ServerSettingsListItemSeed> onSelected;
  final VoidCallback onCreate;
  final bool canWrite;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _RoleScrollRegion(
        key: scrollKey,
        padding: const EdgeInsets.only(right: 3, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionLabel(label: title),
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),
            _RoleActionButton(
              key: createButtonKey,
              label: actionLabel,
              icon: actionIcon,
              enabled: canWrite,
              canManageRoles: canManageRoles,
              saving: saving,
              onPressed: onCreate,
            ),
            const SizedBox(height: 8),
            for (final role in roles)
              _RoleRow(
                role: role,
                selected: _roleIdentity(role) == selectedRoleId,
                onSelected: onSelected,
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.role,
    required this.selected,
    required this.onSelected,
  });

  final ServerSettingsListItemSeed role;
  final bool selected;
  final ValueChanged<ServerSettingsListItemSeed> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final color = _roleColor(role);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextButton(
        key: ValueKey('server-role-row-${role.id ?? _stableRoleKey(role)}'),
        onPressed: () => onSelected(role),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: selected ? colors.accentStrong : colors.textMuted,
          backgroundColor: selected ? colors.actionMuted : Colors.transparent,
          minimumSize: const Size.fromHeight(34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Row(
          children: [
            if (color != null) ...[
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 9),
            ],
            Expanded(
              child: Text(
                role.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? colors.accentStrong : colors.textMuted,
                  fontWeight: VerdantFontWeights.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleDetails extends StatefulWidget {
  const _RoleDetails({
    required this.role,
    required this.canManageRoles,
    required this.canWrite,
    required this.saving,
    required this.error,
    required this.onPatch,
  });

  final ServerSettingsListItemSeed role;
  final bool canManageRoles;
  final bool canWrite;
  final bool saving;
  final String? error;
  final Future<void> Function(
    ServerSettingsListItemSeed role,
    ServerRolePatch patch,
  )
  onPatch;

  @override
  State<_RoleDetails> createState() => _RoleDetailsState();
}

class _RoleDetailsState extends State<_RoleDetails> {
  late final TextEditingController _nameController;
  late final TextEditingController _hexController;
  late bool _draftShowAsSection;
  late int _draftPermissions;
  String? _draftColorHex;
  bool _syncingDraft = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role.title);
    _hexController = TextEditingController(
      text: _roleColorHex(widget.role) ?? '',
    );
    _nameController.addListener(_handleDraftTextChanged);
    _resetDraft(widget.role);
  }

  @override
  void didUpdateWidget(covariant _RoleDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_roleChanged(oldWidget.role, widget.role)) {
      _resetDraft(widget.role);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleDraftTextChanged);
    _nameController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final role = widget.role;
    final isEveryone = _isEveryoneRole(role);
    final color = _parseHexColor(_draftColorHex) ?? role.accent;
    final canWrite = widget.canWrite && !isEveryone;
    final hasChanges = canWrite && _hasDraftChanges;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _RoleScrollRegion(
        key: const ValueKey('server-role-editor-scroll'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isEveryone) ...[
              _SectionLabel(label: 'Role Name'),
              const SizedBox(height: 8),
              _RoleTextField(
                key: const ValueKey('server-role-name-field'),
                controller: _nameController,
                enabled: canWrite,
                onSubmitted: _normalizeDraftName,
              ),
              const SizedBox(height: 18),
            ],
            if (!isEveryone && !role.colorOnly) ...[
              _MemberListSectionCard(
                value: _draftShowAsSection,
                enabled: canWrite,
                onChanged: (value) =>
                    setState(() => _draftShowAsSection = value),
              ),
              const SizedBox(height: 18),
            ],
            if (!isEveryone) ...[
              _SectionLabel(label: 'Role Color'),
              const SizedBox(height: 8),
              _RoleColorPicker(
                value: _draftColorHex,
                color: color,
                enabled: canWrite,
                hexController: _hexController,
                onCommitted: (hex) => setState(() {
                  _draftColorHex = hex;
                  _hexController.text = hex ?? '';
                }),
              ),
              const SizedBox(height: 18),
            ],
            if (!role.colorOnly) ...[
              _SectionLabel(label: 'Permissions'),
              const SizedBox(height: 10),
              for (final category in serverPermissionCategories) ...[
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textMuted,
                    fontWeight: VerdantFontWeights.black,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                for (final permission in category.permissions)
                  _PermissionRow(
                    permission: permission,
                    value: permissionsInclude(
                      _draftPermissions,
                      permission.bit,
                    ),
                    enabled: canWrite,
                    onChanged: (value) => setState(() {
                      _draftPermissions = togglePermissionBit(
                        _draftPermissions,
                        permission.bit,
                        value,
                      );
                    }),
                  ),
                const SizedBox(height: 12),
              ],
            ] else
              Text(
                'Name Colors are cosmetic only. They do not grant permissions or create member-list sections.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (widget.error != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.error!,
                key: const ValueKey('server-role-editor-error'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF809A)),
              ),
            ],
            if (widget.saving) ...[
              const SizedBox(height: 12),
              Text(
                'Saving role changes...',
                key: const ValueKey('server-role-editor-saving'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ],
            if (hasChanges) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  TextButton(
                    key: const ValueKey('server-role-reset-button'),
                    onPressed: widget.saving
                        ? null
                        : () => setState(() => _resetDraft(widget.role)),
                    child: const Text('Reset'),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey('server-role-save-button'),
                    onPressed: widget.saving ? null : _saveDraft,
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleDraftTextChanged() {
    if (mounted && !_syncingDraft) {
      setState(() {});
    }
  }

  void _resetDraft(ServerSettingsListItemSeed role) {
    final colorHex = _roleColorHex(role);
    _syncingDraft = true;
    _nameController.text = role.title;
    _draftShowAsSection = role.showAsSection;
    _draftPermissions = role.permissions ?? 0;
    _draftColorHex = colorHex;
    _hexController.text = colorHex ?? '';
    _syncingDraft = false;
  }

  bool _roleChanged(
    ServerSettingsListItemSeed oldRole,
    ServerSettingsListItemSeed newRole,
  ) {
    return oldRole.id != newRole.id ||
        oldRole.title != newRole.title ||
        oldRole.trailing != newRole.trailing ||
        oldRole.permissions != newRole.permissions ||
        oldRole.position != newRole.position ||
        oldRole.colorOnly != newRole.colorOnly ||
        oldRole.showAsSection != newRole.showAsSection ||
        oldRole.colorPriority != newRole.colorPriority;
  }

  bool get _hasDraftChanges {
    final role = widget.role;
    return _draftName != role.title ||
        _draftColorHex != _roleColorHex(role) ||
        (!role.colorOnly && _draftShowAsSection != role.showAsSection) ||
        (!role.colorOnly && _draftPermissions != (role.permissions ?? 0));
  }

  String get _draftName => _nameController.text.trim();

  void _normalizeDraftName(String value) {
    final trimmed = value.trim();
    _nameController.text = trimmed.isEmpty ? widget.role.title : trimmed;
  }

  Future<void> _saveDraft() async {
    if (!_hasDraftChanges || widget.saving) {
      return;
    }
    final role = widget.role;
    final colorChanged = _draftColorHex != _roleColorHex(role);
    await widget.onPatch(
      role,
      ServerRolePatch(
        name: _draftName == role.title ? null : _draftName,
        color: colorChanged ? _draftColorHex : ServerRolePatch.unset,
        permissions:
            role.colorOnly || _draftPermissions == (role.permissions ?? 0)
            ? null
            : _draftPermissions,
        showAsSection:
            role.colorOnly || _draftShowAsSection == role.showAsSection
            ? null
            : _draftShowAsSection,
      ),
    );
  }
}

class _RoleScrollRegion extends StatefulWidget {
  const _RoleScrollRegion({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  State<_RoleScrollRegion> createState() => _RoleScrollRegionState();
}

class _RoleScrollRegionState extends State<_RoleScrollRegion> {
  final ScrollController _controller = ScrollController();
  final _metricsVersion = ValueNotifier<int>(0);

  @override
  void dispose() {
    _controller.dispose();
    _metricsVersion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical) {
          _metricsVersion.value += 1;
        }
        return false;
      },
      child: Stack(
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: SmoothSingleChildScrollView(
              controller: _controller,
              primary: false,
              padding: widget.padding,
              child: widget.child,
            ),
          ),
          _RoleMiniScrollIndicator(
            controller: _controller,
            metricsVersion: _metricsVersion,
          ),
        ],
      ),
    );
  }
}

class _RoleMiniScrollIndicator extends StatefulWidget {
  const _RoleMiniScrollIndicator({
    required this.controller,
    required this.metricsVersion,
  });

  static const _trackTop = 4.0;
  static const _trackBottom = 4.0;
  static const _thumbMinHeight = 26.0;
  static const _thumbWidth = 3.0;
  static const _hitWidth = 14.0;
  static const _animationDuration = Duration(milliseconds: 100);
  static const _metricsSettleDelay = Duration(milliseconds: 180);

  final ScrollController controller;
  final ValueListenable<int> metricsVersion;

  @override
  State<_RoleMiniScrollIndicator> createState() =>
      _RoleMiniScrollIndicatorState();
}

class _RoleMiniScrollIndicatorState extends State<_RoleMiniScrollIndicator> {
  _RoleScrollMetrics? _visualMetrics;
  _RoleScrollMetrics? _pendingMetrics;
  _RoleScrollbarDragAnchor? _dragAnchor;
  Timer? _metricsSettleTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChanged);
    widget.metricsVersion.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(covariant _RoleMiniScrollIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChanged);
      widget.controller.addListener(_handleChanged);
      _visualMetrics = null;
      _pendingMetrics = null;
      _dragAnchor = null;
      _metricsSettleTimer?.cancel();
      _metricsSettleTimer = null;
    }
    if (oldWidget.metricsVersion != widget.metricsVersion) {
      oldWidget.metricsVersion.removeListener(_handleChanged);
      widget.metricsVersion.addListener(_handleChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChanged);
    widget.metricsVersion.removeListener(_handleChanged);
    _metricsSettleTimer?.cancel();
    super.dispose();
  }

  void _handleChanged() {
    final actualMetrics = _readMetrics();
    if (actualMetrics != null) {
      _reconcileVisualMetrics(actualMetrics);
    }
    if (mounted) {
      setState(() {});
    }
  }

  _RoleScrollMetrics? _readMetrics() {
    if (!widget.controller.hasClients ||
        !widget.controller.position.haveDimensions) {
      return null;
    }
    final position = widget.controller.position;
    return _RoleScrollMetrics(
      minScrollExtent: position.minScrollExtent,
      maxScrollExtent: position.maxScrollExtent,
      viewportDimension: position.viewportDimension,
    );
  }

  void _reconcileVisualMetrics(_RoleScrollMetrics actualMetrics) {
    final currentMetrics = _visualMetrics;
    if (currentMetrics == null || currentMetrics.isSameExtent(actualMetrics)) {
      _visualMetrics = actualMetrics;
      _pendingMetrics = null;
      _metricsSettleTimer?.cancel();
      _metricsSettleTimer = null;
      return;
    }

    _schedulePendingMetrics(actualMetrics);
  }

  void _schedulePendingMetrics(_RoleScrollMetrics actualMetrics) {
    if (_dragAnchor != null) {
      _pendingMetrics = actualMetrics;
      return;
    }
    _pendingMetrics = actualMetrics;
    _metricsSettleTimer?.cancel();
    _metricsSettleTimer = Timer(
      _RoleMiniScrollIndicator._metricsSettleDelay,
      () {
        if (!mounted) {
          return;
        }
        setState(() {
          _visualMetrics = _readMetrics() ?? _pendingMetrics;
          _pendingMetrics = null;
          _metricsSettleTimer = null;
        });
      },
    );
  }

  _RoleScrollbarGeometry? _geometryFor(
    BoxConstraints constraints,
    _RoleScrollMetrics metrics,
  ) {
    final scrollRange = metrics.maxScrollExtent - metrics.minScrollExtent;
    final viewport = metrics.viewportDimension;
    if (scrollRange <= 1 || viewport <= 0) {
      return null;
    }
    final trackHeight =
        constraints.maxHeight -
        _RoleMiniScrollIndicator._trackTop -
        _RoleMiniScrollIndicator._trackBottom;
    if (trackHeight <= 0) {
      return null;
    }
    final totalExtent = scrollRange + viewport;
    final thumbHeight = (viewport / totalExtent * trackHeight)
        .clamp(_RoleMiniScrollIndicator._thumbMinHeight, trackHeight)
        .toDouble();
    return _RoleScrollbarGeometry(
      trackHeight: trackHeight,
      thumbHeight: thumbHeight,
      scrollRange: scrollRange,
    );
  }

  void _handleDragStart(
    DragStartDetails details,
    BoxConstraints constraints,
    _RoleScrollMetrics metrics,
  ) {
    if (!widget.controller.hasClients) {
      return;
    }
    final geometry = _geometryFor(constraints, metrics);
    if (geometry == null || geometry.thumbTravel <= 0) {
      return;
    }
    setState(() {
      _dragAnchor = _RoleScrollbarDragAnchor(
        globalY: details.globalPosition.dy,
        scrollPixels: widget.controller.position.pixels,
        metrics: metrics,
        geometry: geometry,
      );
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final anchor = _dragAnchor;
    if (anchor == null || !widget.controller.hasClients) {
      return;
    }
    final deltaY = details.globalPosition.dy - anchor.globalY;
    final scrollDelta =
        deltaY / anchor.geometry.thumbTravel * anchor.geometry.scrollRange;
    final target = (anchor.scrollPixels + scrollDelta)
        .clamp(
          widget.controller.position.minScrollExtent,
          widget.controller.position.maxScrollExtent,
        )
        .toDouble();
    widget.controller.jumpTo(target);
  }

  void _handleDragEnd() {
    final pendingMetrics = _pendingMetrics;
    setState(() {
      _dragAnchor = null;
    });
    if (pendingMetrics != null) {
      _schedulePendingMetrics(pendingMetrics);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Positioned.fill(
      key: const ValueKey('server-role-mini-scroll-indicator'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actualMetrics = _readMetrics();
          if (_visualMetrics == null && actualMetrics != null) {
            _visualMetrics = actualMetrics;
          }
          final visualMetrics = _visualMetrics ?? actualMetrics;
          if (visualMetrics == null ||
              constraints.maxHeight <=
                  _RoleMiniScrollIndicator._trackTop +
                      _RoleMiniScrollIndicator._trackBottom) {
            return const SizedBox.shrink();
          }

          if (actualMetrics != null &&
              !visualMetrics.isSameExtent(actualMetrics)) {
            _schedulePendingMetrics(actualMetrics);
          }
          final geometry = _geometryFor(constraints, visualMetrics);
          if (geometry == null) {
            return const SizedBox.shrink();
          }

          final pixels = widget.controller.hasClients
              ? widget.controller.position.pixels
              : visualMetrics.minScrollExtent;
          final progress =
              ((pixels - visualMetrics.minScrollExtent) / geometry.scrollRange)
                  .clamp(0.0, 1.0)
                  .toDouble();
          final thumbTop =
              _RoleMiniScrollIndicator._trackTop +
              geometry.thumbTravel * progress;

          return Stack(
            children: [
              Positioned(
                top: _RoleMiniScrollIndicator._trackTop,
                right: 2,
                width: 1,
                height: geometry.trackHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.border.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                key: const ValueKey('server-role-mini-scroll-thumb'),
                duration: _dragAnchor == null
                    ? _RoleMiniScrollIndicator._animationDuration
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                top: thumbTop,
                right: 1,
                width: _RoleMiniScrollIndicator._thumbWidth,
                height: geometry.thumbHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.textMuted.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('server-role-mini-scrollbar-hit'),
                top: 0,
                right: 0,
                bottom: 0,
                width: _RoleMiniScrollIndicator._hitWidth,
                child: MouseRegion(
                  cursor: SystemMouseCursors.basic,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: (details) => _handleDragStart(
                      details,
                      constraints,
                      actualMetrics ?? visualMetrics,
                    ),
                    onVerticalDragUpdate: _handleDragUpdate,
                    onVerticalDragEnd: (_) => _handleDragEnd(),
                    onVerticalDragCancel: _handleDragEnd,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoleScrollbarGeometry {
  const _RoleScrollbarGeometry({
    required this.trackHeight,
    required this.thumbHeight,
    required this.scrollRange,
  });

  final double trackHeight;
  final double thumbHeight;
  final double scrollRange;

  double get thumbTravel => trackHeight - thumbHeight;
}

class _RoleScrollbarDragAnchor {
  const _RoleScrollbarDragAnchor({
    required this.globalY,
    required this.scrollPixels,
    required this.metrics,
    required this.geometry,
  });

  final double globalY;
  final double scrollPixels;
  final _RoleScrollMetrics metrics;
  final _RoleScrollbarGeometry geometry;
}

class _RoleScrollMetrics {
  const _RoleScrollMetrics({
    required this.minScrollExtent,
    required this.maxScrollExtent,
    required this.viewportDimension,
  });

  final double minScrollExtent;
  final double maxScrollExtent;
  final double viewportDimension;

  bool isSameExtent(_RoleScrollMetrics other) {
    return (minScrollExtent - other.minScrollExtent).abs() < 0.5 &&
        (maxScrollExtent - other.maxScrollExtent).abs() < 0.5 &&
        (viewportDimension - other.viewportDimension).abs() < 0.5;
  }
}

class _RoleTextField extends StatelessWidget {
  const _RoleTextField({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.border),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _MemberListSectionCard extends StatelessWidget {
  const _MemberListSectionCard({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(label: 'Member List'),
                const SizedBox(height: 8),
                Text(
                  'Show as member-list section',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
          Tooltip(
            message:
                'When enabled, online members with this role are grouped under a separate heading in member panels.',
            child: IconButton(
              key: const ValueKey('server-role-member-list-help'),
              onPressed: null,
              icon: const Icon(Icons.question_mark, size: 14),
              color: colors.textMuted,
              disabledColor: colors.textMuted,
              splashRadius: 16,
            ),
          ),
          const SizedBox(width: 4),
          _PillSwitch(
            key: const ValueKey('server-role-member-list-switch'),
            value: value,
            enabled: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PillSwitch extends StatelessWidget {
  const _PillSwitch({
    required this.value,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final activeColor = enabled
        ? colors.accentStrong
        : colors.textMuted.withValues(alpha: 0.42);
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          width: 48,
          height: 26,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? activeColor : colors.panel,
            border: Border.all(
              color: value ? activeColor : colors.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? Colors.white : colors.textMuted,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 7,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleColorPicker extends StatefulWidget {
  const _RoleColorPicker({
    required this.value,
    required this.color,
    required this.enabled,
    required this.hexController,
    required this.onCommitted,
  });

  final String? value;
  final Color? color;
  final bool enabled;
  final TextEditingController hexController;
  final ValueChanged<String?> onCommitted;

  @override
  State<_RoleColorPicker> createState() => _RoleColorPickerState();
}

class _RoleColorPickerState extends State<_RoleColorPicker> {
  late HSVColor _workingColor = _hsvFromWidget();
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant _RoleColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging &&
        (oldWidget.value != widget.value || oldWidget.color != widget.color)) {
      _workingColor = _hsvFromWidget();
    }
  }

  HSVColor _hsvFromWidget() {
    return HSVColor.fromColor(widget.color ?? const Color(0xFF22C55E));
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final preview = _workingColor.toColor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              key: const ValueKey('server-role-color-preview'),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: widget.color == null && !_dragging
                    ? Colors.transparent
                    : preview,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                key: const ValueKey('server-role-color-hex-field'),
                controller: widget.hexController,
                enabled: widget.enabled,
                maxLength: 7,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: _commitHexInput,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '#22c55e',
                  filled: true,
                  fillColor: colors.panel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.accentStrong),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const ValueKey('server-role-clear-color-button'),
              onPressed: widget.enabled && widget.value != null
                  ? () => widget.onCommitted(null)
                  : null,
              icon: const Icon(Icons.close, size: 16),
              color: colors.textMuted,
              splashRadius: 16,
              tooltip: 'Remove color',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Builder(
          builder: (padContext) {
            return GestureDetector(
              key: const ValueKey('server-role-color-saturation-value'),
              behavior: HitTestBehavior.opaque,
              onTapDown: widget.enabled
                  ? (details) => _handlePadTap(details, padContext)
                  : null,
              onPanStart: widget.enabled
                  ? (details) => _handlePadStart(details, padContext)
                  : null,
              onPanUpdate: widget.enabled
                  ? (details) => _handlePadUpdate(details, padContext)
                  : null,
              onPanEnd: widget.enabled ? (_) => _commitWorkingColor() : null,
              onPanCancel: widget.enabled ? _commitWorkingColor : null,
              child: Container(
                height: 104,
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      HSVColor.fromAHSV(1, _workingColor.hue, 1, 1).toColor(),
                    ],
                  ),
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (hueContext) {
            return GestureDetector(
              key: const ValueKey('server-role-color-hue-slider'),
              behavior: HitTestBehavior.opaque,
              onTapDown: widget.enabled
                  ? (details) => _handleHueTap(details, hueContext)
                  : null,
              onPanStart: widget.enabled
                  ? (details) => _handleHueStart(details, hueContext)
                  : null,
              onPanUpdate: widget.enabled
                  ? (details) => _handleHueUpdate(details, hueContext)
                  : null,
              onPanEnd: widget.enabled ? (_) => _commitWorkingColor() : null,
              onPanCancel: widget.enabled ? _commitWorkingColor : null,
              child: CustomPaint(
                painter: _HueSliderPainter(colors.border),
                child: SizedBox(
                  height: 18,
                  child: Align(
                    alignment: Alignment((_workingColor.hue / 180) - 1, 0),
                    child: Container(
                      width: 10,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colors.panel, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _handlePadTap(TapDownDetails details, BuildContext targetContext) {
    _setColorFromPad(details.localPosition, targetContext);
    _commitWorkingColor();
  }

  void _handlePadStart(DragStartDetails details, BuildContext targetContext) {
    _dragging = true;
    _setColorFromPad(details.localPosition, targetContext);
  }

  void _handlePadUpdate(DragUpdateDetails details, BuildContext targetContext) {
    _setColorFromPad(details.localPosition, targetContext);
  }

  void _handleHueTap(TapDownDetails details, BuildContext targetContext) {
    _setHueFromPosition(details.localPosition, targetContext);
    _commitWorkingColor();
  }

  void _handleHueStart(DragStartDetails details, BuildContext targetContext) {
    _dragging = true;
    _setHueFromPosition(details.localPosition, targetContext);
  }

  void _handleHueUpdate(DragUpdateDetails details, BuildContext targetContext) {
    _setHueFromPosition(details.localPosition, targetContext);
  }

  void _setColorFromPad(Offset localPosition, BuildContext targetContext) {
    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final size = box.size;
    final saturation = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - (localPosition.dy / size.height)).clamp(0.0, 1.0);
    setState(() {
      _workingColor = _workingColor.withSaturation(saturation).withValue(value);
      widget.hexController.text = _hexFromColor(_workingColor.toColor());
    });
  }

  void _setHueFromPosition(Offset localPosition, BuildContext targetContext) {
    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final hue = (localPosition.dx / box.size.width).clamp(0.0, 1.0) * 360;
    setState(() {
      _workingColor = _workingColor.withHue(hue);
      widget.hexController.text = _hexFromColor(_workingColor.toColor());
    });
  }

  void _commitHexInput(String value) {
    final normalized = _normalizedHexInput(value);
    if (normalized == null) {
      widget.hexController.text = widget.value ?? '';
      return;
    }
    setState(() {
      _workingColor = HSVColor.fromColor(_parseHexColor(normalized)!);
      widget.hexController.text = normalized;
    });
    widget.onCommitted(normalized);
  }

  void _commitWorkingColor() {
    _dragging = false;
    final hex = _hexFromColor(_workingColor.toColor());
    widget.hexController.text = hex;
    widget.onCommitted(hex);
  }
}

class _HueSliderPainter extends CustomPainter {
  const _HueSliderPainter(this.borderColor);

  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ).createShader(rect);
    final radius = Radius.circular(size.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(covariant _HueSliderPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor;
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.permission,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final ServerPermissionDefinition permission;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      key: ValueKey('server-role-permission-row-${permission.key}'),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: permission.danger && value
                ? const Color(0xFFFF6B78).withValues(alpha: 0.48)
                : colors.border.withValues(alpha: 0.58),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: permission.danger && value
                        ? const Color(0xFFFF6B78)
                        : null,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  permission.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            key: ValueKey('server-role-permission-${permission.key}'),
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _RoleActionButton extends StatelessWidget {
  const _RoleActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.canManageRoles,
    required this.saving,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool canManageRoles;
  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Tooltip(
      message: canManageRoles
          ? 'Create this role on the owning backend.'
          : 'Manage roles permission required',
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 15),
        label: Text(
          saving ? 'Saving...' : label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 12.5,
            fontWeight: VerdantFontWeights.black,
          ),
        ),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: colors.accentStrong,
          disabledForegroundColor: colors.textMuted,
          minimumSize: const Size.fromHeight(34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        letterSpacing: 1.4,
        fontWeight: VerdantFontWeights.black,
      ),
    );
  }
}

int _compareRolesForTauri(
  ServerSettingsListItemSeed left,
  ServerSettingsListItemSeed right,
) {
  if (_isEveryoneRole(left)) {
    return 1;
  }
  if (_isEveryoneRole(right)) {
    return -1;
  }
  if (left.colorOnly != right.colorOnly) {
    return left.colorOnly ? 1 : -1;
  }
  if (left.colorOnly && right.colorOnly) {
    final priorityCompare = _roleColorPriority(
      right,
    ).compareTo(_roleColorPriority(left));
    if (priorityCompare != 0) {
      return priorityCompare;
    }
  }
  final positionCompare = (right.position ?? 0).compareTo(left.position ?? 0);
  if (positionCompare != 0) {
    return positionCompare;
  }
  return left.title.toLowerCase().compareTo(right.title.toLowerCase());
}

int _roleColorPriority(ServerSettingsListItemSeed role) {
  return role.colorPriority ?? role.position ?? 0;
}

bool _isEveryoneRole(ServerSettingsListItemSeed role) {
  return !role.colorOnly && role.position == 0 && role.title == '@everyone';
}

Color? _roleColor(ServerSettingsListItemSeed role) {
  return _parseHexColor(_roleColorHex(role)) ?? role.accent;
}

String? _roleColorHex(ServerSettingsListItemSeed role) {
  final trailing = role.trailing?.trim().toLowerCase();
  if (trailing != null && RegExp(r'^#[0-9a-f]{6}$').hasMatch(trailing)) {
    return trailing;
  }
  return null;
}

String _roleIdentity(ServerSettingsListItemSeed role) {
  return role.id ?? _stableRoleKey(role);
}

String? _initialRoleIdentity(List<ServerSettingsListItemSeed> roles) {
  if (roles.isEmpty) {
    return null;
  }
  return _roleIdentity(roles.first);
}

Color? _parseHexColor(String? value) {
  if (value == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
    return null;
  }
  return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
}

String _hexFromColor(Color color) {
  final value = color.toARGB32() & 0x00ffffff;
  return '#${value.toRadixString(16).padLeft(6, '0')}';
}

String? _normalizedHexInput(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final prefixed = trimmed.startsWith('#') ? trimmed : '#$trimmed';
  if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(prefixed)) {
    return null;
  }
  return prefixed.toLowerCase();
}

int togglePermissionBit(int permissions, int bit, bool enabled) {
  return enabled ? permissions | bit : permissions & ~bit;
}

String _roleErrorMessage(Object error) {
  if (error is ServerSettingsException) {
    return error.message;
  }
  return 'Role update failed.';
}

String _stableRoleKey(ServerSettingsListItemSeed role) {
  final normalized = role.title
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'role' : normalized;
}
