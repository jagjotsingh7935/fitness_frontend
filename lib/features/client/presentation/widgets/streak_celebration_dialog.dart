import 'package:flutter/material.dart';

class StreakCelebrationDialog extends StatelessWidget {
  final int streakDays;
  final List<dynamic> weekDots;

  const StreakCelebrationDialog({
    super.key,
    required this.streakDays,
    required this.weekDots,
  });

  static Future<void> show(
    BuildContext context, {
    required int streakDays,
    required List<dynamic> weekDots,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StreakCelebrationDialog(
        streakDays: streakDays,
        weekDots: weekDots,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E2540),
              Color(0xFF141829),
              Color(0xFF0C0E1B),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFE5C07B).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Close Button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                ),
              ),
            ),

            // Flame Icon with Glowing Aura
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFFF3366)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('🔥', style: TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: 18),

            // Streak Headline
            Text(
              ' Day Streak!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Motivation Subtitle
            Text(
              'Streak updated for today! You opened the app and stayed committed. Keep the flame burning!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            // Week Dots Visual Tracker
            if (weekDots.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1322),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekDots.map((d) {
                    final dayName = (d['day_name'] ?? '').toString();
                    final isActive = d['is_active'] == true;
                    final isToday = d['is_today'] == true;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            color: isToday ? const Color(0xFF00F5A0) : Colors.white54,
                            fontSize: 10.5,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? const Color(0xFFFF8C00)
                                : Colors.white.withValues(alpha: 0.12),
                            border: isToday
                                ? Border.all(color: const Color(0xFF00F5A0), width: 2)
                                : null,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF8C00).withValues(alpha: 0.6),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: isActive
                              ? const Icon(Icons.check, size: 9, color: Colors.white)
                              : null,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 22),
            ],

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: const Color(0xFFE94560).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Keep It Up! 💪',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
