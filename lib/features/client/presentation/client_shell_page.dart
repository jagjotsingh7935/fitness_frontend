import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class ClientShellPage extends StatelessWidget {
  const ClientShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.background2,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Videos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

