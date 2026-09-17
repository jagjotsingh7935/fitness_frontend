import 'package:flutter/material.dart';

import 'badges_row.dart';

class AllAchievementsSheet {
  static Future<void> show(
    BuildContext context, {
    required List<BadgeModel> badges,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AllAchievementsContent(badges: badges),
    );
  }
}

class _AllAchievementsContent extends StatelessWidget {
  const _AllAchievementsContent({required this.badges});

  final List<BadgeModel> badges;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final earnedCount = badges.where((b) => b.earned).length;
    final totalCount = badges.isNotEmpty ? badges.length : 1;
    final double percent = earnedCount / totalCount;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1326),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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

          // Header
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
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5C07B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5C07B).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🏆', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'All Achievements',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Milestones & badges earned on your journey',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 24 + bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1F3D), Color(0xFF13172E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00F5A0).withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$earnedCount of $totalCount Unlocked',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF00F5A0).withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${(percent * 100).toInt()}% COMPLETED',
                                style: const TextStyle(
                                  color: Color(0xFF00F5A0),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 8,
                            backgroundColor: const Color(0xFF0C0E1C),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F5A0)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          earnedCount == totalCount
                              ? '🏆 Incredible! You have unlocked every single achievement milestone!'
                              : 'Keep logging workouts, diet meals, and hydration daily to unlock more trophies!',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Title
                  Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5C07B),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'All Milestones',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Achievement Grid Cards
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: badges.length,
                    itemBuilder: (context, index) {
                      final badge = badges[index];
                      return _AchievementCard(badge: badge);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.badge});

  final BadgeModel badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: badge.earned ? const Color(0xFF161C36) : const Color(0xFF111425),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: badge.earned
              ? const Color(0xFFE5C07B).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
          width: badge.earned ? 1.4 : 1,
        ),
        boxShadow: badge.earned
            ? [
                BoxShadow(
                  color: const Color(0xFFE5C07B).withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badge.earned
                  ? const Color(0xFFE5C07B).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: badge.earned ? const Color(0xFFE5C07B) : Colors.white24,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              badge.emoji,
              style: TextStyle(
                fontSize: 26,
                color: badge.earned ? null : Colors.white24,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            badge.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: badge.earned ? Colors.white : Colors.white54,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              badge.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: badge.earned ? Colors.white70 : Colors.white38,
                fontSize: 10.5,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badge.earned
                  ? const Color(0xFF00F5A0).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: badge.earned
                    ? const Color(0xFF00F5A0).withValues(alpha: 0.4)
                    : Colors.white10,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  badge.earned ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                  size: 11,
                  color: badge.earned ? const Color(0xFF00F5A0) : Colors.white38,
                ),
                const SizedBox(width: 4),
                Text(
                  badge.earned ? 'UNLOCKED' : 'LOCKED',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: badge.earned ? const Color(0xFF00F5A0) : Colors.white38,
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
