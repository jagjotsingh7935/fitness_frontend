import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';

class TrainerWorkoutsPage extends StatefulWidget {
  const TrainerWorkoutsPage({super.key});

  @override
  State<TrainerWorkoutsPage> createState() => _TrainerWorkoutsPageState();
}

class _TrainerWorkoutsPageState extends State<TrainerWorkoutsPage> {
  List<Map<String, dynamic>> _workoutPlans = [];
  bool _isLoading = true;
  String? _errorMessage;

  final Dio _dio = GetIt.I<DioClient>().dio;

  // Controllers for add/edit workout plan dialog
  final _clientController = TextEditingController();
  final _exerciseController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _timePerRepController = TextEditingController();
  final _orderController = TextEditingController();
  final _notesController = TextEditingController();
  int _selectedDayOfWeek = 0;
  int? _editingPlanId;

  // Data lists for dropdowns
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoadingClients = false;
  bool _isLoadingExercises = false;
  String? _clientsError;
  String? _exercisesError;

  // Available days of week
  final List<Map<int, String>> _daysOfWeek = [
    {0: 'Monday'},
    {1: 'Tuesday'},
    {2: 'Wednesday'},
    {3: 'Thursday'},
    {4: 'Friday'},
    {5: 'Saturday'},
    {6: 'Sunday'},
  ];

  int? _selectedClientId;
  int? _selectedExerciseId;

