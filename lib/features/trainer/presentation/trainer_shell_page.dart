import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/exit_confirmation_dialog.dart';

class TrainerShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const TrainerShellPage({super.key, required this.navigationShell});

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
                  color: const Color(0xFFFF4B72).withValues(alpha: 0.06),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TrainerNavItem(
                  index: 0,
                  currentIndex: currentIndex,
                  label: 'Dashboard',
                  icon: Icons.dashboard_rounded,
                  onTap: () => _onTap(0),
                ),
                _TrainerNavItem(
                  index: 1,
                  currentIndex: currentIndex,
                  label: 'Clients',
                  icon: Icons.people_alt_rounded,
                  onTap: () => _onTap(1),
                ),
                _TrainerNavItem(
                  index: 2,
                  currentIndex: currentIndex,
                  label: 'Exercises',
                  icon: Icons.fitness_center_rounded,
                  onTap: () => _onTap(2),
                ),
                _TrainerNavItem(
                  index: 3,
                  currentIndex: currentIndex,
                  label: 'Routines',
                  icon: Icons.assignment_rounded,
                  onTap: () => _onTap(3),
                ),
                _TrainerNavItem(
                  index: 4,
                  currentIndex: currentIndex,
                  label: 'Profile',
                  icon: Icons.person_rounded,
                  onTap: () => _onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrainerNavItem extends StatelessWidget {
  const _TrainerNavItem({
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
        splashColor: const Color(0xFFFF4B72).withValues(alpha: 0.15),
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
                ? const Color(0xFFFF4B72).withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: isSelected
                ? Border.all(
                    color: const Color(0xFFFF4B72).withValues(alpha: 0.35),
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
                    ? const Color(0xFFFF4B72)
                    : Colors.white.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFFF4B72)
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