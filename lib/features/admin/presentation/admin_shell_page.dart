import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/exit_confirmation_dialog.dart';

class AdminShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShellPage({super.key, required this.navigationShell});

  void _onTap(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    final navItems = [
      const _AdminNavItemData('Dashboard', Icons.dashboard_rounded),
      const _AdminNavItemData('Trainers', Icons.sports_rounded),
      const _AdminNavItemData('Clients', Icons.people_alt_rounded),
      const _AdminNavItemData('Exercises', Icons.fitness_center_rounded),
      const _AdminNavItemData('Workouts', Icons.assignment_rounded),
      const _AdminNavItemData('Videos', Icons.video_library_rounded),
      const _AdminNavItemData('Profile', Icons.admin_panel_settings_rounded),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If on another tab, route back to Dashboard (tab 0)
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
          return;
        }

        // If on Dashboard, ask for exit confirmation
        final shouldExit = await showAppExitConfirmationDialog(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0D1A),
        extendBody: false, // Ensure content is NEVER hidden under the bottom bar
        body: navigationShell,
        bottomNavigationBar: Container(
          color: const Color(0xFF0A0D1A),
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: SafeArea(
            top: false,
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF181E3B),
                    Color(0xFF0F1326),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(navItems.length, (i) {
                    final item = navItems[i];
                    final isSelected = i == currentIndex;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onTap(i),
                          borderRadius: BorderRadius.circular(16),
                          splashColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          highlightColor: Colors.transparent,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSelected ? 12 : 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.22)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected
                                  ? Border.all(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 18,
                                  color: isSelected
                                      ? const Color(0xFF818CF8)
                                      : Colors.white.withValues(alpha: 0.45),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 5),
                                  Text(
                                    item.label,
                                    style: const TextStyle(
                                      color: Color(0xFF818CF8),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItemData {
  const _AdminNavItemData(this.label, this.icon);

  final String label;
  final IconData icon;
}