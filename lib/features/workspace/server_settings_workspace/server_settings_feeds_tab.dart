import 'package:flutter/material.dart';

import '../../../shared/smooth_single_child_scroll_view.dart';
import '../../../theme/verdant_theme.dart';
import 'server_settings_models.dart';
import 'server_settings_service.dart';

class ServerSettingsFeedsTab extends StatefulWidget {
  const ServerSettingsFeedsTab({
    required this.feeds,
    required this.roles,
    required this.canManageServer,
    this.serverId,
    this.feedRepository,
    this.onFeedsChanged,
    super.key,
  });

  final List<ServerSettingsListItemSeed> feeds;
  final List<ServerSettingsListItemSeed> roles;
  final bool canManageServer;
  final String? serverId;
  final ServerSettingsFeedRepository? feedRepository;
  final ValueChanged<List<ServerSettingsListItemSeed>>? onFeedsChanged;

  @override
  State<ServerSettingsFeedsTab> createState() => _ServerSettingsFeedsTabState();
}

class _ServerSettingsFeedsTabState extends State<ServerSettingsFeedsTab> {
  late List<ServerSettingsListItemSeed> _feeds = [...widget.feeds];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final Set<String> _publishRoleIds = <String>{};
  final Set<String> _visibleRoleIds = <String>{};
  String? _editingFeedId;
  String? _deletingFeedId;
  bool _showingEditor = false;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleTextChanged);
    _descriptionController.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant ServerSettingsFeedsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feeds != widget.feeds) {
      _feeds = [...widget.feeds];
      if (_editingFeedId != null &&
          !_feeds.any((feed) => _feedIdentity(feed) == _editingFeedId)) {
        _closeEditor();
      }
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleTextChanged);
    _descriptionController.removeListener(_handleTextChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = _assignableRoles;
    final bodyHeight = (MediaQuery.sizeOf(context).height - 116).clamp(
      420.0,
      720.0,
    );

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
                  child.key == const ValueKey('server-feed-editor-route');
              final offset = Tween<Offset>(
                begin: isEditor ? const Offset(1, 0) : const Offset(-0.08, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: _showingEditor
                ? _FeedEditorRoute(
                    key: const ValueKey('server-feed-editor-route'),
                    nameController: _nameController,
                    descriptionController: _descriptionController,
                    roles: roles,
                    publishRoleIds: _publishRoleIds,
                    visibleRoleIds: _visibleRoleIds,
                    saving: _saving,
                    canSave:
                        _canWrite && _nameController.text.trim().isNotEmpty,
                    editing: _editingFeedId != null,
                    error: _error,
                    roleNameForId: _roleNameForId,
                    onAddPublishRole: (roleId) =>
                        setState(() => _addRole(_publishRoleIds, roleId)),
                    onRemovePublishRole: (roleId) =>
                        setState(() => _removeRole(_publishRoleIds, roleId)),
                    onAddVisibleRole: (roleId) =>
                        setState(() => _addRole(_visibleRoleIds, roleId)),
                    onRemoveVisibleRole: (roleId) =>
                        setState(() => _removeRole(_visibleRoleIds, roleId)),
                    onBack: _saving ? null : _closeEditor,
                    onSave: _canWrite && _nameController.text.trim().isNotEmpty
                        ? _saveEditor
                        : null,
                  )
                : _FeedsListRoute(
                    key: const ValueKey('server-feed-list-route'),
                    feeds: _feeds,
                    deletingFeedId: _deletingFeedId,
                    deleting: _deleting,
                    canWrite: _canWrite,
                    error: _error,
                    roleNameForId: _roleNameForId,
                    onCreate: _openCreateEditor,
                    onEdit: _openEditEditor,
                    onDelete: (feed) => setState(() {
                      _deletingFeedId = _feedIdentity(feed);
                      _error = null;
                    }),
                    onCancelDelete: _deleting
                        ? null
                        : () => setState(() => _deletingFeedId = null),
                    onConfirmDelete: _deleteFeed,
                  ),
          ),
        ),
      ),
    );
  }

  bool get _canWrite =>
      widget.canManageServer &&
      widget.serverId != null &&
      widget.feedRepository != null &&
      !_saving &&
      !_deleting;

  List<ServerSettingsListItemSeed> get _assignableRoles {
    final roles = [
      for (final role in widget.roles)
        if (!role.colorOnly && !_isEveryoneRole(role)) role,
    ];
    roles.sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
    return roles;
  }

  void _handleTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openCreateEditor() {
    _editingFeedId = null;
    _nameController.clear();
    _descriptionController.clear();
    _publishRoleIds.clear();
    _visibleRoleIds.clear();
    setState(() {
      _showingEditor = true;
      _deletingFeedId = null;
      _error = null;
    });
  }

  void _openEditEditor(ServerSettingsListItemSeed feed) {
    _editingFeedId = _feedIdentity(feed);
    _nameController.text = feed.title;
    _descriptionController.text = _descriptionText(feed);
    _publishRoleIds
      ..clear()
      ..addAll(feed.publishRoleIds);
    _visibleRoleIds
      ..clear()
      ..addAll(feed.visibleRoleIds);
    setState(() {
      _showingEditor = true;
      _deletingFeedId = null;
      _error = null;
    });
  }

  void _closeEditor() {
    setState(() {
      _showingEditor = false;
      _editingFeedId = null;
      _error = null;
    });
  }

  Future<void> _saveEditor() async {
    final repository = widget.feedRepository;
    final serverId = widget.serverId;
    if (!_canWrite || repository == null || serverId == null) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final patch = ServerFeedPatch(
      name: _nameController.text.trim(),
      description: _descriptionController.text,
      publishRoleIds: _publishRoleIds.toList(growable: false),
      visibleRoleIds: _visibleRoleIds.toList(growable: false),
    );
    try {
      final editingFeedId = _editingFeedId;
      final saved = editingFeedId == null
          ? await repository.createFeed(serverId: serverId, patch: patch)
          : await repository.updateFeed(
              serverId: serverId,
              feedId: editingFeedId,
              patch: patch,
            );
      if (!mounted) {
        return;
      }
      if (editingFeedId == null) {
        _setFeeds([saved, ..._feeds]);
      } else {
        _setFeeds([
          for (final feed in _feeds)
            if (_feedIdentity(feed) == editingFeedId) saved else feed,
        ]);
      }
      setState(() {
        _saving = false;
        _showingEditor = false;
        _editingFeedId = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = _feedErrorMessage(error);
      });
    }
  }

  Future<void> _deleteFeed(ServerSettingsListItemSeed feed) async {
    final repository = widget.feedRepository;
    final serverId = widget.serverId;
    final feedId = feed.id;
    if (!_canWrite ||
        repository == null ||
        serverId == null ||
        feedId == null) {
      return;
    }
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await repository.deleteFeed(serverId: serverId, feedId: feedId);
      if (!mounted) {
        return;
      }
      _setFeeds([
        for (final existing in _feeds)
          if (_feedIdentity(existing) != _feedIdentity(feed)) existing,
      ]);
      setState(() {
        _deleting = false;
        _deletingFeedId = null;
        if (_editingFeedId == _feedIdentity(feed)) {
          _showingEditor = false;
          _editingFeedId = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deleting = false;
        _error = _feedErrorMessage(error);
      });
    }
  }

  void _setFeeds(List<ServerSettingsListItemSeed> feeds) {
    _feeds = feeds;
    widget.onFeedsChanged?.call(List.unmodifiable(_feeds));
  }

  void _addRole(Set<String> target, String roleId) {
    if (!target.any((selected) => _sameRoleId(selected, roleId))) {
      target.add(roleId);
    }
  }

  void _removeRole(Set<String> target, String roleId) {
    target.removeWhere((selected) => _sameRoleId(selected, roleId));
  }

  String _roleNameForId(String roleId) {
    final localRoleId = _localId(roleId);
    for (final role in widget.roles) {
      final id = role.id;
      if (id == null) {
        continue;
      }
      if (id == roleId || _localId(id) == localRoleId) {
        return role.title;
      }
    }
    return localRoleId;
  }
}

