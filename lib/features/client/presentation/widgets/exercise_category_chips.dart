import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../state/exercise_category_cubit.dart';

class ExerciseCategoryChips extends StatelessWidget {
  const ExerciseCategoryChips({super.key, required this.categories});

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExerciseCategoryCubit(),
      child: SizedBox(
        height: 44,
        child: BlocBuilder<ExerciseCategoryCubit, String>(
          builder: (context, selected) {
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = categories[i];
                final isActive = c == selected;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.read<ExerciseCategoryCubit>().select(c),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        c,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isActive ? Colors.white : AppColors.text2,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

