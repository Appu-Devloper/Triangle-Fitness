import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/change_password_page.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/member_dashboard_page.dart';
import 'package:triangle_fitness/features/auth/presentation/widgets/auth_page_shell.dart';

class MemberLoginPage extends StatelessWidget {
  const MemberLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(context.read<AuthRepository>()),
      child: const _MemberLoginView(),
    );
  }
}

class _MemberLoginView extends StatefulWidget {
  const _MemberLoginView();

  @override
  State<_MemberLoginView> createState() => _MemberLoginViewState();
}

class _MemberLoginViewState extends State<_MemberLoginView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    context.read<AuthCubit>().loginMember(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status != AuthStatus.success || state.memberId == null) {
          return;
        }

        final page = state.destination == AuthDestination.changePassword
            ? ChangePasswordPage(memberId: state.memberId!)
            : const MemberDashboardPage();
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
      },
      builder: (context, state) {
        final loading = state.status == AuthStatus.loading;
        return AuthPageShell(
          eyebrow: 'MEMBER ACCESS',
          title: 'Member Login',
          description:
              'Enter the phone number registered with Triangle Fitness and your password.',
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _phoneController,
                    label: 'Phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: (value) {
                      final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                      if (digits.length != 10) {
                        return 'Enter a valid 10-digit phone number.';
                      }
                      return null;
                    },
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
                  const SizedBox(height: 10),
                  const Text(
                    'First time login? Use your receipt number as password.',
                    style: TextStyle(
                      color: Color(0xFFA3A6AA),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (state.status == AuthStatus.failure &&
                      state.message != null) ...[
                    const SizedBox(height: 18),
                    Container(
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
                  ],
                  const SizedBox(height: 24),
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
                        : const Icon(Icons.login_rounded),
                    label: Text(loading ? 'SIGNING IN...' : 'MEMBER LOGIN'),
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
