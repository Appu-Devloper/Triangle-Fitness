import 'package:equatable/equatable.dart';

class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
  });

  final String id;
  final String name;
  final int durationDays;
  final double price;

  @override
  List<Object?> get props => [id, name, durationDays, price];
}
