import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../injection_container.dart';
import '../data/models/category_dto.dart';
import 'bloc/client_signup_cubit.dart';

class ClientSignupPage extends StatelessWidget {
  const ClientSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InjectionContainer.sl<ClientSignupCubit>()..loadCategories(),
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
  // Step 1 Form Controllers
  final _step1FormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _obscurePassword = true;
  String? _dateOfBirth;

  // Step 3 Optional Metrics Controllers
  String? _selectedGender;
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _neckController = TextEditingController();
  final _waistController = TextEditingController();
  final _bmiController = TextEditingController();
  final _fatPercentController = TextEditingController();

  // Step 3 Preferred Target Controllers
  final _preferredWeightController = TextEditingController();
  final _preferredWaistController = TextEditingController();
  final _preferredBmiController = TextEditingController();
  final _preferredFatPercentController = TextEditingController();

  double? _calculatedBmi;

  @override
  void initState() {
    super.initState();
    _heightController.addListener(_recalculateBmi);
    _weightController.addListener(_recalculateBmi);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();

    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _neckController.dispose();
    _waistController.dispose();
    _bmiController.dispose();
    _fatPercentController.dispose();

    _preferredWeightController.dispose();
    _preferredWaistController.dispose();
    _preferredBmiController.dispose();
    _preferredFatPercentController.dispose();
    super.dispose();
  }

  void _recalculateBmi() {
    final hCm = double.tryParse(_heightController.text.trim());
    final wKg = double.tryParse(_weightController.text.trim());

    if (hCm != null && hCm > 50 && wKg != null && wKg > 20) {
      final hM = hCm / 100.0;
      final bmi = wKg / (hM * hM);
      setState(() {
        _calculatedBmi = double.parse(bmi.toStringAsFixed(1));
        if (_bmiController.text.isEmpty) {
          _bmiController.text = _calculatedBmi!.toString();
        }
      });
    } else {
      if (_calculatedBmi != null) {
        setState(() {
          _calculatedBmi = null;
        });
      }
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1930),
      lastDate: now,
      helpText: 'Select your Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _validateAndGoToStep2() {
    final isValid = _step1FormKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    context.read<ClientSignupCubit>().setStep(1);
  }

  void _validateAndGoToStep3() {
    final state = context.read<ClientSignupCubit>().state;
    if (state.selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one fitness goal to continue'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    context.read<ClientSignupCubit>().setStep(2);
  }

  Future<void> _submitRegistration({bool skipMetrics = false}) async {
    final cubit = context.read<ClientSignupCubit>();
    final state = cubit.state;

    final categoryIds = state.selectedCategoryIds.toList();

    await cubit.submit(
      email: _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      phone: _phoneController.text.trim(),
      dateOfBirth: _dateOfBirth!,
      address: _addressController.text.trim(),
      categoryIds: categoryIds,
      gender: skipMetrics ? null : _selectedGender,
      age: skipMetrics ? null : (_ageController.text.trim().isNotEmpty ? _ageController.text.trim() : null),
      weight: skipMetrics
          ? null
          : (_weightController.text.trim().isNotEmpty
              ? double.tryParse(_weightController.text.trim()) ?? _weightController.text.trim()
              : null),
      height: skipMetrics
          ? null
          : (_heightController.text.trim().isNotEmpty
              ? double.tryParse(_heightController.text.trim()) ?? _heightController.text.trim()
              : null),
      neckCircumference: skipMetrics
          ? null
          : (_neckController.text.trim().isNotEmpty
              ? double.tryParse(_neckController.text.trim()) ?? _neckController.text.trim()
              : null),
      waist: skipMetrics
          ? null
          : (_waistController.text.trim().isNotEmpty
              ? double.tryParse(_waistController.text.trim()) ?? _waistController.text.trim()
              : null),
      bmi: skipMetrics
          ? null
          : (_bmiController.text.trim().isNotEmpty
              ? double.tryParse(_bmiController.text.trim()) ?? _bmiController.text.trim()
              : _calculatedBmi),
      fatPercent: skipMetrics
          ? null
          : (_fatPercentController.text.trim().isNotEmpty
              ? double.tryParse(_fatPercentController.text.trim()) ?? _fatPercentController.text.trim()
              : null),
      preferredWeight: skipMetrics
          ? null
          : (_preferredWeightController.text.trim().isNotEmpty
              ? double.tryParse(_preferredWeightController.text.trim()) ?? _preferredWeightController.text.trim()
              : null),
      preferredWaist: skipMetrics
          ? null
          : (_preferredWaistController.text.trim().isNotEmpty
              ? double.tryParse(_preferredWaistController.text.trim()) ?? _preferredWaistController.text.trim()
              : null),
      preferredBmi: skipMetrics
          ? null
          : (_preferredBmiController.text.trim().isNotEmpty
              ? double.tryParse(_preferredBmiController.text.trim()) ?? _preferredBmiController.text.trim()
              : null),
      preferredFatPercent: skipMetrics
          ? null
          : (_preferredFatPercentController.text.trim().isNotEmpty
              ? double.tryParse(_preferredFatPercentController.text.trim()) ?? _preferredFatPercentController.text.trim()
              : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientSignupCubit, ClientSignupState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == ClientSignupStatus.failure) {
          final msg = state.errorMessage ?? 'Registration failed. Please check your details.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (state.status == ClientSignupStatus.success) {
          final msg = state.successMessage ?? 'Account created successfully!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 $msg'),
              backgroundColor: const Color(0xFF00E5A0),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              final cubit = context.read<ClientSignupCubit>();
              if (cubit.state.currentStep > 0) {
                cubit.previousStep();
              } else {
                context.pop();
              }
            },
          ),
          title: const Text(
            'Client Onboarding',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: BlocBuilder<ClientSignupCubit, ClientSignupState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      // Multi-step Progress Header
                      _buildStepProgressHeader(state.currentStep),

                      // Step Content Container
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _buildCurrentStepView(state),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgressHeader(int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepPill(0, 'Basic Info', Icons.person_outline_rounded, currentStep),
              _buildStepDivider(currentStep >= 1),
              _buildStepPill(1, 'Fitness Goals', Icons.track_changes_rounded, currentStep),
              _buildStepDivider(currentStep >= 2),
              _buildStepPill(2, 'Body Stats', Icons.monitor_weight_outlined, currentStep),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / 3.0,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPill(int stepIndex, String title, IconData icon, int currentStep) {
    final isActive = currentStep == stepIndex;
    final isCompleted = currentStep > stepIndex;

    Color color;
    if (isActive) {
      color = AppColors.primary;
    } else if (isCompleted) {
      color = const Color(0xFF00E5A0);
    } else {
      color = AppColors.text.withValues(alpha: 0.4);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool active) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        height: 1.5,
        color: active ? const Color(0xFF00E5A0) : AppColors.border,
      ),
    );
  }

  Widget _buildCurrentStepView(ClientSignupState state) {
    switch (state.currentStep) {
      case 0:
        return _buildStep1BasicDetails();
      case 1:
        return _buildStep2Goals(state);
      case 2:
      default:
        return _buildStep3BodyMetrics(state);
    }
  }

  // ==========================================
  // STEP 1: Basic Details
  // ==========================================
  Widget _buildStep1BasicDetails() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Personal Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Step 1 of 3: Provide your basic contact & login information.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.text.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 20),

