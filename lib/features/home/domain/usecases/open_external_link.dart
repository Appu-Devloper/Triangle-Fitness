import 'package:triangle_fitness/features/home/domain/entities/home_action.dart';
import 'package:triangle_fitness/features/home/domain/repositories/external_link_repository.dart';

class OpenExternalLink {
  const OpenExternalLink(this.repository);

  final ExternalLinkRepository repository;

  Future<bool> call(ExternalAction action) => repository.open(action);
}
