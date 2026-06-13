import 'package:equatable/equatable.dart';
import 'package:triangle_fitness/features/auth/domain/entities/subscription_plan.dart';

class CreateMemberRequest extends Equatable {
  const CreateMemberRequest({
    required this.memberCode,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.receiptNo,
    required this.weightKg,
    required this.heightCm,
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.paymentMode,
    required this.paymentStatus,
    required this.memberStatus,
  });

  final String memberCode;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String receiptNo;
  final double? weightKg;
  final double? heightCm;
  final SubscriptionPlan plan;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String paymentMode;
  final String paymentStatus;
  final String memberStatus;

  @override
  List<Object?> get props => [
    memberCode,
    name,
    phone,
    email,
    address,
    receiptNo,
    weightKg,
    heightCm,
    plan,
    startDate,
    endDate,
    amount,
    paymentMode,
    paymentStatus,
    memberStatus,
  ];
}
