import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../shared/verdant_input_sanitizer.dart';
import '../../../theme/verdant_button.dart';
import '../../../theme/verdant_theme.dart';
import '../../auth/auth_models.dart';
import '../server_settings_workspace/banner_crop_dialog.dart';
import '../server_settings_workspace/banner_crop_geometry.dart';
import '../server_settings_workspace/server_media_image.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../server_settings_workspace/server_settings_service.dart';
import 'rail_action_modal_shell.dart';

const _maxIconBytes = 8 * 1024 * 1024;
const _maxBannerBytes = 10 * 1024 * 1024;

final _imageTypeGroup = XTypeGroup(
  label: 'Images',
  extensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp'],
  mimeTypes: const ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
);

class CreateServerRailModal extends StatefulWidget {
  const CreateServerRailModal({
    required this.networkOptions,
    required this.initialApiOrigin,
    required this.onCreate,
    super.key,
  });

  final List<CreateServerNetworkOption> networkOptions;
  final String initialApiOrigin;
  final Future<ServerCreationResult> Function(ServerCreationRequest request)
  onCreate;

  @override
  State<CreateServerRailModal> createState() => _CreateServerRailModalState();
}

final class CreateServerNetworkOption {
  const CreateServerNetworkOption({
    required this.name,
    required this.apiOrigin,
    required this.networkId,
    required this.canCreate,
    this.disabledLabel,
    this.disabledReason,
  });

  final String name;
  final String apiOrigin;
  final String networkId;
  final bool canCreate;
  final String? disabledLabel;
  final String? disabledReason;

  String get kindLabel => 'Network';
}

