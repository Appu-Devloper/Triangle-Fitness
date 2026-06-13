import 'package:equatable/equatable.dart';

class GymProfile extends Equatable {
  const GymProfile({
    this.gymName = '',
    this.ownerName = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.openingTime = '',
    this.closingTime = '',
    this.instagramUrl = '',
    this.facebookUrl = '',
    this.whatsappNumber = '',
  });

  final String gymName;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final String openingTime;
  final String closingTime;
  final String instagramUrl;
  final String facebookUrl;
  final String whatsappNumber;

  @override
  List<Object> get props => [
    gymName,
    ownerName,
    phone,
    email,
    address,
    openingTime,
    closingTime,
    instagramUrl,
    facebookUrl,
    whatsappNumber,
  ];
}
