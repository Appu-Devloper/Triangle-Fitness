import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/core/theme/app_theme.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_session.dart';
import 'package:triangle_fitness/features/auth/domain/entities/create_member_request.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_member.dart';
import 'package:triangle_fitness/features/auth/domain/entities/subscription_plan.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/admin_dashboard_page.dart';

void main() {
  testWidgets('renders admin name, metrics and management actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(tester, _AdminPageRepository());

    expect(find.text('ADMIN DASHBOARD'), findsOneWidget);
    expect(find.text('Welcome, Nandhi Admin'), findsOneWidget);
    expect(find.text('TOTAL MEMBERS'), findsOneWidget);
    expect(find.text('ACTIVE MEMBERS'), findsOneWidget);
    expect(find.text('EXPIRED MEMBERS'), findsOneWidget);
    expect(find.text('TOTAL PAYMENTS'), findsOneWidget);
    expect(find.text('TRANSFORMATIONS'), findsNothing);
    expect(find.text('MEMBERS'), findsOneWidget);
    expect(find.text('ADD MEMBER'), findsOneWidget);
    expect(find.text('PAYMENTS'), findsOneWidget);
    expect(find.text('SUBSCRIPTIONS'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });

  testWidgets('opens a management section from a dashboard action', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(tester, _AdminPageRepository());

    await tester.ensureVisible(find.text('MEMBERS'));
    await tester.tap(find.text('MEMBERS'));
    await tester.pumpAndSettle();

    expect(find.text('Search by name, phone or member code'), findsOneWidget);
  });

  testWidgets('opens the add member form', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(tester, _AdminPageRepository());

    await tester.ensureVisible(find.text('ADD MEMBER'));
    await tester.tap(find.text('ADD MEMBER'));
    await tester.pumpAndSettle();

    expect(find.text('NEW GYM MEMBER'), findsOneWidget);
  });

  testWidgets('renders the admin dashboard on a mobile viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(tester, _AdminPageRepository());

    expect(find.text('Welcome, Nandhi Admin'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(find.text('TOTAL MEMBERS'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-mobile-tab-overview')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an error when the admin profile is missing', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      _AdminPageRepository(
        failure: const AuthFailure('Admin profile not found'),
      ),
    );

    expect(find.text('ADMIN DASHBOARD UNAVAILABLE'), findsOneWidget);
    expect(find.text('Admin profile not found'), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsOneWidget);
  });

  testWidgets('logs out from the admin dashboard', (tester) async {
    final repository = _AdminPageRepository();
    await _pumpPage(tester, repository);

    await tester.tap(find.text('LOG OUT'));
    await tester.pump();
    await tester.pump();

    expect(repository.didSignOut, isTrue);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  _AdminPageRepository repository,
) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: repository),
        RepositoryProvider<MemberManagementRepository>.value(
          value: _MemberManagementRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const AdminDashboardPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _MemberManagementRepository implements MemberManagementRepository {
  @override
  Future<void> createMember(CreateMemberRequest request) async {}

  @override
  Future<List<SubscriptionPlan>> getActiveSubscriptionPlans() async => const [
    SubscriptionPlan(
      id: 'monthly',
      name: 'Monthly',
      durationDays: 30,
      price: 1000,
    ),
  ];

  @override
  Future<AdminMember> getMember(String memberId) => throw UnimplementedError();

  @override
  Stream<List<AdminMember>> watchMembers() => Stream.value(const []);
}

class _AdminPageRepository implements AuthRepository {
  _AdminPageRepository({this.failure});

  final AuthFailure? failure;
  bool didSignOut = false;

  @override
  Future<AdminDashboard> getCurrentAdminDashboard() async {
    if (failure case final value?) throw value;
    return const AdminDashboard(
      adminName: 'Nandhi Admin',
      totalMembers: 24,
      activeMembers: 18,
      expiredMembers: 6,
      totalPayments: 31,
      totalPaymentAmount: 125000,
      totalTransformations: 8,
    );
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
  Future<void> signOut() async {
    didSignOut = true;
  }
}
