import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../theme/verdant_button.dart';
import '../../../theme/verdant_theme.dart';
import '../shared/custom_expressive_asset.dart';
import 'server_media_image.dart';
import 'server_media_url_policy.dart';
import 'server_settings_models.dart';
import 'server_settings_service.dart';

const _customExpressionKind = CustomExpressiveAssetKind.emoji;

final _customExpressionImageTypeGroup = XTypeGroup(
  label: 'Custom ${_customExpressionKind.label} images',
  extensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp'],
  mimeTypes: const ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
);

typedef ServerEmojiUploadPicker =
    Future<ServerEmojiUploadSelection?> Function();

final class ServerEmojiUploadSelection {
  const ServerEmojiUploadSelection({
    required this.upload,
    required this.previewBytes,
    required this.sizeBytes,
  });

  final ServerSettingsUpload upload;
  final Uint8List previewBytes;
  final int sizeBytes;

  String get fileName => upload.fileName;
  bool get isAnimated => isAnimatedCustomExpressionImageUrl(fileName);
}

class ServerSettingsEmojiTab extends StatefulWidget {
  const ServerSettingsEmojiTab({
    required this.serverId,
    required this.emojis,
    required this.canManageServer,
    this.mediaPolicy = const ServerMediaPolicy(
      allowedOrigins: {},
      allowLocalHttp: false,
    ),
    this.emojiRepository,
    this.emojiUploadPicker,
    this.onEmojisChanged,
    super.key,
  });

  final String serverId;
  final List<ServerSettingsListItemSeed> emojis;
  final bool canManageServer;
  final ServerMediaPolicy mediaPolicy;
  final ServerSettingsEmojiRepository? emojiRepository;
  final ServerEmojiUploadPicker? emojiUploadPicker;
  final ValueChanged<List<ServerSettingsListItemSeed>>? onEmojisChanged;

  @override
  State<ServerSettingsEmojiTab> createState() => _ServerSettingsEmojiTabState();
}

class _ServerSettingsEmojiTabState extends State<ServerSettingsEmojiTab> {
  late List<ServerSettingsListItemSeed> _emojis = [...widget.emojis];
  late final TextEditingController _nameController = TextEditingController();
  late final TextEditingController _uploadNameController =
      TextEditingController();
  String? _editingEmojiId;
  ServerEmojiUploadSelection? _selectedUpload;
  String? _error;
  bool _saving = false;
  bool _uploading = false;

  bool get _canManage =>
      widget.canManageServer && widget.emojiRepository != null;

  bool get _canUpload =>
      _canManage &&
      !_uploading &&
      validateCustomExpressionName(
            kind: _customExpressionKind,
            value: _uploadNameController.text,
          ) ==
          null &&
      _selectedUpload != null;

