import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/core/theme/app_theme.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_session.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/member_login_page.dart';

void main() {
  testWidgets('shows the required member login controls and guidance', (
    tester,
  ) async {
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: const _PageAuthRepository(),
        child: MaterialApp(theme: AppTheme.dark, home: const MemberLoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Member Login'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('MEMBER LOGIN'), findsOneWidget);
    expect(
      find.text('First time login? Use your receipt number as password.'),
      findsOneWidget,
    );
  });
}

class _PageAuthRepository implements AuthRepository {
  const _PageAuthRepository();

  @override
  Future<void> changePassword(String newPassword) async {}

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
