import 'package:triangle_fitness/features/auth/domain/entities/create_member_request.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_member.dart';
import 'package:triangle_fitness/features/auth/domain/entities/subscription_plan.dart';

abstract interface class MemberManagementRepository {
  Future<List<SubscriptionPlan>> getActiveSubscriptionPlans();

  Stream<List<AdminMember>> watchMembers();

  Future<AdminMember> getMember(String memberId);

  Future<void> createMember(CreateMemberRequest request);
}

class MemberManagementFailure implements Exception {
  const MemberManagementFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
