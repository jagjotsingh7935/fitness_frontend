import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/demo_models.dart';

class MealsCubit extends Cubit<List<MealModel>> {
  MealsCubit({List<MealModel>? initial}) : super(initial ?? DemoClientData.meals);

  void toggle(int index) {
    if (index < 0 || index >= state.length) return;
    final next = List<MealModel>.of(state);
    next[index] = next[index].copyWith(done: !next[index].done);
    emit(next);
  }
}

