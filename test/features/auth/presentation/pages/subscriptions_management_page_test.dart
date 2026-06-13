import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/core/theme/app_theme.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/subscriptions_management_page.dart';

void main() {
  testWidgets('renders enhanced subscription catalog and summaries', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(tester);

    expect(find.text('Total Plans'), findsOneWidget);
    expect(find.text('Active Plans'), findsOneWidget);
    expect(find.text('Inactive Plans'), findsOneWidget);
    expect(find.text('Average Price'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('30 days membership'), findsOneWidget);
    expect(find.text('Rs. 1200'), findsOneWidget);
    expect(find.text('Rs. 40 per day'), findsOneWidget);
    expect(find.text('DOC ID  monthly'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('subscription-plan-monthly')),
      findsOneWidget,
    );
    expect(find.text('ACTIVE'), findsNWidgets(2));
    expect(find.text('INACTIVE'), findsOneWidget);
  });

  testWidgets('renders enhanced subscription cards without mobile overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(tester);

    expect(find.text('Monthly'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('subscription-plan-monthly')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: SubscriptionsManagementPage(
        plansStream: Stream.value(const [
          AdminSubscriptionPlan(
            id: 'monthly',
            name: 'Monthly',
            durationDays: 30,
            price: 1200,
            isActive: true,
          ),
          AdminSubscriptionPlan(
            id: 'quarterly',
            name: 'Quarterly',
            durationDays: 90,
            price: 3000,
            isActive: true,
          ),
          AdminSubscriptionPlan(
            id: 'yearly',
            name: 'Yearly',
            durationDays: 365,
            price: 10000,
            isActive: false,
          ),
        ]),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
