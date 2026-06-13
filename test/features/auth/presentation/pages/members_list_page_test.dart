import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_member.dart';
import 'package:triangle_fitness/features/auth/domain/entities/create_member_request.dart';
import 'package:triangle_fitness/features/auth/domain/entities/subscription_plan.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/members_list_page.dart';

void main() {
  testWidgets('shows member rows and required controls', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(tester, _Repository(_members()));

    expect(find.text('Search by name, phone or member code'), findsOneWidget);
    expect(find.text('ALL'), findsOneWidget);
    expect(find.text('ACTIVE'), findsWidgets);
    expect(find.text('INACTIVE'), findsWidgets);
    expect(find.text('EXPIRED'), findsWidgets);
    expect(find.text('Arun Rao'), findsWidgets);
    expect(find.text('TF001'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('Gold Monthly'), findsWidgets);
    expect(find.byType(PaginatedDataTable), findsOneWidget);
    expect(find.text('EXPIRES IN'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
    expect(find.byKey(const Key('add-member-fab')), findsOneWidget);
  });

  testWidgets('paginates the member table', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final members = List.generate(
      12,
      (index) => _member(
        id: 'member-$index',
        code: 'TF${(index + 1).toString().padLeft(3, '0')}',
        name: 'Member ${(index + 1).toString().padLeft(2, '0')}',
        phone: '900000${index.toString().padLeft(4, '0')}',
        status: 'ACTIVE',
        endDate: DateTime.now().add(const Duration(days: 30)),
      ),
    );
    await _pumpPage(tester, _Repository(members));

    expect(find.text('Member 01'), findsOneWidget);
    expect(find.text('Member 10'), findsOneWidget);
    expect(find.text('Member 11'), findsNothing);

    final nextPage = find.byTooltip('Next page');
    await tester.ensureVisible(nextPage);
    await tester.tap(nextPage);
    await tester.pumpAndSettle();

    expect(find.text('Member 01'), findsNothing);
    expect(find.text('Member 11'), findsOneWidget);
    expect(find.text('Member 12'), findsOneWidget);
  });

  testWidgets('searches locally by name', (tester) async {
    await _pumpPage(tester, _Repository(_members()));

    await tester.enterText(find.byKey(const Key('member-search')), 'Meera');
    await tester.pump();

    expect(find.text('Meera K'), findsOneWidget);
    expect(find.text('Arun Rao'), findsNothing);
  });

  testWidgets('searches locally by phone and member code', (tester) async {
    await _pumpPage(tester, _Repository(_members()));

    await tester.enterText(
      find.byKey(const Key('member-search')),
      '9000000000',
    );
    await tester.pump();

    expect(find.text('Meera K'), findsOneWidget);
    expect(find.text('Arun Rao'), findsNothing);

    await tester.enterText(find.byKey(const Key('member-search')), 'TF001');
    await tester.pump();

    expect(find.text('Arun Rao'), findsOneWidget);
    expect(find.text('Meera K'), findsNothing);
  });

  testWidgets('filters active and inactive members locally', (tester) async {
    await _pumpPage(tester, _Repository(_members()));

    await tester.tap(find.widgetWithText(ChoiceChip, 'ACTIVE'));
    await tester.pump();

    expect(find.text('Arun Rao'), findsOneWidget);
    expect(find.text('Meera K'), findsNothing);
    expect(find.text('Expired Member'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'INACTIVE'));
    await tester.pump();

    expect(find.text('Meera K'), findsOneWidget);
    expect(find.text('Arun Rao'), findsNothing);
  });

  testWidgets('expired filter uses the subscription end date', (tester) async {
    await _pumpPage(tester, _Repository(_members()));

    await tester.tap(find.widgetWithText(ChoiceChip, 'EXPIRED'));
    await tester.pump();

    expect(find.text('Expired Member'), findsOneWidget);
    expect(find.text('Arun Rao'), findsNothing);
  });

  testWidgets('shows empty state when no member matches', (tester) async {
    await _pumpPage(tester, _Repository(_members()));

    await tester.enterText(find.byKey(const Key('member-search')), 'unknown');
    await tester.pump();

    expect(find.text('No members found'), findsOneWidget);
  });

  testWidgets('shows a Firestore stream error', (tester) async {
    await _pumpPage(
      tester,
      _Repository(
        const [],
        watchError: const MemberManagementFailure(
          'permission-denied: Missing or insufficient permissions.',
        ),
      ),
    );

    expect(
      find.text('permission-denied: Missing or insufficient permissions.'),
      findsOneWidget,
    );
    expect(find.text('TRY AGAIN'), findsOneWidget);
  });

  testWidgets('opens member details with the selected member id', (
    tester,
  ) async {
    final repository = _Repository(_members());
    await _pumpPage(tester, repository);

    await tester.tap(find.text('Arun Rao'));
    await tester.pumpAndSettle();

    expect(repository.requestedMemberId, 'one');
    expect(find.text('MEMBER DETAILS'), findsOneWidget);
    expect(find.text('Arun Rao'), findsWidgets);
  });

  testWidgets('add member action opens the form', (tester) async {
    await _pumpPage(tester, _Repository(_members()));

    await tester.tap(find.byKey(const Key('add-member-fab')));
    await tester.pumpAndSettle();

    expect(find.text('NEW GYM MEMBER'), findsOneWidget);
  });

  testWidgets('renders without overflow on mobile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(tester, _Repository(_members()));

    expect(find.text('Arun Rao'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(WidgetTester tester, _Repository repository) async {
  await tester.pumpWidget(
    RepositoryProvider<MemberManagementRepository>.value(
      value: repository,
      child: const MaterialApp(home: MembersListPage()),
    ),
  );
  await tester.pumpAndSettle();
}

List<AdminMember> _members() => [
  _member(
    id: 'one',
    code: 'TF001',
    name: 'Arun Rao',
    phone: '9876543210',
    status: 'ACTIVE',
    endDate: DateTime.now().add(const Duration(days: 30)),
  ),
  _member(
    id: 'two',
    code: 'TF002',
    name: 'Meera K',
    phone: '9000000000',
    status: 'INACTIVE',
    endDate: DateTime.now().add(const Duration(days: 20)),
  ),
  _member(
    id: 'three',
    code: 'TF003',
    name: 'Expired Member',
    phone: '8000000000',
    status: 'ACTIVE',
    endDate: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

AdminMember _member({
  required String id,
  required String code,
  required String name,
  required String phone,
  required String status,
  required DateTime endDate,
}) {
  return AdminMember(
    id: id,
    memberCode: code,
    name: name,
    phone: phone,
    email: '$code@example.com',
    address: 'KRS Road',
    receiptNo: 'REC001',
    weightKg: 75,
    heightCm: 174,
    planName: 'Gold Monthly',
    subscriptionStartDate: DateTime.now(),
    subscriptionEndDate: endDate,
    subscriptionAmount: 1500,
    paymentStatus: 'PAID',
    status: status,
  );
}

class _Repository implements MemberManagementRepository {
  _Repository(this.members, {this.watchError});

  final List<AdminMember> members;
  final Object? watchError;
  String? requestedMemberId;

  @override
  Stream<List<AdminMember>> watchMembers() async* {
    if (watchError != null) throw watchError!;
    yield members;
  }

  @override
  Future<AdminMember> getMember(String memberId) async {
    requestedMemberId = memberId;
    return members.firstWhere((member) => member.id == memberId);
  }

  @override
  Future<void> createMember(CreateMemberRequest request) async {}

  @override
  Future<List<SubscriptionPlan>> getActiveSubscriptionPlans() async => const [
    SubscriptionPlan(
      id: 'gold',
      name: 'Gold Monthly',
      durationDays: 30,
      price: 1500,
    ),
  ];
}
