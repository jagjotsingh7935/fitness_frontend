import 'package:flutter_bloc/flutter_bloc.dart';

enum PlansTab { diet, workout }

class PlansCubit extends Cubit<PlansTab> {
  PlansCubit() : super(PlansTab.diet);

  void setTab(PlansTab tab) => emit(tab);
}

