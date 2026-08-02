import 'package:flutter_bloc/flutter_bloc.dart';

class ExerciseCategoryCubit extends Cubit<String> {
  ExerciseCategoryCubit() : super('All');

  void select(String category) => emit(category);
}

