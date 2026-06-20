import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/core/theme/app_theme.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/transformations_management_page.dart';

void main() {
  testWidgets('renders transformation records in a paginated table', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(tester, _records());

    expect(find.byType(PaginatedDataTable), findsOneWidget);
    expect(
      find.byKey(const Key('admin-transformations-table')),
      findsOneWidget,
    );
    expect(find.text('Member 0'), findsOneWidget);
    expect(find.text('TF000'), findsOneWidget);
    expect(find.text('Transformation 0'), findsOneWidget);
    expect(find.text('PUBLISHED'), findsWidgets);
    expect(find.text('Member 11'), findsNothing);

    final nextPage = find.byTooltip('Next page');
    await tester.ensureVisible(nextPage);
    await tester.tap(nextPage);
    await tester.pumpAndSettle();

    expect(find.text('Member 0'), findsNothing);
    expect(find.text('Member 11'), findsOneWidget);
  });

  testWidgets('searches and filters transformation table locally', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(tester, _records().take(4).toList());

    await tester.enterText(
      find.byKey(const Key('transformation-search')),
      'TF003',
    );
    await tester.pumpAndSettle();
    expect(find.text('Member 3'), findsOneWidget);
    expect(find.text('Member 0'), findsNothing);

    await tester.enterText(find.byKey(const Key('transformation-search')), '');
    await tester.tap(find.widgetWithText(ChoiceChip, 'UNPUBLISHED'));
    await tester.pumpAndSettle();
    expect(find.text('Member 1'), findsOneWidget);
    expect(find.text('Member 0'), findsNothing);
  });

  testWidgets('renders transformation table without overflow on mobile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPage(tester, _records().take(2).toList());

    expect(
      find.byKey(const Key('admin-transformations-table')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  List<TransformationRecord> records,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: TransformationsManagementPage(
        transformationsStream: Stream.value(records),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<TransformationRecord> _records() {
  return List.generate(
    12,
    (index) => TransformationRecord(
      id: 'transformation-$index',
      memberId: 'member-$index',
      memberCode: 'TF${index.toString().padLeft(3, '0')}',
      name: 'Member $index',
      title: 'Transformation $index',
      description: 'Consistent training result number $index.',
      weightBeforeKg: 90 - index.toDouble(),
      weightAfterKg: 80 - index.toDouble(),
      heightCm: index.isEven ? 170 + index.toDouble() : null,
      durationText: '12 weeks',
      isPublished: index.isEven,
      displayOrder: index,
      createdAt: DateTime(2026, 6, 13).subtract(Duration(days: index)),
    ),
  );
}