  @override
  void didUpdateWidget(covariant ServerSettingsEmojiTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emojis != widget.emojis) {
      _emojis = [...widget.emojis];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _uploadNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Emoji', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 5),
          Text(
            'Upload, rename, or remove custom emoji for this server.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          if (_canManage) ...[
            _buildUploadPanel(context),
            const SizedBox(height: 18),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              key: const ValueKey('server-emoji-error'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF809A)),
            ),
            const SizedBox(height: 12),
          ],
          if (_emojis.isEmpty)
            const _EmptyPanel(
              label: 'This server does not have custom emoji yet.',
            )
          else
            for (final emoji in _emojis)
              _EmojiRow(
                key: ValueKey('server-emoji-row-${emoji.id ?? emoji.title}'),
                emoji: emoji,
                mediaPolicy: widget.mediaPolicy,
                editing: emoji.id != null && _editingEmojiId == emoji.id,
                canManage: _canManage,
                nameController: _nameController,
                saving: _saving,
                onEdit: emoji.id == null ? null : () => _startEditing(emoji),
                onSave: emoji.id == null ? null : () => _saveEmoji(emoji),
                onCancel: _cancelEditing,
                onDelete: emoji.id == null ? null : () => _confirmDelete(emoji),
              ),
        ],
      ),
    );
  }

  void _startEditing(ServerSettingsListItemSeed emoji) {
    final emojiId = emoji.id;
    if (emojiId == null) {
      return;
    }
    setState(() {
      _editingEmojiId = emojiId;
      _nameController.text = _emojiName(emoji.title);
      _error = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingEmojiId = null;
      _nameController.clear();
      _error = null;
    });
  }

  Widget _buildUploadPanel(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final upload = _selectedUpload;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Custom Emoji',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('server-emoji-upload-name-field'),
            controller: _uploadNameController,
            maxLength: 32,
            enabled: !_uploading,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'emoji_name',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EmojiUploadPreview(selection: upload),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      key: const ValueKey('server-emoji-upload-file-label'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.background,
                        border: Border.all(color: colors.border),
                        borderRadius: VerdantRadii.sharp,
                      ),
                      child: Text(
                        upload?.fileName ?? 'No file selected',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colors.text),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _UploadInfoChip(
                          icon: Icons.image_outlined,
                          label: 'PNG, JPG, GIF, WebP',
                        ),
                        _UploadInfoChip(
                          icon: Icons.sd_storage_outlined,
                          label:
                              '${customExpressionMaxBytes(_customExpressionKind) ~/ 1024} KB max',
                        ),
                        if (upload != null)
                          _UploadInfoChip(
                            icon: upload.isAnimated
                                ? Icons.motion_photos_on_outlined
                                : Icons.image_not_supported_outlined,
                            label: upload.isAnimated ? 'Animated' : 'Static',
                            accent: upload.isAnimated,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 148,
                child: VerdantButton(
                  key: const ValueKey('server-emoji-select-file-button'),
                  label: 'Choose File',
                  icon: Icons.upload_file_outlined,
                  onPressed: _uploading ? null : _selectEmojiFile,
                  variant: VerdantButtonVariant.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 184,
            child: VerdantButton(
              key: const ValueKey('server-emoji-upload-button'),
              label: _uploading ? 'Uploading...' : 'Upload Emoji',
              icon: Icons.add_reaction_outlined,
              onPressed: _canUpload ? _uploadEmoji : null,
              isBusy: _uploading,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectEmojiFile() async {
    try {
      final picker = widget.emojiUploadPicker ?? _pickEmojiUploadFromDisk;
      final selection = await picker();
      if (selection == null || !mounted) {
        return;
      }
      if (!isCustomExpressionImageFileName(selection.fileName)) {
        setState(() => _error = 'Choose a PNG, JPG, GIF, or WebP image.');
        return;
      }
      final maxBytes = customExpressionMaxBytes(_customExpressionKind);
      if (selection.sizeBytes > maxBytes) {
        setState(
          () => _error =
              '${_customExpressionKind.titleLabel} image must be ${maxBytes ~/ 1024} KB or smaller.',
        );
        return;
      }
      setState(() {
        _selectedUpload = selection;
        _error = null;
      });
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    }
  }

  Future<ServerEmojiUploadSelection?> _pickEmojiUploadFromDisk() async {
    final repository = widget.emojiRepository;
    if (repository == null) {
      return null;
    }
    final file = await openFile(
      acceptedTypeGroups: [_customExpressionImageTypeGroup],
    );
    if (file == null) {
      return null;
    }
    final fileName = file.name.isEmpty
        ? _fileNameFromPath(file.path)
        : file.name;
    final upload = ServerSettingsUpload(path: file.path, fileName: fileName);
    final preview = await repository.loadEmojiUploadPreview(upload: upload);
    return ServerEmojiUploadSelection(
      upload: upload,
      previewBytes: preview.previewBytes,
      sizeBytes: preview.sizeBytes,
    );
  }

  Future<void> _uploadEmoji() async {
    final repository = widget.emojiRepository;
    final selection = _selectedUpload;
    if (repository == null || selection == null) {
      return;
    }
    final upload = selection.upload;
    final nameError = validateCustomExpressionName(
      kind: _customExpressionKind,
      value: _uploadNameController.text,
    );
    if (nameError != null) {
      setState(() => _error = nameError);
      return;
    }
    final name = normalizeCustomExpressionName(_uploadNameController.text);
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final uploaded = await repository.uploadEmoji(
        serverId: widget.serverId,
        name: name,
        upload: upload,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _emojis = [
          for (final item in _emojis)
            if (item.id != uploaded.id) item,
          uploaded,
        ];
        _selectedUpload = null;
        _uploadNameController.clear();
        _uploading = false;
      });
      widget.onEmojisChanged?.call(_emojis);
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _uploading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _saveEmoji(ServerSettingsListItemSeed emoji) async {
    final emojiId = emoji.id;
    final repository = widget.emojiRepository;
    if (emojiId == null || repository == null) {
      return;
    }
    final nameError = validateCustomExpressionName(
      kind: _customExpressionKind,
      value: _nameController.text,
    );
    if (nameError != null) {
      setState(() => _error = nameError);
      return;
    }
    final name = normalizeCustomExpressionName(_nameController.text);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await repository.renameEmoji(
        serverId: widget.serverId,
        emojiId: emojiId,
        name: name,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _emojis = [
          for (final item in _emojis) item.id == emojiId ? updated : item,
        ];
        _editingEmojiId = null;
        _nameController.clear();
        _saving = false;
      });
      widget.onEmojisChanged?.call(_emojis);
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

  Future<void> _confirmDelete(ServerSettingsListItemSeed emoji) async {
    final emojiId = emoji.id;
    if (emojiId == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${emoji.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: ValueKey('server-emoji-delete-confirm-$emojiId'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await widget.emojiRepository?.deleteEmoji(
      serverId: widget.serverId,
      emojiId: emojiId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _emojis = [
        for (final item in _emojis)
          if (item.id != emojiId) item,
      ];
      if (_editingEmojiId == emojiId) {
        _editingEmojiId = null;
        _nameController.clear();
      }
    });
    widget.onEmojisChanged?.call(_emojis);
  }
}

class _EmojiUploadPreview extends StatelessWidget {
  const _EmojiUploadPreview({required this.selection});

  final ServerEmojiUploadSelection? selection;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final selected = selection;
    return Container(
      key: const ValueKey('server-emoji-upload-preview'),
      width: 82,
      height: 82,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(
          color: selected == null ? colors.border : colors.accent,
        ),
        borderRadius: VerdantRadii.sharp,
      ),
      child: selected == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_reaction_outlined,
                  color: colors.textMuted,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  'Preview',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
                ),
              ],
            )
          : Image.memory(
              selected.previewBytes,
              key: const ValueKey('server-emoji-upload-preview-image'),
              width: 66,
              height: 66,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.broken_image_outlined,
                  color: colors.textMuted,
                  size: 24,
                );
              },
            ),
    );
  }
}

