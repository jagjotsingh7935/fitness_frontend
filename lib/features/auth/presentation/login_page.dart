import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../injection_container.dart';
import 'bloc/login_cubit.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({
    super.key,
    this.isAdminLogin = false,
  });

  final bool isAdminLogin;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InjectionContainer.sl<LoginCubit>(),
      child: _LoginView(isAdminLogin: isAdminLogin),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView({this.isAdminLogin = false});

  final bool isAdminLogin;

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(BuildContext context) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final cubit = context.read<LoginCubit>();
    await cubit.submit(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      isAdmin: widget.isAdminLogin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == LoginStatus.failure &&
            (state.errorMessage?.isNotEmpty ?? false)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }

        if (state.status == LoginStatus.success) {
          print('🔐 Login success! User role: ${state.userRole}');
          
          // Route based on role from state
          if (state.userRole == 'admin') {
            print('🔐 Routing to Admin Dashboard');
            context.go(AppRouter.adminPath);
          } else if (state.userRole == 'trainer') {
            print('🔐 Routing to Trainer Dashboard');
            // context.go(AppRouter.trainerPath); // Uncomment when trainer dashboard is ready
              context.go(AppRouter.trainerPath); // Fallback for admi
          } else {
            print('🔐 Routing to Client Dashboard');
            context.go(AppRouter.clientPath);
          }
        }
      },
      child: Scaffold(
        appBar: widget.isAdminLogin
            ? AppBar(
                title: const Text('Admin Sign In'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              )
            : null,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    if (!widget.isAdminLogin) ...[
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      widget.isAdminLogin
                          ? 'Sign in with your admin credentials to manage the platform.'
                          : 'Sign in to continue your fitness journey.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.text.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.username],
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'admin@example.com',
                                ),
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) {
                                    return 'Email is required';
                                  }
                                  final looksLikeEmail =
                                      v.contains('@') && v.contains('.');
                                  if (!looksLikeEmail) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              BlocBuilder<LoginCubit, LoginState>(
                                buildWhen: (p, n) =>
                                    p.obscurePassword != n.obscurePassword ||
                                    p.status != n.status,
                                builder: (context, state) {
                                  return TextFormField(
                                    controller: _passwordController,
                                    obscureText: state.obscurePassword,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _onSubmit(context),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      suffixIcon: IconButton(
                                        onPressed: () => context
                                            .read<LoginCubit>()
                                            .togglePasswordVisibility(),
                                        icon: Icon(
                                          state.obscurePassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      final v = value ?? '';
                                      if (v.isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (v.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              BlocBuilder<LoginCubit, LoginState>(
                                buildWhen: (p, n) => p.status != n.status,
                                builder: (context, state) {
                                  final isBusy =
                                      state.status == LoginStatus.submitting;
                                  return SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: isBusy
                                          ? null
                                          : () => _onSubmit(context),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: isBusy
                                            ? const SizedBox(
                                                key: ValueKey('loading'),
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text(
                                                'Sign In',
                                                key: ValueKey('label'),
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (!widget.isAdminLogin) ...[
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () =>
                                      context.push(AppRouter.loginOtpPath),
                                  child: const Text('Login with OTP'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!widget.isAdminLogin) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.text.withValues(alpha: 0.7),
                                ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                context.push(AppRouter.clientSignupPath),
                            child: Text(
                              'Sign Up',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.isAdminLogin) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go(AppRouter.loginPath),
                          child: const Text('← Back to User Login'),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      'Fitness & Metabolism Coach',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}