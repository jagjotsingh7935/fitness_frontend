import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

class WorkoutSessionState {
  const WorkoutSessionState({
    required this.elapsed,
    required this.doneSets,
    required this.totalSets,
  });

  final Duration elapsed;
  final Set<int> doneSets; // 1-based
  final int totalSets;

  String get mmss {
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class WorkoutSessionCubit extends Cubit<WorkoutSessionState> {
  WorkoutSessionCubit({int totalSets = 4})
      : super(
          WorkoutSessionState(
            elapsed: Duration.zero,
            doneSets: <int>{1, 2},
            totalSets: totalSets,
          ),
        ) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      emit(
        WorkoutSessionState(
          elapsed: state.elapsed + const Duration(seconds: 1),
          doneSets: state.doneSets,
          totalSets: state.totalSets,
        ),
      );
    });
  }

  Timer? _timer;

  void toggleSet(int setNumber) {
    final next = Set<int>.of(state.doneSets);
    if (next.contains(setNumber)) {
      next.remove(setNumber);
    } else {
      next.add(setNumber);
    }
    emit(
      WorkoutSessionState(
        elapsed: state.elapsed,
        doneSets: next,
        totalSets: state.totalSets,
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

