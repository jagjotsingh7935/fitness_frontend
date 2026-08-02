import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum StatChangeDirection { up, down }

class StatCardModel {
  const StatCardModel({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
    required this.changeLabel,
    required this.changeDirection,
  });

  final String value;
  final String label;
  final Widget icon;
  final Color accent;
  final String changeLabel;
  final StatChangeDirection changeDirection;
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.model, this.onTap});

  final StatCardModel model;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isUp = model.changeDirection == StatChangeDirection.up;
    final changeBg = (isUp ? AppColors.green : AppColors.orange)
        .withValues(alpha: 0.12);
    final changeFg = isUp ? AppColors.green : AppColors.orange;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: model.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: model.accent.withValues(alpha: 0.15),
                  ),
                  alignment: Alignment.center,
                  child: IconTheme(
                    data: IconThemeData(color: model.accent, size: 18),
                    child: model.icon,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  model.value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        height: 1,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  model.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.text2,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: changeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    model.changeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: changeFg,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

