import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/auth_cubit.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(context.read<AuthRepository>()),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.success &&
              state.destination == AuthDestination.home) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          if (state.status == AuthStatus.failure && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.ink,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Image.asset(
                'assets/logo.png',
                width: 170,
                height: 52,
                fit: BoxFit.cover,
              ),
              actions: [
                TextButton.icon(
                  onPressed: state.status == AuthStatus.loading
                      ? null
                      : context.read<AuthCubit>().signOut,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('SIGN OUT'),
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: const Color(0xFF2A2D30)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 34, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          eyebrow,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 15,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
