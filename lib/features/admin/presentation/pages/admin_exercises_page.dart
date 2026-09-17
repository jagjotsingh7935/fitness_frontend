import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/widgets/app_video_player_modal.dart';

class AdminExercisesPage extends StatefulWidget {
  const AdminExercisesPage({super.key});

  @override
  State<AdminExercisesPage> createState() => _AdminExercisesPageState();
}

class _AdminExercisesPageState extends State<AdminExercisesPage> {
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;
  String? _errorMessage;

  final Dio _dio = GetIt.I<DioClient>().dio;

  // Search and Filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All'; // 'All', 'Active', 'Inactive'
  List<String> _availableCategories = ['All'];

  // Controllers for add/edit exercise dialog
  final _titleController = TextEditingController();
  final _categoryNamesController = TextEditingController();
  final _durationSecondsController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();
  int? _editingExerciseId;

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _categoryNamesController.dispose();
    _durationSecondsController.dispose();
    _videoUrlController.dispose();
    _thumbnailUrlController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredExercises {
    return _exercises.where((exercise) {
      final title = (exercise['title'] ?? '').toString().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || title.contains(_searchQuery.toLowerCase());

      final cats = (exercise['category_names'] as List?)?.map((c) => c.toString()).toList() ?? [];
      final matchesCategory = _selectedCategory == 'All' || cats.contains(_selectedCategory);

      final isActive = exercise['is_active'] == true;
      final matchesStatus = _selectedStatus == 'All' ||
          (_selectedStatus == 'Active' && isActive) ||
          (_selectedStatus == 'Inactive' && !isActive);

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  // Fetch all exercises
  Future<void> _fetchExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔵 Fetching exercises from: /fitness/api/exercises/');
      final response = await _dio.get('/fitness/api/exercises/');

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> exercisesData = [];

        if (responseData is Map && responseData.containsKey('results')) {
          exercisesData = responseData['results'];
        } else if (responseData is List) {
          exercisesData = responseData;
        }

        print('✅ Exercises fetched: ${exercisesData.length} exercises');

        final list = exercisesData.map((exercise) {
          return {
            'id': exercise['id'],
            'title': exercise['title'] ?? 'Unknown',
            'thumbnail_url': exercise['thumbnail_url'] ?? '',
            'duration_seconds': exercise['duration_seconds'] ?? 0,
            'category_names': exercise['category_names'] ?? [],
            'video_url': exercise['video_url'] ?? '',
            'is_active': exercise['is_active'] ?? true,
          };
        }).toList();

        final Set<String> allCats = {'All'};
        for (final ex in list) {
          for (final c in (ex['category_names'] as List? ?? [])) {
            if (c.toString().trim().isNotEmpty) {
              allCats.add(c.toString().trim());
            }
          }
        }

        setState(() {
          _exercises = list;
          _availableCategories = allCats.toList();
          _isLoading = false;
        });
      } else {
        print('❌ Error: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to load exercises: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status code: ${e.response?.statusCode}');
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

  // Create new exercise
  Future<void> _createExercise(BuildContext context) async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise title is required')),
      );
      return;
    }

    try {
      // Parse category names from comma-separated string
      final categoryNames = _categoryNamesController.text.trim().isEmpty
          ? []
          : _categoryNamesController.text.split(',').map((e) => e.trim()).toList();

      final requestBody = {
        'title': _titleController.text.trim(),
        'category_names': categoryNames,
        'duration_seconds': int.tryParse(_durationSecondsController.text.trim()) ?? 0,
        'video_url': _videoUrlController.text.trim(),
        'thumbnail_url': _thumbnailUrlController.text.trim(),
      };

      print('📤 Creating exercise at: /fitness/api/exercises/create/');
      print('📤 Request body: $requestBody');

      final response = await _dio.post('/fitness/api/exercises/create/', data: requestBody);

      if (response.statusCode == 201) {
        _clearForm();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exercise created successfully')),
          );
          _fetchExercises();
        }
      } else {
        throw Exception('Failed to create exercise');
      }
    } on DioException catch (e) {
      String errorMsg = 'Error creating exercise';
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

  // Update existing exercise
  Future<void> _updateExercise(BuildContext context) async {
    if (_editingExerciseId == null) return;

    try {
      final categoryNames = _categoryNamesController.text.trim().isEmpty
          ? []
          : _categoryNamesController.text.split(',').map((e) => e.trim()).toList();

      final requestBody = {
        'title': _titleController.text.trim(),
        'category_names': categoryNames,
        'duration_seconds': int.tryParse(_durationSecondsController.text.trim()) ?? 0,
        'video_url': _videoUrlController.text.trim(),
        'thumbnail_url': _thumbnailUrlController.text.trim(),
      };

      print('📤 Updating exercise at: /fitness/api/exercises/${_editingExerciseId}/update/');
      print('📤 Request body: $requestBody');

      final response = await _dio.put(
        '/fitness/api/exercises/${_editingExerciseId}/update/',
        data: requestBody,
      );

      if (response.statusCode == 200) {
        _clearForm();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exercise updated successfully')),
          );
          _fetchExercises();
        }
      } else {
        throw Exception('Failed to update exercise');
      }
    } on DioException catch (e) {
      String errorMsg = 'Error updating exercise';
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

  // Delete exercise
  Future<void> _deleteExercise(BuildContext context, int exerciseId, String title) async {
    try {
      print('🗑️ Deleting exercise at: /fitness/api/exercises/$exerciseId/delete/');
      
      final response = await _dio.delete('/fitness/api/exercises/$exerciseId/delete/');

      if (response.statusCode == 204 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"$title" deleted successfully')),
          );
          _fetchExercises();
        }
      } else {
        throw Exception('Failed to delete exercise');
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
          SnackBar(content: Text('Error deleting exercise: $e')),
        );
      }
    }
  }

  // Toggle exercise active status
  Future<void> _toggleExerciseStatus(int exerciseId, bool isActive) async {
    try {
      final response = await _dio.patch(
        '/fitness/api/exercises/$exerciseId/update/',
        data: {'is_active': !isActive},
      );

      if (response.statusCode == 200) {
        _fetchExercises();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exercise ${!isActive ? "activated" : "deactivated"}')),
          );
        }
      }
    } catch (e) {
      print('Error toggling exercise status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update exercise status')),
        );
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _categoryNamesController.clear();
    _durationSecondsController.clear();
    _videoUrlController.clear();
    _thumbnailUrlController.clear();
    _editingExerciseId = null;
  }

  void _showAddExerciseDialog(BuildContext context) {
    _clearForm();
    _showExerciseDialog(context, isEdit: false);
  }

  void _showEditExerciseDialog(BuildContext context, Map<String, dynamic> exercise) {
    _clearForm();
    _editingExerciseId = exercise['id'];
    _titleController.text = exercise['title'] ?? '';
    _categoryNamesController.text = (exercise['category_names'] as List?)?.join(', ') ?? '';
    _durationSecondsController.text = exercise['duration_seconds'].toString();
    _videoUrlController.text = exercise['video_url'] ?? '';
    _thumbnailUrlController.text = exercise['thumbnail_url'] ?? '';
    _showExerciseDialog(context, isEdit: true);
  }

  void _showExerciseDialog(BuildContext context, {required bool isEdit}) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161B30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              isEdit ? 'Edit Exercise' : 'Add New Exercise',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Exercise Title *',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF0D1022),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF252D5A))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF252D5A))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _categoryNamesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Categories (comma-separated)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Muscle Building, Weight Loss, Cardio',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF0D1022),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF252D5A))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF252D5A))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _durationSecondsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Duration (seconds)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: '30',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF0D1022),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF252D5A))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF252D5A))),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _videoUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Video URL',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'https://example.com/video.mp4',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF0D1022),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF252D5A))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF252D5A))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _thumbnailUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Thumbnail URL',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'https://example.com/thumbnail.jpg',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF0D1022),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF252D5A))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF252D5A))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                onPressed: isEdit
                    ? () => _updateExercise(context)
                    : () => _createExercise(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEdit ? 'Save Changes' : 'Add Exercise'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int exerciseId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Exercise', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$title"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExercise(context, exerciseId, title);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
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
        title: const Text(
          'Manage Exercises',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0D1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFE94560)),
            onPressed: _fetchExercises,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFE94560)),
            onPressed: () => _showAddExerciseDialog(context),
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
                        onPressed: _fetchExercises,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94560),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 1. Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF131830),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF252D5A),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search exercises by title...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF818CF8), size: 20),
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

                    // 2. Category Filter Chips
                    if (_availableCategories.length > 1)
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _availableCategories.length,
                          itemBuilder: (context, index) {
                            final cat = _availableCategories[index];
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white60,
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFFE94560),
                                backgroundColor: const Color(0xFF131830),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFFE94560) : const Color(0xFF252D5A),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedCategory = cat);
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
                            'Showing ${_filteredExercises.length} of ${_exercises.length} exercises',
                            style: const TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          // Status dropdown / filter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131830),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF252D5A)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                dropdownColor: const Color(0xFF161B30),
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF818CF8), size: 18),
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

                    // 4. Exercise List View
                    Expanded(
                      child: _filteredExercises.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_off_rounded, size: 54, color: Colors.white24),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedStatus != 'All'
                                        ? 'No exercises match your search/filters'
                                        : 'No exercises found',
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
                                      icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFF00F5A0)),
                                      label: const Text('Reset Filters', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 12)),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                              itemCount: _filteredExercises.length,
                              itemBuilder: (context, index) {
                                final exercise = _filteredExercises[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: const Color(0xFF131830),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: Color(0xFF252D5A),
                              width: 1.2,
                            ),
                          ),
                          child: ExpansionTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: exercise['thumbnail_url'] != null && exercise['thumbnail_url'].toString().isNotEmpty
                                  ? Image.network(
                                      exercise['thumbnail_url'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
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
                                        );
                                      },
                                    )
                                  : Container(
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
                            ),
                            title: Text(
                              exercise['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (exercise['duration_seconds'] > 0)
                                  Text(
                                    'Duration: ${exercise['duration_seconds']} sec',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                if (exercise['category_names'].isNotEmpty)
                                  Text(
                                    'Categories: ${(exercise['category_names'] as List).join(', ')}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    exercise['is_active'] == true
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: exercise['is_active'] == true
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  onPressed: () => _toggleExerciseStatus(
                                    exercise['id'],
                                    exercise['is_active'] == true,
                                  ),
                                  tooltip: exercise['is_active'] == true
                                      ? 'Deactivate'
                                      : 'Activate',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditExerciseDialog(context, exercise),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showDeleteDialog(
                                    context,
                                    exercise['id'],
                                    exercise['title'],
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
                                    if (exercise['video_url'] != null && exercise['video_url'].toString().isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Video',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          InkWell(
                                            onTap: () {
                                              showAppVideoPlayerModal(
                                                context,
                                                title: exercise['title'] ?? 'Exercise Video',
                                                videoUrl: exercise['video_url'] ?? '',
                                                category: (exercise['category_names'] as List?)?.join(', '),
                                              );
                                            },
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.play_circle,
                                                  size: 24,
                                                  color: Color(0xFFE94560),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    exercise['video_url'],
                                                    style: const TextStyle(
                                                      color: Color(0xFFE94560),
                                                      fontSize: 12,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      ),
                                    if (exercise['category_names'].isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Categories',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: (exercise['category_names'] as List).map((category) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE94560).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  category,
                                                  style: const TextStyle(
                                                    color: Color(0xFFE94560),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
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
              ),
    );
  }
}