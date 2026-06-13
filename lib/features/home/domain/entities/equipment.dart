import 'package:equatable/equatable.dart';

class Equipment extends Equatable {
  const Equipment({
    required this.name,
    required this.category,
    required this.image,
    required this.description,
    required this.specs,
  });

  final String name;
  final String category;
  final String image;
  final String description;
  final List<String> specs;

  @override
  List<Object> get props => [name, category, image, description, specs];
}
