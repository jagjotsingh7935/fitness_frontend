import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class TrainerCard extends StatelessWidget {
  const TrainerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0056FF), Color(0xFF7C3AED)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'RK',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rahul Kumar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '⭐ 4.9 · Weight Loss Specialist',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.text2,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ACTIVE',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.green,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    fontSize: 10,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.chat_bubble_outline,
                color: AppColors.primary, size: 18),
          ),
        ],
      ),
    );
  }
}