  @override
  void initState() {
    super.initState();
    _fetchWorkoutPlans();
    _fetchClients();
    _fetchExercises();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _exerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _timePerRepController.dispose();
    _orderController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Fetch all workout plans
  Future<void> _fetchWorkoutPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔵 Fetching workout plans from: /fitness/api/workout-plans/');
      final response = await _dio.get('/fitness/api/workout-plans/');

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> plansData = [];

        if (responseData is Map && responseData.containsKey('results')) {
          plansData = responseData['results'];
        } else if (responseData is List) {
          plansData = responseData;
        }

        print('✅ Workout plans fetched: ${plansData.length} plans');

        setState(() {
          _workoutPlans = plansData.map((plan) {
            return {
              'id': plan['id'],
              'trainer_name': plan['trainer_name'] ?? 'Unknown',
              'client_name': plan['client_name'] ?? 'Unknown',
              'client_id': plan['client'],
              'exercise_detail': plan['exercise_detail'],
              'day_of_week': plan['day_of_week'] ?? 0,
              'day_display': plan['day_display'] ?? 'Unknown',
              'sets': plan['sets'] ?? 0,
              'reps': plan['reps'] ?? 0,
              'time_per_rep_seconds': plan['time_per_rep_seconds'] ?? 0,
              'order': plan['order'] ?? 0,
              'notes': plan['notes'] ?? '',
              'is_active': plan['is_active'] ?? true,
              'created_at': plan['created_at'],
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load workout plans: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      setState(() {
        _errorMessage = e.message ?? 'Network error occurred';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Fetch clients for dropdown
  Future<void> _fetchClients() async {
    if (_clients.isNotEmpty && !_isLoadingClients) {
      return;
    }

    setState(() {
      _isLoadingClients = true;
      _clientsError = null;
    });

    try {
      final response = await _dio.get('/accounts/api/client/');

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> clientsData = [];

        if (responseData is Map && responseData.containsKey('results')) {
          clientsData = responseData['results'];
        } else if (responseData is List) {
          clientsData = responseData;
        }

        setState(() {
          _clients = clientsData.map((client) {
            return {
              'id': client['client_id'] ?? client['id'],
              'name': client['name'] ?? 
                  '${client['first_name'] ?? ''} ${client['last_name'] ?? ''}'.trim(),
              'email': client['email'] ?? '',
            };
          }).toList();
          _isLoadingClients = false;
        });
      } else {
        throw Exception('Failed to load clients');
      }
    } catch (e) {
      print('❌ Error fetching clients: $e');
      setState(() {
        _isLoadingClients = false;
        _clientsError = e.toString();
      });
    }
  }

  // Fetch exercises for dropdown
  Future<void> _fetchExercises() async {
    if (_exercises.isNotEmpty && !_isLoadingExercises) {
      return;
    }

    setState(() {
      _isLoadingExercises = true;
      _exercisesError = null;
    });

    try {
      final response = await _dio.get('/fitness/api/exercises/');

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> exercisesData = [];

        if (responseData is Map && responseData.containsKey('results')) {
          exercisesData = responseData['results'];
        } else if (responseData is List) {
          exercisesData = responseData;
        }

        setState(() {
          _exercises = exercisesData.map((exercise) {
            return {
              'id': exercise['id'],
              'title': exercise['title'] ?? 'Unknown',
              'duration_seconds': exercise['duration_seconds'] ?? 0,
              'thumbnail_url': exercise['thumbnail_url'] ?? '',
              'category_names': exercise['category_names'] ?? [],
            };
          }).toList();
          _isLoadingExercises = false;
        });
      } else {
        throw Exception('Failed to load exercises');
      }
    } catch (e) {
      print('❌ Error fetching exercises: $e');
      setState(() {
        _isLoadingExercises = false;
        _exercisesError = e.toString();
      });
    }
  }

  // Create new workout plan
  Future<void> _createWorkoutPlan(BuildContext context) async {
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    if (_selectedExerciseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an exercise')),
      );
      return;
    }

    try {
      final requestBody = {
        'client': _selectedClientId,
        'exercise': _selectedExerciseId,
        'day_of_week': _selectedDayOfWeek,
        'sets': int.tryParse(_setsController.text.trim()) ?? 0,
        'reps': int.tryParse(_repsController.text.trim()) ?? 0,
        'time_per_rep_seconds': int.tryParse(_timePerRepController.text.trim()) ?? 0,
        'order': int.tryParse(_orderController.text.trim()) ?? 0,
        'notes': _notesController.text.trim(),
        'is_active': true,
      };

      print('📤 Creating workout plan at: /fitness/api/workout-plans/create/');
      print('📤 Request body: $requestBody');

      final response = await _dio.post('/fitness/api/workout-plans/create/', data: requestBody);

      if (response.statusCode == 201) {
        _clearForm();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout plan created successfully')),
          );
          _fetchWorkoutPlans();
        }
      } else {
        throw Exception('Failed to create workout plan');
      }
    } on DioException catch (e) {
      String errorMsg = 'Error creating workout plan';
      if (e.response?.data != null) {
        errorMsg = e.response!.data.toString();
      }
      print('❌ Create error: $errorMsg');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMsg')),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Update existing workout plan
  Future<void> _updateWorkoutPlan(BuildContext context) async {
    if (_editingPlanId == null) return;

    try {
      final requestBody = {
        'client': _selectedClientId,
        'exercise': _selectedExerciseId,
        'day_of_week': _selectedDayOfWeek,
        'sets': int.tryParse(_setsController.text.trim()) ?? 0,
        'reps': int.tryParse(_repsController.text.trim()) ?? 0,
        'time_per_rep_seconds': int.tryParse(_timePerRepController.text.trim()) ?? 0,
        'order': int.tryParse(_orderController.text.trim()) ?? 0,
        'notes': _notesController.text.trim(),
        'is_active': true,
      };

      print('📤 Updating workout plan at: /fitness/api/workout-plans/${_editingPlanId}/');
      print('📤 Request body: $requestBody');

      final response = await _dio.put(
        '/fitness/api/workout-plans/${_editingPlanId}/',
        data: requestBody,
      );

      if (response.statusCode == 200) {
        _clearForm();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout plan updated successfully')),
          );
          _fetchWorkoutPlans();
        }
      } else {
        throw Exception('Failed to update workout plan');
      }
    } on DioException catch (e) {
      String errorMsg = 'Error updating workout plan';
      if (e.response?.data != null) {
        errorMsg = e.response!.data.toString();
      }
      print('❌ Update error: $errorMsg');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMsg')),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Delete workout plan
  Future<void> _deleteWorkoutPlan(BuildContext context, int planId, String clientName, String exerciseTitle) async {
    try {
      print('🗑️ Deleting workout plan at: /fitness/api/workout-plans/$planId/');
      
      final response = await _dio.delete('/fitness/api/workout-plans/$planId/');

      if (response.statusCode == 204 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Workout plan deleted successfully')),
          );
          _fetchWorkoutPlans();
        }
      } else {
        throw Exception('Failed to delete workout plan');
      }
    } on DioException catch (e) {
      print('❌ Delete error: ${e.response?.data ?? e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.response?.data ?? e.message}')),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting workout plan: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _selectedClientId = null;
    _selectedExerciseId = null;
    _selectedDayOfWeek = 0;
    _setsController.clear();
    _repsController.clear();
    _timePerRepController.clear();
    _orderController.clear();
    _notesController.clear();
    _editingPlanId = null;
  }

  void _showAddWorkoutPlanDialog(BuildContext context) {
    _clearForm();
    _showWorkoutPlanDialog(context, isEdit: false);
  }

  void _showEditWorkoutPlanDialog(BuildContext context, Map<String, dynamic> plan) {
    _clearForm();
    _editingPlanId = plan['id'];
    _selectedClientId = plan['client_id'];
    _selectedExerciseId = plan['exercise_detail']?['id'];
    _selectedDayOfWeek = plan['day_of_week'] ?? 0;
    _setsController.text = plan['sets'].toString();
    _repsController.text = plan['reps'].toString();
    _timePerRepController.text = plan['time_per_rep_seconds'].toString();
    _orderController.text = plan['order'].toString();
    _notesController.text = plan['notes'] ?? '';
    _showWorkoutPlanDialog(context, isEdit: true);
  }

  void _showWorkoutPlanDialog(BuildContext context, {required bool isEdit}) {
    // Fetch fresh data if needed
    if (_clients.isEmpty) _fetchClients();
    if (_exercises.isEmpty) _fetchExercises();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Workout Plan' : 'Add New Workout Plan'),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Client Dropdown
                    _isLoadingClients
                        ? const Center(child: CircularProgressIndicator())
                        : _clientsError != null
                            ? Column(
                                children: [
                                  Text(
                                    'Error: $_clientsError',
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => _fetchClients(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              )
                            : DropdownButtonFormField<int>(
                                value: _selectedClientId,
                                decoration: const InputDecoration(
                                  labelText: 'Select Client *',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Select a client')),
                                  ..._clients.map((client) {
                                    return DropdownMenuItem(
                                      value: client['id'],
                                      child: Text(client['name']),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    _selectedClientId = value;
                                  });
                                },
                              ),
                    const SizedBox(height: 12),
                    
                    // Exercise Dropdown
                    _isLoadingExercises
                        ? const Center(child: CircularProgressIndicator())
                        : _exercisesError != null
                            ? Column(
                                children: [
                                  Text(
                                    'Error: $_exercisesError',
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => _fetchExercises(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              )
                            : DropdownButtonFormField<int>(
                                value: _selectedExerciseId,
                                decoration: const InputDecoration(
                                  labelText: 'Select Exercise *',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Select an exercise')),
                                  ..._exercises.map((exercise) {
                                    return DropdownMenuItem(
                                      value: exercise['id'],
                                      child: Text(exercise['title']),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    _selectedExerciseId = value;
                                  });
                                },
                              ),
                    const SizedBox(height: 12),
                    
                    // Day of Week Dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedDayOfWeek,
                      decoration: const InputDecoration(
                        labelText: 'Day of Week *',
                        border: OutlineInputBorder(),
                      ),
                      items: _daysOfWeek.map((day) {
                        final dayOfWeek = day.keys.first;
                        final dayName = day.values.first;
                        return DropdownMenuItem(
                          value: dayOfWeek,
                          child: Text(dayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedDayOfWeek = value ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Sets and Reps Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _setsController,
                            decoration: const InputDecoration(
                              labelText: 'Sets',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _repsController,
                            decoration: const InputDecoration(
                              labelText: 'Reps',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Time per Rep and Order Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _timePerRepController,
                            decoration: const InputDecoration(
                              labelText: 'Time/Rep (sec)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _orderController,
                            decoration: const InputDecoration(
                              labelText: 'Order',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isEdit
                    ? () => _updateWorkoutPlan(context)
                    : () => _createWorkoutPlan(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                ),
                child: Text(isEdit ? 'Save Changes' : 'Add Plan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int planId, String clientName, String exerciseTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout Plan'),
        content: Text('Are you sure you want to delete the workout plan for $clientName - $exerciseTitle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteWorkoutPlan(context, planId, clientName, exerciseTitle);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          'Manage Workout Plans',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books, color: Color(0xFFE94560)),
            onPressed: () => context.push('/trainer/exercises'),
            tooltip: 'Exercise Library',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFE94560)),
            onPressed: _fetchWorkoutPlans,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFE94560)),
            onPressed: () => _showAddWorkoutPlanDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchWorkoutPlans,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94560),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _workoutPlans.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No workout plans found',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first workout plan',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _workoutPlans.length,
                      itemBuilder: (context, index) {
                        final plan = _workoutPlans[index];
                        final clientName = plan['client_name'] ?? 'Unknown';
                        final exerciseDetail = plan['exercise_detail'];
                        final exerciseTitle = exerciseDetail?['title'] ?? 'Unknown';
                        final dayDisplay = plan['day_display'] ?? 'Unknown';
                        final sets = plan['sets'] ?? 0;
                        final reps = plan['reps'] ?? 0;
                        final timePerRep = plan['time_per_rep_seconds'] ?? 0;
                        final order = plan['order'] ?? 0;
                        final notes = plan['notes'] ?? '';
                        final isActive = plan['is_active'] ?? true;
                        final createdAt = plan['created_at'] ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: const Color(0xFFE94560).withOpacity(0.15),
                            ),
                          ),
                          child: ExpansionTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE94560), Color(0xFFC72A48)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              '$exerciseTitle - $clientName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$dayDisplay • $sets sets × $reps reps',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                if (timePerRep > 0)
                                  Text(
                                    '${timePerRep}s per rep',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isActive ? Icons.visibility : Icons.visibility_off,
                                    color: isActive ? Colors.green : Colors.grey,
                                  ),
                                  onPressed: () {
                                    // Toggle active status - can be implemented with PATCH
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Status toggle coming soon')),
                                    );
                                  },
                                  tooltip: isActive ? 'Deactivate' : 'Activate',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditWorkoutPlanDialog(context, plan),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showDeleteDialog(
                                    context,
                                    plan['id'],
                                    clientName,
                                    exerciseTitle,
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoCard(
                                            'Order',
                                            order.toString(),
                                            Icons.format_list_numbered,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildInfoCard(
                                            'Sets',
                                            sets.toString(),
                                            Icons.repeat,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildInfoCard(
                                            'Reps',
                                            reps.toString(),
                                            Icons.fitness_center,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (timePerRep > 0) ...[
                                      const SizedBox(height: 12),
                                      _buildInfoCard(
                                        'Time per Rep',
                                        '$timePerRep seconds',
                                        Icons.timer,
                                      ),
                                    ],
                                    if (notes.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Notes',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notes,
                                        style: const TextStyle(color: Colors.white54),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Text(
                                      'Created: ${createdAt.toString().split('T')[0]}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFE94560)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}