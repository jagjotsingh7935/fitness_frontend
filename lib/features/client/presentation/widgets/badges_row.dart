import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class BadgeModel {
  const BadgeModel({required this.emoji, required this.name, required this.earned});

  final String emoji;
  final String name;
  final bool earned;
}

class BadgesRow extends StatelessWidget {
  const BadgesRow({super.key, required this.badges});

  final List<BadgeModel> badges;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _BadgeItem(badge: badges[index]),
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({required this.badge});
  final BadgeModel badge;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        badge.earned ? AppColors.yellow : AppColors.border;
    final bg = badge.earned
        ? AppColors.yellow.withValues(alpha: 0.08)
        : Colors.transparent;

    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
            color: bg,
            boxShadow: badge.earned
                ? [
                    BoxShadow(
                      color: AppColors.yellow.withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(badge.emoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: Text(
            badge.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.text2,
                  fontSize: 9,
                  height: 1.2,
                ),
          ),
        ),
      ],
    );
  }
}

