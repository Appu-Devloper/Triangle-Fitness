import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_session.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/auth_cubit.dart';

void main() {
  test('converts a member phone number to the Firebase email format', () {
    expect(
      FirebaseAuthRepository.memberEmailFromPhone('9876543210'),
      '9876543210@trianglefitness.local',
    );
  });

  test('formats Firestore weightKg and heightCm measurements', () {
    expect(FirebaseAuthRepository.measurementDisplay(75, 'kg'), '75 kg');
    expect(FirebaseAuthRepository.measurementDisplay(174, 'cm'), '174 cm');
    expect(FirebaseAuthRepository.measurementDisplay('72 kg', 'kg'), '72 kg');
    expect(FirebaseAuthRepository.measurementDisplay(null, 'kg'), 'Not added');
  });

  blocTest<AuthCubit, AuthState>(
    'routes a regular member to the member dashboard',
    build: () => AuthCubit(
      const _FakeAuthRepository(
        session: MemberSession(memberId: 'member-1', mustChangePassword: false),
      ),
    ),
    act: (cubit) => cubit.loginMember(phone: '9876543210', password: 'secret'),
    expect: () => const [
      AuthState(status: AuthStatus.loading),
      AuthState(
        status: AuthStatus.success,
        destination: AuthDestination.memberDashboard,
        memberId: 'member-1',
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'routes a member with a temporary password to change password',
    build: () => AuthCubit(
      const _FakeAuthRepository(
        session: MemberSession(memberId: 'member-2', mustChangePassword: true),
      ),
    ),
    act: (cubit) => cubit.loginMember(phone: '9876543210', password: 'secret'),
    expect: () => const [
      AuthState(status: AuthStatus.loading),
      AuthState(
        status: AuthStatus.success,
        destination: AuthDestination.changePassword,
        memberId: 'member-2',
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'routes an authorized admin to the admin dashboard',
    build: () => AuthCubit(
      const _FakeAuthRepository(
        session: MemberSession(memberId: 'unused', mustChangePassword: false),
      ),
    ),
    act: (cubit) => cubit.loginAdmin(
      email: 'admin@trianglefitness.com',
      password: 'secret',
    ),
    expect: () => const [
      AuthState(status: AuthStatus.loading),
      AuthState(
        status: AuthStatus.success,
        destination: AuthDestination.adminDashboard,
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'shows the exact denied message for an unauthorized admin',
    build: () => AuthCubit(
      const _FakeAuthRepository(
        session: MemberSession(memberId: 'unused', mustChangePassword: false),
        adminFailure: AuthFailure('Admin access denied'),
      ),
    ),
    act: (cubit) => cubit.loginAdmin(
      email: 'blocked@trianglefitness.com',
      password: 'secret',
    ),
    expect: () => const [
      AuthState(status: AuthStatus.loading),
      AuthState(status: AuthStatus.failure, message: 'Admin access denied'),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'preserves the admin Firestore error code and message',
    build: () => AuthCubit(
      const _FakeAuthRepository(
        session: MemberSession(memberId: 'unused', mustChangePassword: false),
        adminFailure: AuthFailure(
          'permission-denied: Missing or insufficient permissions.',
        ),
      ),
    ),
    act: (cubit) => cubit.loginAdmin(
      email: 'admin@trianglefitness.com',
      password: 'secret',
    ),
    expect: () => const [
      AuthState(status: AuthStatus.loading),
      AuthState(
        status: AuthStatus.failure,
        message: 'permission-denied: Missing or insufficient permissions.',
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'routes to the member dashboard after changing password',
    build: () => AuthCubit(
      const _FakeAuthRepository(
        session: MemberSession(memberId: 'member-3', mustChangePassword: true),
      ),
    ),
    act: (cubit) =>
        cubit.changePassword(newPassword: 'new-secret', memberId: 'member-3'),
    expect: () => const [
      AuthState(status: AuthStatus.loading),
      AuthState(
        status: AuthStatus.success,
        destination: AuthDestination.memberDashboard,
        memberId: 'member-3',
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'exposes the member login failure message',
    build: () => AuthCubit(
      const _FakeAuthRepository(
        session: MemberSession(memberId: 'unused', mustChangePassword: false),
        memberFailure: AuthFailure('Member login record not found'),
      ),
    ),
    act: (cubit) => cubit.loginMember(phone: '9876543210', password: 'secret'),
    expect: () => const [
      AuthState(status: AuthStatus.loading),
      AuthState(
        status: AuthStatus.failure,
        message: 'Member login record not found',
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'preserves the Firestore error code and message',
    build: () => AuthCubit(
      const _FakeAuthRepository(
        session: MemberSession(memberId: 'unused', mustChangePassword: false),
        memberFailure: AuthFailure(
          'permission-denied: Missing or insufficient permissions.',
        ),
      ),
    ),
    act: (cubit) => cubit.loginMember(phone: '9876543210', password: 'secret'),
    expect: () => const [
      AuthState(status: AuthStatus.loading),
      AuthState(
        status: AuthStatus.failure,
        message: 'permission-denied: Missing or insufficient permissions.',
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'exposes the full Firebase password update error',
    build: () => AuthCubit(
      const _FakeAuthRepository(
        session: MemberSession(memberId: 'member-4', mustChangePassword: true),
        changePasswordFailure: AuthFailure(
          'requires-recent-login: This operation is sensitive and requires recent authentication.',
        ),
      ),
    ),
    act: (cubit) =>
        cubit.changePassword(newPassword: 'new-secret', memberId: 'member-4'),
    expect: () => const [
      AuthState(status: AuthStatus.loading),
      AuthState(
        status: AuthStatus.failure,
        message:
            'requires-recent-login: This operation is sensitive and requires recent authentication.',
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'routes an expired change-password session to member login',
    build: () => AuthCubit(
      const _FakeAuthRepository(
        session: MemberSession(memberId: 'member-5', mustChangePassword: true),
        changePasswordFailure: AuthenticationRequiredFailure(
          'Your session has expired. Please log in again.',
        ),
      ),
    ),
    act: (cubit) =>
        cubit.changePassword(newPassword: 'new-secret', memberId: 'member-5'),
    expect: () => const [
      AuthState(status: AuthStatus.loading),
      AuthState(
        status: AuthStatus.failure,
        destination: AuthDestination.memberLogin,
        message: 'Your session has expired. Please log in again.',
      ),
    ],
  );
}

class _FakeAuthRepository implements AuthRepository {
  const _FakeAuthRepository({
    required this.session,
    this.memberFailure,
    this.changePasswordFailure,
    this.adminFailure,
  });

  final MemberSession session;
  final AuthFailure? memberFailure;
  final AuthFailure? changePasswordFailure;
  final AuthFailure? adminFailure;

  @override
  Future<void> changePassword(String newPassword) async {
    if (changePasswordFailure case final failure?) {
      throw failure;
    }
  }

  @override
  Future<MemberDashboard> getCurrentMemberDashboard() {
    throw UnimplementedError();
  }

  @override
  Future<AdminDashboard> getCurrentAdminDashboard() {
    throw UnimplementedError();
  }

  @override
  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    if (adminFailure case final failure?) {
      throw failure;
    }
  }

  @override
  Future<MemberSession> signInMember({
    required String phone,
    required String password,
  }) async {
    if (memberFailure case final failure?) {
      throw failure;
    }
    return session;
  }

  @override
  Future<void> signOut() async {}
}
