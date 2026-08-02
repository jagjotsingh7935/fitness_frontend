import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class QuickActionModel {
  const QuickActionModel({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
}

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key, required this.items});

  final List<QuickActionModel> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: items.map((item) => _QuickAction(item: item)).toList(),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.item});
  final QuickActionModel item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item.gradient,
              ),
            ),
            child: Icon(item.icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.text2,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

