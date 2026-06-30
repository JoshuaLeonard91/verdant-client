import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../theme/verdant_button.dart';
import '../../../theme/verdant_theme.dart';
import 'banner_crop_dialog.dart';
import 'banner_crop_geometry.dart';
import 'server_media_image.dart';
import 'server_media_loader.dart';
import 'server_media_url_policy.dart';
import 'server_settings_models.dart';
import 'server_settings_service.dart';

final _imageTypeGroup = XTypeGroup(
  label: 'Images',
  extensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp'],
  mimeTypes: const ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
);
final _serverMediaLoader = ServerMediaLoader();

class ServerSettingsOverviewTab extends StatefulWidget {
  const ServerSettingsOverviewTab({
    required this.data,
    required this.repository,
    required this.onServerUpdated,
    super.key,
  });

  final ServerSettingsData data;
  final ServerSettingsRepository repository;
  final ValueChanged<ServerSettingsServer> onServerUpdated;

  @override
  State<ServerSettingsOverviewTab> createState() =>
      _ServerSettingsOverviewTabState();
}

class _ServerSettingsOverviewTabState extends State<ServerSettingsOverviewTab> {
  late final TextEditingController _nameController;
  String _welcomeChannelId = '';
  String? _error;
  String? _busyAction;

  ServerSettingsServer get _server => widget.data.server;

  bool get _isBusy => _busyAction != null;

  bool get _nameChanged {
    final nextName = _nameController.text.trim();
    return nextName.isNotEmpty && nextName != _server.name;
  }

  bool get _welcomeChanged {
    final current = _server.welcomeChannelId ?? '';
    return _welcomeChannelId != current;
  }

