import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/core/theme/app_theme.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_session.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/change_password_page.dart';

void main() {
  testWidgets('shows change password fields and actions', (tester) async {
    await _pumpPage(tester, _PageAuthRepository());

    expect(find.text('New password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('CHANGE PASSWORD'), findsOneWidget);
    expect(find.text('LOG OUT'), findsOneWidget);
  });

  testWidgets('validates password length and confirmation', (tester) async {
    await _pumpPage(tester, _PageAuthRepository());

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '12345');
    await tester.enterText(fields.at(1), 'different');
    await _tapVisible(tester, find.text('CHANGE PASSWORD'));
    await tester.pump();

    expect(find.text('Use at least 6 characters.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('shows the full Firebase password update error', (tester) async {
    await _pumpPage(
      tester,
      _PageAuthRepository(
        changePasswordFailure: const AuthFailure(
          'requires-recent-login: This operation requires recent authentication.',
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'new-secret');
    await tester.enterText(fields.at(1), 'new-secret');
    await _tapVisible(tester, find.text('CHANGE PASSWORD'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'requires-recent-login: This operation requires recent authentication.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('returns an expired session to member login with an error', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      _PageAuthRepository(
        changePasswordFailure: const AuthenticationRequiredFailure(
          'Your session has expired. Please log in again.',
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'new-secret');
    await tester.enterText(fields.at(1), 'new-secret');
    await _tapVisible(tester, find.text('CHANGE PASSWORD'));
    await tester.pumpAndSettle();

    expect(find.text('Member Login'), findsOneWidget);
    expect(
      find.text('Your session has expired. Please log in again.'),
      findsOneWidget,
    );
  });

  testWidgets('signs out from the change password page', (tester) async {
    final repository = _PageAuthRepository();
    await _pumpPage(tester, repository);

    await _tapVisible(tester, find.text('LOG OUT'));
    await tester.pumpAndSettle();

    expect(repository.didSignOut, isTrue);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  _PageAuthRepository repository,
) async {
  await tester.pumpWidget(
    RepositoryProvider<AuthRepository>.value(
      value: repository,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const ChangePasswordPage(memberId: 'member-test'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

class _PageAuthRepository implements AuthRepository {
  _PageAuthRepository({this.changePasswordFailure});

  final AuthFailure? changePasswordFailure;
  bool didSignOut = false;

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
  Future<AdminDashboard> getCurrentAdminDashboard({DateTime? periodStart}) {
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
  Future<void> signOut() async {
    didSignOut = true;
  }
}
