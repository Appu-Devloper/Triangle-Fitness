import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/main.dart';

void main() {
  testWidgets('renders the desktop gym landing page', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TriangleFitnessApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('BUILD YOUR'), findsOneWidget);
    expect(find.text('START TRAINING'), findsOneWidget);
    expect(find.text('PROGRAMS'), findsOneWidget);
  });

  testWidgets('renders the mobile gym landing page', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TriangleFitnessApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('BUILD YOUR'), findsOneWidget);
    expect(find.byTooltip('Open menu'), findsOneWidget);
  });

  testWidgets('desktop navigation scrolls every section below the header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TriangleFitnessApp());
    await tester.pumpAndSettle();

    await _expectDesktopNavigation(
      tester,
      button: 'PROGRAMS',
      sectionTitle: 'ONE GYM.\nMORE WAYS TO MOVE.',
    );
    await _expectDesktopNavigation(
      tester,
      button: 'EQUIPMENT',
      sectionTitle: 'EQUIPMENT THAT\nMEANS BUSINESS.',
    );
    await _expectDesktopNavigation(
      tester,
      button: 'WHY US',
      sectionTitle: 'WHAT MEMBERS VALUE',
    );
    await _expectDesktopNavigation(
      tester,
      button: 'LOCATION',
      sectionTitle: 'YOUR NEXT REP\nSTARTS HERE.',
    );
  });

  testWidgets('mobile drawer navigation closes and scrolls to location', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TriangleFitnessApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LOCATION'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR NEXT REP\nSTARTS HERE.'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
    expect(
      tester.getTopLeft(find.text('YOUR NEXT REP\nSTARTS HERE.')).dy,
      inInclusiveRange(78, 350),
    );
  });
}

Future<void> _expectDesktopNavigation(
  WidgetTester tester, {
  required String button,
  required String sectionTitle,
}) async {
  await tester.tap(find.text(button));
  await tester.pumpAndSettle();

  final title = find.text(sectionTitle);
  expect(title, findsOneWidget);
  expect(tester.getTopLeft(title).dy, inInclusiveRange(78, 350));
}
