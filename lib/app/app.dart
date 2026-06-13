import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/core/services/firebase_initializer.dart';
import 'package:triangle_fitness/core/services/url_launcher_service.dart';
import 'package:triangle_fitness/core/theme/app_theme.dart';
import 'package:triangle_fitness/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:triangle_fitness/features/auth/data/repositories/firebase_member_management_repository.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';
import 'package:triangle_fitness/features/home/data/repositories/external_link_repository_impl.dart';
import 'package:triangle_fitness/features/home/data/repositories/gym_repository_impl.dart';
import 'package:triangle_fitness/features/home/domain/usecases/get_gym_content.dart';
import 'package:triangle_fitness/features/home/domain/usecases/open_external_link.dart';
import 'package:triangle_fitness/features/home/presentation/bloc/home_bloc.dart';
import 'package:triangle_fitness/features/home/presentation/pages/home_page.dart';

class TriangleFitnessApp extends StatelessWidget {
  const TriangleFitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final gymRepository = GymRepositoryImpl();
    final externalLinkRepository = ExternalLinkRepositoryImpl(
      launcher: UrlLauncherService(),
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (_) =>
              FirebaseAuthRepository(initializer: FirebaseInitializer.instance),
        ),
        RepositoryProvider<MemberManagementRepository>(
          create: (_) => FirebaseMemberManagementRepository(
            initializer: FirebaseInitializer.instance,
          ),
        ),
      ],
      child: BlocProvider(
        create: (_) => HomeBloc(
          getGymContent: GetGymContent(gymRepository),
          openExternalLink: OpenExternalLink(externalLinkRepository),
        )..add(const HomeStarted()),
        child: MaterialApp(
          title: 'Triangle Fitness',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const HomePage(),
        ),
      ),
    );
  }
}
