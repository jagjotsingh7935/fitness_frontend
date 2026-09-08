import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';

class AdminClientsPage extends StatefulWidget {
  const AdminClientsPage({super.key});

  @override
  State<AdminClientsPage> createState() => _AdminClientsPageState();
}

class _AdminClientsPageState extends State<AdminClientsPage> {
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;
  String? _errorMessage;

  final Dio _dio = GetIt.I<DioClient>().dio;
  List<Map<String, dynamic>> _categories = [];

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All'; // 'All', 'Active', 'Inactive'
  String _selectedCoachFilter = 'All'; // 'All', 'With Coach', 'Self-Guided'

  @override
  void initState() {
    super.initState();
    _fetchClients();
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredClients {
    return _clients.where((client) {
      final name = (client['user_full_name'] ?? '').toString().toLowerCase();
      final email = (client['user_email'] ?? '').toString().toLowerCase();
      final phone = (client['phone'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          email.contains(query) ||
          phone.contains(query);

      final cats = (client['category_names'] as List?)?.map((c) => c.toString()).toList() ?? [];
      final matchesCategory = _selectedCategory == 'All' || cats.contains(_selectedCategory);

      final isActive = client['is_active'] == true;
      final matchesStatus = _selectedStatus == 'All' ||
          (_selectedStatus == 'Active' && isActive) ||
          (_selectedStatus == 'Inactive' && !isActive);

      final trainers = client['active_trainers'] is List ? (client['active_trainers'] as List) : [];
      final matchesCoach = _selectedCoachFilter == 'All' ||
          (_selectedCoachFilter == 'With Coach' && trainers.isNotEmpty) ||
          (_selectedCoachFilter == 'Self-Guided' && trainers.isEmpty);

      return matchesSearch && matchesCategory && matchesStatus && matchesCoach;
    }).toList();
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'C';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().substring(0, 1).toUpperCase();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _dio.get('/accounts/api/category-list/');
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> list = data is List ? data : (data['results'] ?? []);
        if (!mounted) return;
        setState(() {
          _categories = List<Map<String, dynamic>>.from(list);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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

        if (!mounted) return;

        setState(() {
          _clients = clientsData.map((client) {
            List<int> categoryIds = [];
            List<String> categoryNames = [];

            if (client['categories'] != null && client['categories'] is List) {
              categoryIds = (client['categories'] as List)
                  .map((cat) => cat['id'] is int ? cat['id'] as int : int.tryParse(cat['id'].toString()) ?? 0)
                  .toList();
              categoryNames = (client['categories'] as List)
                  .map((cat) => cat['name']?.toString() ?? '')
                  .toList();
            }

            return {
              'id': client['client_id'] ?? client['id'],
              'user_email': client['email'] ?? client['user_email'] ?? 'N/A',
              'user_full_name': client['name'] ?? client['user_full_name'] ??
                  '${client['first_name'] ?? ''} ${client['last_name'] ?? ''}'.trim(),
              'phone': client['phone']?.toString() ?? '',
              'address': client['address']?.toString() ?? '',
              'date_of_birth': client['date_of_birth']?.toString() ?? '',
              'is_active': client['is_active'] ?? true,
              'is_subscribed': client['is_subscribed'] ?? true,
              'category_ids': categoryIds,
              'category_names': categoryNames,
              'active_trainers': client['active_trainers'] ?? [],
              'created_at': client['created_at'],
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load clients: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message ?? 'Network error occurred';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFreshTrainers() async {
    try {
      final response = await _dio.get('/accounts/api/trainer/');
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> list = data is List ? data : (data['results'] ?? []);
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (_) {}
    return [];
  }

  Future<void> _createClient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String address,
    required List<int> categoryIds,
  }) async {
    try {
      final response = await _dio.post(
        '/accounts/api/signup/client/',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'phone': phone,
          'address': address,
          'category_ids': categoryIds,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        _fetchClients();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ New client enrolled successfully!'),
            backgroundColor: Color(0xFF00F5A0),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final msg = data is Map ? (data['email'] ?? data['detail'] ?? data['error'] ?? e.message) : e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Error: $msg'),
          backgroundColor: const Color(0xFFFF4B72),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating client: $e'),
          backgroundColor: const Color(0xFFFF4B72),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _syncTrainersForClient(int clientId, List<int> trainerIds) async {
    try {
      final response = await _dio.post(
        '/accounts/api/assign-trainer/',
        data: {'client_id': clientId, 'trainer_ids': trainerIds},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        _fetchClients();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              trainerIds.isEmpty
                  ? 'Coaches unlinked successfully.'
                  : '✅ Coach assignments updated (${trainerIds.length} linked)!',
            ),
            backgroundColor: const Color(0xFF00F5A0),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final msg = data is Map ? (data['error'] ?? data['detail'] ?? e.message) : (e.message ?? 'Failed to update');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ $msg'),
          backgroundColor: const Color(0xFFFF4B72),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFFF4B72),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteClient(int clientId) async {
    try {
      await _dio.delete('/accounts/api/client/$clientId/');
      if (!mounted) return;
      _fetchClients();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client removed successfully'),
          backgroundColor: Color(0xFFFF4B72),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: $e'), backgroundColor: const Color(0xFFFF4B72)),
      );
    }
  }

  void _showAddClientModal() {
    final fNameCtrl = TextEditingController();
    final lNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'Client@123456');
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final selectedCatIds = <int>{};

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1326),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enroll New Client',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildInputField('First Name *', fNameCtrl)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField('Last Name', lNameCtrl)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildInputField('Email Address *', emailCtrl, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 14),
                        _buildInputField('Temporary Password *', passwordCtrl, icon: Icons.lock_outline_rounded),
                        const SizedBox(height: 14),
                        _buildInputField('Phone Number', phoneCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 14),
                        _buildInputField('Residential Address', addressCtrl, icon: Icons.location_on_outlined),
                        const SizedBox(height: 18),

                        if (_categories.isNotEmpty) ...[
                          const Text(
                            'Select Fitness Goals',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((cat) {
                              final catId = cat['id'] as int;
                              final isSel = selectedCatIds.contains(catId);
                              return FilterChip(
                                label: Text(cat['name']?.toString() ?? ''),
                                selected: isSel,
                                selectedColor: const Color(0xFF00F5A0).withValues(alpha: 0.25),
                                backgroundColor: const Color(0xFF161B36),
                                labelStyle: TextStyle(
                                  color: isSel ? const Color(0xFF00F5A0) : Colors.white70,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: isSel ? const Color(0xFF00F5A0) : Colors.white.withValues(alpha: 0.08),
                                ),
                                onSelected: (sel) {
                                  setModalState(() {
                                    if (sel) {
                                      selectedCatIds.add(catId);
                                    } else {
                                      selectedCatIds.remove(catId);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              if (emailCtrl.text.trim().isEmpty || fNameCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter First Name and Email.'),
                                    backgroundColor: Color(0xFFFF4B72),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(modalCtx);
                              _createClient(
                                firstName: fNameCtrl.text.trim(),
                                lastName: lNameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                password: passwordCtrl.text.trim().isNotEmpty ? passwordCtrl.text.trim() : 'Client@123456',
                                phone: phoneCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                                categoryIds: selectedCatIds.toList(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F5A0),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Enroll Member',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl,
      {IconData? icon, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 16, color: Colors.white38) : null,
            filled: true,
            fillColor: const Color(0xFF161B36),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00F5A0), width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  void _showAssignTrainerDialog(int clientId, String? clientName, List<dynamic> activeTrainers) {
    final selectedTrainerIds = activeTrainers
        .map((t) => t is Map ? t['id'] : null)
        .whereType<int>()
        .toSet();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161B36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            title: Text(
              'Assign Coaches for ${clientName ?? 'Client'}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchFreshTrainers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF00F5A0)),
                      ),
                    );
                  }

                  final trainers = snapshot.data ?? [];

                  if (trainers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No active trainers available', style: TextStyle(color: Colors.white60)),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Select coaches to link. Uncheck to unlink.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11.5),
                        ),
                      ),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: trainers.length,
                          itemBuilder: (ctx, index) {
                            final trainer = trainers[index];
                            final id = trainer['id'] ?? trainer['trainer_id'];
                            final isChecked = id is int && selectedTrainerIds.contains(id);
                            final name = trainer['name'] ?? trainer['user_full_name'] ?? 'Coach';
                            final spec = trainer['specialization'] ?? 'Fitness Coach';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? const Color(0xFF00F5A0).withValues(alpha: 0.12)
                                    : const Color(0xFF131830),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isChecked
                                      ? const Color(0xFF00F5A0)
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: CheckboxListTile(
                                value: isChecked,
                                activeColor: const Color(0xFF00F5A0),
                                checkColor: Colors.black,
                                dense: true,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    color: isChecked ? const Color(0xFF00F5A0) : Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  spec,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                                ),
                                onChanged: (bool? val) {
                                  if (id is int) {
                                    setDialogState(() {
                                      if (val == true) {
                                        selectedTrainerIds.add(id);
                                      } else {
                                        selectedTrainerIds.remove(id);
                                      }
                                    });
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                onPressed: () {
                  final ids = selectedTrainerIds.toList();
                  Navigator.pop(dialogCtx);
                  _syncTrainersForClient(clientId, ids);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5A0),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Assignments', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(int clientId, String? clientName) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF161B36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Text('Remove Client', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to delete ${clientName ?? 'this client'}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _deleteClient(clientId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B72),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0D1A),
        elevation: 0,
        title: const Text(
          'Client Directory',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF00F5A0), size: 24),
            tooltip: 'Add Client',
            onPressed: _showAddClientModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchClients,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F5A0))),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF4B72), size: 42),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchClients,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                          child: const Text('Retry'),
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
                            color: const Color(0xFF00F5A0).withValues(alpha: 0.25),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search client by name, email, phone...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00F5A0), size: 20),
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

                    // 2. Category Chips Bar
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
                                    color: _selectedCategory == 'All' ? Colors.black : Colors.white60,
                                    fontSize: 11.5,
                                    fontWeight: _selectedCategory == 'All' ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                ),
                                selected: _selectedCategory == 'All',
                                selectedColor: const Color(0xFF00F5A0),
                                backgroundColor: const Color(0xFF161B30),
                                side: BorderSide(
                                  color: _selectedCategory == 'All' ? const Color(0xFF00F5A0) : Colors.white12,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedCategory = 'All');
                                },
                              ),
                            ),
                            ..._categories.map((c) {
                              final catName = c['name']?.toString() ?? '';
                              final isSelected = _selectedCategory == catName;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    catName,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white60,
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF00F5A0),
                                  backgroundColor: const Color(0xFF161B30),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF00F5A0) : Colors.white12,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedCategory = catName);
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                    // 3. Status & Coach Filters + Results Count
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            'Showing ${_filteredClients.length} of ${_clients.length} clients',
                            style: const TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          // Coach filter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B30),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCoachFilter,
                                dropdownColor: const Color(0xFF161B30),
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00F5A0), size: 18),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                isDense: true,
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('Coach: All')),
                                  DropdownMenuItem(value: 'With Coach', child: Text('With Coach')),
                                  DropdownMenuItem(value: 'Self-Guided', child: Text('Self-Guided')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedCoachFilter = val);
                                },
                              ),
                            ),
                          ),
                          // Status filter
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
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00F5A0), size: 18),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                isDense: true,
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('Status: All')),
                                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
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

