import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_constants.dart';

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

  // Controllers for add client dialog
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  List<int> _selectedCategoryIds = [];
  int? _selectedTrainerId;

  // Data lists
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _trainers = [];
  bool _isLoadingCategories = false;
  bool _isLoadingTrainers = false;
  String? _categoriesError;
  String? _trainersError;

  // Controllers for edit client dialog
  int? _editingClientId;
  final _editFirstNameController = TextEditingController();
  final _editLastNameController = TextEditingController();
  final _editEmailController = TextEditingController();
  final _editPhoneController = TextEditingController();
  final _editAddressController = TextEditingController();
  DateTime? _editSelectedDateOfBirth;
  List<int> _editSelectedCategoryIds = [];
  int? _editSelectedTrainerId;

  // Controller for assign trainer dialog
  int? _assignClientId;
  int? _assignTrainerId;

  @override
  void initState() {
    super.initState();
    _fetchClients();
    _fetchCategories();
    _fetchTrainers();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _editFirstNameController.dispose();
    _editLastNameController.dispose();
    _editEmailController.dispose();
    _editPhoneController.dispose();
    _editAddressController.dispose();
    super.dispose();
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) {
      return '?';
    }
    return name.trim().substring(0, 1).toUpperCase();
  }

  // Fetch all clients
  // Fetch all clients
