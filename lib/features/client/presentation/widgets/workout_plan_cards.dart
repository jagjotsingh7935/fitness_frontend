import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class WorkoutPlanCards extends StatelessWidget {
  const WorkoutPlanCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _WorkoutPlanCard(
          title: '8-Week Fat Burn',
          subtitle: 'Week 4 of 8 · Intermediate',
          badgeLabel: 'Active',
          badgeColor: AppColors.primary,
          days: [
            _DayState.completed,
            _DayState.completed,
            _DayState.completed,
            _DayState.today,
            _DayState.normal,
            _DayState.rest,
            _DayState.normal,
          ],
        ),
        SizedBox(height: 12),
        _WorkoutPlanCard(
          title: 'Core Strength Builder',
          subtitle: 'Week 2 of 4 · Beginner',
          badgeLabel: 'Scheduled',
          badgeColor: AppColors.accent,
          days: [
            _DayState.completed,
            _DayState.completed,
            _DayState.rest,
            _DayState.today,
            _DayState.normal,
            _DayState.rest,
            _DayState.rest,
          ],
        ),
      ],
    );
  }
}

enum _DayState { normal, completed, today, rest }

class _WorkoutPlanCard extends StatelessWidget {
  const _WorkoutPlanCard({
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeColor,
    required this.days,
  });

  final String title;
  final String subtitle;
  final String badgeLabel;
  final Color badgeColor;
  final List<_DayState> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.text2,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeLabel.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: badgeColor == AppColors.primary
                            ? AppColors.primary.withValues(alpha: 0.85)
                            : AppColors.accent.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(7, (i) {
              const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              return _DayCircle(label: labels[i], state: days[i]);
            }),
          ),
          const SizedBox(height: 4),
          Text(
            'R = Rest Day',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.text3,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({required this.label, required this.state});
  final String label;
  final _DayState state;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    final String center;

    switch (state) {
      case _DayState.completed:
        bg = AppColors.primary.withValues(alpha: 0.15);
        fg = AppColors.primary;
        border = AppColors.primary;
        center = '✓';
      case _DayState.today:
        bg = AppColors.primary;
        fg = Colors.white;
        border = Colors.transparent;
        center = '•';
      case _DayState.rest:
        bg = AppColors.orange.withValues(alpha: 0.1);
        fg = AppColors.orange;
        border = AppColors.orange.withValues(alpha: 0.3);
        center = 'R';
      case _DayState.normal:
        bg = AppColors.card2;
        fg = AppColors.text3;
        border = Colors.transparent;
        center = '';
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: border, width: 2),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: fg,
                ),
          ),
          Text(
            center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: fg,
                  height: 1.05,
                ),
          ),
        ],
      ),
    );
  }
}

