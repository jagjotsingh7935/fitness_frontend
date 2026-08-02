import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ProfileHero extends StatelessWidget {
  const ProfileHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A3E), Color(0xFF0D1B3E)],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.accent],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 3,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'A',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Arjun Singh',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            'Weight Loss · Ludhiana, Punjab 📍',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.text2,
                ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                Expanded(child: _Stat(val: '12', lbl: 'Day Streak')),
                Expanded(child: _Stat(val: '8', lbl: 'Workouts')),
                Expanded(child: _Stat(val: '3.2', lbl: 'Kg Lost')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.val, required this.lbl});
  final String val;
  final String lbl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            lbl,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.text2,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

