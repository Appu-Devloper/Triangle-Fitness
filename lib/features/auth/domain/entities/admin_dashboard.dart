import 'package:equatable/equatable.dart';

class AdminDashboard extends Equatable {
  const AdminDashboard({
    required this.adminName,
    required this.totalMembers,
    required this.activeMembers,
    required this.expiredMembers,
    required this.totalPayments,
    required this.totalPaymentAmount,
    required this.totalTransformations,
  });

  final String adminName;
  final int totalMembers;
  final int activeMembers;
  final int expiredMembers;
  final int totalPayments;
  final double totalPaymentAmount;
  final int totalTransformations;

  @override
  List<Object> get props => [
    adminName,
    totalMembers,
    activeMembers,
    expiredMembers,
    totalPayments,
    totalPaymentAmount,
    totalTransformations,
  ];
}
