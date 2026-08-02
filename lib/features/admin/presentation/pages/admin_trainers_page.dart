import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_constants.dart';

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

  // Controllers for add trainer dialog
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specializationController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  List<int> _selectedCategoryIds = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = false;
  String? _categoriesError;

  // Controllers for edit trainer dialog
  int? _editingTrainerId;
  final _editFirstNameController = TextEditingController();
  final _editLastNameController = TextEditingController();
  final _editEmailController = TextEditingController();
  final _editSpecializationController = TextEditingController();
  final _editBioController = TextEditingController();
  final _editPhoneController = TextEditingController();
  List<int> _editSelectedCategoryIds = [];

  @override
  void initState() {
    super.initState();
    _fetchTrainers();
    _fetchCategories();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _specializationController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _editFirstNameController.dispose();
    _editLastNameController.dispose();
    _editEmailController.dispose();
    _editSpecializationController.dispose();
    _editBioController.dispose();
    _editPhoneController.dispose();
    super.dispose();
  }

  // Fetch all trainers
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
        
      // In _fetchTrainers method, update the trainer mapping:
setState(() {
  _trainers = trainersData.map((trainer) {
    // Extract category_ids from the response
    List<int> categoryIds = [];
    
    // Try to get category_ids from different possible locations in response
    if (trainer.containsKey('category_ids')) {
      categoryIds = List<int>.from(trainer['category_ids']);
    } else if (trainer.containsKey('categories')) {
      categoryIds = (trainer['categories'] as List?)?.map((c) => c['id'] as int).toList() ?? [];
    }
    
    return {
      'id': trainer['id'],
      'user_email': trainer['user_email'] ?? trainer['user']?['email'] ?? 'N/A',
      'user_full_name': trainer['user_full_name'] ?? 
          '${trainer['user']?['first_name'] ?? ''} ${trainer['user']?['last_name'] ?? ''}'.trim(),
      'specialization': trainer['specialization'] ?? 'Not specified',
      'bio': trainer['bio'] ?? '',
      'phone': trainer['phone'] ?? '',
      'is_active': trainer['is_active'] ?? true,
      'category_ids': categoryIds,  // Store the IDs
      'category_names': trainer['category_names'] ?? 
          (trainer['categories'] as List?)?.map((c) => c['name']).toList() ?? [],
      'created_at': trainer['created_at'],
    };
  }).toList();
  _isLoading = false;
});
      } else {
        throw Exception('Failed to load trainers: ${response.statusCode}');
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Network error occurred';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Fetch categories
  Future<void> _fetchCategories() async {
    // Don't fetch if already loaded and not empty
    if (_categories.isNotEmpty && !_isLoadingCategories) {
      print('✅ Using cached categories: ${_categories.length} categories');
      return;
    }
    
    setState(() {
      _isLoadingCategories = true;
      _categoriesError = null;
    });
    
    try {
      print('🔵 Fetching categories from API...');
      
      final response = await _dio.get('/accounts/api/categories/');
      
      print('🔵 Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> categoriesData = [];
        
        if (responseData is Map && responseData.containsKey('results')) {
          categoriesData = responseData['results'];
        } else if (responseData is List) {
          categoriesData = responseData;
        }

        print('✅ Categories fetched: ${categoriesData.length} items');
        
        setState(() {
          _categories = categoriesData.map((cat) {
            return {
              'id': cat['id'],
              'name': cat['name'],
              'description': cat['description'] ?? '',
              'is_active': cat['is_active'] ?? true,
            };
          }).toList();
          _isLoadingCategories = false;
        });
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ERROR fetching categories: $e');
      setState(() {
        _isLoadingCategories = false;
        _categoriesError = e.toString();
      });
    }
  }

  // Create new trainer
  Future<void> _createTrainer(BuildContext context) async {
    if (_emailController.text.trim().isEmpty ||
        _firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and First Name are required')),
      );
      return;
    }

    try {
      final requestBody = {
        'email': _emailController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'category_ids': _selectedCategoryIds,
      };

      final response = await _dio.post(
        '/accounts/api/signup/trainer/',
        data: requestBody,
      );

      if (response.statusCode == 201) {
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _specializationController.clear();
        _bioController.clear();
        _phoneController.clear();
        _selectedCategoryIds.clear();
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trainer added successfully')),
          );
          _fetchTrainers();
        }
      } else {
        throw Exception('Failed to create trainer');
      }
    } on DioException catch (e) {
      String errorMsg = 'Error creating trainer';
      if (e.response?.data != null) {
        errorMsg = e.response!.data.toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMsg')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Update existing trainer
  Future<void> _updateTrainer(BuildContext context) async {
    if (_editingTrainerId == null) return;
    
    if (_editEmailController.text.trim().isEmpty ||
        _editFirstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and First Name are required')),
      );
      return;
    }

    try {
      final requestBody = {
        'email': _editEmailController.text.trim(),
        'first_name': _editFirstNameController.text.trim(),
        'last_name': _editLastNameController.text.trim(),
        'specialization': _editSpecializationController.text.trim(),
        'bio': _editBioController.text.trim(),
        'phone': _editPhoneController.text.trim(),
        'category_ids': _editSelectedCategoryIds,
      };

      final response = await _dio.patch(
        '/accounts/api/trainer/${_editingTrainerId}/',
        data: requestBody,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trainer updated successfully')),
          );
          _fetchTrainers();
        }
      } else {
        throw Exception('Failed to update trainer');
      }
    } on DioException catch (e) {
      String errorMsg = 'Error updating trainer';
      if (e.response?.data != null) {
        errorMsg = e.response!.data.toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMsg')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Delete trainer
  Future<void> _deleteTrainer(BuildContext context, int trainerId, String name) async {
    try {
      final response = await _dio.delete('/accounts/api/trainer/$trainerId/');

      if (response.statusCode == 204 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name deleted successfully')),
          );
          _fetchTrainers();
        }
      } else {
        throw Exception('Failed to delete trainer');
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.response?.data ?? e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting trainer: $e')),
        );
      }
    }
  }

  // Toggle trainer active status
  Future<void> _toggleTrainerStatus(int trainerId, bool isActive) async {
    try {
      final response = await _dio.patch(
        '/accounts/api/trainer/$trainerId/',
        data: {'is_active': !isActive},
      );

      if (response.statusCode == 200) {
        _fetchTrainers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Trainer ${!isActive ? "activated" : "deactivated"}')),
          );
        }
      }
    } catch (e) {
      print('Error toggling trainer status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update trainer status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Trainers'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchTrainers();
              _fetchCategories();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTrainerDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        onPressed: _fetchTrainers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _trainers.isEmpty
                  ? const Center(
                      child: Text('No trainers found. Add your first trainer!'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _trainers.length,
                      itemBuilder: (context, index) {
                        final trainer = _trainers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                trainer['user_full_name']
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                              ),
                            ),
                            title: Text(
                              trainer['user_full_name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(trainer['specialization'] ?? 'No specialization'),
                                const SizedBox(height: 4),
                                Text(
                                  trainer['user_email'] ?? 'No email',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    trainer['is_active'] == true
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: trainer['is_active'] == true
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  onPressed: () => _toggleTrainerStatus(
                                    trainer['id'],
                                    trainer['is_active'] == true,
                                  ),
                                  tooltip: trainer['is_active'] == true
                                      ? 'Deactivate'
                                      : 'Activate',
                                ),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _showDeleteDialog(
                                        context,
                                        trainer['id'],
                                        trainer['user_full_name'],
                                      );
                                    } else if (value == 'edit') {
                                      _showEditTrainerDialog(context, trainer);
                                    }
                                  },
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (trainer['bio'] != null &&
                                        trainer['bio'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          'Bio: ${trainer['bio']}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    if (trainer['phone'] != null &&
                                        trainer['phone'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          'Phone: ${trainer['phone']}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    const Divider(),
                                    const Text(
                                      'Categories',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (trainer['category_names'] != null &&
                                        (trainer['category_names'] as List).isNotEmpty)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: (trainer['category_names'] as List)
                                            .map((cat) => Chip(
                                                  label: Text(
                                                    cat.toString(),
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                  backgroundColor:
                                                      Colors.blue.withAlpha(26),
                                                  avatar: const Icon(
                                                    Icons.category,
                                                    size: 16,
                                                  ),
                                                ))
                                            .toList(),
                                      )
                                    else
                                      const Text(
                                        'No categories assigned',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Created: ${trainer['created_at']?.toString().split('T')[0] ?? 'Unknown'}',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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

  void _showAddTrainerDialog(BuildContext context) {
    // Reset form fields
    _selectedCategoryIds.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _specializationController.clear();
    _bioController.clear();
    _phoneController.clear();
    
    // Fetch categories if needed
    _fetchCategories();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Trainer'),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name *'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email *'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _specializationController,
                      decoration: const InputDecoration(labelText: 'Specialization'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text(
                      'Assign Categories',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Categories section
                    _isLoadingCategories
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _categoriesError != null
                            ? Column(
                                children: [
                                  Text(
                                    'Error: $_categoriesError',
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      _fetchCategories().then((_) {
                                        if (mounted) {
                                          setDialogState(() {});
                                        }
                                      });
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              )
                            : _categories.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'No categories available',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : Container(
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _categories.length,
                                      itemBuilder: (context, index) {
                                        final category = _categories[index];
                                        final isSelected = _selectedCategoryIds.contains(category['id']);
                                        return CheckboxListTile(
                                          title: Text(category['name']),
                                          value: isSelected,
                                          onChanged: (selected) {
                                            setDialogState(() {
                                              if (selected == true) {
                                                _selectedCategoryIds.add(category['id']);
                                              } else {
                                                _selectedCategoryIds.remove(category['id']);
                                              }
                                            });
                                          },
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          controlAffinity: ListTileControlAffinity.leading,
                                        );
                                      },
                                    ),
                                  ),
                    if (_selectedCategoryIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Selected: ${_selectedCategoryIds.length} categories',
                          style: const TextStyle(fontSize: 12, color: Colors.green),
                        ),
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
                onPressed: () => _createTrainer(context),
                child: const Text('Add Trainer'),
              ),
            ],
          );
        },
      ),
    );
  }

void _showEditTrainerDialog(BuildContext context, Map<String, dynamic> trainer) {
  // Populate edit controllers with existing trainer data
  final nameParts = trainer['user_full_name']?.split(' ') ?? [];
  _editingTrainerId = trainer['id'];
  _editFirstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
  _editLastNameController.text = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
  _editEmailController.text = trainer['user_email'] ?? '';
  _editSpecializationController.text = trainer['specialization'] ?? '';
  _editBioController.text = trainer['bio'] ?? '';
  _editPhoneController.text = trainer['phone'] ?? '';
  
  // IMPORTANT: Get category_ids from the trainer data
  // The trainer data has 'category_ids' field directly from the API
  _editSelectedCategoryIds = List<int>.from(trainer['category_ids'] ?? []);
  
  print('📝 Editing trainer: ${trainer['user_full_name']}');
  print('📝 Existing category IDs: $_editSelectedCategoryIds');
  print('📝 Existing category names: ${trainer['category_names']}');
  
  // First, ensure categories are loaded
  // If categories are already loaded, use them; otherwise fetch first
  if (_categories.isEmpty && !_isLoadingCategories) {
    // Show loading dialog while fetching categories
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    _fetchCategories().then((_) {
      Navigator.pop(context); // Close loading dialog
      if (mounted) {
        _showEditDialogContent(context);
      }
    });
  } else {
    _showEditDialogContent(context);
  }
}

void _showEditDialogContent(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        // Debug print to verify selected categories
        print('🎯 Dialog opened - Selected category IDs: $_editSelectedCategoryIds');
        
        return AlertDialog(
          title: const Text('Edit Trainer'),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _editFirstNameController,
                    decoration: const InputDecoration(labelText: 'First Name *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _editLastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _editEmailController,
                    decoration: const InputDecoration(labelText: 'Email *'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _editSpecializationController,
                    decoration: const InputDecoration(labelText: 'Specialization'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _editBioController,
                    decoration: const InputDecoration(labelText: 'Bio'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _editPhoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Update Categories',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Categories section
                  _isLoadingCategories
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _categoriesError != null
                          ? Column(
                              children: [
                                Text(
                                  'Error: $_categoriesError',
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    _fetchCategories().then((_) {
                                      if (mounted) {
                                        setDialogState(() {});
                                      }
                                    });
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            )
                          : _categories.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'No categories available',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _categories.length,
                                    itemBuilder: (context, index) {
                                      final category = _categories[index];
                                      // Check if this category ID is in the selected list
                                      final isSelected = _editSelectedCategoryIds.contains(category['id']);
                                      
                                      return CheckboxListTile(
                                        title: Text(category['name']),
                                        value: isSelected,
                                        onChanged: (selected) {
                                          setDialogState(() {
                                            if (selected == true) {
                                              if (!_editSelectedCategoryIds.contains(category['id'])) {
                                                _editSelectedCategoryIds.add(category['id']);
                                              }
                                            } else {
                                              _editSelectedCategoryIds.remove(category['id']);
                                            }
                                            print('🔄 Category ${category['name']} selected: $selected');
                                            print('📋 Updated selected IDs: $_editSelectedCategoryIds');
                                          });
                                        },
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        controlAffinity: ListTileControlAffinity.leading,
                                      );
                                    },
                                  ),
                                ),
                  if (_editSelectedCategoryIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Selected: ${_editSelectedCategoryIds.length} categories',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
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
              onPressed: () => _updateTrainer(context),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    ),
  );
} 
 
  void _showDeleteDialog(BuildContext context, int trainerId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trainer'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTrainer(context, trainerId, name);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}