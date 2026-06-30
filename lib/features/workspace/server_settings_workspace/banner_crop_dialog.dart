import 'package:flutter/material.dart';

import '../../../theme/verdant_button.dart';
import '../../../theme/verdant_theme.dart';
import 'banner_crop_geometry.dart';
import 'server_media_image.dart';
import 'server_settings_models.dart';

Future<BannerCrop?> showBannerCropDialog({
  required BuildContext context,
  required String title,
  required ImageProvider imageProvider,
  required BannerCrop? initialCrop,
  double aspectRatio = serverBannerAspectRatio,
}) {
  return showDialog<BannerCrop>(
    context: context,
    builder: (context) {
      return _BannerCropDialog(
        title: title,
        imageProvider: imageProvider,
        initialCrop: initialCrop,
        aspectRatio: aspectRatio,
      );
    },
  );
}

class _BannerCropDialog extends StatefulWidget {
  const _BannerCropDialog({
    required this.title,
    required this.imageProvider,
    required this.initialCrop,
    required this.aspectRatio,
  });

  final String title;
  final ImageProvider imageProvider;
  final BannerCrop? initialCrop;
  final double aspectRatio;

  @override
  State<_BannerCropDialog> createState() => _BannerCropDialogState();
}

class _BannerCropDialogState extends State<_BannerCropDialog> {
  late BannerCrop _crop = (widget.initialCrop ?? defaultBannerCrop)
      .normalized();
  late double _zoom = zoomForBannerCrop(_crop);

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Dialog(
      backgroundColor: colors.panelRaised,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 19),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AspectRatio(
                aspectRatio: widget.aspectRatio,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _crop = shiftBannerCrop(_crop, details.delta, size);
                          _zoom = zoomForBannerCrop(_crop);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.border),
                          color: colors.panel,
                        ),
                        child: CroppedServerBannerImage(
                          imageProvider: widget.imageProvider,
                          crop: _crop,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      'Zoom',
                      style: TextStyle(color: colors.textMuted),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _zoom,
                      min: 1,
                      max: 4,
                      onChanged: (value) {
                        setState(() {
                          _zoom = value;
                          _crop = zoomBannerCrop(_crop, value);
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      '${(_zoom * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: colors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 112,
                    child: VerdantButton(
                      label: 'Reset',
                      onPressed: () {
                        setState(() {
                          _crop = defaultBannerCrop;
                          _zoom = 1;
                        });
                      },
                      variant: VerdantButtonVariant.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 112,
                    child: VerdantButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                      variant: VerdantButtonVariant.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 150,
                    child: VerdantButton(
                      label: 'Save Position',
                      onPressed: () => Navigator.of(context).pop(_crop),
                      icon: Icons.check,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
