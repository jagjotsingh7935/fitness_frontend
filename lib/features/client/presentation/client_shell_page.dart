import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/exit_confirmation_dialog.dart';

class ClientShellPage extends StatelessWidget {
  const ClientShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If on another tab, route back to Home tab
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
          return;
        }

        // If on Home tab, ask for exit confirmation
        final shouldExit = await showAppExitConfirmationDialog(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0D1A),
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF181E3B),
                  Color(0xFF0F1326),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF00F5A0).withValues(alpha: 0.05),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavBarItem(
                  index: 0,
                  currentIndex: currentIndex,
                  label: 'Home',
                  icon: Icons.grid_view_rounded,
                  onTap: () => _onTap(0),
                ),
                _NavBarItem(
                  index: 1,
                  currentIndex: currentIndex,
                  label: 'Workouts',
                  icon: Icons.fitness_center_rounded,
                  onTap: () => _onTap(1),
                ),
                _NavBarItem(
                  index: 2,
                  currentIndex: currentIndex,
                  label: 'Plans',
                  icon: Icons.calendar_today_rounded,
                  onTap: () => _onTap(2),
                ),
                // Videos tab commented out as requested
                // _NavBarItem(
                //   index: 3,
                //   currentIndex: currentIndex,
                //   label: 'Videos',
                //   icon: Icons.play_circle_fill_rounded,
                //   onTap: () => _onTap(3),
                // ),
                _NavBarItem(
                  index: 3,
                  currentIndex: currentIndex,
                  label: 'Profile',
                  icon: Icons.person_rounded,
                  onTap: () => _onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xFF00F5A0).withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 12 : 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00F5A0).withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: isSelected
                ? Border.all(
                    color: const Color(0xFF00F5A0).withValues(alpha: 0.35),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: isSelected
                    ? const Color(0xFF00F5A0)
                    : Colors.white.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF00F5A0)
                      : Colors.white.withValues(alpha: 0.45),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 10,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