  bool get _hasOverviewChanges => _nameChanged || _welcomeChanged;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _server.name)
      ..addListener(_handleFieldChanged);
    _welcomeChannelId = _server.welcomeChannelId ?? '';
  }

  @override
  void didUpdateWidget(covariant ServerSettingsOverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.server.id != oldWidget.data.server.id ||
        widget.data.server.name != oldWidget.data.server.name) {
      _nameController.text = _server.name;
    }
    if (widget.data.server.welcomeChannelId !=
        oldWidget.data.server.welcomeChannelId) {
      _welcomeChannelId = _server.welcomeChannelId ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textChannels = widget.data.channels
        .where((channel) => channel.type == 0)
        .toList(growable: false);

    return _SettingsSection(
      children: [
        _ServerMediaSection(
          server: _server,
          mediaPolicy: widget.data.mediaPolicy,
          onUploadBanner: _isBusy ? null : _selectBanner,
          onPositionBanner: _isBusy || _server.bannerUrl == null
              ? null
              : _positionBanner,
          onRemoveBanner: _isBusy || _server.bannerUrl == null
              ? null
              : _removeBanner,
          onUploadIcon: _isBusy ? null : _uploadIcon,
          onRemoveIcon: _isBusy || _server.iconUrl == null ? null : _removeIcon,
          busyAction: _busyAction,
        ),
        const SizedBox(height: 22),
        _TextField(
          key: const ValueKey('server-settings-name-field'),
          controller: _nameController,
          label: 'Server Name',
          enabled: !_isBusy,
        ),
        const SizedBox(height: 14),
        _ReadonlyField(
          label: 'Description',
          value: _server.description ?? 'No server description set.',
        ),
        const SizedBox(height: 14),
        _WelcomeChannelField(
          channels: textChannels,
          value: _welcomeChannelId,
          enabled: !_isBusy,
          onChanged: (value) {
            setState(() => _welcomeChannelId = value ?? '');
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          _ErrorMessage(message: _error!),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            SizedBox(
              width: 170,
              child: VerdantButton(
                key: const ValueKey('server-settings-save-button'),
                label: 'Save Changes',
                onPressed: _hasOverviewChanges && !_isBusy
                    ? _saveOverview
                    : null,
                icon: Icons.save_outlined,
                isBusy: _busyAction == 'overview',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _DangerZone(),
      ],
    );
  }

  void _handleFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveOverview() async {
    final patch = _welcomeChanged
        ? ServerSettingsPatch(
            name: _nameChanged ? _nameController.text : null,
            welcomeChannelId: _welcomeChannelId.isEmpty
                ? null
                : _welcomeChannelId,
          )
        : ServerSettingsPatch(name: _nameChanged ? _nameController.text : null);
    await _runServerAction('overview', () {
      return widget.repository.updateServer(serverId: _server.id, patch: patch);
    });
  }

  Future<void> _uploadIcon() async {
    final file = await openFile(acceptedTypeGroups: [_imageTypeGroup]);
    if (file == null) {
      return;
    }
    await _runServerAction('icon', () {
      return widget.repository.uploadServerIcon(
        serverId: _server.id,
        upload: ServerSettingsUpload(path: file.path, fileName: file.name),
      );
    });
  }

  Future<void> _removeIcon() async {
    await _runServerAction('icon', () {
      return widget.repository.deleteServerIcon(serverId: _server.id);
    });
  }

  Future<void> _selectBanner() async {
    final file = await openFile(acceptedTypeGroups: [_imageTypeGroup]);
    if (file == null) {
      return;
    }
    final crop = await _showBannerCropDialog(
      imageProvider: MemoryImage(await file.readAsBytes()),
      initialCrop: null,
      title: 'Position New Banner',
    );
    if (crop == null) {
      return;
    }

    await _runServerAction('banner', () async {
      final uploaded = await widget.repository.uploadServerBanner(
        serverId: _server.id,
        upload: ServerSettingsUpload(path: file.path, fileName: file.name),
      );
      return widget.repository.updateBannerCrop(
        serverId: uploaded.id,
        crop: crop,
      );
    });
  }

  Future<void> _positionBanner() async {
    final bannerUrl = _server.bannerUrl;
    final bannerUri = safeServerMediaUri(
      bannerUrl,
      policy: widget.data.mediaPolicy,
    );
    if (bannerUri == null) {
      setState(() {
        _error = 'Server banner URL is outside this network media policy';
      });
      return;
    }
    Uint8List bannerBytes;
    setState(() {
      _busyAction = 'banner';
      _error = null;
    });
    try {
      bannerBytes = await _serverMediaLoader.load(
        bannerUri,
        policy: widget.data.mediaPolicy,
      );
    } on ServerMediaLoadException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
      return;
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Server banner could not be loaded');
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
    final crop = await _showBannerCropDialog(
      imageProvider: MemoryImage(bannerBytes),
      initialCrop: _server.bannerCrop,
      title: 'Position Banner',
    );
    if (crop == null) {
      return;
    }

    await _runServerAction('banner', () {
      return widget.repository.updateBannerCrop(
        serverId: _server.id,
        crop: crop,
      );
    });
  }

  Future<void> _removeBanner() async {
    await _runServerAction('banner', () {
      return widget.repository.deleteServerBanner(serverId: _server.id);
    });
  }

  Future<BannerCrop?> _showBannerCropDialog({
    required ImageProvider imageProvider,
    required BannerCrop? initialCrop,
    required String title,
  }) {
    return showBannerCropDialog(
      context: context,
      title: title,
      imageProvider: imageProvider,
      initialCrop: initialCrop,
    );
  }

  Future<void> _runServerAction(
    String action,
    Future<ServerSettingsServer> Function() task,
  ) async {
    setState(() {
      _busyAction = action;
      _error = null;
    });
    try {
      final updated = await task();
      if (!mounted) {
        return;
      }
      widget.onServerUpdated(updated);
      setState(() {
        _nameController.text = updated.name;
        _welcomeChannelId = updated.welcomeChannelId ?? '';
      });
    } on ServerSettingsException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Server settings could not be saved');
      }
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }
}

class _ServerMediaSection extends StatelessWidget {
  const _ServerMediaSection({
    required this.server,
    required this.mediaPolicy,
    required this.onUploadBanner,
    required this.onPositionBanner,
    required this.onRemoveBanner,
    required this.onUploadIcon,
    required this.onRemoveIcon,
    required this.busyAction,
  });

  final ServerSettingsServer server;
  final ServerMediaPolicy mediaPolicy;
  final VoidCallback? onUploadBanner;
  final VoidCallback? onPositionBanner;
  final VoidCallback? onRemoveBanner;
  final VoidCallback? onUploadIcon;
  final VoidCallback? onRemoveIcon;
  final String? busyAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconPreview(
                server: server,
                mediaPolicy: mediaPolicy,
                onUploadIcon: onUploadIcon,
                busyAction: busyAction,
              ),
              const SizedBox(height: 14),
              const _HorizontalMediaSeparator(),
              const SizedBox(height: 14),
              _BannerPreview(
                server: server,
                mediaPolicy: mediaPolicy,
                onUploadBanner: onUploadBanner,
                busyAction: busyAction,
              ),
              const SizedBox(height: 8),
              _CompactMediaActions(
                hasIcon: server.iconUrl != null,
                hasBanner: server.bannerUrl != null,
                onRemoveIcon: onRemoveIcon,
                onPositionBanner: onPositionBanner,
                onRemoveBanner: onRemoveBanner,
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconPreview(
                  server: server,
                  mediaPolicy: mediaPolicy,
                  onUploadIcon: onUploadIcon,
                  busyAction: busyAction,
                ),
                const SizedBox(width: 14),
                const _VerticalMediaSeparator(),
                const SizedBox(width: 14),
                Expanded(
                  child: _BannerPreview(
                    server: server,
                    mediaPolicy: mediaPolicy,
                    onUploadBanner: onUploadBanner,
                    busyAction: busyAction,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _MediaActionsRow(
              hasIcon: server.iconUrl != null,
              hasBanner: server.bannerUrl != null,
              onRemoveIcon: onRemoveIcon,
              onPositionBanner: onPositionBanner,
              onRemoveBanner: onRemoveBanner,
            ),
          ],
        );
      },
    );
  }
}

