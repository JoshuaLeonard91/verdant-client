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

const _customExpressionKind = CustomExpressiveAssetKind.sticker;

final _customExpressionImageTypeGroup = XTypeGroup(
  label: 'Custom ${_customExpressionKind.label} images',
  extensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp'],
  mimeTypes: const ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
);

typedef ServerStickerUploadPicker =
    Future<ServerStickerUploadSelection?> Function();

final class ServerStickerUploadSelection {
  const ServerStickerUploadSelection({
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

class ServerSettingsStickersTab extends StatefulWidget {
  const ServerSettingsStickersTab({
    required this.serverId,
    required this.stickers,
    required this.canManageServer,
    this.mediaPolicy = const ServerMediaPolicy(
      allowedOrigins: {},
      allowLocalHttp: false,
    ),
    this.stickerRepository,
    this.stickerUploadPicker,
    this.onStickersChanged,
    super.key,
  });

  final String serverId;
  final List<ServerSettingsListItemSeed> stickers;
  final bool canManageServer;
  final ServerMediaPolicy mediaPolicy;
  final ServerSettingsEmojiRepository? stickerRepository;
  final ServerStickerUploadPicker? stickerUploadPicker;
  final ValueChanged<List<ServerSettingsListItemSeed>>? onStickersChanged;

  @override
  State<ServerSettingsStickersTab> createState() =>
      _ServerSettingsStickersTabState();
}

class _ServerSettingsStickersTabState extends State<ServerSettingsStickersTab> {
  late List<ServerSettingsListItemSeed> _stickers = [...widget.stickers];
  late final TextEditingController _nameController = TextEditingController();
  late final TextEditingController _uploadNameController =
      TextEditingController();
  String? _editingStickerId;
  ServerStickerUploadSelection? _selectedUpload;
  String? _error;
  bool _saving = false;
  bool _uploading = false;

  bool get _canManage =>
      widget.canManageServer && widget.stickerRepository != null;

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
  void didUpdateWidget(covariant ServerSettingsStickersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stickers != widget.stickers) {
      _stickers = [...widget.stickers];
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
          Text('Stickers', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 5),
          Text(
            'Upload, rename, or remove custom stickers for this server.',
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
              key: const ValueKey('server-sticker-error'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF809A)),
            ),
            const SizedBox(height: 12),
          ],
          if (_stickers.isEmpty)
            const _EmptyPanel(
              label: 'This server does not have custom stickers yet.',
            )
          else
            for (final sticker in _stickers)
              _StickerRow(
                key: ValueKey(
                  'server-sticker-row-${sticker.id ?? sticker.title}',
                ),
                sticker: sticker,
                mediaPolicy: widget.mediaPolicy,
                editing: sticker.id != null && _editingStickerId == sticker.id,
                canManage: _canManage,
                nameController: _nameController,
                saving: _saving,
                onEdit: sticker.id == null
                    ? null
                    : () => _startEditing(sticker),
                onSave: sticker.id == null ? null : () => _saveSticker(sticker),
                onCancel: _cancelEditing,
                onDelete: sticker.id == null
                    ? null
                    : () => _confirmDelete(sticker),
              ),
        ],
      ),
    );
  }

  void _startEditing(ServerSettingsListItemSeed sticker) {
    final stickerId = sticker.id;
    if (stickerId == null) {
      return;
    }
    setState(() {
      _editingStickerId = stickerId;
      _nameController.text = _stickerName(sticker.title);
      _error = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingStickerId = null;
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
            'Upload Custom Sticker',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('server-sticker-upload-name-field'),
            controller: _uploadNameController,
            maxLength: 32,
            enabled: !_uploading,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'sticker_name',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StickerUploadPreview(selection: upload),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      key: const ValueKey('server-sticker-upload-file-label'),
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
                  key: const ValueKey('server-sticker-select-file-button'),
                  label: 'Choose File',
                  icon: Icons.upload_file_outlined,
                  onPressed: _uploading ? null : _selectStickerFile,
                  variant: VerdantButtonVariant.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 184,
            child: VerdantButton(
              key: const ValueKey('server-sticker-upload-button'),
              label: _uploading ? 'Uploading...' : 'Upload Sticker',
              icon: Icons.add_reaction_outlined,
              onPressed: _canUpload ? _uploadSticker : null,
              isBusy: _uploading,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStickerFile() async {
    try {
      final picker = widget.stickerUploadPicker ?? _pickStickerUploadFromDisk;
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

  Future<ServerStickerUploadSelection?> _pickStickerUploadFromDisk() async {
    final repository = widget.stickerRepository;
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
    final preview = await repository.loadStickerUploadPreview(upload: upload);
    return ServerStickerUploadSelection(
      upload: upload,
      previewBytes: preview.previewBytes,
      sizeBytes: preview.sizeBytes,
    );
  }

  Future<void> _uploadSticker() async {
    final repository = widget.stickerRepository;
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
      final uploaded = await repository.uploadSticker(
        serverId: widget.serverId,
        name: name,
        upload: upload,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _stickers = [
          for (final item in _stickers)
            if (item.id != uploaded.id) item,
          uploaded,
        ];
        _selectedUpload = null;
        _uploadNameController.clear();
        _uploading = false;
      });
      widget.onStickersChanged?.call(_stickers);
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

  Future<void> _saveSticker(ServerSettingsListItemSeed sticker) async {
    final stickerId = sticker.id;
    final repository = widget.stickerRepository;
    if (stickerId == null || repository == null) {
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
      final updated = await repository.renameSticker(
        serverId: widget.serverId,
        stickerId: stickerId,
        name: name,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _stickers = [
          for (final item in _stickers) item.id == stickerId ? updated : item,
        ];
        _editingStickerId = null;
        _nameController.clear();
        _saving = false;
      });
      widget.onStickersChanged?.call(_stickers);
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

  Future<void> _confirmDelete(ServerSettingsListItemSeed sticker) async {
    final stickerId = sticker.id;
    if (stickerId == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${sticker.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: ValueKey('server-sticker-delete-confirm-$stickerId'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await widget.stickerRepository?.deleteSticker(
      serverId: widget.serverId,
      stickerId: stickerId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _stickers = [
        for (final item in _stickers)
          if (item.id != stickerId) item,
      ];
      if (_editingStickerId == stickerId) {
        _editingStickerId = null;
        _nameController.clear();
      }
    });
    widget.onStickersChanged?.call(_stickers);
  }
}

class _StickerUploadPreview extends StatelessWidget {
  const _StickerUploadPreview({required this.selection});

  final ServerStickerUploadSelection? selection;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final selected = selection;
    return Container(
      key: const ValueKey('server-sticker-upload-preview'),
      width: 110,
      height: 110,
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
              key: const ValueKey('server-sticker-upload-preview-image'),
              width: 92,
              height: 92,
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

class _StickerRow extends StatelessWidget {
  const _StickerRow({
    required this.sticker,
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

  final ServerSettingsListItemSeed sticker;
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
    final stickerId = sticker.id ?? 'unknown';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: editing ? colors.action : colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: editing
          ? _buildEditor(context, stickerId)
          : _buildReadRow(context, stickerId),
    );
  }

  Widget _buildReadRow(BuildContext context, String stickerId) {
    final colors = VerdantThemeColors.of(context);
    return Row(
      children: [
        _StickerGlyph(
          label: sticker.title,
          imageUrl: sticker.avatarUrl,
          mediaPolicy: mediaPolicy,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sticker.title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                sticker.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (sticker.trailing != null) ...[
          const SizedBox(width: 12),
          Text(
            sticker.trailing!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ],
        if (canManage) ...[
          const SizedBox(width: 8),
          IconButton(
            key: ValueKey('server-sticker-edit-$stickerId'),
            tooltip: 'Rename sticker',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            key: ValueKey('server-sticker-delete-$stickerId'),
            tooltip: 'Delete sticker',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ],
    );
  }

  Widget _buildEditor(BuildContext context, String stickerId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: ValueKey('server-sticker-name-field-$stickerId'),
          controller: nameController,
          autofocus: true,
          maxLength: 48,
          decoration: const InputDecoration(hintText: 'Sticker name'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: VerdantButton(
                key: ValueKey('server-sticker-save-$stickerId'),
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

class _StickerGlyph extends StatelessWidget {
  const _StickerGlyph({
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
              Icons.sticky_note_2_outlined,
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

String _stickerName(String value) {
  return value.trim().replaceAll(RegExp(r'^:+|:+$'), '');
}

String _fileNameFromPath(String path) {
  final parts = path.split(RegExp(r'[/\\]'));
  return parts.isEmpty ? 'sticker.png' : parts.last;
}