class _FeedsListRoute extends StatelessWidget {
  const _FeedsListRoute({
    required this.feeds,
    required this.deletingFeedId,
    required this.deleting,
    required this.canWrite,
    required this.error,
    required this.roleNameForId,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onCancelDelete,
    required this.onConfirmDelete,
    super.key,
  });

  final List<ServerSettingsListItemSeed> feeds;
  final String? deletingFeedId;
  final bool deleting;
  final bool canWrite;
  final String? error;
  final String Function(String roleId) roleNameForId;
  final VoidCallback onCreate;
  final ValueChanged<ServerSettingsListItemSeed> onEdit;
  final ValueChanged<ServerSettingsListItemSeed> onDelete;
  final VoidCallback? onCancelDelete;
  final ValueChanged<ServerSettingsListItemSeed> onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Announcement Feeds',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Feeds define announcement spaces and server-side role rules.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            FilledButton.icon(
              key: const ValueKey('server-feed-create-button'),
              onPressed: canWrite ? onCreate : null,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create Feed'),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            key: const ValueKey('server-feed-error'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF809A)),
          ),
        ],
        const SizedBox(height: 18),
        Expanded(
          child: SmoothSingleChildScrollView(
            primary: false,
            child: Column(
              children: [
                if (feeds.isEmpty)
                  _FeedsEmptyState(canCreate: canWrite, onCreate: onCreate)
                else
                  for (final feed in feeds)
                    _FeedCard(
                      feed: feed,
                      roleNameForId: roleNameForId,
                      deleting: deletingFeedId == _feedIdentity(feed),
                      busy: deleting,
                      onEdit: canWrite ? () => onEdit(feed) : null,
                      onDelete: canWrite ? () => onDelete(feed) : null,
                      onCancelDelete: onCancelDelete,
                      onConfirmDelete: canWrite
                          ? () => onConfirmDelete(feed)
                          : null,
                    ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.panel,
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        color: colors.accentStrong,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Feed role rules gate human publishing and visibility. Bot publishing is controlled by bot token scopes and allowed feed IDs.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedEditorRoute extends StatelessWidget {
  const _FeedEditorRoute({
    required this.nameController,
    required this.descriptionController,
    required this.roles,
    required this.publishRoleIds,
    required this.visibleRoleIds,
    required this.saving,
    required this.canSave,
    required this.editing,
    required this.error,
    required this.roleNameForId,
    required this.onAddPublishRole,
    required this.onRemovePublishRole,
    required this.onAddVisibleRole,
    required this.onRemoveVisibleRole,
    required this.onBack,
    required this.onSave,
    super.key,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final List<ServerSettingsListItemSeed> roles;
  final Set<String> publishRoleIds;
  final Set<String> visibleRoleIds;
  final bool saving;
  final bool canSave;
  final bool editing;
  final String? error;
  final String Function(String roleId) roleNameForId;
  final ValueChanged<String> onAddPublishRole;
  final ValueChanged<String> onRemovePublishRole;
  final ValueChanged<String> onAddVisibleRole;
  final ValueChanged<String> onRemoveVisibleRole;
  final VoidCallback? onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 58,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: TextButton.icon(
                  key: const ValueKey('server-feed-editor-back-button'),
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, size: 15),
                  label: const Text('Back'),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(96, 2, 96, 0),
                  child: ListenableBuilder(
                    listenable: nameController,
                    builder: (context, _) {
                      final title = _editorFeedTitle(
                        controller: nameController,
                        editing: editing,
                      );
                      return Text(
                        title,
                        key: const ValueKey('server-feed-editor-title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: VerdantFontWeights.black,
                          letterSpacing: -0.2,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            key: const ValueKey('server-feed-error'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF809A)),
          ),
        ],
        const SizedBox(height: 10),
        Expanded(
          child: SmoothSingleChildScrollView(
            primary: false,
            child: _FeedEditorCard(
              nameController: nameController,
              descriptionController: descriptionController,
              roles: roles,
              publishRoleIds: publishRoleIds,
              visibleRoleIds: visibleRoleIds,
              saving: saving,
              canSave: canSave,
              editing: editing,
              roleNameForId: roleNameForId,
              onAddPublishRole: onAddPublishRole,
              onRemovePublishRole: onRemovePublishRole,
              onAddVisibleRole: onAddVisibleRole,
              onRemoveVisibleRole: onRemoveVisibleRole,
              onBack: onBack,
              onSave: onSave,
            ),
          ),
        ),
      ],
    );
  }
}

String _editorFeedTitle({
  required TextEditingController controller,
  required bool editing,
}) {
  final value = controller.text.trim();
  if (value.isNotEmpty) {
    return value;
  }
  return editing ? 'Untitled Feed' : 'Create Feed';
}

class _FeedEditorCard extends StatelessWidget {
  const _FeedEditorCard({
    required this.nameController,
    required this.descriptionController,
    required this.roles,
    required this.publishRoleIds,
    required this.visibleRoleIds,
    required this.saving,
    required this.canSave,
    required this.editing,
    required this.roleNameForId,
    required this.onAddPublishRole,
    required this.onRemovePublishRole,
    required this.onAddVisibleRole,
    required this.onRemoveVisibleRole,
    required this.onBack,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final List<ServerSettingsListItemSeed> roles;
  final Set<String> publishRoleIds;
  final Set<String> visibleRoleIds;
  final bool saving;
  final bool canSave;
  final bool editing;
  final String Function(String roleId) roleNameForId;
  final ValueChanged<String> onAddPublishRole;
  final ValueChanged<String> onRemovePublishRole;
  final ValueChanged<String> onAddVisibleRole;
  final ValueChanged<String> onRemoveVisibleRole;
  final VoidCallback? onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.borderStrong),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FeedTextField(
            key: const ValueKey('server-feed-name-field'),
            controller: nameController,
            label: 'Name',
            hint: 'Patch Notes',
            maxLength: 100,
            enabled: !saving,
          ),
          const SizedBox(height: 12),
          _FeedTextField(
            key: const ValueKey('server-feed-description-field'),
            controller: descriptionController,
            label: 'Description',
            hint: 'Optional feed description',
            maxLength: 500,
            enabled: !saving,
          ),
          const SizedBox(height: 16),
          _RoleMenuSection(
            label: 'Publish Roles',
            description:
                'Select access roles allowed to publish. Empty means server managers only.',
            emptyLabel: 'Managers only',
            roles: roles,
            selectedIds: publishRoleIds,
            keyPrefix: 'server-feed-publish-role',
            enabled: !saving,
            roleNameForId: roleNameForId,
            onAdd: onAddPublishRole,
            onRemove: onRemovePublishRole,
          ),
          const SizedBox(height: 14),
          _RoleMenuSection(
            label: 'Visible Roles',
            description:
                'Select access roles allowed to see this feed. Empty means everyone can see it.',
            emptyLabel: 'Everyone',
            roles: roles,
            selectedIds: visibleRoleIds,
            keyPrefix: 'server-feed-visible-role',
            enabled: !saving,
            roleNameForId: roleNameForId,
            onAdd: onAddVisibleRole,
            onRemove: onRemoveVisibleRole,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              TextButton(
                key: const ValueKey('server-feed-cancel-button'),
                onPressed: onBack,
                child: const Text('Cancel'),
              ),
              const Spacer(),
              FilledButton.icon(
                key: const ValueKey('server-feed-save-button'),
                onPressed: canSave && !saving ? onSave : null,
                icon: saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 16),
                label: Text(editing ? 'Save Changes' : 'Create Feed'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedTextField extends StatelessWidget {
  const _FeedTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.enabled,
    this.maxLength,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.textMuted,
            fontWeight: VerdantFontWeights.black,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLength: maxLength,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            filled: true,
            fillColor: colors.panel,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.accentStrong),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleMenuSection extends StatelessWidget {
  const _RoleMenuSection({
    required this.label,
    required this.description,
    required this.emptyLabel,
    required this.roles,
    required this.selectedIds,
    required this.keyPrefix,
    required this.enabled,
    required this.roleNameForId,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final String description;
  final String emptyLabel;
  final List<ServerSettingsListItemSeed> roles;
  final Set<String> selectedIds;
  final String keyPrefix;
  final bool enabled;
  final String Function(String roleId) roleNameForId;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final availableRoles = [
      for (final role in roles)
        if (role.id != null &&
            !selectedIds.any((selected) => _sameRoleId(selected, role.id!)))
          role,
    ];
    final selectedRoleIds = selectedIds.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.textMuted,
            fontWeight: VerdantFontWeights.black,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (selectedRoleIds.isEmpty)
              _SelectedRolePill(
                label: emptyLabel,
                muted: true,
                accent: colors.textMuted,
              )
            else
              for (final roleId in selectedRoleIds)
                _SelectedRolePill(
                  key: ValueKey('$keyPrefix-selected-$roleId'),
                  label: roleNameForId(roleId),
                  accent: _roleAccent(roles, roleId) ?? colors.accent,
                  onRemove: enabled ? () => onRemove(roleId) : null,
                ),
            _RoleAddMenu(
              roles: availableRoles,
              keyPrefix: keyPrefix,
              enabled: enabled && availableRoles.isNotEmpty,
              onAdd: onAdd,
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleAddMenu extends StatefulWidget {
  const _RoleAddMenu({
    required this.roles,
    required this.keyPrefix,
    required this.enabled,
    required this.onAdd,
  });

  final List<ServerSettingsListItemSeed> roles;
  final String keyPrefix;
  final bool enabled;
  final ValueChanged<String> onAdd;

  @override
  State<_RoleAddMenu> createState() => _RoleAddMenuState();
}

class _RoleAddMenuState extends State<_RoleAddMenu>
    with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  late final AnimationController _menuController;
  late final Animation<double> _menuCurve;
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 105),
    );
    _menuCurve = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(covariant _RoleAddMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _entry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _removeMenu(immediate: true);
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _entry?.markNeedsBuild();
        }
      });
    }
  }

  @override
  void dispose() {
    _removeMenu(immediate: true);
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final enabled = widget.enabled;
    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          key: ValueKey('${widget.keyPrefix}-menu'),
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? _toggleMenu : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: colors.panel,
                border: Border.all(
                  color: _entry != null
                      ? colors.accent
                      : enabled
                      ? colors.accentStrong
                      : colors.border,
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: colors.accentStrong.withValues(alpha: 0.14),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: colors.accentStrong, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    enabled ? 'Add Role' : 'No Roles',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: enabled ? colors.accentStrong : colors.textMuted,
                      fontWeight: VerdantFontWeights.black,
                    ),
                  ),
                  if (enabled) ...[
                    const SizedBox(width: 5),
                    AnimatedRotation(
                      turns: _entry == null ? 0 : 0.5,
                      duration: const Duration(milliseconds: 130),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: colors.textMuted,
                        size: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleMenu() {
    if (_entry == null) {
      _showMenu();
    } else {
      _hideMenu();
    }
  }

  void _showMenu() {
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_entry!);
    _menuController.forward(from: 0);
    setState(() {});
  }

  Future<void> _hideMenu() async {
    await _removeMenu();
  }

  Future<void> _removeMenu({bool immediate = false}) async {
    final entry = _entry;
    if (entry == null) {
      return;
    }
    if (!immediate) {
      await _menuController.reverse();
    }
    entry.remove();
    if (identical(entry, _entry)) {
      _entry = null;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildOverlay(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hideMenu,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 7),
          child: FadeTransition(
            opacity: _menuCurve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.04),
                end: Offset.zero,
              ).animate(_menuCurve),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(_menuCurve),
                alignment: Alignment.topLeft,
                child: Material(
                  key: ValueKey('${widget.keyPrefix}-popover'),
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 192,
                      maxWidth: 250,
                      maxHeight: 276,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.panelRaised,
                        border: Border.all(color: colors.borderStrong),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.34),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: SmoothSingleChildScrollView(
                          primary: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final role in widget.roles)
                                  _RoleMenuOption(
                                    key: ValueKey(
                                      '${widget.keyPrefix}-option-${role.id!}',
                                    ),
                                    role: role,
                                    textStyle: textTheme.labelMedium,
                                    onTap: () {
                                      widget.onAdd(role.id!);
                                      _hideMenu();
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleMenuOption extends StatelessWidget {
  const _RoleMenuOption({
    required this.role,
    required this.textStyle,
    required this.onTap,
    super.key,
  });

  final ServerSettingsListItemSeed role;
  final TextStyle? textStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: colors.panelHover.withValues(alpha: 0.78),
        splashColor: colors.accent.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: role.accent ?? colors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  role.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle?.copyWith(
                    color: colors.text,
                    fontWeight: VerdantFontWeights.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedRolePill extends StatelessWidget {
  const _SelectedRolePill({
    required this.label,
    required this.accent,
    this.muted = false,
    this.onRemove,
    super.key,
  });

  final String label;
  final Color accent;
  final bool muted;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 10,
        right: onRemove == null ? 10 : 4,
        top: 6,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: muted ? colors.panel : colors.accent.withValues(alpha: 0.13),
        border: Border.all(color: muted ? colors.border : accent),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: muted ? colors.textMuted : colors.text,
              fontWeight: VerdantFontWeights.bold,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 3),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(Icons.close, color: colors.textMuted, size: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.feed,
    required this.roleNameForId,
    required this.deleting,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onCancelDelete,
    required this.onConfirmDelete,
  });

  final ServerSettingsListItemSeed feed;
  final String Function(String roleId) roleNameForId;
  final bool deleting;
  final bool busy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCancelDelete;
  final VoidCallback? onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final feedId = _feedIdentity(feed);
    final description = _descriptionText(feed);
    return Container(
      key: ValueKey('server-feed-row-$feedId'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.panel,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(9),
            ),
            child: feed.feedIcon == null || feed.feedIcon!.isEmpty
                ? Icon(
                    Icons.campaign_outlined,
                    color: colors.accentStrong,
                    size: 20,
                  )
                : Text(
                    feed.feedIcon!,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.accentStrong,
                      fontWeight: VerdantFontWeights.black,
                    ),
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feed.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.text,
                    fontWeight: VerdantFontWeights.black,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _RuleBadge(
                      label:
                          'Publish: ${_roleSummary(feed.publishRoleIds, roleNameForId, emptyLabel: 'Managers only')}',
                    ),
                    _RuleBadge(
                      label:
                          'Visible: ${_roleSummary(feed.visibleRoleIds, roleNameForId, emptyLabel: 'Everyone')}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (deleting)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete?',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFFF809A),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  key: ValueKey('server-feed-delete-confirm-$feedId'),
                  onPressed: busy ? null : onConfirmDelete,
                  child: const Text('Yes'),
                ),
                TextButton(
                  key: ValueKey('server-feed-delete-cancel-$feedId'),
                  onPressed: busy ? null : onCancelDelete,
                  child: const Text('No'),
                ),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: ValueKey('server-feed-edit-$feedId'),
                  tooltip: 'Edit feed',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                IconButton(
                  key: ValueKey('server-feed-delete-$feedId'),
                  tooltip: 'Delete feed',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RuleBadge extends StatelessWidget {
  const _RuleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.textMuted,
          fontWeight: VerdantFontWeights.bold,
        ),
      ),
    );
  }
}

class _FeedsEmptyState extends StatelessWidget {
  const _FeedsEmptyState({required this.canCreate, required this.onCreate});

  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign_outlined, color: colors.accentStrong, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No announcement feeds yet. Create one to get started.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: canCreate ? onCreate : null,
            child: const Text('Create Feed'),
          ),
        ],
      ),
    );
  }
}

bool _isEveryoneRole(ServerSettingsListItemSeed role) {
  return role.title == '@everyone' || role.position == 0;
}

String _feedIdentity(ServerSettingsListItemSeed feed) {
  return feed.id ?? feed.title;
}

String _descriptionText(ServerSettingsListItemSeed feed) {
  return feed.subtitle == 'No description' ? '' : feed.subtitle;
}

String _roleSummary(
  List<String> roleIds,
  String Function(String roleId) roleNameForId, {
  required String emptyLabel,
}) {
  if (roleIds.isEmpty) {
    return emptyLabel;
  }
  return roleIds.map(roleNameForId).join(', ');
}

Color? _roleAccent(List<ServerSettingsListItemSeed> roles, String roleId) {
  for (final role in roles) {
    final id = role.id;
    if (id != null && _sameRoleId(id, roleId)) {
      return role.accent;
    }
  }
  return null;
}

bool _sameRoleId(String left, String right) {
  return left == right || _localId(left) == _localId(right);
}

String _localId(String value) {
  final slash = value.indexOf('/');
  return slash < 0 ? value : value.substring(slash + 1);
}

String _feedErrorMessage(Object error) {
  if (error is ServerSettingsException) {
    return error.message;
  }
  return 'Feed changes could not be saved.';
}