Future<void> _fetchClients() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final response = await _dio.get('/accounts/api/client/');
    print('📋 Raw clients response: ${response.data}');
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
          // Extract category IDs and names from the categories list
          List<int> categoryIds = [];
          List<String> categoryNames = [];
          
          if (client['categories'] != null && client['categories'] is List) {
            categoryIds = (client['categories'] as List)
                .map((cat) => cat['id'] as int)
                .toList();
            categoryNames = (client['categories'] as List)
                .map((cat) => cat['name'] as String)
                .toList();
          }
          
          return {
            'id': client['client_id'] ?? client['id'],
            'user_email': client['email'] ?? 'N/A',
            'user_full_name': client['name'] ?? 
                '${client['first_name'] ?? ''} ${client['last_name'] ?? ''}'.trim(),
            'phone': client['phone'] ?? '',
            'address': client['address'] ?? '',
            'date_of_birth': client['date_of_birth'] ?? '',
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
    if (_categories.isNotEmpty && !_isLoadingCategories) {
      return;
    }

    setState(() {
      _isLoadingCategories = true;
      _categoriesError = null;
    });

    try {
      final response = await _dio.get('/accounts/api/categories/');

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> categoriesData = [];

        if (responseData is Map && responseData.containsKey('results')) {
          categoriesData = responseData['results'];
        } else if (responseData is List) {
          categoriesData = responseData;
        }

        setState(() {
          _categories = categoriesData.map((cat) {
            return {
              'id': cat['id'],
              'name': cat['name'],
              'description': cat['description'] ?? '',
            };
          }).toList();
          _isLoadingCategories = false;
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _categoriesError = e.toString();
      });
    }
  }

  // Fetch trainers for assignment
  Future<void> _fetchTrainers() async {
    if (_trainers.isNotEmpty && !_isLoadingTrainers) {
      return;
    }

    setState(() {
      _isLoadingTrainers = true;
      _trainersError = null;
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

        setState(() {
          _trainers = trainersData.map((trainer) {
            return {
              'id': trainer['id'],
              'name': trainer['user_full_name'] ?? 
                  '${trainer['user']?['first_name'] ?? ''} ${trainer['user']?['last_name'] ?? ''}'.trim(),
              'email': trainer['user_email'] ?? trainer['user']?['email'] ?? '',
              'specialization': trainer['specialization'] ?? '',
            };
          }).toList();
          _isLoadingTrainers = false;
        });
      } else {
        throw Exception('Failed to load trainers');
      }
    } catch (e) {
      setState(() {
        _isLoadingTrainers = false;
        _trainersError = e.toString();
      });
    }
  }

  // Create new client
  Future<void> _createClient(BuildContext context) async {
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
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'category_ids': _selectedCategoryIds,
      };

      if (_selectedDateOfBirth != null) {
        requestBody['date_of_birth'] =
            '${_selectedDateOfBirth!.year}-${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}';
      }

      print('📤 Creating client with data: $requestBody');

      final response = await _dio.post(
        '/accounts/api/signup/client/',
        data: requestBody,
      );

      if (response.statusCode == 201) {
        _clearForm();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client added successfully')),
          );
          _fetchClients();
        }
      } else {
        throw Exception('Failed to create client');
      }
    } on DioException catch (e) {
      String errorMsg = 'Error creating client';
      if (e.response?.data != null) {
        errorMsg = e.response!.data.toString();
      }
      print('❌ Create client error: $errorMsg');
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

  // Update existing client
  Future<void> _updateClient(BuildContext context) async {
    if (_editingClientId == null) return;

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
        'phone': _editPhoneController.text.trim(),
        'address': _editAddressController.text.trim(),
        'category_ids': _editSelectedCategoryIds,
      };

      if (_editSelectedDateOfBirth != null) {
        requestBody['date_of_birth'] =
            '${_editSelectedDateOfBirth!.year}-${_editSelectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_editSelectedDateOfBirth!.day.toString().padLeft(2, '0')}';
      }

      final response = await _dio.patch(
        '/accounts/api/client/${_editingClientId}/',
        data: requestBody,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client updated successfully')),
          );
          _fetchClients();
        }
      } else {
        throw Exception('Failed to update client');
      }
    } on DioException catch (e) {
      String errorMsg = 'Error updating client';
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

  // Delete client
  Future<void> _deleteClient(BuildContext context, int clientId, String name) async {
    try {
      final response = await _dio.delete('/accounts/api/client/$clientId/');

      if (response.statusCode == 204 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name deleted successfully')),
          );
          _fetchClients();
        }
      } else {
        throw Exception('Failed to delete client');
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
          SnackBar(content: Text('Error deleting client: $e')),
        );
      }
    }
  }

  // Assign trainer to client
  Future<void> _assignTrainerToClient(BuildContext context, int clientId, int trainerId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requestBody = {'client': clientId, 'trainer': trainerId};

      final response = await _dio.post(
        '/accounts/api/trainer-client-links/',
        data: requestBody,
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trainer assigned successfully')),
          );
          Navigator.pop(context); // Close the assign dialog
          _fetchClients(); // Refresh the list
        }
      } else {
        throw Exception('Failed to assign trainer');
      }
    } on DioException catch (e) {
      String errorMsg = 'Error assigning trainer';
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Show assign trainer dialog
  void _showAssignTrainerDialog(BuildContext context, int clientId, String clientName) {
    _assignClientId = clientId;
    _assignTrainerId = null;

    // Refresh trainers list before showing dialog
    _fetchTrainers();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Assign Trainer to $clientName'),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select a trainer to assign:'),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoadingTrainers
                        ? const Center(child: CircularProgressIndicator())
                        : _trainersError != null
                            ? Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Error: $_trainersError',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => _fetchTrainers(),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : _trainers.isEmpty
                                ? const Center(
                                    child: Text('No trainers available'),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _trainers.length,
                                    itemBuilder: (context, index) {
                                      final trainer = _trainers[index];
                                      final isSelected = _assignTrainerId == trainer['id'];
                                      return RadioListTile<int>(
                                        title: Text(trainer['name']),
                                        subtitle: Text(trainer['specialization'] ?? 'No specialization'),
                                        value: trainer['id'],
                                        groupValue: _assignTrainerId,
                                        onChanged: (value) {
                                          setDialogState(() {
                                            _assignTrainerId = value;
                                          });
                                        },
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _assignTrainerId == null
                    ? null
                    : () => _assignTrainerToClient(context, _assignClientId!, _assignTrainerId!),
                child: const Text('Assign'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _selectedDateOfBirth = null;
    _selectedCategoryIds.clear();
    _selectedTrainerId = null;
  }

  void _showAddClientDialog(BuildContext context) {
    _clearForm();

    if (_categories.isEmpty) _fetchCategories();
    if (_trainers.isEmpty) _fetchTrainers();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Client'),
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
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setDialogState(() {
                            _selectedDateOfBirth = date;
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            hintText: _selectedDateOfBirth != null
                                ? '${_selectedDateOfBirth!.year}-${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}'
                                : 'Tap to select',
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text(
                      'Select Categories',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildCategoriesSelector(setDialogState, forEdit: false),
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
                onPressed: () => _createClient(context),
                child: const Text('Add Client'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditClientDialog(BuildContext context, Map<String, dynamic> client) {
  _editingClientId = client['id'];
  
  // Split the full name if needed, or use the stored values
  _editFirstNameController.text = client['first_name'] ?? '';
  _editLastNameController.text = client['last_name'] ?? '';
  
  // If first_name/last_name not available, try to split the full name
  if (_editFirstNameController.text.isEmpty && client['user_full_name'] != null) {
    final nameParts = client['user_full_name'].toString().split(' ');
    _editFirstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
    _editLastNameController.text = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
  }
  
  _editEmailController.text = client['user_email'] ?? '';
  _editPhoneController.text = client['phone'] ?? '';
  _editAddressController.text = client['address'] ?? '';
  _editSelectedCategoryIds = List<int>.from(client['category_ids'] ?? []);

  if (client['date_of_birth'] != null && client['date_of_birth'].toString().isNotEmpty) {
    final dobParts = client['date_of_birth'].toString().split('-');
    if (dobParts.length == 3) {
      _editSelectedDateOfBirth = DateTime(
        int.parse(dobParts[0]),
        int.parse(dobParts[1]),
        int.parse(dobParts[2]),
      );
    }
  }

  // Fetch fresh client details for edit
  _fetchClientDetails(client['id']);
}

  Future<void> _fetchClientDetails(int clientId) async {
  try {
    final response = await _dio.get('/accounts/api/client/$clientId/');
    
    if (response.statusCode == 200) {
      final clientData = response.data;
      print('📋 Client details for edit: $clientData');
      
      _editFirstNameController.text = clientData['first_name'] ?? clientData['user']?['first_name'] ?? '';
      _editLastNameController.text = clientData['last_name'] ?? clientData['user']?['last_name'] ?? '';
      _editEmailController.text = clientData['email'] ?? clientData['user']?['email'] ?? '';
      _editPhoneController.text = clientData['phone'] ?? '';
      _editAddressController.text = clientData['address'] ?? '';
      
      // Fix: Extract category IDs from the categories list
      if (clientData['categories'] != null && clientData['categories'] is List) {
        _editSelectedCategoryIds = (clientData['categories'] as List)
            .map((cat) => cat['id'] as int)
            .toList();
        print('📋 Extracted category IDs: $_editSelectedCategoryIds');
      } else {
        _editSelectedCategoryIds = [];
      }
      
      if (clientData['date_of_birth'] != null && clientData['date_of_birth'].toString().isNotEmpty) {
        final dobParts = clientData['date_of_birth'].toString().split('-');
        if (dobParts.length == 3) {
          _editSelectedDateOfBirth = DateTime(
            int.parse(dobParts[0]),
            int.parse(dobParts[1]),
            int.parse(dobParts[2]),
          );
        }
      }
      
      if (mounted) {
        setState(() {});
      }
    }
  } catch (e) {
    print('❌ Error fetching client details: $e');
  }
}

  Widget _buildCategoriesSelector(Function(void Function()) setDialogState, {required bool forEdit}) {
    if (_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_categoriesError != null) {
      return Column(
        children: [
          Text(
            'Error: $_categoriesError',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _fetchCategories(),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No categories available', style: TextStyle(color: Colors.grey)),
      );
    }

    final selectedIds = forEdit ? _editSelectedCategoryIds : _selectedCategoryIds;

    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = selectedIds.contains(category['id']);
          return CheckboxListTile(
            title: Text(category['name']),
            value: isSelected,
            onChanged: (selected) {
              setDialogState(() {
                if (selected == true) {
                  if (!selectedIds.contains(category['id'])) {
                    selectedIds.add(category['id']);
                  }
                } else {
                  selectedIds.remove(category['id']);
                }
              });
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Clients'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchClients();
              _fetchCategories();
              _fetchTrainers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddClientDialog(context),
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
                        onPressed: _fetchClients,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _clients.isEmpty
                  ? const Center(
                      child: Text('No clients found. Add your first client!'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _clients.length,
                      itemBuilder: (context, index) {
                        final client = _clients[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(_getInitials(client['user_full_name'])),
                            ),
                            title: Text(
                              client['user_full_name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(client['user_email'] ?? 'No email'),
                                if (client['phone'] != null && client['phone'].toString().isNotEmpty)
                                  Text(
                                    client['phone'],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.person_add, color: Colors.orange),
                                  onPressed: () => _showAssignTrainerDialog(
                                    context,
                                    client['id'],
                                    client['user_full_name'],
                                  ),
                                  tooltip: 'Assign Trainer',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditClientDialog(context, client),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _showDeleteDialog(
                                      context,
                                      client['id'],
                                      client['user_full_name'],
                                    );
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
                                    if (client['address'] != null && client['address'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          'Address: ${client['address']}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    if (client['date_of_birth'] != null && client['date_of_birth'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          'Date of Birth: ${client['date_of_birth']}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    const Divider(),
                                    const Text(
                                      'Categories',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    if (client['category_names'] != null && (client['category_names'] as List).isNotEmpty)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: (client['category_names'] as List).map((cat) => Chip(
                                          label: Text(cat.toString(), style: const TextStyle(fontSize: 12)),
                                          backgroundColor: Colors.green.withAlpha(26),
                                          avatar: const Icon(Icons.category, size: 16),
                                        )).toList(),
                                      )
                                    else
                                      const Text(
                                        'No categories assigned',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    if (client['active_trainers'] != null && (client['active_trainers'] as List).isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Assigned Trainers',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 8),
                                            ...(client['active_trainers'] as List).map((trainer) => Chip(
                                              label: Text(trainer['name'] ?? 'Trainer'),
                                              backgroundColor: Colors.blue.withAlpha(26),
                                              avatar: const Icon(Icons.person, size: 16),
                                            )),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Created: ${client['created_at']?.toString().split('T')[0] ?? 'Unknown'}',
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

  void _showDeleteDialog(BuildContext context, int clientId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteClient(context, clientId, name);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}