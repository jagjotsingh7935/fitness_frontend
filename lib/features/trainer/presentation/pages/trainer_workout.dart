import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/searchable_dropdown.dart';

class TrainerWorkoutsPage extends StatefulWidget {
  const TrainerWorkoutsPage({super.key});

  @override
  State<TrainerWorkoutsPage> createState() => _TrainerWorkoutsPageState();
}

class _TrainerWorkoutsPageState extends State<TrainerWorkoutsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Dio _dio = GetIt.I<DioClient>().dio;

  // Master Programs state
  List<Map<String, dynamic>> _masterPlans = [];
  bool _isLoadingMasters = true;
  String? _mastersError;
  final TextEditingController _masterSearchController = TextEditingController();
  String _masterSearchQuery = '';
  String _masterCategoryFilter = 'All';

  // Client Schedules state
  List<Map<String, dynamic>> _workoutPlans = [];
  bool _isLoadingClientPlans = true;
  String? _clientPlansError;
  int? _filterClientId;
  final TextEditingController _scheduleSearchController = TextEditingController();
  String _scheduleSearchQuery = '';
  int _selectedDayFilter = -1; // -1 = All Days

  // Shared dropdown data
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingClients = false;
  bool _isLoadingExercises = false;

  final List<Map<int, String>> _daysOfWeek = [
    {0: 'Monday'},
    {1: 'Tuesday'},
    {2: 'Wednesday'},
    {3: 'Thursday'},
    {4: 'Friday'},
    {5: 'Saturday'},
    {6: 'Sunday'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchMasterPlans();
    _fetchClientWorkoutPlans();
    _fetchClients();
    _fetchExercises();
    _fetchCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _masterSearchController.dispose();
    _scheduleSearchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredMasterPlans {
    return _masterPlans.where((plan) {
      final title = (plan['title'] ?? '').toString().toLowerCase();
      final desc = (plan['description'] ?? '').toString().toLowerCase();
      final query = _masterSearchQuery.toLowerCase();

      final List<dynamic> items = plan['items'] ?? [];
      final bool matchesExerciseName = items.any((item) {
        final ex = item['exercise_detail'];
        final exTitle = (ex is Map ? (ex['title'] ?? '') : '').toString().toLowerCase();
        return exTitle.contains(query);
      });

      final matchesSearch = query.isEmpty ||
          title.contains(query) ||
          desc.contains(query) ||
          matchesExerciseName;

      final List<dynamic> cats = plan['categories'] ?? [];
      final matchesCategory = _masterCategoryFilter == 'All' ||
          cats.any((c) => (c['name'] ?? '').toString() == _masterCategoryFilter);

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredClientPlans {
    return _workoutPlans.where((plan) {
      final matchesClient = _filterClientId == null || plan['client_id'] == _filterClientId;

      final matchesDay = _selectedDayFilter == -1 || plan['day_of_week'] == _selectedDayFilter;

      final clientName = (plan['client_name'] ?? '').toString().toLowerCase();
      final exDetail = plan['exercise_detail'];
      final exTitle = (exDetail is Map ? (exDetail['title'] ?? '') : '').toString().toLowerCase();
      final notes = (plan['notes'] ?? '').toString().toLowerCase();
      final query = _scheduleSearchQuery.toLowerCase();

      final matchesSearch = query.isEmpty ||
          clientName.contains(query) ||
          exTitle.contains(query) ||
          notes.contains(query);

      return matchesClient && matchesDay && matchesSearch;
    }).toList();
  }

  // ─────────────────────────────────────────────
  //  DATA FETCHING
  // ─────────────────────────────────────────────

  Future<void> _fetchMasterPlans() async {
    setState(() {
      _isLoadingMasters = true;
      _mastersError = null;
    });

    try {
      final res = await _dio.get('/fitness/api/master-workout-plans/');
      if (res.statusCode == 200) {
        final data = res.data is List
            ? res.data
            : (res.data is Map && res.data['results'] is List ? res.data['results'] : []);
        setState(() {
          _masterPlans = (data as List).map((p) => p as Map<String, dynamic>).toList();
          _isLoadingMasters = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _mastersError = e.response?.data?['detail']?.toString() ?? e.message ?? 'Error fetching master plans';
        _isLoadingMasters = false;
      });
    } catch (e) {
      setState(() {
        _mastersError = e.toString();
        _isLoadingMasters = false;
      });
    }
  }

  Future<void> _fetchClientWorkoutPlans() async {
    setState(() {
      _isLoadingClientPlans = true;
      _clientPlansError = null;
    });

    try {
      final res = await _dio.get('/fitness/api/workout-plans/');
      if (res.statusCode == 200) {
        final data = res.data is List
            ? res.data
            : (res.data is Map && res.data['results'] is List ? res.data['results'] : []);
        setState(() {
          _workoutPlans = (data as List).map((plan) {
            final p = plan as Map<String, dynamic>;
            return {
              'id': p['id'],
              'trainer_name': p['trainer_name'] ?? 'Trainer',
              'client_name': p['client_name'] ?? 'Client',
              'client_id': p['client'],
              'exercise_detail': p['exercise_detail'],
              'day_of_week': p['day_of_week'] ?? 0,
              'day_display': p['day_display'] ?? 'Unknown',
              'sets': p['sets'] ?? 0,
              'reps': p['reps'] ?? 0,
              'time_per_rep_seconds': p['time_per_rep_seconds'] ?? 0,
              'order': p['order'] ?? 0,
              'notes': p['notes'] ?? '',
              'is_active': p['is_active'] ?? true,
            };
          }).toList();
          _isLoadingClientPlans = false;
        });
      }
    } catch (e) {
      setState(() {
        _clientPlansError = e.toString();
        _isLoadingClientPlans = false;
      });
    }
  }

  Future<void> _fetchClients() async {
    if (_clients.isNotEmpty && !_isLoadingClients) return;
    setState(() => _isLoadingClients = true);
    try {
      final res = await _dio.get('/accounts/api/trainers-client-list/');
      if (res.statusCode == 200) {
        final data = res.data is List
            ? res.data
            : (res.data is Map && res.data['results'] is List ? res.data['results'] : []);
        if (data.isNotEmpty) {
          setState(() {
            _clients = (data as List).map((item) {
              final c = item as Map<String, dynamic>;
              return {
                'id': c['client_id'] ?? c['client'] ?? c['id'],
                'name': c['client_name'] ?? 'Client',
                'email': c['client_email'] ?? '',
              };
            }).toList();
            _isLoadingClients = false;
          });
          return;
        }
      }
      final fallback = await _dio.get('/accounts/api/client/');
      if (fallback.statusCode == 200) {
        final data = fallback.data is List
            ? fallback.data
            : (fallback.data is Map && fallback.data['results'] is List ? fallback.data['results'] : []);
        setState(() {
          _clients = (data as List).map((c) {
            return {
              'id': c['client_id'] ?? c['id'],
              'name': c['name'] ?? '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'.trim(),
              'email': c['email'] ?? '',
            };
          }).toList();
          _isLoadingClients = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingClients = false);
    }
  }

  Future<void> _fetchExercises() async {
    if (_exercises.isNotEmpty && !_isLoadingExercises) return;
    setState(() => _isLoadingExercises = true);
    try {
      final res = await _dio.get('/fitness/api/exercises/');
      if (res.statusCode == 200) {
        final data = res.data is List
            ? res.data
            : (res.data is Map && res.data['results'] is List ? res.data['results'] : []);
        setState(() {
          _exercises = (data as List).map((e) => e as Map<String, dynamic>).toList();
          _isLoadingExercises = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingExercises = false);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await _dio.get('/accounts/api/category/');
      if (res.statusCode == 200) {
        final data = res.data is List
            ? res.data
            : (res.data is Map && res.data['results'] is List ? res.data['results'] : []);
        setState(() {
          _categories = (data as List).map((c) => c as Map<String, dynamic>).toList();
        });
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  //  MASTER PROGRAM ACTIONS
  // ─────────────────────────────────────────────

  void _showCreateMasterPlanDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final List<int> selectedCategoryIds = [];
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161B30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.auto_stories_rounded, color: Color(0xFFE94560), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Create Master Program',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Program Title *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'e.g. 4-Week Hypertrophy Split',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF111425),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Program Description',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Overview, target audience, frequency...',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF111425),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                if (_categories.isNotEmpty) ...[
                  const Text('Target Categories:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _categories.map((cat) {
                      final catId = cat['id'] as int;
                      final isSelected = selectedCategoryIds.contains(catId);
                      return FilterChip(
                        label: Text(cat['name'] ?? '', style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.white70)),
                        selected: isSelected,
                        selectedColor: const Color(0xFFE94560),
                        backgroundColor: const Color(0xFF111425),
                        checkmarkColor: Colors.white,
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              selectedCategoryIds.add(catId);
                            } else {
                              selectedCategoryIds.remove(catId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a program title')),
                        );
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      try {
                        final req = {
                          'title': title,
                          'description': descCtrl.text.trim(),
                          'category_ids': selectedCategoryIds,
                        };
                        final res = await _dio.post('/fitness/api/master-workout-plans/create/', data: req);
                        if (res.statusCode == 201 || res.statusCode == 200) {
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Master program created! Now add daily exercises to it.'),
                                backgroundColor: Color(0xFF00F5A0),
                              ),
                            );
                            _fetchMasterPlans();
                          }
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Program'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExerciseToMasterDialog(Map<String, dynamic> masterPlan) {
    int? selectedExerciseId;
    int selectedDay = 0;
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '12');
    final timeCtrl = TextEditingController(text: '45');
    final notesCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161B30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.add_task_rounded, color: Color(0xFFE94560), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add Exercise to ${masterPlan['title']}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchableDropdown<int>(
                  value: selectedExerciseId,
                  labelText: 'Select Exercise *',
                  hintText: 'Search and select exercise',
                  searchHint: 'Search exercise name...',
                  items: _exercises.map((e) {
                    return SearchableDropdownItem<int>(
                      value: e['id'] as int,
                      label: e['title'] ?? 'Exercise',
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedExerciseId = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: selectedDay,
                  dropdownColor: const Color(0xFF1F243E),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Day of Week *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF111425),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _daysOfWeek.map((d) {
                    final entry = d.entries.first;
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedDay = val ?? 0),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: setsCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Sets',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF111425),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: repsCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Reps',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF111425),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Coach Instructions / Notes (Optional)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'e.g. 60s rest, focus on depth',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF111425),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (selectedExerciseId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select an exercise')),
                        );
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      try {
                        final req = {
                          'exercise': selectedExerciseId,
                          'day_of_week': selectedDay,
                          'sets': int.tryParse(setsCtrl.text) ?? 3,
                          'reps': int.tryParse(repsCtrl.text) ?? 12,
                          'time_per_rep_seconds': int.tryParse(timeCtrl.text) ?? 45,
                          'notes': notesCtrl.text.trim(),
                        };
                        final res = await _dio.post(
                          '/fitness/api/master-workout-plans/${masterPlan['id']}/items/',
                          data: req,
                        );
                        if (res.statusCode == 201 || res.statusCode == 200) {
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Exercise added to master program!'),
                                backgroundColor: Color(0xFF00F5A0),
                              ),
                            );
                            _fetchMasterPlans();
                          }
                        }
                      } on DioException catch (e) {
                        setDialogState(() => isSaving = false);
                        final msg = e.response?.data is Map
                            ? (e.response?.data['error'] ?? e.response?.data['detail'] ?? e.response?.data.values.join(', '))
                            : (e.message ?? 'Failed to add exercise');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.redAccent),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Add Exercise'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignMasterToClientsDialog(Map<String, dynamic> masterPlan) {
    final List<int> selectedClients = [];
    bool clearExisting = true;
    bool isAssigning = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161B30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF00F5A0), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Assign "${masterPlan['title']}"',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select the client(s) you want to link this workout routine to:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (_clients.isEmpty)
                    const Text('No clients assigned yet.', style: TextStyle(color: Colors.white54))
                  else
                    ..._clients.map((client) {
                      final cId = client['id'] as int;
                      final isSelected = selectedClients.contains(cId);
                      return CheckboxListTile(
                        value: isSelected,
                        activeColor: const Color(0xFFE94560),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          client['name'] ?? 'Client',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        subtitle: Text(
                          client['email'] ?? '',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedClients.add(cId);
                            } else {
                              selectedClients.remove(cId);
                            }
                          });
                        },
                      );
                    }),
                  const Divider(color: Colors.white12, height: 24),
                  CheckboxListTile(
                    value: clearExisting,
                    activeColor: const Color(0xFFE94560),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Replace existing client workouts',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Clears old routines for selected clients before applying this program.',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    onChanged: (val) {
                      setDialogState(() => clearExisting = val ?? true);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: isAssigning
                  ? null
                  : () async {
                      if (selectedClients.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select at least one client')),
                        );
                        return;
                      }
                      setDialogState(() => isAssigning = true);
                      try {
                        final req = {
                          'client_ids': selectedClients,
                          'clear_existing': clearExisting,
                        };
                        final res = await _dio.post(
                          '/fitness/api/master-workout-plans/${masterPlan['id']}/assign/',
                          data: req,
                        );
                        if (res.statusCode == 200) {
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.data['message'] ?? '✅ Program assigned successfully!'),
                                backgroundColor: const Color(0xFF00F5A0),
                              ),
                            );
                            _fetchClientWorkoutPlans();
                          }
                        }
                      } on DioException catch (e) {
                        setDialogState(() => isAssigning = false);
                        final msg = e.response?.data is Map
                            ? (e.response?.data['error'] ?? e.response?.data['detail'] ?? e.response?.data.values.join(', '))
                            : (e.message ?? 'Failed to assign program');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.redAccent),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isAssigning = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5A0),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isAssigning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Confirm Assignment', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMasterPlan(int masterId) async {
    try {
      await _dio.delete('/fitness/api/master-workout-plans/$masterId/');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Master workout program deleted')),
        );
        _fetchMasterPlans();
      }
    } catch (_) {}
  }

  Future<void> _deleteMasterPlanItem(int itemId) async {
    try {
      await _dio.delete('/fitness/api/master-workout-plans/items/$itemId/');
      _fetchMasterPlans();
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D1A),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'FLUX',
              style: TextStyle(
                color: Color(0xFFE5C07B),
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Workout Hub',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0D1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books, color: Color(0xFFE94560)),
            onPressed: () => context.push('/trainer/exercises'),
            tooltip: 'Exercise Library',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFE94560)),
            onPressed: () {
              _fetchMasterPlans();
              _fetchClientWorkoutPlans();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFE94560)),
            onPressed: () {
              if (_tabController.index == 0) {
                _showCreateMasterPlanDialog();
              } else {
                _showAddIndividualWorkoutDialog();
              }
            },
            tooltip: 'Create Program / Plan',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE94560),
          indicatorWeight: 3,
          labelColor: const Color(0xFFE94560),
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.auto_stories_rounded, size: 20),
              text: 'Master Programs',
            ),
            Tab(
              icon: Icon(Icons.calendar_month_rounded, size: 20),
              text: 'Client Schedules',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMasterProgramsTab(),
          _buildClientSchedulesTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TAB 1: MASTER PROGRAMS
  // ─────────────────────────────────────────────

  Widget _buildMasterProgramsTab() {
    if (_isLoadingMasters) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560))),
      );
    }

    if (_mastersError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_mastersError', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchMasterPlans, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_masterPlans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131830),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.auto_stories_rounded, size: 48, color: Color(0xFFE94560)),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Master Workout Programs',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create reusable master workout templates with weekly exercise routines, then assign them to clients in 1 click.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _showCreateMasterPlanDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create First Master Program'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 1. Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161B30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE5C07B).withValues(alpha: 0.25),
              ),
            ),
            child: TextField(
              controller: _masterSearchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (val) => setState(() => _masterSearchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search master template by title, exercise, description...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE5C07B), size: 20),
                suffixIcon: _masterSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                        onPressed: () {
                          _masterSearchController.clear();
                          setState(() => _masterSearchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),

        // 2. Category Filter Chips
        if (_categories.isNotEmpty)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      'All Categories',
                      style: TextStyle(
                        color: _masterCategoryFilter == 'All' ? Colors.white : Colors.white60,
                        fontSize: 11.5,
                        fontWeight: _masterCategoryFilter == 'All' ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    selected: _masterCategoryFilter == 'All',
                    selectedColor: const Color(0xFFE94560),
                    backgroundColor: const Color(0xFF161B30),
                    side: BorderSide(
                      color: _masterCategoryFilter == 'All' ? const Color(0xFFE94560) : Colors.white12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      if (selected) setState(() => _masterCategoryFilter = 'All');
                    },
                  ),
                ),
                ..._categories.map((c) {
                  final catName = c['name']?.toString() ?? '';
                  final isSelected = _masterCategoryFilter == catName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        catName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFFE94560),
                      backgroundColor: const Color(0xFF161B30),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFE94560) : Colors.white12,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        if (selected) setState(() => _masterCategoryFilter = catName);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

        // 3. Results Count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                'Showing ${_filteredMasterPlans.length} of ${_masterPlans.length} master programs',
                style: const TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_masterSearchQuery.isNotEmpty || _masterCategoryFilter != 'All')
                GestureDetector(
                  onTap: () {
                    _masterSearchController.clear();
                    setState(() {
                      _masterSearchQuery = '';
                      _masterCategoryFilter = 'All';
                    });
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restart_alt_rounded, size: 14, color: Color(0xFF00F5A0)),
                      SizedBox(width: 4),
                      Text('Reset', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // 4. Master Plans List
        Expanded(
          child: _filteredMasterPlans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded, size: 54, color: Colors.white24),
                      const SizedBox(height: 12),
                      const Text(
                        'No master programs match your search/filters',
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                  itemCount: _filteredMasterPlans.length,
                  itemBuilder: (context, index) {
                    final plan = _filteredMasterPlans[index];
                    final title = plan['title'] ?? 'Program';
                    final desc = plan['description'] ?? '';
                    final List<dynamic> items = plan['items'] ?? [];
                    final List<dynamic> categories = plan['categories'] ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF131830),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE94560).withValues(alpha: 0.2), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ExpansionTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE94560), Color(0xFF8B0D2A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
            ),
            title: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (desc.toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE94560).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${items.length} Exercises',
                        style: const TextStyle(color: Color(0xFFE94560), fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (categories.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          categories.map((c) => c['name']).join(', '),
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Program Action Bar
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (items.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Please add at least one exercise to '$title' before assigning."),
                                    backgroundColor: const Color(0xFFFF9F43),
                                  ),
                                );
                                return;
                              }
                              _showAssignMasterToClientsDialog(plan);
                            },
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                            label: const Text('Assign to Clients', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F5A0),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showAddExerciseToMasterDialog(plan),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Exercise', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE94560),
                            side: const BorderSide(color: Color(0xFFE94560)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4B72), size: 20),
                          onPressed: () => _deleteMasterPlan(plan['id']),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Exercises breakdown
                    if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111425),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'No exercises added to this template yet.\nTap "Add Exercise" to schedule weekly routines.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ),
                      )
                    else
                      ...items.map((item) {
                        final ex = item['exercise_detail'];
                        final exTitle = ex?['title'] ?? 'Exercise';
                        final day = item['day_display'] ?? 'Day';
                        final sets = item['sets'] ?? 0;
                        final reps = item['reps'] ?? 0;
                        final notes = item['notes'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111425),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE94560).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  day.substring(0, 3).toUpperCase(),
                                  style: const TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.w900, fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exTitle,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    if (notes.toString().isNotEmpty)
                                      Text(notes, style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1),
                                  ],
                                ),
                              ),
                              Text(
                                '$sets × $reps',
                                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white38),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteMasterPlanItem(item['id']),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  ),
  ],
);
  }

  // ─────────────────────────────────────────────
  //  TAB 2: CLIENT SCHEDULES
  // ─────────────────────────────────────────────

  Widget _buildClientSchedulesTab() {
    if (_isLoadingClientPlans) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560))),
      );
    }

    if (_clientPlansError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_clientPlansError', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchClientWorkoutPlans, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 1. Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161B30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE94560).withValues(alpha: 0.25),
              ),
            ),
            child: TextField(
              controller: _scheduleSearchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (val) => setState(() => _scheduleSearchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search by client, exercise, or notes...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE94560), size: 20),
                suffixIcon: _scheduleSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                        onPressed: () {
                          _scheduleSearchController.clear();
                          setState(() => _scheduleSearchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),

        // 2. Client Filter Chips
        if (_clients.isNotEmpty)
          Container(
            height: 36,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All Clients (${_workoutPlans.length})', null),
                ..._clients.map((client) {
                  final cId = client['id'] as int?;
                  final count = _workoutPlans.where((p) => p['client_id'] == cId).length;
                  return _buildFilterChip('${client['name']} ($count)', cId);
                }),
              ],
            ),
          ),

        // 3. Day of Week Filter Chips
        Container(
          height: 34,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(
                    'All Days',
                    style: TextStyle(
                      color: _selectedDayFilter == -1 ? Colors.white : Colors.white60,
                      fontSize: 11,
                      fontWeight: _selectedDayFilter == -1 ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  selected: _selectedDayFilter == -1,
                  selectedColor: const Color(0xFFE94560),
                  backgroundColor: const Color(0xFF161B30),
                  side: BorderSide(
                    color: _selectedDayFilter == -1 ? const Color(0xFFE94560) : Colors.white12,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedDayFilter = -1);
                  },
                ),
              ),
              ..._daysOfWeek.map((dayMap) {
                final dayIndex = dayMap.keys.first;
                final dayName = dayMap.values.first;
                final isSelected = _selectedDayFilter == dayIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      dayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFE94560),
                    backgroundColor: const Color(0xFF161B30),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFE94560) : Colors.white12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDayFilter = dayIndex);
                    },
                  ),
                );
              }),
            ],
          ),
        ),

        // 4. Counter & Reset
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              Text(
                'Showing ${_filteredClientPlans.length} of ${_workoutPlans.length} routines',
                style: const TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_scheduleSearchQuery.isNotEmpty || _filterClientId != null || _selectedDayFilter != -1)
                GestureDetector(
                  onTap: () {
                    _scheduleSearchController.clear();
                    setState(() {
                      _scheduleSearchQuery = '';
                      _filterClientId = null;
                      _selectedDayFilter = -1;
                    });
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restart_alt_rounded, size: 14, color: Color(0xFF00F5A0)),
                      SizedBox(width: 4),
                      Text('Reset', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // 5. Client Schedules List
        Expanded(
          child: _filteredClientPlans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fitness_center_rounded, size: 48, color: Colors.white24),
                      const SizedBox(height: 14),
                      Text(
                        _scheduleSearchQuery.isNotEmpty || _filterClientId != null || _selectedDayFilter != -1
                            ? 'No workout routines match your search/filters'
                            : 'No individual workouts assigned yet',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Assign a Master Program from the "Master Programs" tab\nor add a custom exercise below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddIndividualWorkoutDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Custom Exercise'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560), foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                  itemCount: _filteredClientPlans.length,
                  itemBuilder: (context, index) {
                    final plan = _filteredClientPlans[index];
                    final clientName = plan['client_name'] ?? 'Unknown';
                    final exerciseDetail = plan['exercise_detail'];
                    final exerciseTitle = exerciseDetail?['title'] ?? 'Unknown';
                    final dayDisplay = plan['day_display'] ?? 'Unknown';
                    final sets = plan['sets'] ?? 0;
                    final reps = plan['reps'] ?? 0;
                    final notes = plan['notes'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131830),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE94560).withValues(alpha: 0.15)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFE94560), Color(0xFF8B0D2A)]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fitness_center, color: Colors.white, size: 22),
                        ),
                        title: Text(
                          exerciseTitle,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$clientName · $dayDisplay · $sets sets × $reps reps',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            if (notes.toString().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                notes,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4B72), size: 20),
                          onPressed: () async {
                            try {
                              await _dio.delete('/fitness/api/workout-plans/${plan['id']}/');
                              _fetchClientWorkoutPlans();
                            } catch (_) {}
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int? clientId) {
    final isSelected = _filterClientId == clientId;
    return GestureDetector(
      onTap: () => setState(() => _filterClientId = clientId),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE94560).withValues(alpha: 0.2) : const Color(0xFF131830),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFE94560) : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFE94560) : Colors.white70,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showAddIndividualWorkoutDialog() {
    int? selectedClient = _filterClientId;
    int? selectedExercise;
    int selectedDay = 0;
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '12');
    final notesCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161B30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Assign Custom Exercise', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SearchableDropdown<int>(
                  value: selectedClient,
                  labelText: 'Select Client *',
                  hintText: 'Search and select client',
                  searchHint: 'Search client name...',
                  items: _clients.map((c) {
                    return SearchableDropdownItem<int>(
                      value: c['id'] as int,
                      label: c['name'] ?? 'Client',
                      subtitle: c['email'],
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedClient = val),
                ),
                const SizedBox(height: 12),
                SearchableDropdown<int>(
                  value: selectedExercise,
                  labelText: 'Select Exercise *',
                  hintText: 'Search and select exercise',
                  searchHint: 'Search exercise name...',
                  items: _exercises.map((e) {
                    return SearchableDropdownItem<int>(
                      value: e['id'] as int,
                      label: e['title'] ?? 'Exercise',
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedExercise = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: selectedDay,
                  dropdownColor: const Color(0xFF1F243E),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Day of Week *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF111425),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _daysOfWeek.map((d) {
                    final entry = d.entries.first;
                    return DropdownMenuItem<int>(value: entry.key, child: Text(entry.value));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedDay = val ?? 0),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: setsCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Sets',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF111425),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: repsCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Reps',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF111425),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF111425),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (selectedClient == null || selectedExercise == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select client and exercise')));
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      try {
                        final req = {
                          'client': selectedClient,
                          'client_id': selectedClient,
                          'exercise': selectedExercise,
                          'exercise_id': selectedExercise,
                          'day_of_week': selectedDay,
                          'sets': int.tryParse(setsCtrl.text) ?? 3,
                          'reps': int.tryParse(repsCtrl.text) ?? 12,
                          'notes': notesCtrl.text.trim(),
                        };
                        final res = await _dio.post('/fitness/api/workout-plans/create/', data: req);
                        if (res.statusCode == 201 || res.statusCode == 200) {
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Exercise assigned successfully!'),
                                backgroundColor: Color(0xFF00F5A0),
                              ),
                            );
                          }
                          _fetchClientWorkoutPlans();
                        }
                      } on DioException catch (e) {
                        setDialogState(() => isSaving = false);
                        final msg = e.response?.data is Map
                            ? (e.response?.data['error'] ??
                                e.response?.data['detail'] ??
                                (e.response?.data as Map).values.map((v) => v is List ? v.join(', ') : v.toString()).join(' | '))
                            : (e.message ?? 'Failed to assign exercise');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.redAccent),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560), foregroundColor: Colors.white),
              child: isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}