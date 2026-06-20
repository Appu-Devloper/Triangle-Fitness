import 'package:triangle_fitness/core/constants/app_links.dart';
import 'package:triangle_fitness/core/services/url_launcher_service.dart';
import 'package:triangle_fitness/features/home/domain/entities/home_action.dart';
import 'package:triangle_fitness/features/home/domain/repositories/external_link_repository.dart';

class ExternalLinkRepositoryImpl implements ExternalLinkRepository {
  const ExternalLinkRepositoryImpl({required this.launcher});

  final UrlLauncherService launcher;

  @override
  Future<bool> open(ExternalAction action) {
    final uri = switch (action) {
      ExternalAction.call => AppLinks.call,
      ExternalAction.directions => AppLinks.directions,
      ExternalAction.whatsapp => AppLinks.whatsapp,
    };
    return launcher.launch(uri);
  }

  @override
  Future<bool> openUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) return Future.value(false);
    return launcher.launch(uri);
  }
}
