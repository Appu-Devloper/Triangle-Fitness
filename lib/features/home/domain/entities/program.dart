import 'package:equatable/equatable.dart';

enum ProgramType {
  weightTraining,
  crossFit,
  personalTraining,
  aerobics,
  cycling,
  yoga,
  zumba,
  danceFitness,
  aquatics,
  adultSports,
}

class Program extends Equatable {
  const Program({
    required this.name,
    required this.type,
    required this.category,
    required this.description,
  });

  final String name;
  final ProgramType type;
  final String category;
  final String description;

  @override
  List<Object> get props => [name, type, category, description];
}
