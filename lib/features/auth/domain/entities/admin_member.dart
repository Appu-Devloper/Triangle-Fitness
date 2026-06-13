import 'package:equatable/equatable.dart';
import 'package:triangle_fitness/features/auth/domain/entities/membership_expiry.dart';

class AdminMember extends Equatable {
  const AdminMember({
    required this.id,
    required this.memberCode,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.receiptNo,
    required this.weightKg,
    required this.heightCm,
    required this.planName,
    required this.subscriptionStartDate,
    required this.subscriptionEndDate,
    required this.subscriptionAmount,
    required this.paymentStatus,
    required this.status,
  });

  final String id;
  final String memberCode;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String receiptNo;
  final double? weightKg;
  final double? heightCm;
  final String planName;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final double? subscriptionAmount;
  final String paymentStatus;
  final String status;

  bool isExpiredOn(DateTime date) {
    final endDate = subscriptionEndDate;
    if (endDate == null) return false;
    final today = DateTime(date.year, date.month, date.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    return endDay.isBefore(today);
  }

  String effectiveStatusOn(DateTime date) {
    return isExpiredOn(date) ? 'EXPIRED' : status.trim().toUpperCase();
  }

  String expiresInOn(DateTime date) {
    return membershipExpiryCountdown(subscriptionEndDate, date);
  }

  bool matchesSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        phone.toLowerCase().contains(normalized) ||
        memberCode.toLowerCase().contains(normalized);
  }

  @override
  List<Object?> get props => [
    id,
    memberCode,
    name,
    phone,
    email,
    address,
    receiptNo,
    weightKg,
    heightCm,
    planName,
    subscriptionStartDate,
    subscriptionEndDate,
    subscriptionAmount,
    paymentStatus,
    status,
  ];
}
