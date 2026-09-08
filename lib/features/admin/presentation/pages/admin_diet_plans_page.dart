import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/dio_client.dart';

class AdminDietPlansPage extends StatefulWidget {
  const AdminDietPlansPage({super.key});

  @override
  State<AdminDietPlansPage> createState() => _AdminDietPlansPageState();
}

class _AdminDietPlansPageState extends State<AdminDietPlansPage> {
  final Dio _dio = GetIt.I<DioClient>().dio;
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = 'All'; // 'All', 'Active', 'Inactive'

  @override
  void initState() {
    super.initState();
    _fetchDietPlans();
    _fetchClients();
  }

  Future<void> _fetchDietPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _dio.get('/fitness/api/diet-plans/');
      if (res.statusCode == 200) {
        final data = res.data;
        List<dynamic> list = data is List ? data : (data['results'] ?? []);
        _plans = List<Map<String, dynamic>>.from(list);
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load diet plans';
        });
      }
    }
  }

  Future<void> _fetchClients() async {
    try {
      final res = await _dio.get('/accounts/api/client/');
      if (res.statusCode == 200) {
        final data = res.data;
        List<dynamic> list = data is List ? data : (data['results'] ?? []);
        if (mounted) {
          setState(() {
            _clients = List<Map<String, dynamic>>.from(list);
          });
        }
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filteredPlans {
    return _plans.where((p) {
      final clientName = (p['client_name'] ?? '').toString().toLowerCase();
      final clientEmail = (p['client_email'] ?? '').toString().toLowerCase();
      final title = (p['title'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();

      final matchesQuery = q.isEmpty ||
          clientName.contains(q) ||
          clientEmail.contains(q) ||
          title.contains(q);

      final isActive = p['is_active'] == true;
      final matchesStatus = _filterStatus == 'All' ||
          (_filterStatus == 'Active' && isActive) ||
          (_filterStatus == 'Inactive' && !isActive);

      return matchesQuery && matchesStatus;
    }).toList();
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
      await _dio.delete('/fitness/api/diet-plans/$id/');
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

  void _openPlanForm([Map<String, dynamic>? plan]) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DietPlanFormSheet(
        plan: plan,
        clients: _clients,
        dio: _dio,
        onSaved: () {
          Navigator.pop(ctx);
          _fetchDietPlans();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101426),
        title: const Text('Client Diet Plans', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchDietPlans,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPlanForm(),
        backgroundColor: const Color(0xFFE94560),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Diet Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B30),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.2)),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search by client or diet title...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: Color(0xFFE5C07B), size: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Filter status
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B30),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.2)),
                    ),
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      dropdownColor: const Color(0xFF161B30),
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                      icon: const Icon(Icons.filter_list_rounded, color: Color(0xFFE5C07B), size: 18),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Plans')),
                        DropdownMenuItem(value: 'Active', child: Text('Active')),
                        DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _filterStatus = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Showing ${_filteredPlans.length} diet plans',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 48),
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchDietPlans, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _filteredPlans.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.restaurant_rounded, size: 54, color: Colors.white24),
                                const SizedBox(height: 12),
                                const Text('No diet plans found.', style: TextStyle(color: Colors.white60, fontSize: 15)),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: () => _openPlanForm(),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Create First Diet Plan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE94560),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _filteredPlans.length,
                            itemBuilder: (ctx, i) => _buildPlanCard(_filteredPlans[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final id = plan['id'];
    final title = plan['title'] ?? 'Diet Plan';
    final clientName = plan['client_name'] ?? 'Client';
    final clientEmail = plan['client_email'] ?? '';
    final kcal = plan['daily_calorie_target'] ?? 2000;
    final protein = plan['protein_grams'] ?? 140;
    final carbs = plan['carbs_grams'] ?? 220;
    final fat = plan['fat_grams'] ?? 65;
    final isActive = plan['is_active'] == true;
    final meals = (plan['meals'] as List?) ?? [];
    final notes = (plan['notes'] ?? '').toString().trim();

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
          color: isActive
              ? const Color(0xFFE5C07B).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08),
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
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: const Color(0xFFE5C07B),
        collapsedIconColor: Colors.white54,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFE5C07B)],
                ),
              ),
              alignment: Alignment.center,
              child: const Text('🥗', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$clientName ($clientEmail)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF00F5A0).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF00F5A0).withValues(alpha: 0.4)
                      : Colors.white24,
                ),
              ),
              child: Text(
                isActive ? 'Active' : 'Archived',
                style: TextStyle(
                  color: isActive ? const Color(0xFF00F5A0) : Colors.white54,
                  fontSize: 10.5,
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
                    onPressed: () => _openPlanForm(plan),
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
//  CREATE / EDIT DIET PLAN MODAL BOTTOM SHEET
// ─────────────────────────────────────────────

class _DietPlanFormSheet extends StatefulWidget {
  final Map<String, dynamic>? plan;
  final List<Map<String, dynamic>> clients;
  final Dio dio;
  final VoidCallback onSaved;

  const _DietPlanFormSheet({
    this.plan,
    required this.clients,
    required this.dio,
    required this.onSaved,
  });

  @override
  State<_DietPlanFormSheet> createState() => _DietPlanFormSheetState();
}

class _DietPlanFormSheetState extends State<_DietPlanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedClientId;
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
    _selectedClientId = p?['client'];
    _titleCtrl = TextEditingController(text: p?['title'] ?? 'Weight Loss Nutrition Plan');
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
      // Default initial meals template
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
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client for this diet plan')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final mealsPayload = _meals.map((m) => {
      'meal_type': m['meal_type'],
      'name': m['name'],
      'time_label': m['time_label'],
      'calories': int.tryParse(m['calories']?.toString() ?? '350') ?? 350,
    }).toList();

    final payload = {
      'client': _selectedClientId,
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
                  Text(
                    isEditing ? 'Edit Diet Plan' : 'Create Client Diet Plan',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const Spacer(),
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
                    // Client Selector
                    const Text('Assign to Client *', style: TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1322),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedClientId,
                          hint: const Text('Select a Client', style: TextStyle(color: Colors.white38, fontSize: 13)),
                          dropdownColor: const Color(0xFF161B30),
                          items: widget.clients.map((c) {
                            final id = c['id'] as int;
                            final name = c['user_full_name'] ?? c['name'] ?? 'Client #$id';
                            final email = c['user_email'] ?? c['email'] ?? '';
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text('$name ($email)',
                                  style: const TextStyle(color: Colors.white, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedClientId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

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

                    // Calorie and Macro targets
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Target Kcal', style: TextStyle(color: Color(0xFFFF8C00), fontWeight: FontWeight.w700, fontSize: 11.5)),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Protein (g)', style: TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.w700, fontSize: 11.5)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _proteinCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                decoration: _inputDeco('150'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Carbs (g)', style: TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.w700, fontSize: 11.5)),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fats (g)', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w700, fontSize: 11.5)),
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
                      decoration: _inputDeco('e.g. Drink 3.5L water, avoid processed carbs after 7 PM'),
                    ),
                    const SizedBox(height: 20),

                    // Meals Builder Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SCHEDULED MEALS',
                            style: TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.w900, letterSpacing: 1.1, fontSize: 12)),
                        TextButton.icon(
                          onPressed: _addMeal,
                          icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF00F5A0)),
                          label: const Text('+ Add Meal', style: TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Meals Items
                    ...List<Widget>.generate(_meals.length, (i) {
                      final m = _meals[i];
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
                                // Meal Type dropdown with auto-icon
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: m['meal_type'],
                                    dropdownColor: const Color(0xFF161B30),
                                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                                    decoration: _inputDeco('Meal Type'),
                                    items: _mealTypes.map((t) => DropdownMenuItem(
                                      value: t['value'],
                                      child: Text(t['label']!),
                                    )).toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _meals[i]['meal_type'] = v);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Time
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: m['time_label'],
                                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                    decoration: _inputDeco('Time (8 AM)'),
                                    onChanged: (v) => _meals[i]['time_label'] = v.trim(),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252), size: 20),
                                  onPressed: () => _removeMeal(i),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Description
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    initialValue: m['name'],
                                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                    decoration: _inputDeco('Food (e.g. Oats + Eggs)'),
                                    onChanged: (v) => _meals[i]['name'] = v.trim(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Calories
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    initialValue: m['calories'],
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Color(0xFFFF8C00), fontSize: 12.5, fontWeight: FontWeight.bold),
                                    decoration: _inputDeco('Kcal'),
                                    onChanged: (v) => _meals[i]['calories'] = v.trim(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94560),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                isEditing ? 'Update Diet Plan' : 'Save & Assign Diet Plan',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
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
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      filled: true,
      fillColor: const Color(0xFF0F1322),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5C07B))),
    );
  }
}
