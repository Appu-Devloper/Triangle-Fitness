import 'package:equatable/equatable.dart';
import 'package:triangle_fitness/features/home/domain/entities/equipment.dart';
import 'package:triangle_fitness/features/home/domain/entities/program.dart';

class GymContent extends Equatable {
  const GymContent({required this.programs, required this.equipment});

  final List<Program> programs;
  final List<Equipment> equipment;

  @override
  List<Object> get props => [programs, equipment];
}
