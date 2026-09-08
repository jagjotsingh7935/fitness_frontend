import 'package:flutter/material.dart';

import 'client_top_bar.dart';

class ClientScaffold extends StatelessWidget {
  const ClientScaffold({
    super.key,
    required this.greeting,
    required this.title,
    required this.child,
    this.showNotificationDot = false,
    this.onNotificationTap,
    this.onRefresh,
  });

  final String greeting;
  final String title;
  final Widget child;
  final bool showNotificationDot;
  final VoidCallback? onNotificationTap;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF090B14),
      ),
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
              child: onRefresh != null
                  ? RefreshIndicator(
                      onRefresh: onRefresh!,
                      color: const Color(0xFFE94560),
                      backgroundColor: const Color(0xFF161B30),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        child: child,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      child: child,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

