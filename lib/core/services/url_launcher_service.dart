import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  Future<bool> launch(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
