import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/core/theme/app_theme.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_session.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/admin_login_page.dart';

void main() {
  testWidgets('shows the required admin login controls', (tester) async {
    await _pumpPage(tester, _AdminPageRepository());

    expect(find.text('Admin Login'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('ADMIN LOGIN'), findsOneWidget);
    expect(find.byTooltip('Back to Home'), findsOneWidget);
  });

  testWidgets('shows Admin access denied inline', (tester) async {
    await _pumpPage(
      tester,
      _AdminPageRepository(
        adminFailure: const AuthFailure('Admin access denied'),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'admin@trianglefitness.com');
    await tester.enterText(fields.at(1), 'password');
    await tester.ensureVisible(find.text('ADMIN LOGIN'));
    await tester.tap(find.text('ADMIN LOGIN'));
    await tester.pumpAndSettle();

    expect(find.text('Admin access denied'), findsOneWidget);
    expect(find.byKey(const Key('admin-login-error')), findsOneWidget);
  });

  testWidgets('shows the full Firebase error code and message inline', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      _AdminPageRepository(
        adminFailure: const AuthFailure(
          'permission-denied: Missing or insufficient permissions.',
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'admin@trianglefitness.com');
    await tester.enterText(fields.at(1), 'password');
    await tester.ensureVisible(find.text('ADMIN LOGIN'));
    await tester.tap(find.text('ADMIN LOGIN'));
    await tester.pumpAndSettle();

    expect(
      find.text('permission-denied: Missing or insufficient permissions.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  _AdminPageRepository repository,
) async {
  await tester.pumpWidget(
    RepositoryProvider<AuthRepository>.value(
      value: repository,
      child: MaterialApp(theme: AppTheme.dark, home: const AdminLoginPage()),
    ),
  );
  await tester.pumpAndSettle();
}

class _AdminPageRepository implements AuthRepository {
  _AdminPageRepository({this.adminFailure});

  final AuthFailure? adminFailure;

  @override
  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    if (adminFailure case final failure?) throw failure;
  }

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
  Future<MemberSession> signInMember({
    required String phone,
    required String password,
  }) async =>
      const MemberSession(memberId: 'member-test', mustChangePassword: false);

  @override
  Future<void> signOut() async {}
}
