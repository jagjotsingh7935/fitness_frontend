import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.periodLabel,
    required this.child,
  });

  final String title;
  final String periodLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  periodLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

