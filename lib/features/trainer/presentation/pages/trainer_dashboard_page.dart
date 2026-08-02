import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

// ─────────────────────────────────────────────
//  DUMMY DATA MODELS
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
  final double rating; // 0.0 – 5.0

  const _SatisfactionEntry(this.month, this.rating);
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
  bool _isLoading = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── Dummy Stats ──────────────────────────────
  final int _totalClients = 24;
  final int _activeWorkoutPlans = 18;
  final int _totalExercises = 142;
  final double _avgSatisfaction = 4.6;

  // ── Trainer Info ─────────────────────────────
  final String _trainerName = 'Alex Morgan';
  final List<String> _categories = ['Strength', 'HIIT', 'Mobility', 'Nutrition'];

  // ── Top Clients ──────────────────────────────
  final List<_TopClient> _topClients = const [
    _TopClient(
      name: 'Riya Sharma',
      avatarInitial: 'R',
      avatarColor: Color(0xFF7C3AED),
      goal: 'Weight Loss',
      sessionsCompleted: 32,
      progress: 0.82,
    ),
    _TopClient(
      name: 'Arjun Mehta',
      avatarInitial: 'A',
      avatarColor: Color(0xFF0891B2),
      goal: 'Muscle Gain',
      sessionsCompleted: 28,
      progress: 0.74,
    ),
    _TopClient(
      name: 'Priya Nair',
      avatarInitial: 'P',
      avatarColor: Color(0xFF059669),
      goal: 'Endurance',
      sessionsCompleted: 25,
      progress: 0.68,
    ),
    _TopClient(
      name: 'Kunal Singh',
      avatarInitial: 'K',
      avatarColor: Color(0xFFD97706),
      goal: 'Flexibility',
      sessionsCompleted: 20,
      progress: 0.55,
    ),
    _TopClient(
      name: 'Sneha Patel',
      avatarInitial: 'S',
      avatarColor: Color(0xFFE94560),
      goal: 'Core Strength',
      sessionsCompleted: 17,
      progress: 0.48,
    ),
  ];

  // ── Satisfaction Chart ────────────────────────
  final List<_SatisfactionEntry> _satisfaction = const [
    _SatisfactionEntry('Jan', 4.0),
    _SatisfactionEntry('Feb', 4.2),
    _SatisfactionEntry('Mar', 4.1),
    _SatisfactionEntry('Apr', 4.5),
    _SatisfactionEntry('May', 4.7),
    _SatisfactionEntry('Jun', 4.6),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeCtrl.forward();
      }
    });
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
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoader() : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Dashboard',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF111111),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go('/trainer/profile'),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFE94560),
            child: Text(
              _trainerName.isNotEmpty ? _trainerName[0].toUpperCase() : 'T',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFFE94560)),
          onPressed: () {
            setState(() => _isLoading = true);
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) setState(() => _isLoading = false);
            });
          },
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(),
            const SizedBox(height: 20),
            _buildCategoryChips(),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildSectionTitle('Satisfaction Trend'),
            const SizedBox(height: 12),
            _buildSatisfactionChart(),
            const SizedBox(height: 24),
            _buildSectionTitle('Top Clients'),
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
            color: const Color(0xFFE94560).withOpacity(0.35),
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
              _buildMiniPill('${_activeWorkoutPlans} Plans', Icons.assignment_rounded),
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
        color: Colors.white.withOpacity(0.15),
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
        Row(
          children: _categories.map((cat) {
            final color = categoryColors[cat] ?? const Color(0xFFE94560);
            final icon = categoryIcons[cat] ?? Icons.label;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      cat,
                      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
            subtitle: '+3 this month', onTap: () => context.go('/trainer/progress')),
        const SizedBox(width: 12),
        _buildStatCard('Avg Rating', '$_avgSatisfaction', Icons.star_rounded, Colors.amber,
            subtitle: 'Out of 5.0'),
        const SizedBox(width: 12),
        _buildStatCard('Sessions', '186', Icons.calendar_today_rounded, const Color(0xFFE94560),
            subtitle: 'This month'),
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
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Client Satisfaction',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Last 6 months',
                    style: TextStyle(color: Color(0xFFE94560), fontSize: 10)),
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
                    style: const TextStyle(color: Colors.white38, fontSize: 10)))
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
    return Column(
      children: _topClients.asMap().entries.map((entry) {
        final i = entry.key;
        final client = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: i == 0
                      ? Colors.amber.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
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
                            color: client.avatarColor.withOpacity(0.15),
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
      (label: 'Assign Plan', icon: Icons.assignment_add, route: '/trainer/workouts'),
      (label: 'View Profile', icon: Icons.person_rounded, route: '/trainer/profile'),
      (label: 'Send Message', icon: Icons.chat_bubble_outline_rounded, route: null),
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
          onTap: () {
            if (a.route != null) {
              context.go(a.route!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${a.label} — Coming Soon'),
                  backgroundColor: const Color(0xFF1A1A1A),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE94560).withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE94560).withOpacity(0.15),
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

    const double minVal = 3.5;
    const double maxVal = 5.0;

    double xStep = size.width / (data.length - 1);

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      double x = i * xStep;
      double normalized = (data[i].rating - minVal) / (maxVal - minVal);
      double y = size.height - (normalized * size.height);
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
          const Color(0xFFE94560).withOpacity(0.35),
          const Color(0xFFE94560).withOpacity(0.0),
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
      // Dot glow
      canvas.drawCircle(
          points[i], 6, Paint()..color = const Color(0xFFE94560).withOpacity(0.25));
      canvas.drawCircle(points[i], 4, Paint()..color = const Color(0xFFE94560));
      canvas.drawCircle(points[i], 2, Paint()..color = Colors.white);

      // Rating label
      final tp = TextPainter(
        text: TextSpan(
          text: data[i].rating.toStringAsFixed(1),
          style: const TextStyle(color: Colors.white70, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, points[i].dy - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}