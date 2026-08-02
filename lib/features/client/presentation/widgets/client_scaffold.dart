import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'client_top_bar.dart';

class ClientScaffold extends StatelessWidget {
  const ClientScaffold({
    super.key,
    required this.greeting,
    required this.title,
    required this.child,
    this.showNotificationDot = false,
    this.onNotificationTap,
  });

  final String greeting;
  final String title;
  final Widget child;
  final bool showNotificationDot;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            ClientTopBar(
              greeting: greeting,
              title: title,
              showNotification: showNotificationDot,
              onNotificationTap: onNotificationTap,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