          // Card Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: AppColors.text),
                        decoration: const InputDecoration(
                          labelText: 'First Name *',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                        ),
                        validator: (v) {
                          if ((v?.trim() ?? '').isEmpty) return 'Required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: AppColors.text),
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Email is required';
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'Password (Optional)',
                    hintText: 'Leave empty for auto-generated password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: '9876543210',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Phone number is required';
                    if (val.length < 8) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Date of Birth Picker
                InkWell(
                  onTap: _pickDateOfBirth,
                  borderRadius: BorderRadius.circular(12),
                  child: AbsorbPointer(
                    child: TextFormField(
                      style: const TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        labelText: 'Date of Birth *',
                        hintText: _dateOfBirth ?? 'Tap to select birth date',
                        prefixIcon: const Icon(Icons.cake_outlined, size: 20),
                        suffixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
                      ),
                      controller: TextEditingController(text: _dateOfBirth),
                      validator: (_) {
                        if (_dateOfBirth == null) return 'Date of birth is required';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Address
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'City, State or Full Address',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Next Button
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _validateAndGoToStep2,
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: const Text(
                'Next: Select Goals',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: Fitness Goals (Categories)
  // ==========================================
  Widget _buildStep2Goals(ClientSignupState state) {
    final selectedCount = state.selectedCategoryIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Fitness Goals',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step 2 of 3: Select all categories that apply to you.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.text.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
            if (selectedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Text(
                  '$selectedCount Selected',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        if (state.status == ClientSignupStatus.loadingCategories) ...[
          const SizedBox(height: 80),
          const Center(
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Loading fitness goals...',
              style: TextStyle(color: AppColors.text2),
            ),
          ),
        ] else if (state.categories.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.fitness_center_rounded, size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                const Text(
                  'No categories found',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap retry to reload goals from server.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text2, fontSize: 13),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.read<ClientSignupCubit>().loadCategories(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ] else ...[
          // Grid of Category Cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: state.categories.length,
            itemBuilder: (context, index) {
              final cat = state.categories[index];
              final isSelected = state.selectedCategoryIds.contains(cat.id);
              return _buildCategoryCard(cat, isSelected);
            },
          ),
        ],

        const SizedBox(height: 28),

        // Navigation Buttons
        Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => context.read<ClientSignupCubit>().setStep(0),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _validateAndGoToStep3,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: const Text(
                    'Next: Body Stats',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryDto category, bool isSelected) {
    // Determine appropriate fallback icon based on category name
    final nameLower = category.name.toLowerCase();
    IconData fallbackIcon = Icons.fitness_center_rounded;
    if (nameLower.contains('loss') || nameLower.contains('burn')) {
      fallbackIcon = Icons.local_fire_department_rounded;
    } else if (nameLower.contains('muscle') || nameLower.contains('gain') || nameLower.contains('hypertrophy')) {
      fallbackIcon = Icons.fitness_center_rounded;
    } else if (nameLower.contains('endurance') || nameLower.contains('cardio') || nameLower.contains('run')) {
      fallbackIcon = Icons.directions_run_rounded;
    } else if (nameLower.contains('flex') || nameLower.contains('yoga') || nameLower.contains('mobility')) {
      fallbackIcon = Icons.self_improvement_rounded;
    } else if (nameLower.contains('strength')) {
      fallbackIcon = Icons.sports_gymnastics_rounded;
    }

    String? fullIconUrl = category.iconUrl;
    if (fullIconUrl != null && !fullIconUrl.startsWith('http')) {
      fullIconUrl = '${ApiConstants.baseUrl}$fullIconUrl';
    }

    return InkWell(
      onTap: () => context.read<ClientSignupCubit>().toggleCategory(category.id),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.18) : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.background.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: fullIconUrl != null
                      ? Image.network(
                          fullIconUrl,
                          width: 22,
                          height: 22,
                          color: isSelected ? Colors.white : AppColors.primary,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            fallbackIcon,
                            size: 22,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        )
                      : Icon(
                          fallbackIcon,
                          size: 22,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.text.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.text,
                  ),
                ),
                if (category.description != null && category.description!.isNotEmpty)
                  Text(
                    category.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.text.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 3: Body Metrics & Goals (Optional)
  // ==========================================
  Widget _buildStep3BodyMetrics(ClientSignupState state) {
    final isBusy = state.status == ClientSignupStatus.submitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Body Metrics & Targets',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Step 3 of 3: Enter your current stats & preferred targets (Optional).',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.text.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 16),

        // Info Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'These metrics help us calibrate your nutrition and workout plans. All fields here are optional.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section A: Current Metrics Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.straighten_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Current Body Stats',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Gender Selector
              const Text(
                'Gender',
                style: TextStyle(fontSize: 12, color: AppColors.text2),
              ),
              const SizedBox(height: 6),
              Row(
                children: ['Male', 'Female', 'Other'].map((gender) {
                  final isSelected = _selectedGender == gender;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(gender),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      onSelected: (selected) {
                        setState(() {
                          _selectedGender = selected ? gender : null;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Age & Height Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(
                        labelText: 'Age (years)',
                        hintText: 'e.g. 26',
                        prefixIcon: Icon(Icons.cake_outlined, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        hintText: 'e.g. 175',
                        prefixIcon: Icon(Icons.height_rounded, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Weight & Live BMI Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        hintText: 'e.g. 72.5',
                        prefixIcon: Icon(Icons.monitor_weight_outlined, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _bmiController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        labelText: 'BMI',
                        hintText: _calculatedBmi != null ? '$_calculatedBmi' : 'e.g. 23.5',
                        prefixIcon: const Icon(Icons.speed_rounded, size: 18),
                        helperText: _calculatedBmi != null ? 'Auto-calculated' : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Neck & Waist Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _neckController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(
                        labelText: 'Neck (cm)',
                        hintText: 'e.g. 38',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _waistController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(
                        labelText: 'Waist (cm)',
                        hintText: 'e.g. 82',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Fat Percent
              TextFormField(
                controller: _fatPercentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.text),
                decoration: const InputDecoration(
                  labelText: 'Body Fat (%)',
                  hintText: 'e.g. 18.5',
                  prefixIcon: Icon(Icons.pie_chart_outline_rounded, size: 18),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Section B: Preferred Target Goals Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag_rounded, size: 18, color: Color(0xFF00E5A0)),
                  const SizedBox(width: 8),
                  const Text(
                    'Preferred Target Goals',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Preferred Weight & Preferred Waist
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _preferredWeightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(
                        labelText: 'Target Weight (kg)',
                        hintText: 'e.g. 68.0',
                        prefixIcon: Icon(Icons.track_changes_rounded, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _preferredWaistController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(
                        labelText: 'Target Waist (cm)',
                        hintText: 'e.g. 76',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Preferred BMI & Fat Percent
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _preferredBmiController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(
                        labelText: 'Target BMI',
                        hintText: 'e.g. 22.0',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _preferredFatPercentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(
                        labelText: 'Target Fat (%)',
                        hintText: 'e.g. 15.0',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Action Buttons
        Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : () => context.read<ClientSignupCubit>().setStep(1),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isBusy ? null : () => _submitRegistration(skipMetrics: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5A0),
                    foregroundColor: Colors.black,
                    elevation: 4,
                    shadowColor: const Color(0xFF00E5A0).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isBusy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Complete Registration',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: isBusy ? null : () => _submitRegistration(skipMetrics: true),
            child: Text(
              'Skip metrics & create account',
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}