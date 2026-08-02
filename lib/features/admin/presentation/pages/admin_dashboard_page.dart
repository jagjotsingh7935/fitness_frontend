import 'package:flutter/material.dart';
import 'dart:ui';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 28),
                _buildSectionLabel('OVERVIEW'),
                const SizedBox(height: 14),
                _buildStatsGrid(context),
                const SizedBox(height: 32),
                _buildSectionLabel('QUICK ACTIONS'),
                const SizedBox(height: 14),
                _buildActionsGrid(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF0D0D0D),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF16213E),
                    Color(0xFF0F3460),
                  ],
                ),
              ),
            ),
            // Decorative circle accent
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE94560).withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0F3460).withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Header text
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE94560),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ADMIN PANEL',
                        style: TextStyle(
                          color: Color(0xFFE94560),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Welcome back,\nAdmin!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your fitness platform from here',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      title: const Text(
        'Dashboard',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFE94560),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final stats = [
      _StatData('Total Trainers', '12', Icons.person_outline, const Color(0xFF4ECDC4), const Color(0xFF1A1A2E)),
      _StatData('Total Clients', '156', Icons.people_outline, const Color(0xFF45B7D1), const Color(0xFF1A1A2E)),
      _StatData('Diet Plans', '8', Icons.restaurant_outlined, const Color(0xFFFFBE0B), const Color(0xFF1A1A2E)),
      _StatData('Workouts', '24', Icons.fitness_center, const Color(0xFFE94560), const Color(0xFF1A1A2E)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.45,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _buildStatCard(context, stats[index]),
    );
  }

  Widget _buildStatCard(BuildContext context, _StatData data) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                data.bgColor.withOpacity(0.9),
                data.bgColor.withOpacity(0.6),
              ],
            ),
            border: Border.all(
              color: data.accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(data.icon, color: data.accentColor, size: 22),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsGrid(BuildContext context) {
    final actions = [
      _ActionData('Add Trainer', Icons.person_add_outlined, const Color(0xFF4ECDC4)),
      _ActionData('Add Client', Icons.group_add_outlined, const Color(0xFF45B7D1)),
      _ActionData('Create Diet Plan', Icons.restaurant_outlined, const Color(0xFFFFBE0B)),
      _ActionData('Create Workout', Icons.fitness_center, const Color(0xFFE94560)),
      _ActionData('Upload Video', Icons.video_library_outlined, const Color(0xFFBB86FC)),
    ];

    return Column(
      children: [
        // Top row: 2 items
        Row(
          children: actions
              .sublist(0, 2)
              .map((a) => Expanded(child: Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: _buildActionButton(context, a),
                  )))
              .toList()
            ..[1] = Expanded(child: _buildActionButton(context, actions[1])),
        ),
        const SizedBox(height: 12),
        // Middle row: 2 items
        Row(
          children: [
            Expanded(child: _buildActionButton(context, actions[2])),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(context, actions[3])),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom: full width
        _buildActionButton(context, actions[4], fullWidth: true),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, _ActionData data, {bool fullWidth = false}) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data.label} - Coming Soon'),
            backgroundColor: data.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1C1C1C),
          border: Border.all(
            color: data.color.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(data.icon, color: data.color, size: 18),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                data.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (fullWidth) ...[
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: data.color.withOpacity(0.5), size: 13),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;

  const _StatData(this.title, this.value, this.icon, this.accentColor, this.bgColor);
}

class _ActionData {
  final String label;
  final IconData icon;
  final Color color;

  const _ActionData(this.label, this.icon, this.color);
}