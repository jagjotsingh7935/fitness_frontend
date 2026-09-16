import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/searchable_dropdown.dart';

class TrainerClientsPage extends StatefulWidget {
  const TrainerClientsPage({super.key});

  @override
  State<TrainerClientsPage> createState() => _TrainerClientsPageState();
}

class _TrainerClientsPageState extends State<TrainerClientsPage> {
  final Dio _dio = GetIt.I<DioClient>().dio;
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGoalFilter = 'All';
  String _selectedStatus = 'All'; // 'All', 'Active', 'Inactive'
  List<String> _availableGoals = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredClients {
    return _clients.where((client) {
      final name = (client['name'] ?? '').toString().toLowerCase();
      final email = (client['email'] ?? '').toString().toLowerCase();
      final phone = (client['phone'] ?? '').toString().toLowerCase();
      final target = (client['target'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          target.contains(query);

      final matchesGoal = _selectedGoalFilter == 'All' || client['target'] == _selectedGoalFilter;

      final isActive = client['is_active'] == true;
      final matchesStatus = _selectedStatus == 'All' ||
          (_selectedStatus == 'Active' && isActive) ||
          (_selectedStatus == 'Inactive' && !isActive);

      return matchesSearch && matchesGoal && matchesStatus;
    }).toList();
  }

  Future<void> _fetchClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _dio.get('/accounts/api/trainers-client-list/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data is Map && response.data['results'] is List
                ? response.data['results']
                : []);

        final mapped = data.asMap().entries.map((entry) {
          final idx = entry.key;
          final c = entry.value as Map<String, dynamic>;
          final clientName = c['client_name']?.toString() ?? 'Client';
          final email = c['client_email']?.toString() ?? '';
          final phone = c['client_phone']?.toString() ?? '';
          final goal = c['target']?.toString() ??
              (c['categories'] is List && (c['categories'] as List).isNotEmpty
                  ? (c['categories'] as List)[0].toString()
                  : 'Strength & Fitness');
          final isActive = c['is_active'] == true;
          final clientId = c['client_id'] ?? c['client'] ?? (idx + 1);

          return {
            'id': clientId,
            'link_id': c['id'],
            'name': clientName,
            'email': email,
            'phone': phone,
            'target': goal,
            'is_active': isActive,
            'workouts_done': 10 + (idx * 3),
            'total_workouts': 15,
            'assigned_at': c['assigned_at']?.toString() ?? '',
          };
        }).toList();

        final Set<String> goals = {'All'};
        for (final cl in mapped) {
          final g = cl['target']?.toString().trim() ?? '';
          if (g.isNotEmpty) goals.add(g);
        }

        setState(() {
          _clients = mapped;
          _availableGoals = goals.toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load assigned clients (${response.statusCode})');
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['error']?.toString() ??
            e.response?.data?['detail']?.toString() ??
            e.message ??
            'Network error occurred';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ─────────────────────────────────────────────
  //  MODAL: CLIENT ROUTINES & DIRECT ASSIGNMENT
  // ─────────────────────────────────────────────

  void _showClientRoutinesSheet(BuildContext context, Map<String, dynamic> client) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ClientRoutinesSheet(
        client: client,
        dio: _dio,
      ),
    );
  }

  void _showClientDietSheet(BuildContext context, Map<String, dynamic> client) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ClientDietSheet(
        client: client,
        dio: _dio,
      ),
    );
  }

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
              'Client Roster',
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
            icon: const Icon(Icons.refresh, color: Color(0xFFE94560)),
            onPressed: _fetchClients,
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
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF4B72), size: 48),
                        const SizedBox(height: 14),
                        Text(
                          '$_errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _fetchClients,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE94560),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // 1. Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B30),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE94560).withValues(alpha: 0.25),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search client by name, email, phone, goal...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE94560), size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    // 2. Goal / Category Filter Chips
                    if (_availableGoals.length > 1)
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _availableGoals.length,
                          itemBuilder: (context, index) {
                            final goal = _availableGoals[index];
                            final isSelected = _selectedGoalFilter == goal;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  goal,
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
                                  if (selected) {
                                    setState(() => _selectedGoalFilter = goal);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),

                    // 3. Status Filters & Result Count
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            'Showing ${_filteredClients.length} of ${_clients.length} assigned clients',
                            style: const TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          // Status dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B30),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                dropdownColor: const Color(0xFF161B30),
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE94560), size: 18),
                                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                                isDense: true,
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('Status: All')),
                                  DropdownMenuItem(value: 'Active', child: Text('Active Only')),
                                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive Only')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedStatus = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 4. Client List View
                    Expanded(
                      child: _filteredClients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_search_rounded, size: 54, color: Colors.white24),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty || _selectedGoalFilter != 'All' || _selectedStatus != 'All'
                                        ? 'No clients match your search/filters'
                                        : 'No clients assigned yet.',
                                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                                  ),
                                  if (_searchQuery.isNotEmpty || _selectedGoalFilter != 'All' || _selectedStatus != 'All') ...[
                                    const SizedBox(height: 10),
                                    TextButton.icon(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _selectedGoalFilter = 'All';
                                          _selectedStatus = 'All';
                                        });
                                      },
                                      icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFF00F5A0)),
                                      label: const Text('Reset Filters', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 12)),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                              itemCount: _filteredClients.length,
                              itemBuilder: (context, index) {
                                final client = _filteredClients[index];
                                return _buildProgressCard(client);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> client) {
    final int workoutsDone = client['workouts_done'] ?? 0;
    final int totalWorkouts = client['total_workouts'] ?? 15;
    final double completion = (workoutsDone / totalWorkouts).clamp(0.0, 1.0);
    final String target = client['target'] ?? 'General Fitness';
    final bool isActive = client['is_active'] == true;
    final String phone = client['phone'] ?? '';

    return GestureDetector(
      onTap: () => _showClientRoutinesSheet(context, client),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF131830),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE94560).withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE94560).withValues(alpha: 0.15),
                    radius: 24,
                    child: Text(
                      client['name'].toString().isNotEmpty
                          ? client['name'].toString().substring(0, 1).toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Color(0xFFE94560),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                client['name'] ?? 'Client',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF00F5A0).withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(
                                  color: isActive ? const Color(0xFF00F5A0) : Colors.white54,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          client['email'] ?? (phone.isNotEmpty ? phone : ''),
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFE5C07B), size: 22),
                    tooltip: 'Manage Nutrition & Diet Plan',
                    onPressed: () => _showClientDietSheet(context, client),
                  ),
                  IconButton(
                    icon: const Icon(Icons.assignment_add, color: Color(0xFFE94560), size: 22),
                    tooltip: 'Manage Workout Routines',
                    onPressed: () => _showClientRoutinesSheet(context, client),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Plan Completion',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${(completion * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFFE94560),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completion,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Workouts', '$workoutsDone/$totalWorkouts', Icons.fitness_center),
                    _buildStatItem(
                      'Status',
                      completion >= 1.0 ? 'Completed' : (isActive ? 'In Progress' : 'Pending'),
                      Icons.bolt,
                    ),
                    _buildStatItem('Goal', target, Icons.track_changes),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.white38),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  CLIENT SPECIFIC ROUTINES MODAL SHEET