class _MediaActionsRow extends StatelessWidget {
  const _MediaActionsRow({
    required this.hasIcon,
    required this.hasBanner,
    required this.onRemoveIcon,
    required this.onPositionBanner,
    required this.onRemoveBanner,
  });

  final bool hasIcon;
  final bool hasBanner;
  final VoidCallback? onRemoveIcon;
  final VoidCallback? onPositionBanner;
  final VoidCallback? onRemoveBanner;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 112,
          child: hasIcon
              ? _MiniActionButton(
                  key: const ValueKey('server-settings-remove-icon-button'),
                  label: 'Remove',
                  icon: PhosphorIcons.trash,
                  onPressed: onRemoveIcon,
                  danger: true,
                  fullWidth: true,
                )
              : const SizedBox(height: 32),
        ),
        const SizedBox(width: 14),
        const SizedBox(width: 1),
        const SizedBox(width: 14),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniActionButton(
                key: const ValueKey('server-settings-position-banner-button'),
                label: 'Position',
                icon: PhosphorIcons.crop,
                onPressed: onPositionBanner,
              ),
              if (hasBanner)
                _MiniActionButton(
                  key: const ValueKey('server-settings-remove-banner-button'),
                  label: 'Remove',
                  icon: PhosphorIcons.trash,
                  onPressed: onRemoveBanner,
                  danger: true,
                ),
              const _DimensionText('1200 x 427 px', width: 116),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactMediaActions extends StatelessWidget {
  const _CompactMediaActions({
    required this.hasIcon,
    required this.hasBanner,
    required this.onRemoveIcon,
    required this.onPositionBanner,
    required this.onRemoveBanner,
  });

  final bool hasIcon;
  final bool hasBanner;
  final VoidCallback? onRemoveIcon;
  final VoidCallback? onPositionBanner;
  final VoidCallback? onRemoveBanner;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hasIcon)
          _MiniActionButton(
            key: const ValueKey('server-settings-remove-icon-button'),
            label: 'Remove Icon',
            icon: PhosphorIcons.trash,
            onPressed: onRemoveIcon,
            danger: true,
          ),
        _MiniActionButton(
          key: const ValueKey('server-settings-position-banner-button'),
          label: 'Position',
          icon: PhosphorIcons.crop,
          onPressed: onPositionBanner,
        ),
        if (hasBanner)
          _MiniActionButton(
            key: const ValueKey('server-settings-remove-banner-button'),
            label: 'Remove Banner',
            icon: PhosphorIcons.trash,
            onPressed: onRemoveBanner,
            danger: true,
          ),
        const _DimensionText('1200 x 427 px', width: 116),
      ],
    );
  }
}

