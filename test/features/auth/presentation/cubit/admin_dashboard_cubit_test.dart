import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_session.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/admin_dashboard_cubit.dart';

void main() {
  const dashboard = AdminDashboard(
    adminName: 'Nandhi Admin',
    totalMembers: 24,
    activeMembers: 18,
    expiredMembers: 6,
    totalPayments: 31,
    totalPaymentAmount: 125000,
    totalTransformations: 8,
  );

  blocTest<AdminDashboardCubit, AdminDashboardState>(
    'loads admin dashboard metrics',
    build: () =>
        AdminDashboardCubit(_AdminDashboardRepository(dashboard: dashboard)),
    act: (cubit) => cubit.load(),
    expect: () => const [
      AdminDashboardState(status: AdminDashboardStatus.loading),
      AdminDashboardState(
        status: AdminDashboardStatus.success,
        dashboard: dashboard,
      ),
    ],
  );

  blocTest<AdminDashboardCubit, AdminDashboardState>(
    'shows an error when the admin document is missing',
    build: () => AdminDashboardCubit(
      const _AdminDashboardRepository(
        dashboard: dashboard,
        failure: AuthFailure('Admin profile not found'),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => const [
      AdminDashboardState(status: AdminDashboardStatus.loading),
      AdminDashboardState(
        status: AdminDashboardStatus.failure,
        message: 'Admin profile not found',
      ),
    ],
  );
}

class _AdminDashboardRepository implements AuthRepository {
  const _AdminDashboardRepository({required this.dashboard, this.failure});

  final AdminDashboard dashboard;
  final AuthFailure? failure;

  @override
  Future<AdminDashboard> getCurrentAdminDashboard() async {
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
