import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.days, required this.litDots});

  final int days;
  final int litDots;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B35),
            const Color(0xFFF7C59F).withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 38)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$days Day Streak!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Keep it up — don't break the chain!",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: List<Widget>.generate(10, (i) {
                    final lit = i < litDots;
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: lit
                            ? AppColors.yellow
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: lit
                            ? [
                                BoxShadow(
                                  color: AppColors.yellow.withValues(alpha: 0.7),
                                  blurRadius: 8,
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
    );
  }
}

