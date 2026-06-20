import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/admin_dashboard_page.dart';
import 'package:triangle_fitness/features/auth/presentation/widgets/auth_page_shell.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(context.read<AuthRepository>()),
      child: const _AdminLoginView(),
    );
  }
}

class _AdminLoginView extends StatefulWidget {
  const _AdminLoginView();

  @override
  State<_AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<_AdminLoginView> {
  static const _adminEmail = 'trianglefitness.krs@gmail.com';

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    context.read<AuthCubit>().loginAdmin(
      email: _adminEmail,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.success &&
            state.destination == AuthDestination.adminDashboard) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const AdminDashboardPage()),
          );
        }
      },
      builder: (context, state) {
        final loading = state.status == AuthStatus.loading;
        return AuthPageShell(
          eyebrow: 'RESTRICTED ACCESS',
          title: 'Admin Login',
          description: 'Authorized Triangle Fitness administrators only.',
          backTooltip: 'Back to Home',
          onBack: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.alternate_email_rounded,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Email',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              const Text(_adminEmail),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  if (state.status == AuthStatus.failure &&
                      state.message != null) ...[
                    Container(
                      key: const Key('admin-login-error'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3242B).withValues(alpha: 0.1),
                        border: Border.all(
                          color: const Color(0xFFE3242B).withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFE3242B),
                            size: 18,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              state.message!,
                              style: const TextStyle(
                                color: Color(0xFFFFA8AB),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: loading ? null : _submit,
                    icon: loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.admin_panel_settings_outlined),
                    label: Text(loading ? 'VERIFYING...' : 'ADMIN LOGIN'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
