import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_token_store.dart';
import '../../../../core/router/app_router.dart';
import '../../../../injection_container.dart';
import '../../../auth/data/models/category_dto.dart';
import '../../data/models/client_profile_dto.dart';
import '../state/client_profile_cubit.dart';
import '../widgets/assigned_coaches_sheet.dart';
import '../widgets/chart_card.dart';
import '../widgets/charts/weight_progress_chart.dart';
import '../widgets/client_scaffold.dart';
import '../widgets/daily_reminders_sheet.dart';
import '../widgets/fitness_goals_sheet.dart';
import '../widgets/preferences_section.dart';
import '../widgets/profile_hero.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';

class ClientProfilePage extends StatelessWidget {
  const ClientProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InjectionContainer.sl<ClientProfileCubit>()..loadProfile(),
      child: const _ClientProfileView(),
    );
  }
}

class _ClientProfileView extends StatelessWidget {
  const _ClientProfileView();

  void _showEditProfileModal(BuildContext context, ClientProfileDto? currentProfile, List<CategoryDto> allCategories) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return BlocProvider.value(
          value: context.read<ClientProfileCubit>(),
          child: _EditProfileModal(
            profile: currentProfile,
            allCategories: allCategories,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientProfileCubit, ClientProfileState>(
      listener: (context, state) {
        if (state.status == ClientProfileStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: const Color(0xFFFF4B72),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state.status == ClientProfileStatus.updateSuccess && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${state.successMessage}'),
              backgroundColor: const Color(0xFF00F5A0),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final profile = state.profile;
        final isBusy = state.status == ClientProfileStatus.loading && profile == null;

        if (isBusy) {
          return ClientScaffold(
            greeting: 'Account & Analytics',
            title: 'Profile',
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F5A0)),
                ),
              ),
            ),
          );
        }

        final double? curWeight = _parseDouble(profile?.weight);
        final double? targetWeight = _parseDouble(profile?.preferredWeight);

        return ClientScaffold(
          greeting: 'Account & Analytics',
          title: 'Profile',
          onRefresh: () async => context.read<ClientProfileCubit>().loadProfile(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                // 1. Sleek Glassmorphic Profile Hero
                ProfileHero(
                  profile: profile,
                  onEditProfile: () => _showEditProfileModal(context, profile, state.categories),
                ),

                // 2. Weight Progress & Target Trend
                ChartCard(
                  title: 'Weight & Goal Trajectory',
                  periodLabel: targetWeight != null ? 'Goal: ${targetWeight.toStringAsFixed(1)} kg' : 'Active Plan',
                  child: WeightProgressChart(
                    currentWeight: curWeight,
                    targetWeight: targetWeight,
                  ),
                ),

                // 3. Body Metrics Grid (100% Overflow-safe)
                const SectionHeader(title: 'Body Metrics & Composition'),
                _BodyMetricsGrid(profile: profile),

                // 4. Target Goals Grid
                const SectionHeader(title: 'Fitness Target Preferences'),
                _TargetGoalsGrid(profile: profile),

                // 5. Assigned Trainer Banner
                if (profile?.activeTrainers.isNotEmpty == true) ...[
                  const SectionHeader(title: 'Dedicated Coach'),
                  _AssignedTrainerCard(trainer: profile!.activeTrainers.first),
                ],

                // 6. Account Preferences & Actions
                const SectionHeader(title: 'Account Settings & Actions'),
                PreferencesSection(
                  items: [
                    PreferenceItemModel(
                      icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF818CF8), size: 20),
                      iconBg: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      title: 'Edit Profile & Stats',
                      subtitle: 'Update body measurements, target weights & contact info',
                      onTap: () => _showEditProfileModal(context, profile, state.categories),
                    ),
                    PreferenceItemModel(
                      icon: const Icon(Icons.track_changes_rounded, color: Color(0xFF00F5A0), size: 20),
                      iconBg: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                      title: 'My Fitness Goals',
                      subtitle: profile?.categories.isNotEmpty == true
                          ? profile!.categories.map((c) => c.name).join(' · ')
                          : 'No fitness goals selected yet',
                      onTap: () => FitnessGoalsSheet.show(
                        context,
                        profile: profile,
                        allCategories: state.categories,
                        onSaved: () => context.read<ClientProfileCubit>().loadProfile(),
                      ),
                    ),
                    PreferenceItemModel(
                      icon: const Icon(Icons.fitness_center_rounded, color: Color(0xFFFF9F43), size: 20),
                      iconBg: const Color(0xFFFF9F43).withValues(alpha: 0.15),
                      title: 'Assigned Coaches',
                      subtitle: profile?.activeTrainers.isNotEmpty == true
                          ? '${profile!.activeTrainers.length} coach connected'
                          : 'Self-guided training mode',
                      onTap: () => AssignedCoachesSheet.show(
                        context,
                        profile: profile,
                      ),
                    ),
                    PreferenceItemModel(
                      icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF38BDF8), size: 20),
                      iconBg: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      title: 'Daily Reminders & Alerts',
                      subtitle: 'Hydration reminders, workout schedule & meal times',
                      onTap: () => DailyRemindersSheet.show(
                        context,
                      ),
                    ),
                    PreferenceItemModel(
                      icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF4B72), size: 20),
                      iconBg: const Color(0xFFFF4B72).withValues(alpha: 0.15),
                      title: 'Log Out',
                      subtitle: 'Safely sign out from this device',
                      arrowColor: const Color(0xFFFF4B72),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF161B36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            title: const Text(
                              'Sign Out',
                              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            content: const Text(
                              'Are you sure you want to log out of your fitness account?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF4B72),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await GetIt.I<AuthTokenStore>().clear();
                          if (context.mounted) {
                            context.go(AppRouter.loginPath);
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
        );
      },
    );
  }

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }
}

