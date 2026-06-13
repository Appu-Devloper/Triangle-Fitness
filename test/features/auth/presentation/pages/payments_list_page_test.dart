import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/core/theme/app_theme.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/payments_list_page.dart';

void main() {
  testWidgets('shows payment details, filters and summary totals', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(tester, Stream.value(_payments()));

    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('Total Collection'), findsOneWidget);
    expect(find.text('Paid Collection'), findsOneWidget);
    expect(find.text('Pending Amount'), findsOneWidget);
    expect(find.text('Total Payments Count'), findsOneWidget);
    _expectSummary('Total Collection', 'Rs. 3000');
    _expectSummary('Paid Collection', 'Rs. 2000');
    _expectSummary('Pending Amount', 'Rs. 1000');
    _expectSummary('Total Payments Count', '2');

    final firstPayment = find.byKey(const ValueKey('payment-one'));
    expect(
      find.descendant(of: firstPayment, matching: find.text('REC-1001')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: firstPayment, matching: find.text('TF001')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: firstPayment, matching: find.text('Arun Rao')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: firstPayment, matching: find.text('9876543210')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: firstPayment, matching: find.text('UPI')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: firstPayment, matching: find.text('PAID')),
      findsOneWidget,
    );
    expect(find.text('SUBSCRIPTION START DATE'), findsNWidgets(2));
    expect(find.text('SUBSCRIPTION END DATE'), findsNWidgets(2));
  });

  testWidgets('searches locally across requested payment fields', (
    tester,
  ) async {
    await _pumpPage(tester, Stream.value(_payments()));

    await tester.enterText(
      find.byKey(const Key('payment-search')),
      '9000000000',
    );
    await tester.pump();

    expect(find.text('Meera K'), findsOneWidget);
    expect(find.text('Arun Rao'), findsNothing);

    await tester.enterText(find.byKey(const Key('payment-search')), 'REC-1001');
    await tester.pump();

    expect(find.text('Arun Rao'), findsOneWidget);
    expect(find.text('Meera K'), findsNothing);
  });

  testWidgets('filters by status, mode and date and recalculates summaries', (
    tester,
  ) async {
    await _pumpPage(tester, Stream.value(_payments()));

    await tester.tap(find.byKey(const ValueKey('Payment Status-PENDING')));
    await tester.pump();
    expect(find.text('Meera K'), findsOneWidget);
    expect(find.text('Arun Rao'), findsNothing);
    _expectSummary('Total Collection', 'Rs. 1000');
    _expectSummary('Paid Collection', 'Rs. 0');
    _expectSummary('Pending Amount', 'Rs. 1000');

    await tester.tap(find.byKey(const ValueKey('Payment Status-ALL')));
    await tester.tap(find.byKey(const ValueKey('Payment Mode-CARD')));
    await tester.pump();
    expect(find.text('Meera K'), findsOneWidget);
    expect(find.text('Arun Rao'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('Payment Mode-ALL')));
    final todayFilter = find.byKey(const ValueKey('Payment Date-Today'));
    await tester.ensureVisible(todayFilter);
    await tester.tap(todayFilter);
    await tester.pump();
    expect(find.text('Arun Rao'), findsOneWidget);
    expect(find.text('Meera K'), findsNothing);
  });

  testWidgets('shows the requested empty state', (tester) async {
    await _pumpPage(tester, Stream.value(const []));

    expect(find.text('No payment records found'), findsOneWidget);
    expect(find.text('Rs. 0'), findsNWidgets(3));
  });

  testWidgets('shows loading and stream errors', (tester) async {
    final loading = StreamController<List<PaymentRecord>>();
    addTearDown(loading.close);
    await _pumpPage(tester, loading.stream, settle: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    loading.addError(Exception('permission-denied'));
    await tester.pump();
    expect(
      find.textContaining(
        'Unable to load payments: Exception: permission-denied',
      ),
      findsOneWidget,
    );
    expect(find.text('TRY AGAIN'), findsOneWidget);
  });

  testWidgets('renders payment cards without overflow on mobile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(tester, Stream.value(_payments()));

    expect(find.text('REC-1001'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  Stream<List<PaymentRecord>> stream, {
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: PaymentsListPage(paymentsStream: stream),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

List<PaymentRecord> _payments() {
  final now = DateTime.now();
  return [
    PaymentRecord(
      id: 'one',
      receiptNo: 'REC-1001',
      memberCode: 'TF001',
      memberName: 'Arun Rao',
      phone: '9876543210',
      amount: 2000,
      paymentMode: 'UPI',
      paymentStatus: 'PAID',
      paymentDate: now,
      subscriptionStartDate: DateTime(now.year, now.month, 1),
      subscriptionEndDate: DateTime(now.year, now.month + 1, 1),
    ),
    PaymentRecord(
      id: 'two',
      receiptNo: 'REC-1002',
      memberCode: 'TF002',
      memberName: 'Meera K',
      phone: '9000000000',
      amount: 1000,
      paymentMode: 'CARD',
      paymentStatus: 'PENDING',
      paymentDate: DateTime(now.year, now.month - 1, 15),
      subscriptionStartDate: DateTime(now.year, now.month - 1, 15),
      subscriptionEndDate: DateTime(now.year, now.month, 15),
    ),
  ];
}

void _expectSummary(String label, String value) {
  expect(
    find.descendant(
      of: find.byKey(ValueKey('summary-$label')),
      matching: find.text(value),
    ),
    findsOneWidget,
  );
}
