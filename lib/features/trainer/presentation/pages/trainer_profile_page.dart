import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_token_store.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';

class TrainerProfilePage extends StatefulWidget {
  const TrainerProfilePage({super.key});

  @override
  State<TrainerProfilePage> createState() => _TrainerProfilePageState();
}

class _TrainerProfilePageState extends State<TrainerProfilePage> {
  final Dio _dio = GetIt.I<DioClient>().dio;
  bool _isLoading = true;

  String _name = 'Marcus Vance';
  String _specialization = 'Strength & Conditioning Specialist';
  String _email = 'trainer@fitness.com';
  String _phone = '+1 (555) 234-5678';
  String _bio = 'Certified Coach with 8+ years experience helping clients build muscle, burn fat and optimize movement patterns.';
  List<String> _categories = ['Strength', 'Weight Loss', 'Endurance'];

  int _clientCount = 0;
  int _workoutPlanCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);

    try {
      final response = await _dio.get('/accounts/api/me/');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          setState(() {
            _name = data['full_name']?.toString() ??
                '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
            if (_name.isEmpty) _name = data['email']?.toString() ?? 'Trainer';
            _email = data['email']?.toString() ?? _email;
            _specialization = data['specialization']?.toString() ?? _specialization;
            _phone = data['phone']?.toString() ?? _phone;
            _bio = data['bio']?.toString() ?? _bio;

            if (data['categories'] is List) {
              _categories = (data['categories'] as List)
                  .map((c) => c['name']?.toString() ?? '')
                  .where((n) => n.isNotEmpty)
                  .toList();
            }
          });
        }
      }

      // Fetch client count
      try {
        final clientsRes = await _dio.get('/accounts/api/trainers-client-list/');
        if (clientsRes.statusCode == 200) {
          final cData = clientsRes.data;
          if (cData is List) {
            _clientCount = cData.length;
          }
        }
      } catch (_) {}

      // Fetch workout plans count
      try {
        final plansRes = await _dio.get('/fitness/api/workout-plans/');
        if (plansRes.statusCode == 200) {
          final pData = plansRes.data;
          if (pData is Map && pData['results'] is List) {
            _workoutPlanCount = (pData['results'] as List).length;
          } else if (pData is List) {
            _workoutPlanCount = pData.length;
          }
        }
      } catch (_) {}

      setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showEditModal() {
    final nameCtrl = TextEditingController(text: _name);
    final specCtrl = TextEditingController(text: _specialization);
    final phoneCtrl = TextEditingController(text: _phone);
    final bioCtrl = TextEditingController(text: _bio);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.82,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1326),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Coach Profile',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField('Full Name', nameCtrl, icon: Icons.person_outline),
                        const SizedBox(height: 14),
                        _buildInputField('Specialization', specCtrl, icon: Icons.stars_outlined),
                        const SizedBox(height: 14),
                        _buildInputField('Phone Number', phoneCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 14),
                        _buildInputField('Bio / Philosophy', bioCtrl, icon: Icons.notes_outlined, maxLines: 3),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setModalState(() => isSaving = true);
                                    try {
                                      final names = nameCtrl.text.trim().split(' ');
                                      final fName = names.isNotEmpty ? names.first : '';
                                      final lName = names.length > 1 ? names.sublist(1).join(' ') : '';

                                      await _dio.patch(
                                        '/accounts/api/me/',
                                        data: {
                                          'first_name': fName,
                                          'last_name': lName,
                                          'specialization': specCtrl.text.trim(),
                                          'phone': phoneCtrl.text.trim(),
                                          'bio': bioCtrl.text.trim(),
                                        },
                                      );
                                      if (mounted) {
                                        Navigator.pop(modalCtx);
                                        _fetchProfileData();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('✅ Coach profile updated!'),
                                            backgroundColor: Color(0xFF00F5A0),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(() => isSaving = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error updating: $e'),
                                          backgroundColor: const Color(0xFFFF4B72),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF4B72),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Save Profile',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl,
      {IconData? icon, TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
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
              borderSide: const BorderSide(color: Color(0xFFFF4B72), width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'T';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D1A),
      appBar: AppBar(
        title: const Text(
          'Coach Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0D1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFFFF4B72)),
            onPressed: _showEditModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchProfileData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4B72)),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFFFF4B72),
              backgroundColor: const Color(0xFF161B36),
              onRefresh: _fetchProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                child: Column(
                  children: [
                    // Profile Header Card
                    _buildProfileHero(initial),
                    const SizedBox(height: 18),

                    // Live Stats Row
                    _buildStatsRow(),
                    const SizedBox(height: 18),

                    // About Coach Card
                    _buildAboutCard(),
                    const SizedBox(height: 18),

                    // Account Settings & Logout
                    _buildAccountSettingsCard(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHero(String initial) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF181E3B), Color(0xFF0F1326)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF4B72).withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4B72), Color(0xFFFF9F43)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4B72).withValues(alpha: 0.3),
                      blurRadius: 14,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F1326),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5A0),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0F1326), width: 2),
                  ),
                  child: const Icon(Icons.verified_rounded, color: Colors.black, size: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _specialization,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4B72).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF4B72).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Text(
              'CERTIFIED TRAINER',
              style: TextStyle(
                color: Color(0xFFFF4B72),
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatTile('Clients', '$_clientCount', const Color(0xFF38BDF8), Icons.people_outline_rounded),
        const SizedBox(width: 10),
        _buildStatTile('Routines', '$_workoutPlanCount', const Color(0xFF00F5A0), Icons.fitness_center_rounded),
        const SizedBox(width: 10),
        _buildStatTile('Rating', '4.9 ★', const Color(0xFFFF9F43), Icons.star_outline_rounded),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, Color accent, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF131830),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: accent,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131830),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Coach',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _bio,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          if (_categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Expertise & Categories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _categories.map((c) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4B72).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF4B72).withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '🎯 $c',
                    style: const TextStyle(
                      color: Color(0xFFFF4B72),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          _buildContactRow(Icons.email_outlined, _email),
          if (_phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildContactRow(Icons.phone_outlined, _phone),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFFFF4B72)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettingsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131830),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildSettingsTile(
            Icons.edit_note_rounded,
            'Edit Profile Information',
            'Update your bio, phone and specialization',
            const Color(0xFF38BDF8),
            onTap: _showEditModal,
          ),
          const Divider(height: 1, color: Colors.white10),
          _buildSettingsTile(
            Icons.logout_rounded,
            'Sign Out',
            'Log out of trainer account on this device',
            const Color(0xFFFF4B72),
            isDestructive: true,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF161B36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  content: const Text('Are you sure you want to log out of trainer portal?', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4B72)),
                      child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, Color accent,
      {required VoidCallback onTap, bool isDestructive = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDestructive ? const Color(0xFFFF4B72) : Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDestructive ? const Color(0xFFFF4B72) : Colors.white24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}