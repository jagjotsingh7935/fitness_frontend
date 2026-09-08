import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';

class AdminTrainersPage extends StatefulWidget {
  const AdminTrainersPage({super.key});

  @override
  State<AdminTrainersPage> createState() => _AdminTrainersPageState();
}

class _AdminTrainersPageState extends State<AdminTrainersPage> {
  List<Map<String, dynamic>> _trainers = [];
  bool _isLoading = true;
  String? _errorMessage;

  final Dio _dio = GetIt.I<DioClient>().dio;
  List<Map<String, dynamic>> _categories = [];

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All'; // 'All', 'Active', 'Inactive'

  @override
  void initState() {
    super.initState();
    _fetchTrainers();
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTrainers {
    return _trainers.where((trainer) {
      final name = (trainer['user_full_name'] ?? '').toString().toLowerCase();
      final email = (trainer['user_email'] ?? '').toString().toLowerCase();
      final spec = (trainer['specialization'] ?? '').toString().toLowerCase();
      final phone = (trainer['phone'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          email.contains(query) ||
          spec.contains(query) ||
          phone.contains(query);

      final cats = (trainer['category_names'] as List?)?.map((c) => c.toString()).toList() ?? [];
      final matchesCategory = _selectedCategory == 'All' || cats.contains(_selectedCategory) || spec.toLowerCase().contains(_selectedCategory.toLowerCase());

      final isActive = trainer['is_active'] == true;
      final matchesStatus = _selectedStatus == 'All' ||
          (_selectedStatus == 'Active' && isActive) ||
          (_selectedStatus == 'Inactive' && !isActive);

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  Future<void> _fetchTrainers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _dio.get('/accounts/api/trainer/');
      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> trainersData = [];

        if (responseData is Map && responseData.containsKey('results')) {
          trainersData = responseData['results'];
        } else if (responseData is List) {
          trainersData = responseData;
        }

        if (!mounted) return;

        setState(() {
          _trainers = trainersData.map((trainer) {
            List<int> categoryIds = [];
            List<String> categoryNames = [];

            if (trainer.containsKey('category_ids') && trainer['category_ids'] is List) {
              categoryIds = List<int>.from(trainer['category_ids']);
            } else if (trainer.containsKey('categories') && trainer['categories'] is List) {
              categoryIds = (trainer['categories'] as List).map((c) => c['id'] as int).toList();
              categoryNames = (trainer['categories'] as List).map((c) => c['name'] as String).toList();
            }

            return {
              'id': trainer['trainer_id'] ?? trainer['id'],
              'user_email': trainer['email'] ?? trainer['user_email'] ?? 'N/A',
              'user_full_name': trainer['name'] ?? trainer['user_full_name'] ??
                  '${trainer['first_name'] ?? ''} ${trainer['last_name'] ?? ''}'.trim(),
              'first_name': trainer['first_name'] ?? '',
              'last_name': trainer['last_name'] ?? '',
              'specialization': trainer['specialization'] ?? 'Fitness & Nutrition',
              'bio': trainer['bio'] ?? '',
              'phone': trainer['phone'] ?? '',
              'is_active': trainer['is_active'] ?? true,
              'category_ids': categoryIds,
              'category_names': categoryNames,
              'client_count': trainer['client_count'] ?? 0,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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

  Future<void> _createTrainer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String specialization,
    required String phone,
    required String bio,
    required List<int> categoryIds,
  }) async {
    try {
      final response = await _dio.post(
        '/accounts/api/signup/trainer/',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'specialization': specialization,
          'phone': phone,
          'bio': bio,
          'category_ids': categoryIds,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        _fetchTrainers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ New coach registered successfully!'),
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
          content: Text('Error creating coach: $e'),
          backgroundColor: const Color(0xFFFF4B72),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _updateTrainer(
    int id,
    String fName,
    String lName,
    String spec,
    String phone,
    String bio,
    List<int> catIds,
  ) async {
    try {
      await _dio.patch(
        '/accounts/api/trainer/$id/',
        data: {
          'first_name': fName,
          'last_name': lName,
          'specialization': spec,
          'phone': phone,
          'bio': bio,
          'category_ids': catIds,
        },
      );
      if (!mounted) return;
      _fetchTrainers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Coach details updated successfully!'),
          backgroundColor: Color(0xFF00F5A0),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating: $e'),
          backgroundColor: const Color(0xFFFF4B72),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddTrainerModal() {
    final fNameCtrl = TextEditingController();
    final lNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'Trainer@123456');
    final specCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
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
                        'Enroll New Coach',
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
                        _buildInputField('Specialization (e.g. HIIT, Strength)', specCtrl, icon: Icons.stars_outlined),
                        const SizedBox(height: 14),
                        _buildInputField('Phone Number', phoneCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 14),
                        _buildInputField('Bio / Bio Profile', bioCtrl, icon: Icons.notes_outlined, maxLines: 2),
                        const SizedBox(height: 18),

                        if (_categories.isNotEmpty) ...[
                          const Text(
                            'Assign Fitness Categories',
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
                                selectedColor: const Color(0xFFFF9F43).withValues(alpha: 0.25),
                                backgroundColor: const Color(0xFF161B36),
                                labelStyle: TextStyle(
                                  color: isSel ? const Color(0xFFFF9F43) : Colors.white70,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: isSel ? const Color(0xFFFF9F43) : Colors.white.withValues(alpha: 0.08),
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
                                    content: Text('Please fill First Name and Email.'),
                                    backgroundColor: Color(0xFFFF4B72),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(modalCtx);
                              _createTrainer(
                                firstName: fNameCtrl.text.trim(),
                                lastName: lNameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                password: passwordCtrl.text.trim().isNotEmpty ? passwordCtrl.text.trim() : 'Trainer@123456',
                                specialization: specCtrl.text.trim().isNotEmpty ? specCtrl.text.trim() : 'Fitness Coach',
                                phone: phoneCtrl.text.trim(),
                                bio: bioCtrl.text.trim(),
                                categoryIds: selectedCatIds.toList(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9F43),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Register Coach',
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

  void _showEditTrainerModal(Map<String, dynamic> trainer) {
    final id = trainer['id'];
    final nameParts = (trainer['user_full_name']?.toString() ?? '').split(' ');
    final fName = nameParts.isNotEmpty ? nameParts.first : '';
    final lName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final fNameCtrl = TextEditingController(text: trainer['first_name']?.toString().isNotEmpty == true ? trainer['first_name'] : fName);
    final lNameCtrl = TextEditingController(text: trainer['last_name']?.toString().isNotEmpty == true ? trainer['last_name'] : lName);
    final specCtrl = TextEditingController(text: trainer['specialization']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: trainer['phone']?.toString() ?? '');
    final bioCtrl = TextEditingController(text: trainer['bio']?.toString() ?? '');

    final selectedCatIds = Set<int>.from(trainer['category_ids'] as List? ?? []);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
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
                        'Edit Coach Details',
                        style: TextStyle(
                          fontSize: 16.5,
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
                            Expanded(child: _buildInputField('First Name', fNameCtrl)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField('Last Name', lNameCtrl)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildInputField('Specialization', specCtrl, icon: Icons.stars_outlined),
                        const SizedBox(height: 14),
                        _buildInputField('Phone Number', phoneCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 14),
                        _buildInputField('Bio / Credentials', bioCtrl, icon: Icons.notes_outlined, maxLines: 3),
                        const SizedBox(height: 18),

                        if (_categories.isNotEmpty) ...[
                          const Text(
                            'Assign Fitness Categories',
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
                                selectedColor: const Color(0xFFFF9F43).withValues(alpha: 0.25),
                                backgroundColor: const Color(0xFF161B36),
                                labelStyle: TextStyle(
                                  color: isSel ? const Color(0xFFFF9F43) : Colors.white70,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: isSel ? const Color(0xFFFF9F43) : Colors.white.withValues(alpha: 0.08),
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
                              if (id is int) {
                                Navigator.pop(modalCtx);
                                _updateTrainer(
                                  id,
                                  fNameCtrl.text.trim(),
                                  lNameCtrl.text.trim(),
                                  specCtrl.text.trim(),
                                  phoneCtrl.text.trim(),
                                  bioCtrl.text.trim(),
                                  selectedCatIds.toList(),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9F43),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Save Coach Changes',
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
      {IconData? icon, TextInputType? keyboardType, int maxLines = 1}) {
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
          maxLines: maxLines,
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
              borderSide: const BorderSide(color: Color(0xFFFF9F43), width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteTrainer(int trainerId) async {
    try {
      await _dio.delete('/accounts/api/trainer/$trainerId/');
      if (!mounted) return;
      _fetchTrainers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coach removed successfully'),
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

  void _showDeleteDialog(int trainerId, String? trainerName) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF161B36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Text('Remove Trainer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to delete ${trainerName ?? 'this coach'}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _deleteTrainer(trainerId);
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
          'Coach Roster',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFFF9F43), size: 24),
            tooltip: 'Add Coach',
            onPressed: _showAddTrainerModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchTrainers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9F43))),
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
                          onPressed: _fetchTrainers,
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
                            color: const Color(0xFFFF9F43).withValues(alpha: 0.25),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search coach by name, email, specialization...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF9F43), size: 20),
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
                                selectedColor: const Color(0xFFFF9F43),
                                backgroundColor: const Color(0xFF161B30),
                                side: BorderSide(
                                  color: _selectedCategory == 'All' ? const Color(0xFFFF9F43) : Colors.white12,
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
                                  selectedColor: const Color(0xFFFF9F43),
                                  backgroundColor: const Color(0xFF161B30),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFFFF9F43) : Colors.white12,
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

                    // 3. Status Filters + Results Count
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            'Showing ${_filteredTrainers.length} of ${_trainers.length} coaches',
                            style: const TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
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
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF9F43), size: 18),
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
                      child: _filteredTrainers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_search_rounded, size: 54, color: Colors.white24),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedStatus != 'All'
                                        ? 'No coaches match your search/filters'
                                        : 'No trainers enrolled yet.',
                                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                                  ),
                                  if (_searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedStatus != 'All') ...[
                                    const SizedBox(height: 10),
                                    TextButton.icon(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _selectedCategory = 'All';
                                          _selectedStatus = 'All';
                                        });
                                      },
                                      icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFFFF9F43)),
                                      label: const Text('Reset Filters', style: TextStyle(color: Color(0xFFFF9F43), fontSize: 12)),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              color: const Color(0xFFFF9F43),
                              backgroundColor: const Color(0xFF161B36),
                              onRefresh: _fetchTrainers,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                                itemCount: _filteredTrainers.length,
                                itemBuilder: (context, index) {
                                  final trainer = _filteredTrainers[index];
                                  return _buildTrainerCard(context, trainer);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTrainerCard(BuildContext context, Map<String, dynamic> trainer) {
    final name = trainer['user_full_name']?.toString() ?? 'Coach';
    final email = trainer['user_email']?.toString() ?? 'No email';
    final spec = trainer['specialization']?.toString() ?? 'Fitness & Nutrition';
    final phone = trainer['phone']?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';
    final categories = trainer['category_names'] as List? ?? [];
    final isActive = trainer['is_active'] == true;
    final trainerId = trainer['id'];

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
            // Top Row: Avatar + Name/Spec + Active Tag
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9F43), Color(0xFFFF4B72)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                        spec,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF00F5A0).withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF00F5A0).withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    isActive ? 'CERTIFIED' : 'INACTIVE',
                    style: TextStyle(
                      color: isActive ? const Color(0xFF00F5A0) : Colors.white60,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            // Email & Phone Row
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 12, color: Colors.white38),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.phone_outlined, size: 12, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    phone,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                  ),
                ],
              ],
            ),

            // Categories Chips
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: categories.map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9F43).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF9F43).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '🎯 $c',
                        style: const TextStyle(
                          color: Color(0xFFFF9F43),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )).toList(),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),

            // Bottom Actions Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildCardActionButton(
                  label: 'Edit Coach',
                  icon: Icons.edit_note_rounded,
                  color: const Color(0xFFFF9F43),
                  onTap: () => _showEditTrainerModal(trainer),
                ),
                const SizedBox(width: 8),
                _buildCardActionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFFF4B72),
                  onTap: () {
                    if (trainerId is int) {
                      _showDeleteDialog(trainerId, name);
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