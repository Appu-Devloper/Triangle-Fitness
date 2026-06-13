import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_session.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/member_dashboard_cubit.dart';

void main() {
  test('marks a subscription ending yesterday as expired', () {
    final dashboard = _dashboard(endDate: DateTime(2026, 6, 12, 23, 59));

    expect(
      dashboard.subscriptionStatusFor(DateTime(2026, 6, 13, 1)),
      'Expired',
    );
  });

  test('marks a subscription ending today as active', () {
    final dashboard = _dashboard(endDate: DateTime(2026, 6, 13));

    expect(
      dashboard.subscriptionStatusFor(DateTime(2026, 6, 13, 23, 59)),
      'Active',
    );
  });

  test('shows the number of days until membership expiry', () {
    final dashboard = _dashboard(endDate: DateTime(2026, 6, 23));

    expect(dashboard.expiresInFor(DateTime(2026, 6, 13)), '10 days');
  });

  test('shows how long ago a membership expired', () {
    final dashboard = _dashboard(endDate: DateTime(2026, 6, 11));

    expect(dashboard.expiresInFor(DateTime(2026, 6, 13)), 'Expired 2 days ago');
  });

  blocTest<MemberDashboardCubit, MemberDashboardState>(
    'loads the current member dashboard',
    build: () =>
        MemberDashboardCubit(_DashboardRepository(dashboard: _dashboard())),
    act: (cubit) => cubit.load(),
    expect: () => [
      const MemberDashboardState(status: MemberDashboardStatus.loading),
      MemberDashboardState(
        status: MemberDashboardStatus.success,
        dashboard: _dashboard(),
      ),
    ],
  );

  blocTest<MemberDashboardCubit, MemberDashboardState>(
    'shows a missing member document error',
    build: () => MemberDashboardCubit(
      _DashboardRepository(
        dashboard: _dashboard(),
        loadFailure: const AuthFailure('Member profile not found'),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => const [
      MemberDashboardState(status: MemberDashboardStatus.loading),
      MemberDashboardState(
        status: MemberDashboardStatus.failure,
        message: 'Member profile not found',
      ),
    ],
  );
}

MemberDashboard _dashboard({DateTime? endDate}) {
  return MemberDashboard(
    memberId: 'member-1',
    memberCode: 'TF001',
    name: 'Test Member',
    phone: '9876543210',
    email: 'member@example.com',
    address: 'KRS Road',
    receiptNo: 'R1001',
    weight: '70 kg',
    height: '175 cm',
    status: 'Active',
    planName: 'Annual',
    amount: '12000',
    paymentStatus: 'Paid',
    subscriptionStatus: 'Active',
    startDate: DateTime(2026, 1, 1),
    endDate: endDate ?? DateTime(2026, 12, 31),
  );
}

class _DashboardRepository implements AuthRepository {
  _DashboardRepository({required this.dashboard, this.loadFailure});

  final MemberDashboard dashboard;
  final AuthFailure? loadFailure;

  @override
  Future<MemberDashboard> getCurrentMemberDashboard() async {
    if (loadFailure case final failure?) throw failure;
    return dashboard;
  }

  @override
  Future<AdminDashboard> getCurrentAdminDashboard() {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword(String newPassword) async {}

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
      const MemberSession(memberId: 'member-1', mustChangePassword: false);

  @override
  Future<void> signOut() async {}
}