// ─────────────────────────────────────────────

class _ClientRoutinesSheet extends StatefulWidget {
  final Map<String, dynamic> client;
  final Dio dio;

  const _ClientRoutinesSheet({required this.client, required this.dio});

  @override
  State<_ClientRoutinesSheet> createState() => _ClientRoutinesSheetState();
}

class _ClientRoutinesSheetState extends State<_ClientRoutinesSheet> {
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _masterPlans = [];
  bool _isLoading = true;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _fetchClientRoutines();
    _fetchExercises();
    _fetchMasterPlans();
  }

  Future<void> _fetchClientRoutines() async {
    setState(() => _isLoading = true);
    try {
      final res = await widget.dio.get('/fitness/api/workout-plans/');
      if (res.statusCode == 200) {
        final List<dynamic> data = res.data is List
            ? res.data
            : (res.data is Map && res.data['results'] is List ? res.data['results'] : []);

        final clientId = widget.client['id'];
        final clientPlans = data.where((p) => p['client'] == clientId || p['client_id'] == clientId).map((p) => p as Map<String, dynamic>).toList();

        setState(() {
          _plans = clientPlans;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchExercises() async {
    try {
      final res = await widget.dio.get('/fitness/api/exercises/');
      if (res.statusCode == 200) {
        final List<dynamic> data = res.data is List
            ? res.data
            : (res.data is Map && res.data['results'] is List ? res.data['results'] : []);
        setState(() {
          _exercises = data.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchMasterPlans() async {
    try {
      final res = await widget.dio.get('/fitness/api/master-workout-plans/');
      if (res.statusCode == 200) {
        final List<dynamic> data = res.data is List
            ? res.data
            : (res.data is Map && res.data['results'] is List ? res.data['results'] : []);
        setState(() {
          _masterPlans = data.map((p) => p as Map<String, dynamic>).toList();
        });
      }
    } catch (_) {}
  }

  void _showApplyMasterProgramDialog() {
    int? selectedMasterId = _masterPlans.isNotEmpty ? _masterPlans[0]['id'] as int : null;
    bool clearExisting = true;
    bool isApplying = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161B30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.auto_stories_rounded, color: Color(0xFF00F5A0), size: 22),
              SizedBox(width: 8),
              Text(
                'Apply Master Program',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select a master workout template to assign to ${widget.client['name']}:',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                if (_masterPlans.isEmpty)
                  const Text('No master programs created yet. Create one in the Routines tab.', style: TextStyle(color: Colors.white54, fontSize: 12))
                else
                  SearchableDropdown<int>(
                    value: selectedMasterId,
                    labelText: 'Select Master Template *',
                    hintText: 'Search and select master template',
                    searchHint: 'Search template name...',
                    items: _masterPlans.map((m) {
                      final itemsCount = (m['items'] as List?)?.length ?? 0;
                      return SearchableDropdownItem<int>(
                        value: m['id'] as int,
                        label: m['title'] ?? 'Template',
                        subtitle: '$itemsCount exercises',
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedMasterId = val),
                  ),
                const SizedBox(height: 14),
                CheckboxListTile(
                  value: clearExisting,
                  activeColor: const Color(0xFFE94560),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Replace existing routines', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Clears old routines before applying.', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  onChanged: (val) => setDialogState(() => clearExisting = val ?? true),
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
              onPressed: (_masterPlans.isEmpty || selectedMasterId == null || isApplying)
                  ? null
                  : () async {
                      setDialogState(() => isApplying = true);
                      try {
                        final req = {
                          'client_ids': [widget.client['id']],
                          'clear_existing': clearExisting,
                        };
                        final res = await widget.dio.post(
                          '/fitness/api/master-workout-plans/$selectedMasterId/assign/',
                          data: req,
                        );
                        if (res.statusCode == 200) {
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Master program applied to client schedule!'),
                                backgroundColor: Color(0xFF00F5A0),
                              ),
                            );
                            _fetchClientRoutines();
                          }
                        }
                      } on DioException catch (e) {
                        setDialogState(() => isApplying = false);
                        final msg = e.response?.data is Map
                            ? (e.response?.data['error'] ?? e.response?.data['detail'] ?? e.response?.data.values.join(', '))
                            : (e.message ?? 'Failed to apply program');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.redAccent),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isApplying = false);
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
              child: isApplying
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Apply Program', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignExerciseDialog() {
    int? selectedExerciseId;
    int selectedDay = 0;
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '12');
    final timeCtrl = TextEditingController(text: '45');
    final notesCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161B30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.add_box_rounded, color: Color(0xFFE94560), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Assign Custom Exercise to ${widget.client['name']}',
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
                  items: _days.asMap().entries.map((e) {
                    return DropdownMenuItem<int>(
                      value: e.key,
                      child: Text(e.value),
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
                    labelText: 'Coach Instructions (Optional)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'e.g. 45s rest between sets',
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
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (selectedExerciseId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select an exercise')),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        final req = {
                          'client_id': widget.client['id'],
                          'exercise_id': selectedExerciseId,
                          'day_of_week': selectedDay,
                          'sets': int.tryParse(setsCtrl.text) ?? 3,
                          'reps': int.tryParse(repsCtrl.text) ?? 12,
                          'time_per_rep_seconds': int.tryParse(timeCtrl.text) ?? 45,
                          'order': _plans.length + 1,
                          'notes': notesCtrl.text.trim(),
                        };
                        final res = await widget.dio.post('/fitness/api/workout-plans/create/', data: req);
                        if (res.statusCode == 201 || res.statusCode == 200) {
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          _fetchClientRoutines();
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Add Exercise'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRoutine(int planId) async {
    try {
      await widget.dio.delete('/fitness/api/workout-plans/$planId/');
      _fetchClientRoutines();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF101323),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE94560).withValues(alpha: 0.15),
                  radius: 20,
                  child: Text(
                    widget.client['name'].toString().isNotEmpty
                        ? widget.client['name'].toString().substring(0, 1).toUpperCase()
                        : 'C',
                    style: const TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client['name'] ?? 'Client',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        '${widget.client['target']} · ${_plans.length} Assigned',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (sheetCtx) => _ClientDietSheet(
                        client: widget.client,
                        dio: widget.dio,
                      ),
                    );
                  },
                  icon: const Icon(Icons.restaurant_menu_rounded, size: 14),
                  label: const Text('Diet', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE5C07B),
                    side: const BorderSide(color: Color(0xFFE5C07B)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: _showApplyMasterProgramDialog,
                  icon: const Icon(Icons.auto_stories_rounded, size: 14),
                  label: const Text('Program', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00F5A0),
                    side: const BorderSide(color: Color(0xFF00F5A0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: _showAssignExerciseDialog,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('+ Ex', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
                : _plans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.fitness_center_rounded, color: Colors.white24, size: 54),
                            const SizedBox(height: 14),
                            const Text(
                              'No Workouts Assigned to this Client',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tap "Program" to link a Master Program or "+ Ex" to add an exercise.',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: _showApplyMasterProgramDialog,
                              icon: const Icon(Icons.auto_stories_rounded, size: 18),
                              label: const Text('Apply Master Program'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00F5A0),
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        itemCount: _plans.length,
                        itemBuilder: (context, index) {
                          final plan = _plans[index];
                          final exercise = plan['exercise_detail'];
                          final title = exercise?['title'] ?? 'Exercise';
                          final day = plan['day_display'] ?? _days[plan['day_of_week'] ?? 0];
                          final sets = plan['sets'] ?? 0;
                          final reps = plan['reps'] ?? 0;
                          final notes = plan['notes']?.toString() ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1F36),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE94560).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        day.substring(0, 3).toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFFE94560),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$sets×$reps',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (notes.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          notes,
                                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4B72), size: 20),
                                  onPressed: () => _deleteRoutine(plan['id']),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CLIENT DIET PLAN MODAL SHEET
// ─────────────────────────────────────────────

class _ClientDietSheet extends StatefulWidget {
  final Map<String, dynamic> client;
  final Dio dio;

  const _ClientDietSheet({required this.client, required this.dio});

  @override
  State<_ClientDietSheet> createState() => _ClientDietSheetState();
}

class _ClientDietSheetState extends State<_ClientDietSheet> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDietPlans();
  }

  Future<void> _fetchDietPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clientId = widget.client['id'];
      final res = await widget.dio.get('/fitness/api/diet-plans/?client_id=$clientId');
      if (res.statusCode == 200) {
        final data = res.data;
        List<dynamic> list = data is List ? data : (data['results'] ?? []);
        setState(() {
          _plans = List<Map<String, dynamic>>.from(list);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load diet plans';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Network error loading diet plans';
        });
      }
    }
  }

  void _openDietPlanEditor([Map<String, dynamic>? plan]) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ClientDietPlanEditorSheet(
        client: widget.client,
        plan: plan,
        dio: widget.dio,
        onSaved: () {
          Navigator.pop(ctx);
          _fetchDietPlans();
        },
      ),
    );
  }

  Future<void> _deletePlan(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141829),
        title: const Text('Delete Diet Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this diet plan? This cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5252)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.dio.delete('/fitness/api/diet-plans/$id/');
      _fetchDietPlans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diet plan deleted successfully')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete diet plan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientName = widget.client['name'] ?? 'Client';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF101323),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE5C07B).withValues(alpha: 0.15),
                  radius: 20,
                  child: Text(
                    clientName.toString().isNotEmpty
                        ? clientName.toString().substring(0, 1).toUpperCase()
                        : 'C',
                    style: const TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const Text(
                        'Nutrition & Diet Plans',
                        style: TextStyle(color: Color(0xFFE5C07B), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openDietPlanEditor(),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('+ New Plan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5C07B),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5C07B)),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 40),
                            const SizedBox(height: 10),
                            Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _fetchDietPlans,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C07B), foregroundColor: Colors.black),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _plans.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFE5C07B).withValues(alpha: 0.1),
                                      border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.25)),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text('🥗', style: TextStyle(fontSize: 34)),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'No Diet Plan Assigned Yet',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Build a custom daily meal plan with calorie and macro targets for $clientName.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                                  ),
                                  const SizedBox(height: 22),
                                  ElevatedButton.icon(
                                    onPressed: () => _openDietPlanEditor(),
                                    icon: const Icon(Icons.add_circle_outline, size: 18),
                                    label: const Text('Create Diet Plan', style: TextStyle(fontWeight: FontWeight.w800)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE5C07B),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _plans.length,
                            itemBuilder: (context, idx) {
                              final plan = _plans[idx];
                              return _buildDietPlanCard(plan);
                            },
                          ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildDietPlanCard(Map<String, dynamic> plan) {
    final int id = plan['id'] ?? 0;
    final String title = plan['title'] ?? 'Diet Plan';
    final int kcal = plan['daily_calorie_target'] ?? 2000;
    final int protein = plan['protein_grams'] ?? 0;
    final int carbs = plan['carbs_grams'] ?? 0;
    final int fat = plan['fat_grams'] ?? 0;
    final String notes = plan['notes'] ?? '';
    final bool isActive = plan['is_active'] == true;
    final List meals = (plan['meals'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF191F38),
            Color(0xFF13172A),
            Color(0xFF0C0E1B),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFFE5C07B).withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: isActive,
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: const Color(0xFFE5C07B),
        collapsedIconColor: Colors.white54,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFE5C07B)],
                ),
              ),
              alignment: Alignment.center,
              child: const Text('🥗', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF00F5A0).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isActive ? const Color(0xFF00F5A0).withValues(alpha: 0.4) : Colors.white24,
                ),
              ),
              child: Text(
                isActive ? 'Active' : 'Archived',
                style: TextStyle(
                  color: isActive ? const Color(0xFF00F5A0) : Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              _statTag('🔥 $kcal kcal', const Color(0xFFFF8C00)),
              const SizedBox(width: 6),
              _statTag('🥩 ${protein}g P', const Color(0xFF00F5A0)),
              const SizedBox(width: 6),
              _statTag('🍚 ${carbs}g C', const Color(0xFFE5C07B)),
              const SizedBox(width: 6),
              _statTag('🥑 ${fat}g F', const Color(0xFFFF5252)),
            ],
          ),
        ),
        children: [
          const Divider(color: Colors.white12, height: 20),

          if (notes.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5C07B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.2)),
              ),
              child: Text('💡 Notes: $notes',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3)),
            ),
          ],

          // Meals section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meals Scheduled (${meals.length})',
                style: const TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.w800, fontSize: 12),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Color(0xFFE5C07B), size: 18),
                    onPressed: () => _openDietPlanEditor(plan),
                    tooltip: 'Edit Plan',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252), size: 18),
                    onPressed: () => _deletePlan(id),
                    tooltip: 'Delete Plan',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          ...meals.map((m) {
            final mealType = (m['meal_type_display'] ?? '').toString();
            final name = (m['name'] ?? 'Meal').toString();
            final time = (m['time_label'] ?? '').toString();
            final calories = (m['calories'] ?? 0).toString();
            final emoji = (m['emoji'] ?? '🍽️').toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1322),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                        Text(time.isNotEmpty ? '$time · $mealType' : mealType,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10)),
                      ],
                    ),
                  ),
                  Text('$calories kcal', style: const TextStyle(color: Color(0xFFFF8C00), fontSize: 11.5, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

// ─────────────────────────────────────────────
//  CLIENT DIET PLAN BUILDER / EDITOR MODAL SHEET
// ─────────────────────────────────────────────

class _ClientDietPlanEditorSheet extends StatefulWidget {
  final Map<String, dynamic> client;
  final Map<String, dynamic>? plan;
  final Dio dio;
  final VoidCallback onSaved;

  const _ClientDietPlanEditorSheet({
    required this.client,
    this.plan,
    required this.dio,
    required this.onSaved,
  });

  @override
  State<_ClientDietPlanEditorSheet> createState() => _ClientDietPlanEditorSheetState();
}

class _ClientDietPlanEditorSheetState extends State<_ClientDietPlanEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _kcalCtrl;
  late TextEditingController _proteinCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _fatCtrl;
  late TextEditingController _notesCtrl;
  bool _isActive = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _meals = [];

  final List<Map<String, String>> _mealTypes = [
    {'value': 'BREAKFAST', 'label': '🌅 Breakfast'},
    {'value': 'MID_MORNING', 'label': '🍎 Mid-Morning Snack'},
    {'value': 'LUNCH', 'label': '🥗 Lunch'},
    {'value': 'EVENING_SNACK', 'label': '🥜 Evening Snack'},
    {'value': 'DINNER', 'label': '🍽️ Dinner'},
    {'value': 'POST_WORKOUT', 'label': '⚡ Post-Workout'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _titleCtrl = TextEditingController(text: p?['title'] ?? 'Personalized Nutrition Plan');
    _kcalCtrl = TextEditingController(text: (p?['daily_calorie_target'] ?? 2000).toString());
    _proteinCtrl = TextEditingController(text: (p?['protein_grams'] ?? 140).toString());
    _carbsCtrl = TextEditingController(text: (p?['carbs_grams'] ?? 220).toString());
    _fatCtrl = TextEditingController(text: (p?['fat_grams'] ?? 65).toString());
    _notesCtrl = TextEditingController(text: p?['notes'] ?? '');
    _isActive = p?['is_active'] ?? true;

    if (p != null && p['meals'] is List) {
      _meals = (p['meals'] as List).map((m) => {
        'meal_type': m['meal_type'] ?? 'BREAKFAST',
        'name': m['name'] ?? '',
        'time_label': m['time_label'] ?? '',
        'calories': (m['calories'] ?? 350).toString(),
      }).toList();
    } else {
      _meals = [
        {'meal_type': 'BREAKFAST', 'name': 'Oats + Banana + Whey Protein', 'time_label': '8:00 AM', 'calories': '400'},
        {'meal_type': 'MID_MORNING', 'name': 'Boiled Eggs + Whole Wheat Toast', 'time_label': '10:30 AM', 'calories': '250'},
        {'meal_type': 'LUNCH', 'name': 'Grilled Chicken Breast + Brown Rice', 'time_label': '1:30 PM', 'calories': '550'},
        {'meal_type': 'DINNER', 'name': 'Grilled Fish + Mixed Green Salad', 'time_label': '8:00 PM', 'calories': '450'},
      ];
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _addMeal() {
    setState(() {
      _meals.add({
        'meal_type': 'LUNCH',
        'name': '',
        'time_label': '1:00 PM',
        'calories': '400',
      });
    });
  }

  void _removeMeal(int i) {
    setState(() {
      _meals.removeAt(i);
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final mealsPayload = _meals.map((m) => {
      'meal_type': m['meal_type'],
      'name': m['name'],
      'time_label': m['time_label'],
      'calories': int.tryParse(m['calories']?.toString() ?? '350') ?? 350,
    }).toList();

    final payload = {
      'client': widget.client['id'],
      'title': _titleCtrl.text.trim(),
      'daily_calorie_target': int.tryParse(_kcalCtrl.text) ?? 2000,
      'protein_grams': int.tryParse(_proteinCtrl.text) ?? 140,
      'carbs_grams': int.tryParse(_carbsCtrl.text) ?? 220,
      'fat_grams': int.tryParse(_fatCtrl.text) ?? 65,
      'notes': _notesCtrl.text.trim(),
      'is_active': _isActive,
      'meals_data': mealsPayload,
    };

    try {
      if (widget.plan != null) {
        final id = widget.plan!['id'];
        await widget.dio.put('/fitness/api/diet-plans/$id/', data: payload);
      } else {
        await widget.dio.post('/fitness/api/diet-plans/', data: payload);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving diet plan. Please check inputs.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plan != null;
    final clientName = widget.client['name'] ?? 'Client';

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF141828),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Modal Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Diet Plan' : 'Create Diet Plan',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        Text(
                          'For $clientName',
                          style: const TextStyle(color: Color(0xFFE5C07B), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 48 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom),
                  children: [
                    // Plan Title
                    const Text('Plan Title *', style: TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: _inputDeco('e.g. 2,000 kcal Lean Fat Loss'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Calories & Macros Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Calories (kcal)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _kcalCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                decoration: _inputDeco('2000'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Protein (g)', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 11)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _proteinCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                decoration: _inputDeco('140'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Carbs (g)', style: TextStyle(color: Color(0xFFE5C07B), fontSize: 11)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _carbsCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                decoration: _inputDeco('220'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fat (g)', style: TextStyle(color: Color(0xFFFF5252), fontSize: 11)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _fatCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                decoration: _inputDeco('65'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Coach Notes
                    const Text('Coach Instructions / Notes', style: TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _inputDeco('Drink at least 3.5L of water daily, 8 hrs of sleep...'),
                    ),
                    const SizedBox(height: 14),

                    // Active Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isActive,
                      activeThumbColor: const Color(0xFF00F5A0),
                      activeTrackColor: const Color(0xFF00F5A0).withValues(alpha: 0.4),
                      title: const Text('Set as Active Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: const Text('Client will see this plan on their home dashboard.', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                    const Divider(color: Colors.white12, height: 24),

                    // Meals Builder
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daily Meals Schedule', style: TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.w800, fontSize: 14)),
                        ElevatedButton.icon(
                          onPressed: _addMeal,
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add Meal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00F5A0),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ..._meals.asMap().entries.map((entry) {
                      final i = entry.key;
                      final m = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1322),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: m['meal_type'],
                                      dropdownColor: const Color(0xFF161B30),
                                      items: _mealTypes.map((t) {
                                        return DropdownMenuItem<String>(
                                          value: t['value'],
                                          child: Text(t['label']!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => m['meal_type'] = val);
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFF5252), size: 18),
                                  onPressed: () => _removeMeal(i),
                                  tooltip: 'Remove Meal',
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              initialValue: m['name'],
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _inputDeco('Food items (e.g. 4 Egg Whites + Toast)'),
                              onChanged: (val) => m['name'] = val,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: m['time_label'],
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    decoration: _inputDeco('Time (e.g. 8:30 AM)'),
                                    onChanged: (val) => m['time_label'] = val,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: m['calories']?.toString(),
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    decoration: _inputDeco('Calories (e.g. 350)'),
                                    onChanged: (val) => m['calories'] = val,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5C07B),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : Text(
                                isEditing ? 'Save Changes' : 'Assign Diet Plan',
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF0F1322),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5C07B), width: 1.2),
      ),
    );
  }
}