class _CreateServerRailModalState extends State<CreateServerRailModal> {
  final _nameController = TextEditingController();
  XFile? _iconFile;
  XFile? _bannerFile;
  Uint8List? _iconBytes;
  Uint8List? _bannerBytes;
  BannerCrop? _bannerCrop;
  late String _selectedApiOrigin;
  var _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final normalizedInitial = normalizeBackendApiOrigin(
      widget.initialApiOrigin,
    );
    final hasInitial = widget.networkOptions.any(
      (option) => option.apiOrigin == normalizedInitial,
    );
    _selectedApiOrigin = hasInitial
        ? normalizedInitial
        : widget.networkOptions.first.apiOrigin;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = sanitizeDisplayNameInput(_nameController.text);
    final selectedNetwork = _selectedNetwork;
    final canSubmit = !_isSubmitting && selectedNetwork.canCreate;
    return RailActionModalShell(
      key: const ValueKey('create-server-modal'),
      title: 'Create Server',
      icon: PhosphorIconsRegular.plus,
      maxWidth: 680,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NetworkSelector(
              options: widget.networkOptions,
              selectedApiOrigin: _selectedApiOrigin,
              enabled: !_isSubmitting,
              onChanged: (apiOrigin) {
                setState(() {
                  _selectedApiOrigin = apiOrigin;
                  _error = null;
                });
              },
            ),
            if (!selectedNetwork.canCreate &&
                selectedNetwork.disabledReason != null) ...[
              const SizedBox(height: 8),
              RailActionErrorText(selectedNetwork.disabledReason!),
            ],
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('create-server-name-field'),
              controller: _nameController,
              autofocus: true,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
              decoration: railActionInputDecoration(
                label: 'Server Name',
                hint: 'Verdant',
              ),
            ),
            const SizedBox(height: 16),
            _MediaSection(
              name: name,
              iconFile: _iconFile,
              iconBytes: _iconBytes,
              bannerFile: _bannerFile,
              bannerBytes: _bannerBytes,
              bannerCrop: _bannerCrop,
              enabled: !_isSubmitting,
              onPickIcon: _pickIcon,
              onRemoveIcon: () => setState(() {
                _iconFile = null;
                _iconBytes = null;
              }),
              onPickBanner: _pickBanner,
              onPositionBanner: _positionBanner,
              onRemoveBanner: () => setState(() {
                _bannerFile = null;
                _bannerBytes = null;
                _bannerCrop = null;
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              RailActionErrorText(_error!),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: VerdantButton(
                    label: 'Cancel',
                    variant: VerdantButtonVariant.ghost,
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: VerdantButton(
                    key: const ValueKey('create-server-submit-button'),
                    label: 'Create',
                    icon: PhosphorIconsRegular.plus,
                    isBusy: _isSubmitting,
                    onPressed: canSubmit ? _submit : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickIcon() async {
    final file = await openFile(acceptedTypeGroups: [_imageTypeGroup]);
    if (file == null) {
      return;
    }
    final length = await file.length();
    if (length > _maxIconBytes) {
      setState(() => _error = 'Icon must be 8 MB or smaller.');
      return;
    }
    final bytes = await file.readAsBytes();
    setState(() {
      _iconFile = file;
      _iconBytes = bytes;
      _error = null;
    });
  }

  Future<void> _pickBanner() async {
    final file = await openFile(acceptedTypeGroups: [_imageTypeGroup]);
    if (file == null) {
      return;
    }
    final length = await file.length();
    if (length > _maxBannerBytes) {
      setState(() => _error = 'Banner must be 10 MB or smaller.');
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    final crop = await showBannerCropDialog(
      context: context,
      title: 'Position New Banner',
      imageProvider: MemoryImage(bytes),
      initialCrop: null,
    );
    if (crop == null) {
      return;
    }
    setState(() {
      _bannerFile = file;
      _bannerBytes = bytes;
      _bannerCrop = crop;
      _error = null;
    });
  }

  Future<void> _positionBanner() async {
    final bytes = _bannerBytes;
    if (bytes == null) {
      return;
    }
    final crop = await showBannerCropDialog(
      context: context,
      title: 'Position Banner',
      imageProvider: MemoryImage(bytes),
      initialCrop: _bannerCrop,
    );
    if (crop == null) {
      return;
    }
    setState(() => _bannerCrop = crop);
  }

  Future<void> _submit() async {
    final name = sanitizeDisplayNameInput(_nameController.text);
    if (name.length < 2) {
      setState(() => _error = 'Enter a server name');
      return;
    }
    final selectedNetwork = _selectedNetwork;
    if (!selectedNetwork.canCreate) {
      setState(() {
        _error =
            selectedNetwork.disabledReason ??
            selectedNetwork.disabledLabel ??
            'This network cannot create servers.';
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final result = await widget.onCreate(
        ServerCreationRequest(
          name: name,
          apiOrigin: selectedNetwork.apiOrigin,
          networkId: selectedNetwork.networkId,
          iconUpload: _iconFile == null
              ? null
              : ServerSettingsUpload(
                  path: _iconFile!.path,
                  fileName: _iconFile!.name,
                ),
          bannerUpload: _bannerFile == null
              ? null
              : ServerSettingsUpload(
                  path: _bannerFile!.path,
                  fileName: _bannerFile!.name,
                ),
          bannerCrop: _bannerFile == null ? null : _bannerCrop,
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    } on ServerSettingsException catch (error) {
      setState(() {
        _isSubmitting = false;
        _error = error.message;
      });
    } catch (_) {
      setState(() {
        _isSubmitting = false;
        _error = 'Could not create server';
      });
    }
  }

  CreateServerNetworkOption get _selectedNetwork {
    return widget.networkOptions.firstWhere(
      (option) => option.apiOrigin == _selectedApiOrigin,
      orElse: () => widget.networkOptions.first,
    );
  }
}

class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.name,
    required this.iconFile,
    required this.iconBytes,
    required this.bannerFile,
    required this.bannerBytes,
    required this.bannerCrop,
    required this.enabled,
    required this.onPickIcon,
    required this.onRemoveIcon,
    required this.onPickBanner,
    required this.onPositionBanner,
    required this.onRemoveBanner,
  });

  final String name;
  final XFile? iconFile;
  final Uint8List? iconBytes;
  final XFile? bannerFile;
  final Uint8List? bannerBytes;
  final BannerCrop? bannerCrop;
  final bool enabled;
  final VoidCallback onPickIcon;
  final VoidCallback onRemoveIcon;
  final VoidCallback onPickBanner;
  final VoidCallback onPositionBanner;
  final VoidCallback onRemoveBanner;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: _IconPicker(
            name: name,
            file: iconFile,
            bytes: iconBytes,
            enabled: enabled,
            onPick: onPickIcon,
            onRemove: onRemoveIcon,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _BannerPicker(
            file: bannerFile,
            bytes: bannerBytes,
            crop: bannerCrop,
            enabled: enabled,
            onPick: onPickBanner,
            onPosition: onPositionBanner,
            onRemove: onRemoveBanner,
          ),
        ),
      ],
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.name,
    required this.file,
    required this.bytes,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final String name;
  final XFile? file;
  final Uint8List? bytes;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Server Icon', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        AspectRatio(
          key: const ValueKey('create-server-icon-preview'),
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: VerdantColors.background,
              border: Border.all(color: VerdantColors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (file == null)
                  Center(
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        color: VerdantColors.accentStrong,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else
                  Image.memory(bytes!, fit: BoxFit.cover),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _OverlayButton(
                      key: const ValueKey('create-server-icon-upload-button'),
                      label: file == null ? 'Upload' : 'Replace',
                      icon: PhosphorIconsRegular.uploadSimple,
                      enabled: enabled,
                      onPressed: onPick,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text('256 x 256 px', style: Theme.of(context).textTheme.bodySmall),
        if (file != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _DangerOutlineButton(
              key: const ValueKey('create-server-icon-remove-button'),
              label: 'Remove',
              icon: PhosphorIconsRegular.trash,
              enabled: enabled,
              onPressed: onRemove,
            ),
          ),
        ],
      ],
    );
  }
}

class _BannerPicker extends StatelessWidget {
  const _BannerPicker({
    required this.file,
    required this.bytes,
    required this.crop,
    required this.enabled,
    required this.onPick,
    required this.onPosition,
    required this.onRemove,
  });

  final XFile? file;
  final Uint8List? bytes;
  final BannerCrop? crop;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onPosition;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Server Banner', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        AspectRatio(
          key: const ValueKey('create-server-banner-preview'),
          aspectRatio: serverBannerAspectRatio,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: VerdantColors.background,
              border: Border.all(color: VerdantColors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (file != null)
                  CroppedServerBannerImage(
                    imageProvider: MemoryImage(bytes!),
                    crop: crop,
                  ),
                Center(
                  child: _OverlayButton(
                    key: const ValueKey('create-server-banner-upload-button'),
                    label: file == null ? 'Upload Banner' : 'Replace Banner',
                    icon: PhosphorIconsRegular.uploadSimple,
                    enabled: enabled,
                    onPressed: onPick,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (file != null) ...[
              SizedBox(
                width: 112,
                child: _SubtleOutlineButton(
                  key: const ValueKey('create-server-banner-position-button'),
                  label: 'Position',
                  icon: PhosphorIconsRegular.crop,
                  enabled: enabled,
                  onPressed: onPosition,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 104,
                child: _DangerOutlineButton(
                  key: const ValueKey('create-server-banner-remove-button'),
                  label: 'Remove',
                  icon: PhosphorIconsRegular.trash,
                  enabled: enabled,
                  onPressed: onRemove,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                '1200 x 427 px',
                textAlign: file == null ? TextAlign.left : TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: PhosphorIcon(icon, size: 15),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        backgroundColor: VerdantColors.panel.withValues(alpha: 0.86),
        side: const BorderSide(color: VerdantColors.borderStrong),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _SubtleOutlineButton extends StatelessWidget {
  const _SubtleOutlineButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: PhosphorIcon(icon, size: 14),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

class _DangerOutlineButton extends StatelessWidget {
  const _DangerOutlineButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: PhosphorIcon(icon, size: 14),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFF7B86),
        side: const BorderSide(color: Color(0x885C3038)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

class _NetworkSelector extends StatefulWidget {
  const _NetworkSelector({
    required this.options,
    required this.selectedApiOrigin,
    required this.enabled,
    required this.onChanged,
  });

  final List<CreateServerNetworkOption> options;
  final String selectedApiOrigin;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  State<_NetworkSelector> createState() => _NetworkSelectorState();
}

class _NetworkSelectorState extends State<_NetworkSelector> {
  static const _networkAccents = [
    VerdantColors.accentStrong,
    Color(0xFF8EBBFF),
    Color(0xFFFFD166),
    Color(0xFFC9A7FF),
  ];
  static const _fieldSurface = Color(0xFF101418);
  static const _fieldSurfaceHover = Color(0xFF151B20);
  static const _menuSurface = Color(0xFF171D22);
  static const _menuSelectedSurface = Color(0xFF20372F);
  static const _menuHoverSurface = Color(0xFF223039);
  static const _openBorder = Color(0xFF7CFFDE);

  var _isOpen = false;

  @override
  void didUpdateWidget(covariant _NetworkSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _isOpen) {
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedOption;
    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0;
        return MenuAnchor(
          consumeOutsideTap: true,
          crossAxisUnconstrained: false,
          useRootOverlay: true,
          alignmentOffset: const Offset(0, 5),
          onOpen: () => setState(() => _isOpen = true),
          onClose: () => setState(() => _isOpen = false),
          style: MenuStyle(
            alignment: AlignmentDirectional.bottomStart,
            backgroundColor: const WidgetStatePropertyAll(_menuSurface),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            shadowColor: const WidgetStatePropertyAll(Color(0xCC000000)),
            elevation: const WidgetStatePropertyAll(18),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 4),
            ),
            side: const WidgetStatePropertyAll(
              BorderSide(color: Color(0xFF53616A)),
            ),
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            minimumSize: WidgetStatePropertyAll(Size(menuWidth, 0)),
            maximumSize: WidgetStatePropertyAll(Size(menuWidth, 320)),
          ),
          menuChildren: [
            for (final option in widget.options)
              SizedBox(
                width: menuWidth,
                child: _NetworkMenuItem(
                  key: ValueKey(
                    'create-server-network-option-${option.apiOrigin}',
                  ),
                  option: option,
                  selected: option.apiOrigin == widget.selectedApiOrigin,
                  onSelected: option.canCreate
                      ? () => widget.onChanged(option.apiOrigin)
                      : null,
                ),
              ),
          ],
          builder: (context, controller, child) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('create-server-network-dropdown'),
                onTap: widget.enabled
                    ? () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      }
                    : null,
                hoverColor: VerdantColors.desktopHoverOverlay,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isOpen ? _fieldSurfaceHover : _fieldSurface,
                    border: Border.all(
                      color: _isOpen ? _openBorder : VerdantColors.borderStrong,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: double.infinity,
                        color: _NetworkSelectorState.accentForNetwork(
                          selected.networkId,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Network: ${selected.name}',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: selected.canCreate
                                    ? VerdantColors.text
                                    : VerdantColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        _isOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: _isOpen
                            ? VerdantColors.accentStrong
                            : VerdantColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  CreateServerNetworkOption get _selectedOption {
    return widget.options.firstWhere(
      (option) => option.apiOrigin == widget.selectedApiOrigin,
      orElse: () => widget.options.first,
    );
  }

  static Color accentForNetwork(String networkId) {
    if (networkId.isEmpty) {
      return _networkAccents.first;
    }
    final index =
        networkId.codeUnits.fold<int>(0, (sum, code) => sum + code) %
        _networkAccents.length;
    return _networkAccents[index];
  }
}

class _NetworkMenuItem extends StatelessWidget {
  const _NetworkMenuItem({
    required this.option,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final CreateServerNetworkOption option;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = _NetworkSelectorState.accentForNetwork(option.networkId);
    return MenuItemButton(
      onPressed: onSelected,
      closeOnActivate: true,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(36)),
        maximumSize: const WidgetStatePropertyAll(Size.fromHeight(36)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.transparent;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return _NetworkSelectorState._menuHoverSurface;
          }
          if (selected) {
            return _NetworkSelectorState._menuSelectedSurface;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStatePropertyAll(
          option.canCreate ? VerdantColors.text : VerdantColors.textMuted,
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
      child: Row(
        children: [
          Container(width: 7, height: 7, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              option.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: option.canCreate
                    ? VerdantColors.text
                    : VerdantColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            option.canCreate
                ? option.kindLabel
                : option.disabledLabel ?? 'Sign in required',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: option.canCreate ? accent : VerdantColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return 'VE';
  }
  return parts.map((part) => part[0]).join().substring(0, 1).toUpperCase() +
      (parts.length > 1 ? parts[1][0].toUpperCase() : '');
}
