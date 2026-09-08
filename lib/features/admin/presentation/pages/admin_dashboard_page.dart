import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/dio_client.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final Dio _dio = GetIt.I<DioClient>().dio;
  bool _isLoading = false;

  int _totalTrainers = 0;
  int _totalClients = 0;
  int _totalCategories = 0;
  int _totalExercises = 0;

  @override
  void initState() {
    super.initState();
    _fetchLiveMetrics();
  }

  Future<void> _fetchLiveMetrics() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Trainers
      try {
        final res = await _dio.get('/accounts/api/trainer/');
        if (res.statusCode == 200) {
          final d = res.data;
          _totalTrainers = (d is Map && d['results'] is List)
              ? (d['results'] as List).length
              : (d is List ? d.length : 0);
        }
      } catch (_) {}

      // 2. Fetch Clients
      try {
        final res = await _dio.get('/accounts/api/client/');
        if (res.statusCode == 200) {
          final d = res.data;
          _totalClients = (d is Map && d['results'] is List)
              ? (d['results'] as List).length
              : (d is List ? d.length : 0);
        }
      } catch (_) {}

      // 3. Fetch Categories
      try {
        final res = await _dio.get('/accounts/api/category-list/');
        if (res.statusCode == 200 && res.data is List) {
          _totalCategories = (res.data as List).length;
        }
      } catch (_) {}

      // 4. Fetch Exercises
      try {
        final res = await _dio.get('/fitness/api/exercises/');
        if (res.statusCode == 200) {
          final d = res.data;
          _totalExercises = (d is Map && d['results'] is List)
              ? (d['results'] as List).length
              : (d is List ? d.length : 0);
        }
      } catch (_) {}

      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0D1A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/flux_icon.jpg',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Row(
              children: const [
                Text(
                  'FLUX',
                  style: TextStyle(
                    color: Color(0xFFE5C07B),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Admin Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _isLoading ? null : _fetchLiveMetrics,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF6366F1),
        backgroundColor: const Color(0xFF161B36),
        onRefresh: _fetchLiveMetrics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Welcome Header Banner
              _buildWelcomeBanner(),
              const SizedBox(height: 20),

              // 2. Section Header: Overview
              _buildSectionHeader('PLATFORM METRICS', 'Live Database Stats', const Color(0xFF6366F1)),
              const SizedBox(height: 12),

              // 3. Stats Grid (100% Overflow-safe)
              _buildResponsiveStatsGrid(),
              const SizedBox(height: 24),

              // 4. Section Header: Quick Actions
              _buildSectionHeader('MANAGEMENT ACTIONS', 'Quick System Operations', const Color(0xFF00F5A0)),
              const SizedBox(height: 12),

              // 5. Action Cards
              _buildActionCards(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F1D48),
            Color(0xFF11142A),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SUPER ADMIN',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF818CF8),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00F5A0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00F5A0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Welcome, Administrator',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Monitor trainers, manage client enrollments & workout curricula',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF818CF8),
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String tag, String title, Color accent) {
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
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tag,
              style: TextStyle(
                color: accent,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResponsiveStatsGrid() {
    final stats = [
      _AdminStatItem(
        title: 'Active Trainers',
        value: '$_totalTrainers',
        icon: Icons.sports_rounded,
        accent: const Color(0xFFFF9F43),
        tag: 'Coaches',
      ),
      _AdminStatItem(
        title: 'Enrolled Clients',
        value: '$_totalClients',
        icon: Icons.people_alt_rounded,
        accent: const Color(0xFF00F5A0),
        tag: 'Members',
      ),
      _AdminStatItem(
        title: 'Goal Categories',
        value: '$_totalCategories',
        icon: Icons.category_rounded,
        accent: const Color(0xFF38BDF8),
        tag: 'Tags',
      ),
      _AdminStatItem(
        title: 'Master Exercises',
        value: '$_totalExercises',
        icon: Icons.fitness_center_rounded,
        accent: const Color(0xFF818CF8),
        tag: 'Routines',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemCount: stats.length,
      itemBuilder: (context, i) => _buildStatTile(stats[i]),
    );
  }

  Widget _buildStatTile(_AdminStatItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131830),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, color: item.accent, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.tag,
                  style: TextStyle(
                    color: item.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Text(
            item.title,
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
    );
  }

  Widget _buildActionCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'Trainers Hub',
                subtitle: 'Manage & link coaches',
                icon: Icons.sports_rounded,
                color: const Color(0xFFFF9F43),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('👉 Switch to "Trainers" tab in the bottom bar to manage coaches.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                label: 'Clients Hub',
                subtitle: 'Enroll & assign coach',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF00F5A0),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('👉 Switch to "Clients" tab in the bottom bar to manage clients.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'Exercises Library',
                subtitle: 'Master movement list',
                icon: Icons.fitness_center_rounded,
                color: const Color(0xFF818CF8),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('👉 Switch to "Exercises" tab in the bottom bar.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                label: 'Workout Builder',
                subtitle: 'Curate weekly splits',
                icon: Icons.assignment_rounded,
                color: const Color(0xFFFF4B72),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('👉 Switch to "Workouts" tab in the bottom bar.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131830),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminStatItem {
  const _AdminStatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    required this.tag,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final String tag;
}