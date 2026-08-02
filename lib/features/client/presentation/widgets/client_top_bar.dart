import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ClientTopBar extends StatelessWidget {
  const ClientTopBar({
    super.key,
    required this.greeting,
    required this.title,
    this.showNotification = false,
    this.onNotificationTap,
    this.trailing,
  });

  final String greeting;
  final String title;
  final bool showNotification;
  final VoidCallback? onNotificationTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, Colors.transparent],
          stops: [0.7, 1],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.text2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        fontSize: 10,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[trailing!] else ...[
            Row(
              children: [
                _NotificationButton(
                  visible: showNotification,
                  onTap: onNotificationTap,
                ),
                const SizedBox(width: 10),
                const _Avatar(initials: 'A'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.visible, this.onTap});

  final bool visible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            const Center(child: Icon(Icons.notifications_none, size: 20)),
            if (visible)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.pink,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: AppColors.background,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

