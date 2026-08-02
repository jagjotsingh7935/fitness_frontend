import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../injection_container.dart';
import 'bloc/client_signup_cubit.dart';

/// Client onboarding / sign-up page.
///
/// Collects personal details and posts to the signup API.
/// On success, a confirmation is shown and the user is sent back to login.
class ClientSignupPage extends StatelessWidget {
  const ClientSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InjectionContainer.sl<ClientSignupCubit>(),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  /// Formatted as "yyyy-MM-dd" for the API.
  String? _dateOfBirth;

  /// Available fitness categories - Now using String names instead of IDs
  static const _categories = <String>[
    'Weight Loss',
    'Muscle Gain',
    'Endurance',
    'Flexibility',
    'General Fitness',
  ];
  
  final Set<String> _selectedCategories = {}; // Changed to store Strings

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Select your date of birth',
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _onSubmit(BuildContext context) async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one fitness goal')),
      );
      return;
    }

    print('📝 Submitting signup with categories: ${_selectedCategories.toList()}');

    await context.read<ClientSignupCubit>().submit(
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim(),
          dateOfBirth: _dateOfBirth!,
          address: _addressController.text.trim(),
          categoryIds: _selectedCategories.toList(), // Now sending String list
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientSignupCubit, ClientSignupState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == ClientSignupStatus.failure) {
          final msg = state.errorMessage;
          if (msg != null && msg.isNotEmpty) {
            print('❌ Signup error: $msg');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
          }
        }

        if (state.status == ClientSignupStatus.success) {
          final msg = state.successMessage ?? 'Registration successful!';
          print('✅ Signup successful: $msg');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Client Sign Up'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  children: [
                    Text(
                      'Create your account',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fill in your details to get started.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.text.withValues(alpha: 0.8),
                          ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // --- Email ---
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'you@example.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) return 'Email is required';
                                if (!value.contains('@') ||
                                    !value.contains('.')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // --- First / Last name ---
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'First name',
                                      prefixIcon:
                                          Icon(Icons.person_outline),
                                    ),
                                    validator: (v) {
                                      if ((v?.trim() ?? '').isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Last name',
                                    ),
                                    validator: (v) {
                                      if ((v?.trim() ?? '').isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // --- Phone ---
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                hintText: '9988776655',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) return 'Phone is required';
                                if (value.length < 10) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // --- Date of birth ---
                            GestureDetector(
                              onTap: _pickDateOfBirth,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Date of birth',
                                    hintText: _dateOfBirth ?? 'Tap to select',
                                    prefixIcon:
                                        const Icon(Icons.cake_outlined),
                                  ),
                                  controller: TextEditingController(
                                    text: _dateOfBirth,
                                  ),
                                  validator: (_) {
                                    if (_dateOfBirth == null) {
                                      return 'Date of birth is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // --- Address ---
                            TextFormField(
                              controller: _addressController,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              textInputAction: TextInputAction.done,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                hintText: '123 Main Street',
                                prefixIcon:
                                    Icon(Icons.location_on_outlined),
                                alignLabelWithHint: true,
                              ),
                              validator: (v) {
                                if ((v?.trim() ?? '').isEmpty) {
                                  return 'Address is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // --- Category selection ---
                            Text(
                              'Fitness Goals',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppColors.text
                                        .withValues(alpha: 0.9),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select the categories that interest you.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.text
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categories.map((category) {
                                final selected =
                                    _selectedCategories.contains(category);
                                return FilterChip(
                                  label: Text(category),
                                  selected: selected,
                                  onSelected: (on) {
                                    setState(() {
                                      if (on) {
                                        _selectedCategories.add(category);
                                      } else {
                                        _selectedCategories.remove(category);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            if (_selectedCategories.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Please select at least one goal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[300],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),

                            // --- Submit ---
                            BlocBuilder<ClientSignupCubit,
                                ClientSignupState>(
                              buildWhen: (p, c) => p.status != c.status,
                              builder: (context, state) {
                                final isBusy = state.status ==
                                    ClientSignupStatus.submitting;
                                return FilledButton(
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
                                            height: 20,
                                            width: 20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Sign Up',
                                            key: ValueKey('label'),
                                          ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () =>
                                    context.push(AppRouter.adminLoginPath),
                                child: const Text('Go to admin login'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Fitness & Metabolism',
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