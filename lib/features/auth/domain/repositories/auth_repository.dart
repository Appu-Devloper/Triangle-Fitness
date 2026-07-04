import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_session.dart';

abstract interface class AuthRepository {
  Future<MemberSession> signInMember({
    required String phone,
    required String password,
  });

  Future<void> signInAdmin({required String email, required String password});

  Future<void> changePassword(String newPassword);

  Future<MemberDashboard> getCurrentMemberDashboard();

  Future<AdminDashboard> getCurrentAdminDashboard({DateTime? periodStart});

  Future<void> signOut();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthenticationRequiredFailure extends AuthFailure {
  const AuthenticationRequiredFailure(super.message);
}
