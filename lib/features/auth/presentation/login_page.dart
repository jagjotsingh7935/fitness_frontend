import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../injection_container.dart';
import 'bloc/login_cubit.dart';

enum LoginRole { client, trainer, admin }

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
      child: _LoginView(
        initialRole: isAdminLogin ? LoginRole.admin : LoginRole.client,
      ),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView({this.initialRole = LoginRole.client});

  final LoginRole initialRole;

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late LoginRole _activeRole;

  @override
  void initState() {
    super.initState();
    _activeRole = widget.initialRole;
  }

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
      isAdmin: _activeRole == LoginRole.admin,
      expectedRole: _activeRole.name,
    );
  }

  void _switchRole(LoginRole newRole) {
    if (_activeRole == newRole) return;
    setState(() {
      _activeRole = newRole;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isClient = _activeRole == LoginRole.client;
    final isTrainer = _activeRole == LoginRole.trainer;
    final isAdmin = _activeRole == LoginRole.admin;

    final roleTitle = isClient
        ? 'Client Login'
        : isTrainer
            ? 'Trainer Portal'
            : 'Admin Portal';

    final roleSubtitle = isClient
        ? 'Sign in to access your workouts & metabolic coaching.'
        : isTrainer
            ? 'Sign in to manage client workout plans & track progress.'
            : 'Sign in with admin credentials to manage platform & trainers.';

    final roleIcon = isClient
        ? Icons.fitness_center_rounded
        : isTrainer
            ? Icons.sports_rounded
            : Icons.admin_panel_settings_rounded;

    final roleColor = isClient
        ? AppColors.primary
        : isTrainer
            ? const Color(0xFF00E5A0)
            : const Color(0xFFFF7043);

    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == LoginStatus.failure &&
            (state.errorMessage?.isNotEmpty ?? false)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (state.status == LoginStatus.success) {
          final role = state.userRole ?? (isAdmin ? 'admin' : (isTrainer ? 'trainer' : 'client'));

          // Security check: ensure role strictly matches active portal
          if (_activeRole == LoginRole.admin && role != 'admin') return;
          if (_activeRole == LoginRole.trainer && role != 'trainer') return;
          if (_activeRole == LoginRole.client && role != 'client') return;

          if (role == 'admin') {
            context.go(AppRouter.adminPath);
          } else if (role == 'trainer') {
            context.go(AppRouter.trainerPath);
          } else {
            NotificationService().scheduleDailyDietReminder();
            context.go(AppRouter.clientPath);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0D1A),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Brand & Official FLUX Logo
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/flux_icon.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                color: const Color(0xFF131830),
                                child: Icon(roleIcon, size: 40, color: roleColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'FLUX',
                            style: TextStyle(
                              color: Color(0xFFE5C07B),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'MOVE · CONNECT · ELEVATE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      roleTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      roleSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF8E99B7),
                            fontSize: 13,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Main Form Card
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF131830),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF252D5A),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: roleColor.withValues(alpha: 0.08),
                            blurRadius: 20,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.username, AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: const TextStyle(color: Color(0xFF8E99B7)),
                                hintText: isClient ? 'client@example.com' : 'user@example.com',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                                prefixIcon: Icon(
                                  Icons.alternate_email_rounded,
                                  color: roleColor.withValues(alpha: 0.85),
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF0F1326),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF252D5A),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF252D5A),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: roleColor,
                                    width: 1.8,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) return 'Email is required';
                                if (!v.contains('@') || !v.contains('.')) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            BlocBuilder<LoginCubit, LoginState>(
                              buildWhen: (p, n) =>
                                  p.obscurePassword != n.obscurePassword ||
                                  p.status != n.status,
                              builder: (context, state) {
                                return TextFormField(
                                  controller: _passwordController,
                                  obscureText: state.obscurePassword,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _onSubmit(context),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: const TextStyle(color: Color(0xFF8E99B7)),
                                    prefixIcon: Icon(
                                      Icons.lock_outline_rounded,
                                      color: roleColor.withValues(alpha: 0.85),
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () => context
                                          .read<LoginCubit>()
                                          .togglePasswordVisibility(),
                                      icon: Icon(
                                        state.obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: const Color(0xFF8E99B7),
                                        size: 20,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF0F1326),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF252D5A),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF252D5A),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: roleColor,
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    final v = value ?? '';
                                    if (v.isEmpty) return 'Password is required';
                                    if (v.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 22),

                            // Submit Button
                            BlocBuilder<LoginCubit, LoginState>(
                              buildWhen: (p, n) => p.status != n.status,
                              builder: (context, state) {
                                final isBusy = state.status == LoginStatus.submitting;
                                return SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: isBusy ? null : () => _onSubmit(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: roleColor,
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shadowColor: roleColor.withValues(alpha: 0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: isBusy
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              'Sign In to $roleTitle',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Client additional options
                            if (isClient) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => context.push(AppRouter.loginOtpPath),
                                    icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                                    label: const Text('Login with OTP'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Reset/Back to Client button for Trainer/Admin
                            if (!isClient) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => _switchRole(LoginRole.client),
                                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                  label: const Text('Return to Client Login'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF8E99B7),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Client Sign Up link
                    if (isClient) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF8E99B7),
                                ),
                          ),
                          GestureDetector(
                            onTap: () => context.push(AppRouter.clientSignupPath),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 36),

                    // Bottom Portal Switcher Section
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131830),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF252D5A),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: 16,
                                color: Color(0xFF8E99B7),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'QUICK ROLE ACCESS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Color(0xFF8E99B7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Client Button
                              Expanded(
                                child: _RoleIconButton(
                                  title: 'Client',
                                  subtitle: 'User Portal',
                                  icon: Icons.person_rounded,
                                  color: AppColors.primary,
                                  isSelected: isClient,
                                  onTap: () => _switchRole(LoginRole.client),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Trainer Button
                              Expanded(
                                child: _RoleIconButton(
                                  title: 'Trainer',
                                  subtitle: 'Coach Portal',
                                  icon: Icons.sports_rounded,
                                  color: const Color(0xFF00E5A0),
                                  isSelected: isTrainer,
                                  onTap: () => _switchRole(LoginRole.trainer),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Admin Button
                              Expanded(
                                child: _RoleIconButton(
                                  title: 'Admin',
                                  subtitle: 'Management',
                                  icon: Icons.admin_panel_settings_rounded,
                                  color: const Color(0xFFFF7043),
                                  isSelected: isAdmin,
                                  onTap: () => _switchRole(LoginRole.admin),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Fitness & Metabolism Platform',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF5A6689),
                          ),
                    ),
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

class _RoleIconButton extends StatelessWidget {
  const _RoleIconButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : const Color(0xFF0F1326),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF252D5A),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? color : const Color(0xFF8E99B7),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.5,
                color: isSelected ? color.withValues(alpha: 0.85) : const Color(0xFF8E99B7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}