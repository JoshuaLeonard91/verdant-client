import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'verdant_app_profile.dart';
import 'verdant_flutter_app.dart';

Future<void> runVerdantFlutterApp({List<String> args = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final appProfile = VerdantAppProfile.fromArgs(args);
  await configureDesktopWindow(appProfile: appProfile);
  runApp(VerdantFlutterApp(appProfile: appProfile));
}

Future<void> configureDesktopWindow({
  VerdantAppProfile appProfile = VerdantAppProfile.primary,
}) async {
  await windowManager.ensureInitialized();

  final options = WindowOptions(
    title: appProfile.windowTitle,
    size: Size(1280, 720),
    minimumSize: Size(980, 620),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
