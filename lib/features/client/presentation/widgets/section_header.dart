import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (actionLabel != null)
            InkWell(
              onTap: onActionTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  actionLabel!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

