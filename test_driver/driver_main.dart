import 'package:flutter_driver/driver_extension.dart';
import 'package:verdant_flutter/app/verdant_flutter_bootstrap.dart';

Future<void> main() async {
  enableFlutterDriverExtension();
  await runVerdantFlutterApp();
}
