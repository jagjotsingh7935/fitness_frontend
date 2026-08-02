import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/demo_models.dart';

class WorkoutCards extends StatelessWidget {
  const WorkoutCards({super.key, required this.items, this.onTap});

  final List<WorkoutCardModel> items;
  final void Function(WorkoutCardModel workout)? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final w = items[index];
          return _WorkoutCard(
            model: w,
            onTap: onTap == null ? null : () => onTap!(w),
          );
        },
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.model, this.onTap});

  final WorkoutCardModel model;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = model.featured ? 200.0 : 160.0;
    final bg = model.featured
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF4C1D95)],
          )
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: model.featured ? null : AppColors.card,
          gradient: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                model.badge.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Text(model.icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              model.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
            ),
            const Spacer(),
            Row(
              children: [
                _Tag(label: model.durationLabel),
                const SizedBox(width: 8),
                _Tag(label: model.caloriesLabel),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    Container(color: Colors.white.withValues(alpha: 0.1)),
                    FractionallySizedBox(
                      widthFactor: model.progress.clamp(0, 1),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.text2,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

