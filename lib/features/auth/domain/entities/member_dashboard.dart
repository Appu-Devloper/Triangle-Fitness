import 'package:equatable/equatable.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_payment.dart';
import 'package:triangle_fitness/features/auth/domain/entities/membership_expiry.dart';

class MemberDashboard extends Equatable {
  const MemberDashboard({
    required this.memberId,
    required this.memberCode,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.receiptNo,
    required this.weight,
    required this.height,
    required this.status,
    required this.planName,
    required this.amount,
    required this.paymentStatus,
    required this.subscriptionStatus,
    required this.startDate,
    required this.endDate,
    this.payments = const [],
  });

  final String memberId;
  final String memberCode;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String receiptNo;
  final String weight;
  final String height;
  final String status;
  final String planName;
  final String amount;
  final String paymentStatus;
  final String subscriptionStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<MemberPayment> payments;

  String subscriptionStatusFor(DateTime now) {
    final expiry = endDate;
    if (expiry == null) return subscriptionStatus;

    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(expiry.year, expiry.month, expiry.day);
    return endDay.isBefore(today) ? 'Expired' : 'Active';
  }

  String expiresInFor(DateTime now) {
    return membershipExpiryCountdown(endDate, now);
  }

  String expirySummaryFor(DateTime now) {
    return membershipExpirySummary(endDate, now);
  }

  @override
  List<Object?> get props => [
    memberId,
    memberCode,
    name,
    phone,
    email,
    address,
    receiptNo,
    weight,
    height,
    status,
    planName,
    amount,
    paymentStatus,
    subscriptionStatus,
    startDate,
    endDate,
    payments,
  ];
}
