import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/core/theme/app_theme.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_payment.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_session.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/member_dashboard_page.dart';

void main() {
  testWidgets('renders member and subscription details', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: _PageRepository(),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const MemberDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Personal information'), findsOneWidget);
    expect(find.text('Subscription overview'), findsOneWidget);
    expect(find.textContaining('TF001'), findsOneWidget);
    expect(find.text('Nandhi'), findsNWidgets(2));
    expect(find.text('Gold Annual'), findsNWidgets(2));
    expect(find.text('PAID'), findsNothing);
    expect(find.text('Paid'), findsNWidgets(2));
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('EXPIRES IN'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
    expect(find.text('LOG OUT'), findsOneWidget);
  });

  testWidgets('renders the redesigned dashboard on a mobile viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: _PageRepository(),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const MemberDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('YOUR FITNESS MEMBERSHIP'), findsOneWidget);
    expect(find.text('Nandhi'), findsNWidgets(2));
    expect(find.text('Gold Annual'), findsNWidgets(2));
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a missing member error state', (tester) async {
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: _PageRepository(
          loadFailure: const AuthFailure('Member profile not found'),
        ),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const MemberDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MEMBER DETAILS UNAVAILABLE'), findsOneWidget);
    expect(find.text('Member profile not found'), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsOneWidget);
  });

  testWidgets('shows member payment history', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: _PageRepository(includePayment: true),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const MemberDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payment history'), findsOneWidget);
    expect(find.text('REC-PAY-1'), findsNWidgets(2));
    expect(find.text('Rs. 2500'), findsOneWidget);
    expect(find.text('UPI'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('SUBSCRIPTION START DATE'), findsOneWidget);
    expect(find.text('SUBSCRIPTION END DATE'), findsOneWidget);
  });
}

class _PageRepository implements AuthRepository {
  _PageRepository({this.loadFailure, this.includePayment = false});

  final AuthFailure? loadFailure;
  final bool includePayment;

  @override
  Future<MemberDashboard> getCurrentMemberDashboard() async {
    if (loadFailure case final failure?) throw failure;
    final now = DateTime.now();
    return MemberDashboard(
      memberId: 'member-1',
      memberCode: 'TF001',
      name: 'Nandhi',
      phone: '7019997208',
      email: 'nandhi@example.com',
      address: 'KRS Road, Hongahalli',
      receiptNo: 'R1001',
      weight: '72 kg',
      height: '175 cm',
      status: 'Active',
      planName: 'Gold Annual',
      amount: '12000',
      paymentStatus: 'Paid',
      subscriptionStatus: 'Active',
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now.add(const Duration(days: 30)),
      payments: includePayment
          ? [
              MemberPayment(
                id: 'payment-1',
                receiptNo: 'REC-PAY-1',
                amount: 2500,
                paymentMode: 'UPI',
                paymentStatus: 'PENDING',
                paymentDate: now,
                subscriptionStartDate: now.subtract(const Duration(days: 30)),
                subscriptionEndDate: now.add(const Duration(days: 30)),
              ),
            ]
          : const [],
    );
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
