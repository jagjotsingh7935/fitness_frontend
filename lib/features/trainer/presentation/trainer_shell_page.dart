import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TrainerShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const TrainerShellPage({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: navigationShell,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.trending_up_outlined, Icons.trending_up, 'Progress'),
    _NavItem(Icons.library_books_outlined, Icons.library_books, 'Exercises'),
    _NavItem(Icons.assignment_outlined, Icons.assignment, 'Plans'),
    _NavItem(Icons.person_outline, Icons.person, 'Profile'),
  ];

  Widget _buildBottomNav(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE94560).withOpacity(0.15),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = index == currentIndex;
              return Expanded(
                child: _NavButton(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => navigationShell.goBranch(
                    index,
                    initialLocation: index == currentIndex,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? const Color(0xFFE94560).withOpacity(0.12)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                key: ValueKey(isSelected),
                size: 22,
                color: isSelected
                    ? const Color(0xFFE94560)
                    : Colors.white.withOpacity(0.35),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFFE94560)
                    : Colors.white.withOpacity(0.35),
                letterSpacing: isSelected ? 0.3 : 0,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}