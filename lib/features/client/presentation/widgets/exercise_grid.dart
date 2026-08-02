import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/demo_models.dart';

class ExerciseGrid extends StatelessWidget {
  const ExerciseGrid({super.key, required this.exercises, this.onTap});

  final List<ExerciseModel> exercises;
  final void Function(ExerciseModel ex)? onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, i) {
        final ex = exercises[i];
        return InkWell(
          onTap: onTap == null ? null : () => onTap!(ex),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(ex.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  ex.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  ex.detail,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.text2,
                        fontSize: 10,
                      ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(ex.totalSets, (idx) {
                    final done = idx < ex.doneSets;
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: done ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

