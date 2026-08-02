import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../injection_container.dart';
import 'bloc/login_otp_cubit.dart';

enum _OtpFlowStep { email, code }

/// OTP login: first collect email (OTP is sent there), then enter the code.
class LoginOtpPage extends StatelessWidget {
  const LoginOtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InjectionContainer.sl<LoginOtpCubit>(),
      child: const _LoginOtpView(),
    );
  }
}

class _LoginOtpView extends StatefulWidget {
  const _LoginOtpView();

  @override
  State<_LoginOtpView> createState() => _LoginOtpViewState();
}

class _LoginOtpViewState extends State<_LoginOtpView> {
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  _OtpFlowStep _step = _OtpFlowStep.email;
  String _emailForOtp = '';

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onBackPressed() {
    if (_step == _OtpFlowStep.code) {
      setState(() {
        _step = _OtpFlowStep.email;
        _otpController.clear();
      });
      return;
    }
    context.pop();
  }

  /// Validates email and calls [RequestOtpUseCase] via [LoginOtpCubit].
  Future<void> _onSendOtp(BuildContext context) async {
    final valid = _emailFormKey.currentState?.validate() ?? false;
    if (!valid) return;

    final email = _emailController.text.trim();
    await context.read<LoginOtpCubit>().requestOtpForEmail(email);
  }

  Future<void> _onVerifyOtp(BuildContext context) async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code')),
      );
      return;
    }

    await context.read<LoginOtpCubit>().verifyOtp(
          email: _emailForOtp,
          otp: code,
        );
  }

  String _maskedEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) return email;
    final local = email.substring(0, at);
    final domain = email.substring(at);
    final visible =
        local.length <= 2 ? local : '${local.substring(0, 1)}***';
    return '$visible$domain';
  }

  @override
  Widget build(BuildContext context) {
    final title = _step == _OtpFlowStep.email ? 'Login with OTP' : 'Enter OTP';

    return BlocListener<LoginOtpCubit, LoginOtpState>(
      listenWhen: (previous, current) =>
          previous.requestStatus != current.requestStatus ||
          previous.verifyStatus != current.verifyStatus,
      listener: (context, state) {
        if (state.requestStatus == RequestOtpUiStatus.failure) {
          final msg = state.requestErrorMessage;
          if (msg != null && msg.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
          }
          return;
        }

        if (state.requestStatus == RequestOtpUiStatus.success) {
          final email = _emailController.text.trim();
          setState(() {
            _emailForOtp = email;
            _step = _OtpFlowStep.code;
          });
          final text =
              state.requestSuccessMessage ?? 'OTP sent to your email';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(text)),
          );
          context.read<LoginOtpCubit>().clearRequestOutcome();
          return;
        }

        if (state.verifyStatus == VerifyOtpUiStatus.failure) {
          final msg = state.verifyErrorMessage;
          if (msg != null && msg.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
          }
          return;
        }

        if (state.verifyStatus == VerifyOtpUiStatus.success) {
          context.read<LoginOtpCubit>().clearVerifyOutcome();
          if (!context.mounted) return;
          // Matches password login: signed-in users land on the client shell.
          context.go(AppRouter.clientPath);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBackPressed,
          ),
          title: Text(title),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _step == _OtpFlowStep.email
                      ? KeyedSubtree(
                          key: const ValueKey('email_step'),
                          child: BlocBuilder<LoginOtpCubit, LoginOtpState>(
                            buildWhen: (p, c) => p.requestStatus != c.requestStatus,
                            builder: (context, state) {
                              final sending =
                                  state.requestStatus == RequestOtpUiStatus.loading;
                              return _EmailStep(
                                formKey: _emailFormKey,
                                emailController: _emailController,
                                isSending: sending,
                                onSendOtp: () => _onSendOtp(context),
                              );
                            },
                          ),
                        )
                      : KeyedSubtree(
                          key: const ValueKey('otp_step'),
                          child: BlocBuilder<LoginOtpCubit, LoginOtpState>(
                            buildWhen: (p, c) => p.verifyStatus != c.verifyStatus,
                            builder: (context, state) {
                              final verifying =
                                  state.verifyStatus == VerifyOtpUiStatus.loading;
                              return _OtpStep(
                                otpController: _otpController,
                                subtitleEmail: _maskedEmail(_emailForOtp),
                                isVerifying: verifying,
                                onVerify: () => _onVerifyOtp(context),
                                onChangeEmail: () {
                                  setState(() {
                                    _step = _OtpFlowStep.email;
                                    _otpController.clear();
                                  });
                                },
                              );
                            },
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailStep extends StatelessWidget {
  const _EmailStep({
    required this.formKey,
    required this.emailController,
    required this.onSendOtp,
    required this.isSending,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final VoidCallback onSendOtp;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your email',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'We’ll send a one-time code to this address.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.text.withValues(alpha: 0.8),
              ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.done,
                    enabled: !isSending,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Email is required';
                      final ok = v.contains('@') && v.contains('.');
                      if (!ok) return 'Enter a valid email';
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (!isSending) onSendOtp();
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: isSending ? null : onSendOtp,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isSending
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Send OTP',
                              key: ValueKey('label'),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Fitness & Metabolism',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.text.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    required this.otpController,
    required this.subtitleEmail,
    required this.isVerifying,
    required this.onVerify,
    required this.onChangeEmail,
  });

  final TextEditingController otpController;
  final String subtitleEmail;
  final bool isVerifying;
  final VoidCallback onVerify;
  final VoidCallback onChangeEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verification code',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to $subtitleEmail.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.text.withValues(alpha: 0.8),
              ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  enabled: !isVerifying,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'One-time code',
                    hintText: '000000',
                    counterText: '',
                  ),
                  onSubmitted: (_) {
                    if (!isVerifying) onVerify();
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isVerifying ? null : onVerify,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isVerifying
                        ? const SizedBox(
                            key: ValueKey('v-loading'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Continue',
                            key: ValueKey('v-label'),
                          ),
                  ),
                ),
                TextButton(
                  onPressed: isVerifying ? null : onChangeEmail,
                  child: const Text('Use a different email'),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Fitness & Metabolism',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.text.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
