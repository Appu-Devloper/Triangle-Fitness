import 'package:equatable/equatable.dart';

class MemberPayment extends Equatable {
  const MemberPayment({
    required this.id,
    required this.receiptNo,
    required this.amount,
    required this.paymentMode,
    required this.paymentStatus,
    required this.paymentDate,
    required this.subscriptionStartDate,
    required this.subscriptionEndDate,
  });

  final String id;
  final String receiptNo;
  final double amount;
  final String paymentMode;
  final String paymentStatus;
  final DateTime? paymentDate;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;

  @override
  List<Object?> get props => [
    id,
    receiptNo,
    amount,
    paymentMode,
    paymentStatus,
    paymentDate,
    subscriptionStartDate,
    subscriptionEndDate,
  ];
}