class _BodyMetricsGrid extends StatelessWidget {
  const _BodyMetricsGrid({required this.profile});

  final ClientProfileDto? profile;

  @override
  Widget build(BuildContext context) {
    final curWeight = profile?.weight != null ? '${profile!.weight}' : '--';
    final curHeight = profile?.height != null ? '${profile!.height}' : '--';
    final curBmi = profile?.bmi != null ? '${profile!.bmi}' : '--';
    final curFat = profile?.fatPercent != null ? '${profile!.fatPercent}' : '--';
    final curNeck = profile?.neckCircumference != null ? '${profile!.neckCircumference}' : '--';
    final curWaist = profile?.waist != null ? '${profile!.waist}' : '--';

    final items = <StatCardModel>[
      StatCardModel(
        value: curWeight,
        unit: profile?.weight != null ? 'kg' : '',
        label: 'Current Weight',
        icon: const Icon(Icons.monitor_weight_outlined, size: 15, color: Color(0xFF6366F1)),
        accent: const Color(0xFF6366F1),
        changeLabel: 'Current',
        changeDirection: StatChangeDirection.neutral,
      ),
      StatCardModel(
        value: curHeight,
        unit: profile?.height != null ? 'cm' : '',
        label: 'Height',
        icon: const Icon(Icons.height_rounded, size: 15, color: Color(0xFF00F5A0)),
        accent: const Color(0xFF00F5A0),
        changeLabel: profile?.gender ?? 'Stat',
        changeDirection: StatChangeDirection.neutral,
      ),
      StatCardModel(
        value: curBmi,
        unit: '',
        label: 'Body Mass Index',
        icon: const Icon(Icons.speed_rounded, size: 15, color: Color(0xFF38BDF8)),
        accent: const Color(0xFF38BDF8),
        changeLabel: _getBmiStatus(profile?.bmi),
        changeDirection: StatChangeDirection.neutral,
      ),
      StatCardModel(
        value: curFat,
        unit: profile?.fatPercent != null ? '%' : '',
        label: 'Body Fat',
        icon: const Icon(Icons.pie_chart_outline_rounded, size: 15, color: Color(0xFFFF9F43)),
        accent: const Color(0xFFFF9F43),
        changeLabel: 'Fat %',
        changeDirection: StatChangeDirection.neutral,
      ),
      StatCardModel(
        value: curWaist,
        unit: profile?.waist != null ? 'cm' : '',
        label: 'Waist Size',
        icon: const Icon(Icons.straighten_rounded, size: 15, color: Color(0xFF00F5A0)),
        accent: const Color(0xFF00F5A0),
        changeLabel: 'Waist',
        changeDirection: StatChangeDirection.neutral,
      ),
      StatCardModel(
        value: curNeck,
        unit: profile?.neckCircumference != null ? 'cm' : '',
        label: 'Neck Size',
        icon: const Icon(Icons.accessibility_new_rounded, size: 15, color: Color(0xFF818CF8)),
        accent: const Color(0xFF818CF8),
        changeLabel: 'Neck',
        changeDirection: StatChangeDirection.neutral,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => StatCard(model: items[i]),
    );
  }

  String _getBmiStatus(dynamic bmiVal) {
    if (bmiVal == null) return 'Calculated';
    final bmi = double.tryParse(bmiVal.toString());
    if (bmi == null) return 'Calculated';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }
}

class _TargetGoalsGrid extends StatelessWidget {
  const _TargetGoalsGrid({required this.profile});

