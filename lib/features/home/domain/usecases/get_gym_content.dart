import 'package:triangle_fitness/features/home/domain/entities/gym_content.dart';
import 'package:triangle_fitness/features/home/domain/repositories/gym_repository.dart';

class GetGymContent {
  const GetGymContent(this.repository);

  final GymRepository repository;

  Future<GymContent> call() => repository.getContent();
}
