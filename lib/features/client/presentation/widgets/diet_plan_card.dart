import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../state/meals_cubit.dart';

class DietPlanCard extends StatelessWidget {
  const DietPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MealsCubit(),
      child: Container(
        margin: const EdgeInsets.only(top: 14),
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
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.orange, Color(0xFFFF9800)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🥗', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weight Loss Plan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '2,200 kcal / day',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.text2,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '✓ Active',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _MacroRow(),
            const SizedBox(height: 14),
            BlocBuilder<MealsCubit, List>(
              builder: (context, meals) {
                return Column(
                  children: List<Widget>.generate(meals.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MealItem(
                        emoji: meals[i].emoji as String,
                        name: meals[i].name as String,
                        time: meals[i].timeLabel as String,
                        calories: meals[i].caloriesLabel as String,
                        done: meals[i].done as bool,
                        onToggle: () => context.read<MealsCubit>().toggle(i),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _MacroItem(
            value: '165g',
            label: 'Protein',
            color: AppColors.primary,
            bar: [AppColors.primary, Color(0xFF5B9BFF)],
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MacroItem(
            value: '220g',
            label: 'Carbs',
            color: Color(0xFFFF9800),
            bar: [Color(0xFFFF9800), AppColors.yellow],
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MacroItem(
            value: '65g',
            label: 'Fats',
            color: Color(0xFFE91E63),
            bar: [Color(0xFFE91E63), Color(0xFFFF4081)],
          ),
        ),
      ],
    );
  }
}

class _MacroItem extends StatelessWidget {
  const _MacroItem({
    required this.value,
    required this.label,
    required this.color,
    required this.bar,
  });

  final String value;
  final String label;
  final Color color;
  final List<Color> bar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.text2,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(colors: bar),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealItem extends StatelessWidget {
  const _MealItem({
    required this.emoji,
    required this.name,
    required this.time,
    required this.calories,
    required this.done,
    required this.onToggle,
  });

  final String emoji;
  final String name;
  final String time;
  final String calories;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.text2,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            calories,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(99),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.green : Colors.transparent,
                border: Border.all(
                  color: done ? AppColors.green : AppColors.border,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: done
                  ? const Icon(Icons.check, size: 13, color: Colors.black)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

