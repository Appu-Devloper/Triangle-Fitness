import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/core/theme/app_theme.dart';
import 'package:triangle_fitness/features/home/domain/entities/gym_content.dart';
import 'package:triangle_fitness/features/home/domain/entities/gym_profile.dart';
import 'package:triangle_fitness/features/home/domain/entities/home_action.dart';
import 'package:triangle_fitness/features/home/domain/entities/public_subscription_plan.dart';
import 'package:triangle_fitness/features/home/domain/entities/public_transformation.dart';
import 'package:triangle_fitness/features/home/domain/repositories/external_link_repository.dart';
import 'package:triangle_fitness/features/home/domain/repositories/gym_repository.dart';
import 'package:triangle_fitness/features/home/domain/usecases/get_gym_content.dart';
import 'package:triangle_fitness/features/home/domain/usecases/open_external_link.dart';
import 'package:triangle_fitness/features/home/presentation/bloc/home_bloc.dart';
import 'package:triangle_fitness/features/home/presentation/pages/home_page.dart';

void main() {
  testWidgets('renders public Firestore content without authentication', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const content = GymContent(
      programs: [],
      equipment: [],
      profile: GymProfile(
        gymName: 'Triangle Fitness KRS',
        ownerName: 'Nandhi',
        phone: '7019997208',
        address: 'KRS Road',
        openingTime: '5:00 AM',
        closingTime: '10:00 PM',
        whatsappNumber: '917019997208',
      ),
      subscriptionPlans: [
        PublicSubscriptionPlan(
          id: 'monthly',
          name: 'Monthly',
          durationDays: 30,
          price: 1196,
        ),
      ],
      transformations: [
        PublicTransformation(
          id: 'one',
          name: 'Arun',
          title: 'Stronger in 12 weeks',
          description: 'Consistent strength and conditioning.',
          weightBeforeKg: 92,
          weightAfterKg: 80,
          durationText: '12 weeks',
          displayOrder: 1,
        ),
      ],
    );
    final bloc = HomeBloc(
      getGymContent: GetGymContent(const _GymRepository(content)),
      openExternalLink: OpenExternalLink(const _LinksRepository()),
    )..add(const HomeStarted());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<HomeBloc>.value(
        value: bloc,
        child: MaterialApp(theme: AppTheme.dark, home: const HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TRIANGLE FITNESS KRS'), findsWidgets);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
    expect(find.text('₹1196'), findsOneWidget);
    expect(find.text('PLAN PRICE'), findsOneWidget);
    expect(find.text('CHOOSE PLAN'), findsOneWidget);
    expect(find.text('OPENING HOURS'), findsOneWidget);
    expect(find.text('5:00 AM - 10:00 PM'), findsOneWidget);
    expect(find.text('EMAIL'), findsNothing);
    expect(find.text('MEMBER LOGIN'), findsWidgets);
  });

  testWidgets('shows public empty states', (tester) async {
    final bloc = HomeBloc(
      getGymContent: GetGymContent(
        const _GymRepository(GymContent(programs: [], equipment: [])),
      ),
      openExternalLink: OpenExternalLink(const _LinksRepository()),
    )..add(const HomeStarted());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<HomeBloc>.value(
        value: bloc,
        child: MaterialApp(theme: AppTheme.dark, home: const HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No plans available'), findsOneWidget);
    expect(find.text('TRANSFORMATIONS'), findsNothing);
  });
}

class _GymRepository implements GymRepository {
  const _GymRepository(this.content);

  final GymContent content;

  @override
  Future<GymContent> getContent() async => content;
}

class _LinksRepository implements ExternalLinkRepository {
  const _LinksRepository();

  @override
  Future<bool> open(ExternalAction action) async => true;
}
