import 'package:triangle_fitness/features/home/domain/entities/gym_content.dart';

abstract interface class GymRepository {
  Future<GymContent> getContent();
}
