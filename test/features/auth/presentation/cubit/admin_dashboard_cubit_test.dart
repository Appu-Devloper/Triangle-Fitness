import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_session.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/admin_dashboard_cubit.dart';

void main() {
  final periodStart = DateTime(2026, 6, 10);
  final periodEnd = DateTime(2026, 7, 10);
  final dashboard = AdminDashboard(
    adminName: 'Nandhi Admin',
    totalMembers: 24,
    activeMembers: 18,
    expiredMembers: 6,
    totalPayments: 31,
    totalPaymentAmount: 125000,
    collectionPeriodStart: periodStart,
    collectionPeriodEnd: periodEnd,
    totalTransformations: 8,
  );

  blocTest<AdminDashboardCubit, AdminDashboardState>(
    'loads admin dashboard metrics',
    build: () =>
        AdminDashboardCubit(_AdminDashboardRepository(dashboard: dashboard)),
    act: (cubit) => cubit.load(periodStart: periodStart),
    expect: () => [
      AdminDashboardState(
        status: AdminDashboardStatus.loading,
        periodStart: periodStart,
      ),
      AdminDashboardState(
        status: AdminDashboardStatus.success,
        dashboard: dashboard,
        periodStart: periodStart,
      ),
    ],
  );

  blocTest<AdminDashboardCubit, AdminDashboardState>(
    'shows an error when the admin document is missing',
    build: () => AdminDashboardCubit(
      _AdminDashboardRepository(
        dashboard: dashboard,
        failure: AuthFailure('Admin profile not found'),
      ),
    ),
    act: (cubit) => cubit.load(periodStart: periodStart),
    expect: () => [
      AdminDashboardState(
        status: AdminDashboardStatus.loading,
        periodStart: periodStart,
      ),
      AdminDashboardState(
        status: AdminDashboardStatus.failure,
        message: 'Admin profile not found',
        periodStart: periodStart,
      ),
    ],
  );
}

class _AdminDashboardRepository implements AuthRepository {
  const _AdminDashboardRepository({required this.dashboard, this.failure});

  final AdminDashboard dashboard;
  final AuthFailure? failure;

  @override
  Future<AdminDashboard> getCurrentAdminDashboard({
    DateTime? periodStart,
  }) async {
    if (failure case final value?) throw value;
    return dashboard;
  }

  @override
  Future<void> changePassword(String newPassword) async {}

  @override
  Future<MemberDashboard> getCurrentMemberDashboard() {
    throw UnimplementedError();
  }

  @override
  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {}

  @override
  Future<MemberSession> signInMember({
    required String phone,
    required String password,
  }) async =>
      const MemberSession(memberId: 'member-test', mustChangePassword: false);

  @override
  Future<void> signOut() async {}
}
