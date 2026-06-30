import 'package:url_launcher/url_launcher.dart';

class WorkspaceLinkLauncher {
  const WorkspaceLinkLauncher();

  Future<bool> openExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
