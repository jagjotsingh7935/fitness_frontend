import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../state/plans_cubit.dart';

class PlanTabs extends StatelessWidget {
  const PlanTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlansCubit(),
      child: BlocBuilder<PlansCubit, PlansTab>(
        builder: (context, tab) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Tab(
                    label: '🥗 Diet',
                    active: tab == PlansTab.diet,
                    onTap: () => context.read<PlansCubit>().setTab(PlansTab.diet),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _Tab(
                    label: '🏋️ Workout',
                    active: tab == PlansTab.workout,
                    onTap: () =>
                        context.read<PlansCubit>().setTab(PlansTab.workout),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: active ? Colors.white : AppColors.text2,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
        ),
      ),
    );
  }
}