  final ClientProfileDto? profile;

  @override
  Widget build(BuildContext context) {
    final tgtWeight = profile?.preferredWeight != null ? '${profile!.preferredWeight}' : '--';
    final tgtWaist = profile?.preferredWaist != null ? '${profile!.preferredWaist}' : '--';
    final tgtBmi = profile?.preferredBmi != null ? '${profile!.preferredBmi}' : '--';
    final tgtFat = profile?.preferredFatPercent != null ? '${profile!.preferredFatPercent}' : '--';

    final items = <StatCardModel>[
      StatCardModel(
        value: tgtWeight,
        unit: profile?.preferredWeight != null ? 'kg' : '',
        label: 'Target Weight',
        icon: const Icon(Icons.flag_rounded, size: 15, color: Color(0xFF00F5A0)),
        accent: const Color(0xFF00F5A0),
        changeLabel: 'Goal Weight',
        changeDirection: StatChangeDirection.up,
      ),
      StatCardModel(
        value: tgtWaist,
        unit: profile?.preferredWaist != null ? 'cm' : '',
        label: 'Target Waist',
        icon: const Icon(Icons.straighten_rounded, size: 15, color: Color(0xFF38BDF8)),
        accent: const Color(0xFF38BDF8),
        changeLabel: 'Goal Waist',
        changeDirection: StatChangeDirection.down,
      ),
      StatCardModel(
        value: tgtBmi,
        unit: '',
        label: 'Target BMI',
        icon: const Icon(Icons.speed_rounded, size: 15, color: Color(0xFF818CF8)),
        accent: const Color(0xFF818CF8),
        changeLabel: 'Goal BMI',
        changeDirection: StatChangeDirection.neutral,
      ),
      StatCardModel(
        value: tgtFat,
        unit: profile?.preferredFatPercent != null ? '%' : '',
        label: 'Target Fat',
        icon: const Icon(Icons.pie_chart_outline_rounded, size: 15, color: Color(0xFFFF9F43)),
        accent: const Color(0xFFFF9F43),
        changeLabel: 'Goal Fat',
        changeDirection: StatChangeDirection.neutral,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => StatCard(model: items[i]),
    );
  }
}

class _AssignedTrainerCard extends StatelessWidget {
  const _AssignedTrainerCard({required this.trainer});

  final Map<String, dynamic> trainer;

  @override
  Widget build(BuildContext context) {
    final name = trainer['name']?.toString() ?? 'Coach';
    final spec = trainer['specialization']?.toString() ?? 'Fitness & Nutrition';

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131830),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00F5A0).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00F5A0), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'T',
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ACTIVE COACH',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00F5A0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  spec,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileModal extends StatefulWidget {
  const _EditProfileModal({
    required this.profile,
    required this.allCategories,
  });

  final ClientProfileDto? profile;
  final List<CategoryDto> allCategories;

  @override
  State<_EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<_EditProfileModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _neckController;
  late TextEditingController _waistController;
  late TextEditingController _fatPercentController;

  late TextEditingController _preferredWeightController;
  late TextEditingController _preferredWaistController;
  late TextEditingController _preferredBmiController;
  late TextEditingController _preferredFatPercentController;

