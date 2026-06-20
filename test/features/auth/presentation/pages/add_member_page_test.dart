import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/features/auth/domain/entities/create_member_request.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_member.dart';
import 'package:triangle_fitness/features/auth/domain/entities/subscription_plan.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/add_member_page.dart';

void main() {
  testWidgets('shows all member, subscription and payment fields', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepositoryProvider<MemberManagementRepository>.value(
        value: _PageRepository(),
        child: const MaterialApp(home: AddMemberPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ADD MEMBER'), findsOneWidget);
    expect(find.text('Member Code'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Email (optional)'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(find.text('Receipt No / Initial Password'), findsOneWidget);
    expect(find.text('Weight Kg'), findsOneWidget);
    expect(find.text('Height Cm'), findsOneWidget);
    expect(find.text('Subscription Plan'), findsOneWidget);
    expect(find.text('Subscription Start Date'), findsOneWidget);
    expect(find.text('Subscription End Date'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Payment Mode'), findsOneWidget);
    expect(find.text('Payment Status'), findsOneWidget);
    expect(find.text('Member Status'), findsOneWidget);
    expect(find.text('CREATE MEMBER'), findsOneWidget);
    final memberCodeField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Member Code'),
    );
    final receiptField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Receipt No / Initial Password'),
    );
    expect(memberCodeField.decoration?.prefixText, 'TF ');
    expect(receiptField.decoration?.prefixText, 'REC- ');
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a plan auto-fills its amount', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepositoryProvider<MemberManagementRepository>.value(
        value: _PageRepository(),
        child: const MaterialApp(home: AddMemberPage()),
      ),
    );
    await tester.pumpAndSettle();

    final planDropdown = find.byType(DropdownButtonFormField<SubscriptionPlan>);
    await tester.ensureVisible(planDropdown);
    await tester.tap(planDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gold Monthly (30 days)').last);
    await tester.pumpAndSettle();

    final amountField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Amount'),
    );
    expect(amountField.controller?.text, '1500');
  });

  testWidgets('renders without overflow on a mobile viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepositoryProvider<MemberManagementRepository>.value(
        value: _PageRepository(),
        child: const MaterialApp(home: AddMemberPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEW GYM MEMBER'), findsOneWidget);
    expect(find.text('QUICK JUMP'), findsOneWidget);
    expect(find.text('Member Code'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returns success to the admin panel after member creation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _PageRepository();
    await tester.pumpWidget(
      RepositoryProvider<MemberManagementRepository>.value(
        value: repository,
        child: const MaterialApp(home: _AddMemberHost()),
      ),
    );

    await tester.tap(find.text('OPEN ADD MEMBER'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Member Code'),
      'TF001',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Test Member',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone Number'),
      '9876543210',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Receipt No / Initial Password'),
      'REC001',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Weight Kg'),
      '75',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Height Cm'),
      '174',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Address'),
      'KRS Road',
    );

    final planDropdown = find.byType(DropdownButtonFormField<SubscriptionPlan>);
    await tester.ensureVisible(planDropdown);
    await tester.tap(planDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gold Monthly (30 days)').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Select date').first);
    await tester.tap(find.text('Select date').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('CREATE MEMBER'));
    await tester.tap(find.text('CREATE MEMBER'));
    await tester.pumpAndSettle();

    expect(repository.createdRequest, isNotNull);
    expect(find.text('Member created successfully'), findsOneWidget);
  });

  testWidgets('submits null measurements and default payment values', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _PageRepository();
    await tester.pumpWidget(
      RepositoryProvider<MemberManagementRepository>.value(
        value: repository,
        child: const MaterialApp(home: AddMemberPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Member Code'),
      'TF002',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Optional Member',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone Number'),
      '9123456789',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Address'),
      'KRS Road',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Receipt No / Initial Password'),
      'REC002',
    );

    final planDropdown = find.byType(DropdownButtonFormField<SubscriptionPlan>);
    await tester.ensureVisible(planDropdown);
    await tester.tap(planDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gold Monthly (30 days)').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Select date').first);
    await tester.tap(find.text('Select date').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('CREATE MEMBER'));
    await tester.tap(find.text('CREATE MEMBER'));
    await tester.pumpAndSettle();

    expect(repository.createdRequest, isNotNull);
    expect(repository.createdRequest?.weightKg, isNull);
    expect(repository.createdRequest?.heightCm, isNull);
    expect(repository.createdRequest?.paymentMode, 'CASH');
    expect(repository.createdRequest?.paymentStatus, 'PAID');
  });

  testWidgets('normalizes member code and receipt prefixes before submit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _PageRepository();
    await tester.pumpWidget(
      RepositoryProvider<MemberManagementRepository>.value(
        value: repository,
        child: const MaterialApp(home: AddMemberPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Member Code'),
      '007',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Prefix Member',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone Number'),
      '9000000000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Address'),
      'KRS Road',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Receipt No / Initial Password'),
      '1007',
    );

    final planDropdown = find.byType(DropdownButtonFormField<SubscriptionPlan>);
    await tester.ensureVisible(planDropdown);
    await tester.tap(planDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gold Monthly (30 days)').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Select date').first);
    await tester.tap(find.text('Select date').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('CREATE MEMBER'));
    await tester.tap(find.text('CREATE MEMBER'));
    await tester.pumpAndSettle();

    expect(repository.createdRequest?.memberCode, 'TF007');
    expect(repository.createdRequest?.receiptNo, 'REC-1007');
  });
}

class _PageRepository implements MemberManagementRepository {
  CreateMemberRequest? createdRequest;

  @override
  Future<void> createMember(CreateMemberRequest request) async {
    createdRequest = request;
  }

  @override
  Future<List<SubscriptionPlan>> getActiveSubscriptionPlans() async => const [
    SubscriptionPlan(
      id: 'gold',
      name: 'Gold Monthly',
      durationDays: 30,
      price: 1500,
    ),
  ];

  @override
  Future<AdminMember> getMember(String memberId) => throw UnimplementedError();

  @override
  Stream<List<AdminMember>> watchMembers() => const Stream.empty();
}

class _AddMemberHost extends StatefulWidget {
  const _AddMemberHost();

  @override
  State<_AddMemberHost> createState() => _AddMemberHostState();
}

class _AddMemberHostState extends State<_AddMemberHost> {
  String? _message;

  Future<void> _open() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const AddMemberPage()),
    );
    if (mounted) setState(() => _message = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _message == null
            ? FilledButton(
                onPressed: _open,
                child: const Text('OPEN ADD MEMBER'),
              )
            : Text(_message!),
      ),
    );
  }
}
