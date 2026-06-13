import 'package:equatable/equatable.dart';
import 'package:triangle_fitness/features/home/domain/entities/equipment.dart';
import 'package:triangle_fitness/features/home/domain/entities/gym_profile.dart';
import 'package:triangle_fitness/features/home/domain/entities/program.dart';
import 'package:triangle_fitness/features/home/domain/entities/public_subscription_plan.dart';
import 'package:triangle_fitness/features/home/domain/entities/public_transformation.dart';

class GymContent extends Equatable {
  const GymContent({
    required this.programs,
    required this.equipment,
    this.profile = const GymProfile(),
    this.subscriptionPlans = const [],
    this.transformations = const [],
  });

  final List<Program> programs;
  final List<Equipment> equipment;
  final GymProfile profile;
  final List<PublicSubscriptionPlan> subscriptionPlans;
  final List<PublicTransformation> transformations;

  @override
  List<Object> get props => [
    programs,
    equipment,
    profile,
    subscriptionPlans,
    transformations,
  ];
}
