import 'dart:ui';

import 'server_settings_models.dart';

const double serverBannerAspectRatio = 45 / 16;
const BannerCrop defaultBannerCrop = BannerCrop(
  x: 0,
  y: 0,
  width: 100,
  height: 100,
);

Rect bannerCropPreviewRect(Size previewSize, BannerCrop? crop) {
  final normalized = (crop ?? defaultBannerCrop).normalized();
  return Rect.fromLTWH(
    -(normalized.x / normalized.width) * previewSize.width,
    -(normalized.y / normalized.height) * previewSize.height,
    (100 / normalized.width) * previewSize.width,
    (100 / normalized.height) * previewSize.height,
  );
}

BannerCrop shiftBannerCrop(BannerCrop crop, Offset delta, Size previewSize) {
  final normalized = crop.normalized();
  if (previewSize.width <= 0 || previewSize.height <= 0) {
    return normalized;
  }

  final nextX =
      normalized.x - (delta.dx / previewSize.width) * normalized.width;
  final nextY =
      normalized.y - (delta.dy / previewSize.height) * normalized.height;
  return BannerCrop(
    x: _roundedPercent(nextX.clamp(0, 100 - normalized.width).toDouble()),
    y: _roundedPercent(nextY.clamp(0, 100 - normalized.height).toDouble()),
    width: normalized.width,
    height: normalized.height,
  );
}

BannerCrop zoomBannerCrop(BannerCrop crop, double zoom) {
  final normalized = crop.normalized();
  final nextZoom = zoom.clamp(1, 4).toDouble();
  final nextWidth = _roundedPercent(100 / nextZoom);
  final nextHeight = _roundedPercent(100 / nextZoom);
  final centerX = normalized.x + normalized.width / 2;
  final centerY = normalized.y + normalized.height / 2;
  return BannerCrop(
    x: _roundedPercent(
      (centerX - nextWidth / 2).clamp(0, 100 - nextWidth).toDouble(),
    ),
    y: _roundedPercent(
      (centerY - nextHeight / 2).clamp(0, 100 - nextHeight).toDouble(),
    ),
    width: nextWidth,
    height: nextHeight,
  );
}

double zoomForBannerCrop(BannerCrop? crop) {
  final normalized = (crop ?? defaultBannerCrop).normalized();
  return (100 / normalized.width).clamp(1, 4).toDouble();
}

double _roundedPercent(double value) {
  return double.parse(value.toStringAsFixed(4));
}