class _VerticalMediaSeparator extends StatelessWidget {
  const _VerticalMediaSeparator();

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return SizedBox(
      height: 176,
      child: VerticalDivider(color: colors.border, width: 1, thickness: 1),
    );
  }
}

class _HorizontalMediaSeparator extends StatelessWidget {
  const _HorizontalMediaSeparator();

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Divider(color: colors.border, height: 1, thickness: 1);
  }
}

class _BannerPreview extends StatelessWidget {
  const _BannerPreview({
    required this.server,
    required this.mediaPolicy,
    required this.onUploadBanner,
    required this.busyAction,
  });

  final ServerSettingsServer server;
  final ServerMediaPolicy mediaPolicy;
  final VoidCallback? onUploadBanner;
  final String? busyAction;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final bannerUrl = server.bannerUrl;
    final bannerUri = safeServerMediaUri(bannerUrl, policy: mediaPolicy);
    final hasBanner = bannerUri != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Server Banner', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 7),
        AspectRatio(
          aspectRatio: serverBannerAspectRatio,
          child: Container(
            decoration: BoxDecoration(
              color: colors.panel,
              border: Border.all(color: colors.border),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: !hasBanner
                      ? const BlankServerBannerCanvas()
                      : SafeServerMediaImage(
                          uri: bannerUri,
                          policy: mediaPolicy,
                          surface: ServerMediaSurface.serverBanner,
                          retainWhenUnfocused: true,
                          fallback: const BlankServerBannerCanvas(),
                          builder: (context, imageProvider) {
                            return CroppedServerBannerImage(
                              imageProvider: imageProvider,
                              crop: server.bannerCrop,
                              imageKey: const ValueKey(
                                'server-settings-banner-media-image',
                              ),
                            );
                          },
                        ),
                ),
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _OverlayActionButton(
                      key: const ValueKey(
                        'server-settings-upload-banner-button',
                      ),
                      label: hasBanner ? 'Upload New Banner' : 'Upload Banner',
                      icon: PhosphorIcons.uploadSimple,
                      onPressed: onUploadBanner,
                      isBusy: busyAction == 'banner',
                    ),
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

class _IconPreview extends StatelessWidget {
  const _IconPreview({
    required this.server,
    required this.mediaPolicy,
    required this.onUploadIcon,
    required this.busyAction,
  });

  final ServerSettingsServer server;
  final ServerMediaPolicy mediaPolicy;
  final VoidCallback? onUploadIcon;
  final String? busyAction;

  @override
  Widget build(BuildContext context) {
    const previewSize = 112.0;
    return SizedBox(
      width: previewSize,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Server Icon', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 7),
          SizedBox(
            width: previewSize,
            height: previewSize,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ServerMediaIcon(
                    name: server.name,
                    iconUrl: server.iconUrl,
                    mediaPolicy: mediaPolicy,
                    size: previewSize,
                    showBorder: false,
                    imageKey: const ValueKey(
                      'server-settings-icon-media-image',
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: _OverlayActionButton(
                    key: const ValueKey('server-settings-upload-icon-button'),
                    label: 'Upload',
                    icon: PhosphorIcons.uploadSimple,
                    onPressed: onUploadIcon,
                    isBusy: busyAction == 'icon',
                    compact: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const _DimensionText('256 x 256 px'),
        ],
      ),
    );
  }
}

class _OverlayActionButton extends StatelessWidget {
  const _OverlayActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isBusy = false,
    this.compact = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isBusy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return TextButton.icon(
      onPressed: isBusy ? null : onPressed,
      icon: isBusy
          ? const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: compact ? 13 : 15),
      label: Text(
        isBusy ? 'Uploading...' : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 11.5 : 12,
          fontWeight: VerdantFontWeights.semibold,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: colors.text,
        disabledForegroundColor: colors.textMuted,
        backgroundColor: const Color(0xD30B0D10),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 7 : 9,
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        side: BorderSide(color: colors.border),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.danger = false,
    this.fullWidth = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool danger;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final color = danger ? const Color(0xFFFF8A8A) : colors.textMuted;
    final border = danger ? const Color(0x995C3030) : colors.borderStrong;
    return SizedBox(
      width: fullWidth ? double.infinity : 104,
      height: 32,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 13, color: color),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: VerdantFontWeights.semibold,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: BorderSide(color: border),
        ),
      ),
    );
  }
}

class _DimensionText extends StatelessWidget {
  const _DimensionText(this.value, {this.width});

  final String value;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return SizedBox(
      width: width,
      height: 32,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 12,
            fontWeight: VerdantFontWeights.medium,
          ),
        ),
      ),
    );
  }
}