class _UploadInfoChip extends StatelessWidget {
  const _UploadInfoChip({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final foreground = accent ? colors.accentStrong : colors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: accent
            ? colors.actionMuted
            : colors.background.withValues(alpha: 0.7),
        border: Border.all(color: accent ? colors.accent : colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _EmojiRow extends StatelessWidget {
  const _EmojiRow({
    required this.emoji,
    required this.mediaPolicy,
    required this.editing,
    required this.canManage,
    required this.nameController,
    required this.saving,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.onDelete,
    super.key,
  });

  final ServerSettingsListItemSeed emoji;
  final ServerMediaPolicy mediaPolicy;
  final bool editing;
  final bool canManage;
  final TextEditingController nameController;
  final bool saving;
  final VoidCallback? onEdit;
  final VoidCallback? onSave;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final emojiId = emoji.id ?? 'unknown';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: editing ? colors.action : colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: editing
          ? _buildEditor(context, emojiId)
          : _buildReadRow(context, emojiId),
    );
  }

  Widget _buildReadRow(BuildContext context, String emojiId) {
    final colors = VerdantThemeColors.of(context);
    return Row(
      children: [
        _EmojiGlyph(
          label: emoji.title,
          imageUrl: emoji.avatarUrl,
          mediaPolicy: mediaPolicy,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji.title, style: Theme.of(context).textTheme.labelLarge),
              Text(
                emoji.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (emoji.trailing != null) ...[
          const SizedBox(width: 12),
          Text(
            emoji.trailing!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ],
        if (canManage) ...[
          const SizedBox(width: 8),
          IconButton(
            key: ValueKey('server-emoji-edit-$emojiId'),
            tooltip: 'Rename emoji',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            key: ValueKey('server-emoji-delete-$emojiId'),
            tooltip: 'Delete emoji',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ],
    );
  }

  Widget _buildEditor(BuildContext context, String emojiId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: ValueKey('server-emoji-name-field-$emojiId'),
          controller: nameController,
          autofocus: true,
          maxLength: 48,
          decoration: const InputDecoration(hintText: 'Emoji name'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: VerdantButton(
                key: ValueKey('server-emoji-save-$emojiId'),
                label: saving ? 'Saving...' : 'Save',
                icon: Icons.save_outlined,
                onPressed: saving ? null : onSave,
                isBusy: saving,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: VerdantButton(
                label: 'Cancel',
                icon: Icons.close,
                onPressed: saving ? null : onCancel,
                variant: VerdantButtonVariant.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmojiGlyph extends StatelessWidget {
  const _EmojiGlyph({
    required this.label,
    required this.imageUrl,
    required this.mediaPolicy,
  });

  final String label;
  final String? imageUrl;
  final ServerMediaPolicy mediaPolicy;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final rawUrl = imageUrl;
    final uri = rawUrl == null
        ? null
        : safeServerMediaUri(rawUrl, policy: mediaPolicy);
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: uri == null
          ? Icon(
              Icons.emoji_emotions_outlined,
              size: 18,
              color: colors.accentStrong,
            )
          : SafeServerMediaImage(
              uri: uri,
              policy: mediaPolicy,
              surface: ServerMediaSurface.image,
              fallback: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              builder: (context, imageProvider) => Image(
                image: imageProvider,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                semanticLabel: label,
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

String _emojiName(String value) {
  return value.trim().replaceAll(RegExp(r'^:+|:+$'), '');
}

String _fileNameFromPath(String path) {
  final parts = path.split(RegExp(r'[/\\]'));
  return parts.isEmpty ? 'emoji.png' : parts.last;
}
