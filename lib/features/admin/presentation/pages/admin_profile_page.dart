import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_token_store.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final Dio _dio = GetIt.I<DioClient>().dio;
  bool _isLoading = true;

  String _name = 'Admin Director';
  String _email = 'admin@fitness.com';
  String _phone = '+1 (555) 019-2834';

  int _trainersCount = 0;
  int _clientsCount = 0;
  int _categoriesCount = 0;
  int _exercisesCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch admin user data
      final userRes = await _dio.get('/accounts/api/me/');
      if (userRes.statusCode == 200) {
        final data = userRes.data;
        if (data is Map<String, dynamic>) {
          setState(() {
            _name = data['full_name']?.toString() ?? 'Admin Director';
            _email = data['email']?.toString() ?? _email;
          });
        }
      }

      // 2. Fetch stats: Trainers
      try {
        final trRes = await _dio.get('/accounts/api/trainer/');
        if (trRes.statusCode == 200 && trRes.data is Map && trRes.data['results'] is List) {
          _trainersCount = (trRes.data['results'] as List).length;
        } else if (trRes.data is List) {
          _trainersCount = (trRes.data as List).length;
        }
      } catch (_) {}

      // 3. Fetch stats: Clients
      try {
        final clRes = await _dio.get('/accounts/api/client/');
        if (clRes.statusCode == 200 && clRes.data is Map && clRes.data['results'] is List) {
          _clientsCount = (clRes.data['results'] as List).length;
        } else if (clRes.data is List) {
          _clientsCount = (clRes.data as List).length;
        }
      } catch (_) {}

      // 4. Fetch stats: Categories
      try {
        final catRes = await _dio.get('/accounts/api/category-list/');
        if (catRes.statusCode == 200 && catRes.data is List) {
          _categoriesCount = (catRes.data as List).length;
        }
      } catch (_) {}

      // 5. Fetch stats: Exercises
      try {
        final exRes = await _dio.get('/fitness/api/exercises/');
        if (exRes.statusCode == 200 && exRes.data is Map && exRes.data['results'] is List) {
          _exercisesCount = (exRes.data['results'] as List).length;
        } else if (exRes.data is List) {
          _exercisesCount = (exRes.data as List).length;
        }
      } catch (_) {}

      setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showEditModal() {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
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
                        'Edit Administrator Profile',
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
                        _buildInputField('Administrator Name', nameCtrl, icon: Icons.admin_panel_settings_outlined),
                        const SizedBox(height: 14),
                        _buildInputField('Phone Number', phoneCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
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
                                        },
                                      );
                                      if (mounted) {
                                        Navigator.pop(modalCtx);
                                        _fetchAdminData();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('✅ Admin details updated!'),
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
                              backgroundColor: const Color(0xFF6366F1),
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
                                    'Save Admin Profile',
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
      {IconData? icon, TextInputType? keyboardType}) {
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
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D1A),
      appBar: AppBar(
        title: const Text(
          'Admin Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0D1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1)),
            onPressed: _showEditModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchAdminData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF6366F1),
              backgroundColor: const Color(0xFF161B36),
              onRefresh: _fetchAdminData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                child: Column(
                  children: [
                    // Admin Hero Card
                    _buildAdminHero(),
                    const SizedBox(height: 18),

                    // System Overview Grid (2x2)
                    _buildSystemStatsGrid(),
                    const SizedBox(height: 18),

                    // Quick Management Actions
                    _buildManagementActions(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAdminHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1A3F), Color(0xFF0F1326)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.35),
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
                    colors: [Color(0xFF6366F1), Color(0xFF38BDF8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 36,
                    color: Colors.white,
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
                  child: const Icon(Icons.shield_rounded, color: Colors.black, size: 11),
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
            _email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: const Text(
              'SUPER ADMINISTRATOR',
              style: TextStyle(
                color: Color(0xFF818CF8),
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

  Widget _buildSystemStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'System Overview',
            style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800),
          ),
        ),
        Row(
          children: [
            _buildStatCard('Trainers', '$_trainersCount', const Color(0xFFFF9F43), Icons.sports_rounded),
            const SizedBox(width: 10),
            _buildStatCard('Active Clients', '$_clientsCount', const Color(0xFF00F5A0), Icons.people_alt_rounded),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStatCard('Goal Categories', '$_categoriesCount', const Color(0xFF38BDF8), Icons.category_rounded),
            const SizedBox(width: 10),
            _buildStatCard('Master Exercises', '$_exercisesCount', const Color(0xFF818CF8), Icons.fitness_center_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color accent, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF131830),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementActions(BuildContext context) {
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
          _buildActionTile(
            Icons.edit_note_rounded,
            'Edit Administrator Info',
            'Update name & administrator contact profile',
            const Color(0xFF6366F1),
            onTap: _showEditModal,
          ),
          const Divider(height: 1, color: Colors.white10),
          _buildActionTile(
            Icons.sports_rounded,
            'Manage & Edit Coaches',
            'Edit trainer profiles, specialties & categories',
            const Color(0xFFFF9F43),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('👉 Switch to "Trainers" tab to edit coach profiles & categories.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(height: 1, color: Colors.white10),
          _buildActionTile(
            Icons.logout_rounded,
            'Sign Out',
            'Log out of administration portal',
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
                  content: const Text('Are you sure you want to log out of admin portal?', style: TextStyle(color: Colors.white70)),
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

  Widget _buildActionTile(IconData icon, String title, String subtitle, Color accent,
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