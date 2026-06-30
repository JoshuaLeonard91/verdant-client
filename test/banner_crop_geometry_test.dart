import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/banner_crop_geometry.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';

void main() {
  test('maps banner crop percentages to the same preview rect as Tauri', () {
    final rect = bannerCropPreviewRect(
      const Size(450, 160),
      const BannerCrop(x: 10, y: 20, width: 80, height: 40),
    );

    expect(rect.left, -56.25);
    expect(rect.top, -80);
    expect(rect.width, 562.5);
    expect(rect.height, 400);
  });

  test(
    'dragging the banner moves the underlying crop and clamps to bounds',
    () {
      final moved = shiftBannerCrop(
        const BannerCrop(x: 10, y: 10, width: 80, height: 40),
        const Offset(-90, 32),
        const Size(450, 160),
      );

      expect(moved, const BannerCrop(x: 20, y: 2, width: 80, height: 40));

      final clamped = shiftBannerCrop(
        moved,
        const Offset(-900, -900),
        const Size(450, 160),
      );

      expect(clamped, const BannerCrop(x: 20, y: 60, width: 80, height: 40));
    },
  );

  test('zooming banner crop preserves center while respecting crop bounds', () {
    final zoomed = zoomBannerCrop(
      const BannerCrop(x: 25, y: 25, width: 50, height: 50),
      2,
    );

    expect(zoomed, const BannerCrop(x: 25, y: 25, width: 50, height: 50));

    final reset = zoomBannerCrop(zoomed, 1);

    expect(reset, const BannerCrop(x: 0, y: 0, width: 100, height: 100));
  });
}
