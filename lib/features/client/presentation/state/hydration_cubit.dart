import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/dio_client.dart';

class HydrationState {
  final int filledCount;
  final int totalCups;
  final bool isLoading;
  final String? errorMessage;

  HydrationState({
    required this.filledCount,
    required this.totalCups,
    this.isLoading = false,
    this.errorMessage,
  });

  HydrationState copyWith({
    int? filledCount,
    int? totalCups,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HydrationState(
      filledCount: filledCount ?? this.filledCount,
      totalCups: totalCups ?? this.totalCups,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  List<bool> get filledCups {
    return List.generate(totalCups, (i) => i < filledCount);
  }
}

class HydrationCubit extends Cubit<HydrationState> {
  final Dio _dio = GetIt.I<DioClient>().dio;
  String? _todayLogId;
  int? _targetId;

  HydrationCubit() : super(HydrationState(filledCount: 0, totalCups: 8)) {
    loadHydrationData();
  }

  Future<void> loadHydrationData() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Fetch hydration targets
      final targetsResponse = await _dio.get('/fitness/api/hydration-targets/');
      print('targetsResponse $targetsResponse');
      if (targetsResponse.statusCode == 200) {
        final targetsData = targetsResponse.data;
        List<dynamic> targets = [];
        
        if (targetsData is Map && targetsData.containsKey('results')) {
          targets = targetsData['results'];
        } else if (targetsData is List) {
          targets = targetsData;
        }
        
        final todayWeekday = DateTime.now().weekday;
        final backendWeekday = todayWeekday - 1;
        
        final todayTarget = targets.firstWhere(
          (t) => t['day_of_week'] == backendWeekday,
          orElse: () => null,
        );
        
        if (todayTarget != null) {
          emit(state.copyWith(totalCups: todayTarget['target_cups'] ?? 8));
          _targetId = todayTarget['id'];
        }
      }

      // Fetch today's hydration log
      final logsResponse = await _dio.get('/fitness/api/hydration-logs/');
      print('logresponse: $logsResponse');
      if (logsResponse.statusCode == 200) {
        final logsData = logsResponse.data;
        List<dynamic> logs = [];
        
        if (logsData is Map && logsData.containsKey('results')) {
          logs = logsData['results'];
        } else if (logsData is List) {
          logs = logsData;
        }
        
        final todayLog = logs.firstWhere(
          (log) => log['date'] == today,
          orElse: () => null,
        );
        
        if (todayLog != null) {
          emit(state.copyWith(filledCount: todayLog['actual_cups'] ?? 0));
          _todayLogId = todayLog['id'].toString();
        } else {
          emit(state.copyWith(filledCount: 0));
          _todayLogId = null;
        }
      }
      
      emit(state.copyWith(isLoading: false));
    } on DioException catch (e) {
      print('❌ DioException in loadHydrationData: ${e.response?.data ?? e.message}');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Network error occurred',
      ));
    } catch (e) {
      print('❌ Unexpected error in loadHydrationData: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> toggleCup(int index) async {
    final isCurrentlyFilled = index < state.filledCount;
    int newFilledCount;
    
    if (isCurrentlyFilled) {
      newFilledCount = index;
    } else {
      newFilledCount = index + 1;
    }
    
    await _updateHydrationLog(newFilledCount);
  }

  Future<void> _updateHydrationLog(int newFilledCount) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    try {
      if (_todayLogId != null) {
        // Update existing log
        final response = await _dio.put(
          '/fitness/api/hydration-logs/$_todayLogId/',
          data: {
            'date': today,
            'actual_cups': newFilledCount,
            'notes': 'Updated from app',
          },
        );
        print('response: $response');
        if (response.statusCode == 200) {
          emit(state.copyWith(filledCount: newFilledCount));
        }
      } else {
        // Create new log
        final response = await _dio.post(
          '/fitness/api/hydration-logs/',
          data: {
            'date': today,
            'actual_cups': newFilledCount,
            'notes': 'Logged from app',
          },
        );
        print('res: $response');
        if (response.statusCode == 201) {
          final logData = response.data;
          emit(state.copyWith(filledCount: newFilledCount));
          _todayLogId = logData['id'].toString();
        }
      }
    } on DioException catch (e) {
      print('❌ DioException in _updateHydrationLog: ${e.response?.data ?? e.message}');
      // Refresh data on error
      loadHydrationData();
    } catch (e) {
      print('❌ Unexpected error in _updateHydrationLog: $e');
      // Refresh data on error
      loadHydrationData();
    }
  }
}