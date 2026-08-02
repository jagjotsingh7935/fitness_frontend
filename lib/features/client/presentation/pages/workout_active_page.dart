import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../state/workout_session_cubit.dart';

class WorkoutActivePage extends StatelessWidget {
  const WorkoutActivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WorkoutSessionCubit(totalSets: 4),
      child: const _WorkoutActiveView(),
    );
  }
}

class _WorkoutActiveView extends StatelessWidget {
  const _WorkoutActiveView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        'UPPER BODY BLAST',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.text2,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                              fontSize: 10,
                            ),
                      ),
                      const SizedBox(height: 4),
                      BlocBuilder<WorkoutSessionCubit, WorkoutSessionState>(
                        buildWhen: (p, n) => p.elapsed != n.elapsed,
                        builder: (context, state) {
                          return Text(
                            state.mmss,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 38),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.card, Color(0xFF1E1E40)],
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text('🏋️', style: TextStyle(fontSize: 58)),
                          const SizedBox(height: 14),
                          Text(
                            'Bench Press',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Exercise 1 of 8 · 4 Sets × 12 Reps',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.text2,
                                  height: 1.6,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Set Tracker'.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.text2,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            fontSize: 10,
                          ),
                    ),
                    const SizedBox(height: 10),
                    BlocBuilder<WorkoutSessionCubit, WorkoutSessionState>(
                      builder: (context, state) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List<Widget>.generate(state.totalSets, (i) {
                            final setNumber = i + 1;
                            final done = state.doneSets.contains(setNumber);
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => context
                                    .read<WorkoutSessionCubit>()
                                    .toggleSet(setNumber),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: done ? AppColors.primary : AppColors.card,
                                    border: Border.all(
                                      color: done ? AppColors.primary : AppColors.border,
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$setNumber',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Next Exercise'.toUpperCase(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.text2,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      fontSize: 10,
                                    ),
                              ),
                              const Spacer(),
                              Text(
                                '2 of 8',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary.withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('💪', style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bicep Curls',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '3 Sets × 15 Reps',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.text2, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Next Exercise'),
                      SizedBox(width: 10),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

