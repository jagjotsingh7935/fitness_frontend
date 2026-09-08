import 'package:flutter/material.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.days,
    required this.litDots,
    this.weekDots = const [],
    this.onTap,
  });

  final int days;
  final int litDots;
  final List<dynamic> weekDots;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1728),
              Color(0xFF151424),
              Color(0xFF0D0F1B),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFFF3366)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.45),
                    blurRadius: 14,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('🔥', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$days Day Streak!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontSize: 17,
                              letterSpacing: -0.2,
                            ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C00).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$litDots/7 Active',
                          style: const TextStyle(
                            color: Color(0xFFFF8C00),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Keep it up — don't break the chain!",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Week Dots
                  Row(
                    children: weekDots.isNotEmpty
                        ? weekDots.map((d) {
                            final isActive = d['is_active'] == true;
                            final isToday = d['is_today'] == true;
                            return Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFFF8C00)
                                    : Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(99),
                                border: isToday
                                    ? Border.all(color: const Color(0xFF00F5A0), width: 1.5)
                                    : null,
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF8C00).withValues(alpha: 0.7),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          }).toList()
                        : List<Widget>.generate(7, (i) {
                            final lit = i < litDots;
                            return Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: lit
                                    ? const Color(0xFFFF8C00)
                                    : Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: lit
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF8C00).withValues(alpha: 0.7),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

