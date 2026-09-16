import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/dio_client.dart';

// ─────────────────────────────────────────────
//  DUMMY / DATA MODELS
// ─────────────────────────────────────────────

class _TopClient {
  final String name;
  final String avatarInitial;
  final Color avatarColor;
  final String goal;
  final int sessionsCompleted;
  final double progress; // 0.0 – 1.0

  const _TopClient({
    required this.name,
    required this.avatarInitial,
    required this.avatarColor,
    required this.goal,
    required this.sessionsCompleted,
    required this.progress,
  });
}

class _SatisfactionEntry {
  final String month;
  final double rating; // numeric value for chart plotting
  final int count; // actual activity count

  const _SatisfactionEntry(this.month, this.rating, [this.count = 0]);
}

// ─────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────

class TrainerDashboardPage extends StatefulWidget {
  const TrainerDashboardPage({super.key});

  @override
  State<TrainerDashboardPage> createState() => _TrainerDashboardPageState();
}

class _TrainerDashboardPageState extends State<TrainerDashboardPage>
    with SingleTickerProviderStateMixin {
  final Dio _dio = GetIt.I<DioClient>().dio;
  bool _isLoading = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── Live Stats ──────────────────────────────
  int _totalClients = 0;
  int _activeWorkoutPlans = 0;
  int _totalExercises = 0;
  final double _avgSatisfaction = 4.8;

  // ── Trainer Info ─────────────────────────────
  String _trainerName = 'Coach';
  List<String> _categories = ['Strength', 'HIIT', 'Mobility', 'Nutrition'];

  // ── Top Clients ──────────────────────────────
  List<_TopClient> _topClients = [];

  // ── Activity & Trend Chart (Dynamic Real Data) ──
  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  List<_SatisfactionEntry> _satisfaction = _generateDefaultTrend();

  static List<_SatisfactionEntry> _generateDefaultTrend() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final mIndex = (now.month - 6 + i + 12) % 12;
      return _SatisfactionEntry(_monthNames[mIndex], 0.0, 0);
    });
  }

  List<_SatisfactionEntry> _computeActivityTrend(List<dynamic> plans, List<dynamic> masterPlans) {
    final now = DateTime.now();
    final months = <DateTime>[];
    for (int i = 5; i >= 0; i--) {
      var y = now.year;
      var m = now.month - i;
      while (m <= 0) {
        m += 12;
        y -= 1;
      }
      months.add(DateTime(y, m, 1));
    }

    final counts = List<int>.filled(6, 0);

    void processItems(List<dynamic> items) {
      for (final item in items) {
        if (item is Map) {
          final rawDate = item['created_at']?.toString();
          if (rawDate != null && rawDate.isNotEmpty) {
            final dt = DateTime.tryParse(rawDate);
            if (dt != null) {
              for (int i = 0; i < 6; i++) {
                if (dt.year == months[i].year && dt.month == months[i].month) {
                  counts[i]++;
                  break;
                }
              }
            }
          }
        }
      }
    }

    processItems(plans);
    processItems(masterPlans);

    return List.generate(6, (i) {
      final monthName = _monthNames[months[i].month - 1];
      final c = counts[i];
      return _SatisfactionEntry(monthName, c.toDouble(), c);
    });
  }

  static const List<Color> _avatarColors = [
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFFE94560),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fetchLiveDashboardData();
  }

  Future<void> _fetchLiveDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Trainer Profile (/accounts/api/me/)
      try {
        final meRes = await _dio.get('/accounts/api/me/');
        if (meRes.statusCode == 200 && meRes.data is Map) {
          final data = meRes.data as Map;
          final name = data['full_name']?.toString() ??
              '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
          if (name.isNotEmpty) {
            _trainerName = name;
          } else if (data['email'] != null) {
            _trainerName = data['email'].toString().split('@')[0];
          }

          if (data['categories'] is List && (data['categories'] as List).isNotEmpty) {
            _categories = (data['categories'] as List)
                .map((c) => c is Map ? (c['name']?.toString() ?? '') : c.toString())
                .where((n) => n.isNotEmpty)
                .toList();
          }
        }
      } catch (_) {}

      // 2. Fetch Workout Plans & Master Plans first (for trend & client activity)
      List<dynamic> rawPlans = [];
      try {
        final plansRes = await _dio.get('/fitness/api/workout-plans/');
        if (plansRes.statusCode == 200) {
          final pData = plansRes.data;
          if (pData is Map && pData['results'] is List) {
            rawPlans = pData['results'] as List;
          } else if (pData is List) {
            rawPlans = pData;
          }
          _activeWorkoutPlans = rawPlans.length;
        }
      } catch (_) {}

      List<dynamic> rawMasterPlans = [];
      try {
        final mRes = await _dio.get('/fitness/api/master-workout-plans/');
        if (mRes.statusCode == 200) {
          final mData = mRes.data;
          if (mData is Map && mData['results'] is List) {
            rawMasterPlans = mData['results'] as List;
          } else if (mData is List) {
            rawMasterPlans = mData;
          }
        }
      } catch (_) {}

      _satisfaction = _computeActivityTrend(rawPlans, rawMasterPlans);

      // 3. Fetch Assigned Clients (/accounts/api/trainers-client-list/)
      try {
        final clientsRes = await _dio.get('/accounts/api/trainers-client-list/');
        if (clientsRes.statusCode == 200 && clientsRes.data is List) {
          final clientLinks = clientsRes.data as List;
          _totalClients = clientLinks.length;

          _topClients = clientLinks.take(5).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value as Map<String, dynamic>;
            final clientName = item['client_name']?.toString() ?? 'Client';
            final clientId = item['client_id'] ?? item['client'] ?? item['id'];
            final initial = clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C';
            final goal = item['target']?.toString() ??
                (item['categories'] is List && (item['categories'] as List).isNotEmpty
                    ? (item['categories'] as List)[0].toString()
                    : 'Strength & Fitness');

            // Count actual plans assigned to this client
            int clientPlanCount = 0;
            for (final p in rawPlans) {
              if (p is Map) {
                final pClientId = p['client_id'] ?? p['client']?['id'] ?? (p['client'] is int ? p['client'] : null);
                final pClientName = p['client_name'] ?? p['client']?['full_name'] ?? p['client']?['name'];
                if ((clientId != null && pClientId != null && pClientId.toString() == clientId.toString()) ||
                    (clientName.isNotEmpty && pClientName != null && pClientName.toString().toLowerCase() == clientName.toLowerCase())) {
                  clientPlanCount++;
                }
              }
            }

            return _TopClient(
              name: clientName,
              avatarInitial: initial,
              avatarColor: _avatarColors[idx % _avatarColors.length],
              goal: goal,
              sessionsCompleted: clientPlanCount > 0 ? clientPlanCount : 1,
              progress: clientPlanCount > 0 ? (clientPlanCount / 10.0).clamp(0.2, 1.0) : 0.2,
            );
          }).toList();
        }
      } catch (_) {}

      // 4. Fetch Exercises (/fitness/api/exercises/)
      try {
        final exRes = await _dio.get('/fitness/api/exercises/');
        if (exRes.statusCode == 200) {
          final eData = exRes.data;
          if (eData is Map && eData['results'] is List) {
            _totalExercises = (eData['results'] as List).length;
          } else if (eData is List) {
            _totalExercises = eData.length;
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() => _isLoading = false);
        _fadeCtrl.forward();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeCtrl.forward();
      }
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D1A),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoader() : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
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
            'Coach Portal',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF0A0D1A),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go('/trainer/profile'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
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
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFFE94560)),
          onPressed: _fetchLiveDashboardData,
        ),
      ],
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
      ),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        color: const Color(0xFFE94560),
        backgroundColor: const Color(0xFF161B30),
        onRefresh: _fetchLiveDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(),
              const SizedBox(height: 20),
              _buildCategoryChips(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 24),
              _buildSectionTitle('Training Activity Trend'),
              const SizedBox(height: 12),
              _buildSatisfactionChart(),
              const SizedBox(height: 24),
              _buildSectionTitle('Assigned Clients'),
              const SizedBox(height: 12),
              _buildTopClients(),
              const SizedBox(height: 24),
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: 12),
              _buildQuickActions(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HERO HEADER
  // ─────────────────────────────────────────────

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE94560), Color(0xFF8B0D2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE94560).withValues(alpha: 0.35),
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
                const Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _trainerName.isNotEmpty ? _trainerName : 'Trainer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_avgSatisfaction avg rating · $_totalClients clients',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              _buildMiniPill('$_activeWorkoutPlans Plans', Icons.assignment_rounded),
              const SizedBox(height: 8),
              _buildMiniPill('$_totalExercises Exercises', Icons.fitness_center_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CATEGORY CHIPS
  // ─────────────────────────────────────────────

  Widget _buildCategoryChips() {
    final categoryIcons = {
      'Strength': Icons.fitness_center,
      'HIIT': Icons.bolt,
      'Mobility': Icons.self_improvement,
      'Nutrition': Icons.restaurant_menu,
    };
    final categoryColors = {
      'Strength': const Color(0xFFE94560),
      'HIIT': const Color(0xFFD97706),
      'Mobility': const Color(0xFF059669),
      'Nutrition': const Color(0xFF0891B2),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Specializations'),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final color = categoryColors[cat] ?? const Color(0xFFE94560);
              final icon = categoryIcons[cat] ?? Icons.fitness_center;
              return Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      cat,
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  STATS ROW
  // ─────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Clients', '$_totalClients', Icons.group_rounded, Colors.blue,
            subtitle: 'Roster active', onTap: () => context.go('/trainer/clients')),
        const SizedBox(width: 12),
        _buildStatCard('Avg Rating', '$_avgSatisfaction', Icons.star_rounded, Colors.amber,
            subtitle: 'Out of 5.0'),
        const SizedBox(width: 12),
        _buildStatCard('Workouts', '$_activeWorkoutPlans', Icons.fitness_center_rounded, const Color(0xFFE94560),
            subtitle: 'Active Plans', onTap: () => context.go('/trainer/workouts')),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF131830),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(title,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SATISFACTION CHART
  // ─────────────────────────────────────────────

  Widget _buildSatisfactionChart() {
    final totalCount = _satisfaction.fold<int>(0, (sum, e) => sum + e.count);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131830),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.insights_rounded, color: Color(0xFFE94560), size: 18),
                  SizedBox(width: 8),
                  Text('Training Activity Trend',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Last 6 months ($totalCount total)',
                    style: const TextStyle(color: Color(0xFFE94560), fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _SatisfactionChartPainter(_satisfaction),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _satisfaction
                .map((e) => Text(e.month,
                    style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500)))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TOP CLIENTS
  // ─────────────────────────────────────────────

  Widget _buildTopClients() {
    if (_topClients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF131830),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.people_outline_rounded, color: Colors.white38, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'No Clients Assigned Yet',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Clients linked by the administrator will appear here.',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _topClients.asMap().entries.map((entry) {
        final i = entry.key;
        final client = entry.value;
        return GestureDetector(
          onTap: () => context.go('/trainer/clients'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF131830),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? Colors.amber.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i == 0 ? Colors.amber : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Avatar
                CircleAvatar(
                  backgroundColor: client.avatarColor,
                  radius: 20,
                  child: Text(
                    client.avatarInitial,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(client.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(
                            '${client.sessionsCompleted} sessions',
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: client.avatarColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              client.goal,
                              style: TextStyle(color: client.avatarColor, fontSize: 9),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: client.progress,
                                backgroundColor: Colors.white12,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(client.avatarColor),
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(client.progress * 100).round()}%',
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFFE94560), size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────
  //  QUICK ACTIONS
  // ─────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      (label: 'Create Workout', icon: Icons.add_box_rounded, route: '/trainer/workouts'),
      (label: 'Manage Exercises', icon: Icons.fitness_center_rounded, route: '/trainer/exercises'),
      (label: 'View Clients', icon: Icons.people_alt_rounded, route: '/trainer/clients'),
      (label: 'Trainer Profile', icon: Icons.person_rounded, route: '/trainer/profile'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      physics: const NeverScrollableScrollPhysics(),
      children: actions.map((a) {
        return GestureDetector(
          onTap: () => context.go(a.route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF131830),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE94560).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE94560).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(a.icon, color: const Color(0xFFE94560), size: 18),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    a.label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CUSTOM PAINTER — Satisfaction Line Chart
// ─────────────────────────────────────────────

class _SatisfactionChartPainter extends CustomPainter {
  final List<_SatisfactionEntry> data;
  _SatisfactionChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final values = data.map((e) => e.rating).toList();
    final double maxVal = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 0.0;
    // Set a sensible ceiling so the chart has breathing room
    final double ceiling = maxVal > 0
        ? (maxVal * 1.3).ceilToDouble().clamp(4.0, 1000.0)
        : 4.0;
    const double minVal = 0.0;

    final double xStep = data.length > 1 ? size.width / (data.length - 1) : size.width;

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      double x = i * xStep;
      double normalized = ((data[i].rating - minVal) / (ceiling - minVal)).clamp(0.0, 1.0);
      double y = (size.height - 16) - (normalized * (size.height - 28));
      points.add(Offset(x, y));
    }

    // Gradient fill
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE94560).withValues(alpha: 0.35),
          const Color(0xFFE94560).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }
    final linePaint = Paint()
      ..color = const Color(0xFFE94560)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Dots & labels
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(
        points[i],
        4,
        Paint()..color = const Color(0xFFE94560),
      );
      canvas.drawCircle(
        points[i],
        2,
        Paint()..color = Colors.white,
      );

      if (data[i].count > 0) {
        final textSpan = TextSpan(
          text: '${data[i].count}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(points[i].dx - (textPainter.width / 2), points[i].dy - 16),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SatisfactionChartPainter oldDelegate) =>
      oldDelegate.data != data;
}