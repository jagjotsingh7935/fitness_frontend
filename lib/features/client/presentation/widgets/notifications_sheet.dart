import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/demo_models.dart';

class NotificationsSheet {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _NotificationsContent();
      },
    );
  }
}

class _NotificationsContent extends StatelessWidget {
  const _NotificationsContent();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.text3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 16),
              ...DemoClientData.notifications.map((n) => _NotifEntry(n: n)),
            ],
          ),
        );
      },
    );
  }
}

class _NotifEntry extends StatelessWidget {
  const _NotifEntry({required this.n});
  final ClientNotification n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: n.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(n.icon, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  n.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.text2,
                        fontSize: 11,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  n.time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.text3,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

