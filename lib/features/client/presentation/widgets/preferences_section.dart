import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class PreferenceItemModel {
  const PreferenceItemModel({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.arrowColor,
  });

  final Widget icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? arrowColor;
}

class PreferencesSection extends StatelessWidget {
  const PreferencesSection({super.key, required this.items});

  final List<PreferenceItemModel> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List<Widget>.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return InkWell(
            onTap: item.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: item.icon,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.text2,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: item.arrowColor ?? AppColors.text3),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