                    // 4. List View
                    Expanded(
                      child: _filteredClients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_search_rounded, size: 54, color: Colors.white24),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedStatus != 'All' || _selectedCoachFilter != 'All'
                                        ? 'No clients match your search/filters'
                                        : 'No clients found in the platform.',
                                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                                  ),
                                  if (_searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedStatus != 'All' || _selectedCoachFilter != 'All') ...[
                                    const SizedBox(height: 10),
                                    TextButton.icon(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _selectedCategory = 'All';
                                          _selectedStatus = 'All';
                                          _selectedCoachFilter = 'All';
                                        });
                                      },
                                      icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFF00F5A0)),
                                      label: const Text('Reset Filters', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 12)),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              color: const Color(0xFF00F5A0),
                              backgroundColor: const Color(0xFF161B36),
                              onRefresh: _fetchClients,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                                itemCount: _filteredClients.length,
                                itemBuilder: (context, index) {
                                  final client = _filteredClients[index];
                                  return _buildClientCard(context, client);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildClientCard(BuildContext context, Map<String, dynamic> client) {
    final name = client['user_full_name']?.toString() ?? 'Client';
    final email = client['user_email']?.toString() ?? 'No email';
    final phone = client['phone']?.toString() ?? '';
    final address = client['address']?.toString() ?? '';
    final initials = _getInitials(name);
    final categories = client['category_names'] as List? ?? [];
    final activeTrainers = client['active_trainers'] is List ? (client['active_trainers'] as List) : [];
    final clientId = client['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131830),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name/Email + Active Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00F5A0), Color(0xFF38BDF8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5A0).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00F5A0).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Color(0xFF00F5A0),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            // Meta tags (Phone, Address)
            if (phone.isNotEmpty || address.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (phone.isNotEmpty)
                    _buildMetaChip(Icons.phone_outlined, phone),
                  if (address.isNotEmpty)
                    _buildMetaChip(Icons.location_on_outlined, address),
                ],
              ),
            ],

            // Categories & Assigned Coaches Chips
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...categories.map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '🎯 $c',
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )),
                if (activeTrainers.isNotEmpty)
                  ...activeTrainers.map((tr) {
                    String trName = 'Coach';
                    if (tr is Map) {
                      trName = tr['name']?.toString() ?? 'Coach';
                    } else if (tr is String) {
                      trName = tr;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9F43).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF9F43).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '🏋️ Coach: $trName',
                        style: const TextStyle(
                          color: Color(0xFFFF9F43),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  })
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⚠️ No Coach Assigned',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),

            // Bottom Actions Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildCardActionButton(
                  label: activeTrainers.isNotEmpty ? 'Manage Coaches' : 'Assign Coach',
                  icon: Icons.person_add_rounded,
                  color: const Color(0xFFFF9F43),
                  onTap: () {
                    if (clientId is int) {
                      _showAssignTrainerDialog(clientId, name, activeTrainers);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildCardActionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFFF4B72),
                  onTap: () {
                    if (clientId is int) {
                      _showDeleteDialog(clientId, name);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white38),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCardActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}