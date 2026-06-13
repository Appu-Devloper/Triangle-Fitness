import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/member_dashboard_page.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/member_login_page.dart';
import 'package:triangle_fitness/features/auth/presentation/widgets/auth_page_shell.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(context.read<AuthRepository>()),
      child: _ChangePasswordView(memberId: memberId),
    );
  }
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView({required this.memberId});

  final String memberId;

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    context.read<AuthCubit>().changePassword(
      newPassword: _passwordController.text,
      memberId: widget.memberId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.failure &&
            state.destination == AuthDestination.memberLogin) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message ?? 'Please log in again.')),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const MemberLoginPage()),
          );
          return;
        }
        if (state.status == AuthStatus.success &&
            state.destination == AuthDestination.home) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }
        if (state.status == AuthStatus.success &&
            state.destination == AuthDestination.memberDashboard &&
            state.memberId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const MemberDashboardPage(),
            ),
          );
        }
      },
      builder: (context, state) {
        final loading = state.status == AuthStatus.loading;
        return AuthPageShell(
          eyebrow: 'ACCOUNT SECURITY',
          title: 'SET A NEW\nPASSWORD.',
          description:
              'Choose a private password before continuing to your member dashboard.',
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _passwordController,
                    label: 'New password',
                    icon: Icons.lock_reset_rounded,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (value) => value == null || value.length < 6
                        ? 'Use at least 6 characters.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _confirmController,
                    label: 'Confirm password',
                    icon: Icons.verified_user_outlined,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (value) => value != _passwordController.text
                        ? 'Passwords do not match.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  if (state.status == AuthStatus.failure &&
                      state.message != null) ...[
                    Text(
                      state.message!,
                      key: const Key('change-password-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
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
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(loading ? 'CHANGING...' : 'CHANGE PASSWORD'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: loading
                        ? null
                        : () => context.read<AuthCubit>().signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('LOG OUT'),
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
