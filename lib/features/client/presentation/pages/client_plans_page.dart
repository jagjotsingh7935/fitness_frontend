import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../widgets/chart_card.dart';
import '../widgets/charts/macro_split_chart.dart';
import '../widgets/charts/workout_completion_radar_chart.dart';
import '../widgets/client_scaffold.dart';
import '../widgets/diet_plan_card.dart';
import '../widgets/plan_tabs.dart';
import '../widgets/workout_plan_cards.dart';
import '../state/plans_cubit.dart';

class ClientPlansPage extends StatefulWidget {
  const ClientPlansPage({super.key});

  @override
  State<ClientPlansPage> createState() => _ClientPlansPageState();
}

class _ClientPlansPageState extends State<ClientPlansPage> {
  final Dio _dio = GetIt.I<DioClient>().dio;
  
  // Kcal targets for the week
  List<Map<String, dynamic>> _kcalTargets = [];
  Map<String, dynamic>? _todayMacros;
  bool _isLoadingTargets = true;

  @override
  void initState() {
    super.initState();
    _fetchKcalTargets();
  }

  Future<void> _fetchKcalTargets() async {
    setState(() => _isLoadingTargets = true);
    
    try {
      final response = await _dio.get('/fitness/api/kcal-targets/');
      
      if (response.statusCode == 200) {
        final targetsData = response.data;
        List<dynamic> targets = [];
        
        if (targetsData is Map && targetsData.containsKey('results')) {
          targets = targetsData['results'];
        } else if (targetsData is List) {
          targets = targetsData;
        }
        
        setState(() {
          _kcalTargets = List<Map<String, dynamic>>.from(targets);
          _isLoadingTargets = false;
        });
      } else {
        setState(() => _isLoadingTargets = false);
      }
    } catch (e) {
      print('Error fetching kcal targets: $e');
      setState(() => _isLoadingTargets = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClientScaffold(
      greeting: 'Assigned by Trainer',
      title: 'My Plans',
      child: BlocProvider(
        create: (_) => PlansCubit(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PlanTabs(),
            BlocBuilder<PlansCubit, PlansTab>(
              builder: (context, tab) {
                if (tab == PlansTab.workout) {
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 12),
                      WorkoutPlanCards(),
                      ChartCard(
                        title: 'Workout Completion',
                        periodLabel: '4 Weeks',
                        child: WorkoutCompletionRadarChart(),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ChartCard(
                      title: 'Macro Split',
                      periodLabel: 'Today',
                      child: MacroSplitChart(kcalTargets: _kcalTargets),
                    ),
                    const DietPlanCard(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}