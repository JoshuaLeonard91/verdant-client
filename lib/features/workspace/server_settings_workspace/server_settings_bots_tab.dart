import 'package:flutter/material.dart';

import '../../../theme/verdant_button.dart';
import '../../../theme/verdant_theme.dart';
import 'server_settings_models.dart';
import 'server_settings_service.dart';

class ServerSettingsBotsTab extends StatefulWidget {
  const ServerSettingsBotsTab({
    required this.serverId,
    required this.bots,
    required this.canManageServer,
    this.botRepository,
    this.onBotsChanged,
    super.key,
  });

  final String serverId;
  final List<ServerSettingsListItemSeed> bots;
  final bool canManageServer;
  final ServerSettingsBotRepository? botRepository;
  final ValueChanged<List<ServerSettingsListItemSeed>>? onBotsChanged;

  @override
  State<ServerSettingsBotsTab> createState() => _ServerSettingsBotsTabState();
}

class _ServerSettingsBotsTabState extends State<ServerSettingsBotsTab> {
  late List<ServerSettingsListItemSeed> _bots = [...widget.bots];
  late final TextEditingController _nameController = TextEditingController();
  late final TextEditingController _descriptionController =
      TextEditingController();
  final Map<String, String> _oneTimeTokens = {};
  bool _creating = false;
  bool _saving = false;
  String? _error;

  bool get _canManage => widget.canManageServer && widget.botRepository != null;

  @override
  void didUpdateWidget(covariant ServerSettingsBotsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bots != widget.bots) {
      _bots = [...widget.bots];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bots', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 5),
                    Text(
                      'Create scoped bot identities and one-time bot tokens.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_canManage) ...[
                const SizedBox(width: 14),
                SizedBox(
                  width: 156,
                  child: VerdantButton(
                    key: const ValueKey('server-bot-create-button'),
                    label: _creating ? 'Cancel' : 'Create Bot',
                    icon: _creating ? Icons.close : Icons.add,
                    onPressed: _saving ? null : _toggleCreate,
                    variant: VerdantButtonVariant.secondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          if (_creating) ...[
            _BotCreatePanel(
              nameController: _nameController,
              descriptionController: _descriptionController,
              saving: _saving,
              onSave: _createBot,
            ),
            const SizedBox(height: 14),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              key: const ValueKey('server-bot-error'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF809A)),
            ),
            const SizedBox(height: 12),
          ],
          if (_bots.isEmpty)
            const _EmptyPanel(label: 'No bots installed.')
          else
            for (final bot in _bots)
              _BotRow(
                key: ValueKey('server-bot-row-${bot.id ?? bot.title}'),
                bot: bot,
                token: bot.id == null ? null : _oneTimeTokens[bot.id],
                canManage: _canManage,
                onGenerateToken: bot.id == null
                    ? null
                    : () => _generateToken(bot.id!),
                onDelete: bot.id == null ? null : () => _confirmDelete(bot),
              ),
        ],
      ),
    );
  }

  void _toggleCreate() {
    setState(() {
      _creating = !_creating;
      _error = null;
    });
  }

  Future<void> _createBot() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Bot name is required.');
      return;
    }
    final repository = widget.botRepository;
    if (repository == null) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final bot = await repository.createBot(
        serverId: widget.serverId,
        patch: ServerBotPatch(
          name: name,
          description: _descriptionController.text,
          avatarPreset: 'verdant',
          bannerPreset: 'aurora',
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _bots = [..._bots, bot];
        _creating = false;
        _saving = false;
        _nameController.clear();
        _descriptionController.clear();
      });
      widget.onBotsChanged?.call(_bots);
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = error.message;
      });
    }
  }

  Future<void> _generateToken(String botId) async {
    final repository = widget.botRepository;
    if (repository == null) {
      return;
    }
    setState(() => _error = null);
    try {
      final token = await repository.generateBotToken(
        serverId: widget.serverId,
        botId: botId,
        patch: const BotTokenPatch(name: 'default'),
      );
      if (!mounted) {
        return;
      }
      setState(() => _oneTimeTokens[botId] = token.token);
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    }
  }

  Future<void> _confirmDelete(ServerSettingsListItemSeed bot) async {
    final botId = bot.id;
    if (botId == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${bot.title}?'),
        content: const Text('Existing bot tokens will stop working.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: ValueKey('server-bot-delete-confirm-$botId'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await widget.botRepository?.deleteBot(
      serverId: widget.serverId,
      botId: botId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _bots = [
        for (final item in _bots)
          if (item.id != botId) item,
      ];
      _oneTimeTokens.remove(botId);
    });
    widget.onBotsChanged?.call(_bots);
  }
}

class _BotCreatePanel extends StatelessWidget {
  const _BotCreatePanel({
    required this.nameController,
    required this.descriptionController,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Bot', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('server-bot-name-field'),
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Bot name'),
            maxLength: 80,
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('server-bot-description-field'),
            controller: descriptionController,
            decoration: const InputDecoration(hintText: 'Description'),
            maxLength: 160,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 156,
              child: VerdantButton(
                key: const ValueKey('server-bot-save-button'),
                label: saving ? 'Saving...' : 'Save Bot',
                icon: Icons.save_outlined,
                onPressed: saving ? null : onSave,
                isBusy: saving,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotRow extends StatelessWidget {
  const _BotRow({
    required this.bot,
    required this.token,
    required this.canManage,
    required this.onGenerateToken,
    required this.onDelete,
    super.key,
  });

  final ServerSettingsListItemSeed bot;
  final String? token;
  final bool canManage;
  final VoidCallback? onGenerateToken;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final botId = bot.id ?? 'unknown';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BotAvatar(label: bot.title),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bot.title,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      bot.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (bot.trailing != null) _StatusChip(label: bot.trailing!),
              if (canManage) ...[
                const SizedBox(width: 8),
                IconButton(
                  key: ValueKey('server-bot-token-$botId'),
                  tooltip: 'Generate bot token',
                  onPressed: onGenerateToken,
                  icon: const Icon(Icons.key, size: 18),
                ),
                IconButton(
                  key: ValueKey('server-bot-delete-$botId'),
                  tooltip: 'Delete bot',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                ),
              ],
            ],
          ),
          if (token != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.panel,
                border: Border.all(color: colors.action),
                borderRadius: VerdantRadii.sharp,
              ),
              child: Text(
                token!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.actionStrong,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final typography = VerdantThemeTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Text(
        label,
        style: typography.badgeLabel.copyWith(color: colors.textMuted),
      ),
    );
  }
}

class _BotAvatar extends StatelessWidget {
  const _BotAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final compact = label.replaceAll(RegExp(r'\s+'), '');
    final initials = compact.length >= 2
        ? compact.substring(0, 2).toUpperCase()
        : compact.toUpperCase();
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.actionSurface,
        borderRadius: VerdantRadii.sharp,
      ),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.text,
          fontWeight: VerdantFontWeights.black,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
