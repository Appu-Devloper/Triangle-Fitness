import 'package:triangle_fitness/features/home/domain/entities/home_action.dart';

abstract interface class ExternalLinkRepository {
  Future<bool> open(ExternalAction action);
}