  String? _gender;
  final Set<int> _selectedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _firstNameController = TextEditingController(text: p?.firstName ?? '');
    _lastNameController = TextEditingController(text: p?.lastName ?? '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _ageController = TextEditingController(text: p?.age ?? '');
    _weightController = TextEditingController(text: p?.weight?.toString() ?? '');
    _heightController = TextEditingController(text: p?.height?.toString() ?? '');
    _neckController = TextEditingController(text: p?.neckCircumference?.toString() ?? '');
    _waistController = TextEditingController(text: p?.waist?.toString() ?? '');
    _fatPercentController = TextEditingController(text: p?.fatPercent?.toString() ?? '');

    _preferredWeightController = TextEditingController(text: p?.preferredWeight?.toString() ?? '');
    _preferredWaistController = TextEditingController(text: p?.preferredWaist?.toString() ?? '');
    _preferredBmiController = TextEditingController(text: p?.preferredBmi?.toString() ?? '');
    _preferredFatPercentController = TextEditingController(text: p?.preferredFatPercent?.toString() ?? '');

    _gender = p?.gender;
    if (p?.categories != null) {
      for (final c in p!.categories) {
        _selectedCategoryIds.add(c.id);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _neckController.dispose();
    _waistController.dispose();
    _fatPercentController.dispose();
    _preferredWeightController.dispose();
    _preferredWaistController.dispose();
    _preferredBmiController.dispose();
    _preferredFatPercentController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final data = <String, dynamic>{
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'gender': _gender,
      'age': _ageController.text.trim().isNotEmpty ? _ageController.text.trim() : null,
      'weight': double.tryParse(_weightController.text.trim()),
      'height': double.tryParse(_heightController.text.trim()),
      'neck_circumference': double.tryParse(_neckController.text.trim()),
      'waist': double.tryParse(_waistController.text.trim()),
      'fat_percent': double.tryParse(_fatPercentController.text.trim()),
      'preferred_weight': double.tryParse(_preferredWeightController.text.trim()),
      'preferred_waist': double.tryParse(_preferredWaistController.text.trim()),
      'preferred_bmi': double.tryParse(_preferredBmiController.text.trim()),
      'preferred_fat_percent': double.tryParse(_preferredFatPercentController.text.trim()),
      'category_ids': _selectedCategoryIds.toList(),
    };

    // Calculate updated BMI if height & weight exist
    final h = double.tryParse(_heightController.text.trim());
    final w = double.tryParse(_weightController.text.trim());
    if (h != null && h > 0 && w != null && w > 0) {
      final hM = h / 100.0;
      data['bmi'] = double.parse((w / (hM * hM)).toStringAsFixed(1));
    }

    final success = await context.read<ClientProfileCubit>().updateProfile(data);
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1326),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Profile & Body Metrics',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information
                    _buildModalSectionHeader('Personal Details', const Color(0xFF6366F1)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('First Name'),
                            validator: (v) => (v?.trim() ?? '').isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Last Name'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Phone Number', icon: Icons.phone_outlined),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Address / City', icon: Icons.location_on_outlined),
                    ),

                    const SizedBox(height: 22),

                    // Body Stats
                    _buildModalSectionHeader('Current Body Metrics', const Color(0xFF00F5A0)),
                    const SizedBox(height: 12),
                    Row(
                      children: ['Male', 'Female', 'Other'].map((g) {
                        final isSel = _gender == g;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(g),
                            selected: isSel,
                            selectedColor: const Color(0xFF00F5A0),
                            backgroundColor: const Color(0xFF161B36),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.black : Colors.white70,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                              fontSize: 12,
                            ),
                            onSelected: (s) => setState(() => _gender = s ? g : null),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Age'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Height (cm)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Weight (kg)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _fatPercentController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Body Fat (%)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _waistController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Waist (cm)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _neckController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Neck (cm)'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Target Goals
                    _buildModalSectionHeader('Target Preferences & Goals', const Color(0xFFFF9F43)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _preferredWeightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Target Weight (kg)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _preferredWaistController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Target Waist (cm)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _preferredBmiController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Target BMI'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _preferredFatPercentController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Target Fat (%)'),
                          ),
                        ),
                      ],
                    ),

                    if (widget.allCategories.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _buildModalSectionHeader('Fitness Goal Categories', const Color(0xFF38BDF8)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.allCategories.map((cat) {
                          final isSel = _selectedCategoryIds.contains(cat.id);
                          return FilterChip(
                            label: Text(cat.name),
                            selected: isSel,
                            selectedColor: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                            backgroundColor: const Color(0xFF161B36),
                            labelStyle: TextStyle(
                              color: isSel ? const Color(0xFF38BDF8) : Colors.white70,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategoryIds.add(cat.id);
                                } else {
                                  _selectedCategoryIds.remove(cat.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Save Button
                    BlocBuilder<ClientProfileCubit, ClientProfileState>(
                      builder: (context, state) {
                        final isSaving = state.status == ClientProfileStatus.updating;
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _onSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F5A0),
                              foregroundColor: Colors.black,
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Text(
                                    'Save Profile Changes',
                                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
                                  ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalSectionHeader(String title, Color accent) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 14,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: accent,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, size: 16, color: Colors.white38) : null,
      filled: true,
      fillColor: const Color(0xFF161B36),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00F5A0), width: 1.2),
      ),
    );
  }
}