class _WelcomeChannelField extends StatelessWidget {
  const _WelcomeChannelField({
    required this.channels,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final List<ServerSettingsChannelSeed> channels;
  final String value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final knownChannelIds = channels.map((channel) => channel.id).toSet();
    final selectedValue = knownChannelIds.contains(value) ? value : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome Channel', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          key: const ValueKey('server-settings-welcome-channel-field'),
          initialValue: selectedValue,
          isExpanded: true,
          dropdownColor: colors.panelRaised,
          decoration: _inputDecoration(context),
          items: [
            const DropdownMenuItem(value: '', child: Text('None')),
            for (final channel in channels)
              DropdownMenuItem(
                value: channel.id,
                child: Text('#${channel.name}'),
              ),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required super.key,
    required this.controller,
    required this.label,
    required this.enabled,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          enabled: enabled,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 100,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: _inputDecoration(context, counterText: ''),
        ),
      ],
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: colors.panel,
            border: Border.all(color: colors.border),
          ),
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    const dangerColor = Color(0xFFFF6B78);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dangerColor.withValues(alpha: 0.12),
        border: Border.all(color: dangerColor.withValues(alpha: 0.72)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: dangerColor,
          fontWeight: VerdantFontWeights.bold,
        ),
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone();

  @override
  Widget build(BuildContext context) {
    const dangerColor = Color(0xFFFF6B78);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: dangerColor.withValues(alpha: 0.72)),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIcons.warning, color: dangerColor, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Danger Zone',
              style: TextStyle(
                color: dangerColor,
                fontWeight: VerdantFontWeights.black,
              ),
            ),
          ),
          SizedBox(
            width: 154,
            child: VerdantButton(
              label: 'Delete Server',
              onPressed: null,
              icon: PhosphorIcons.trash,
              variant: VerdantButtonVariant.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

InputDecoration _inputDecoration(BuildContext context, {String? counterText}) {
  final colors = VerdantThemeColors.of(context);
  return InputDecoration(
    counterText: counterText,
    filled: true,
    fillColor: colors.panel,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: colors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: colors.action),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: colors.border.withValues(alpha: 0.72)),
    ),
  );
}
