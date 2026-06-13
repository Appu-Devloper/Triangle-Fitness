import 'package:equatable/equatable.dart';

class PublicTransformation extends Equatable {
  const PublicTransformation({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.weightBeforeKg,
    required this.weightAfterKg,
    required this.durationText,
    required this.displayOrder,
  });

  final String id;
  final String name;
  final String title;
  final String description;
  final double? weightBeforeKg;
  final double? weightAfterKg;
  final String durationText;
  final int displayOrder;

  @override
  List<Object?> get props => [
    id,
    name,
    title,
    description,
    weightBeforeKg,
    weightAfterKg,
    durationText,
    displayOrder,
  ];
}
