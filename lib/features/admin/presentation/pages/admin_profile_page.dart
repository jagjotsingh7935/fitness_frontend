import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for profile fields
  final _nameController = TextEditingController(text: 'Admin User');
  final _emailController = TextEditingController(text: 'admin@fitness.com');
  final _phoneController = TextEditingController(text: '+1 234 567 8900');
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isEditing = false;
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 3),
                    ),
                    child: const CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Change photo - Coming Soon')),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Profile Information Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    // Name
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Email is required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    if (_isEditing) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _isEditing = false);
                                _resetProfileFields();
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Change Password Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Change Password',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(_isChangingPassword ? Icons.remove : Icons.add),
                          onPressed: () {
                            setState(() => _isChangingPassword = !_isChangingPassword);
                          },
                        ),
                      ],
                    ),
                    if (_isChangingPassword) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      ElevatedButton(
                        onPressed: _changePassword,
                        child: const Text('Update Password'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Account Information Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings),
                      title: const Text('Role'),
                      subtitle: const Text('Administrator'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Admin', style: TextStyle(color: Colors.blue)),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Member Since'),
                      subtitle: Text(DateTime.now().toString().split(' ')[0]),
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Last Login'),
                      subtitle: Text('${DateTime.now().toString().split(' ')[0]} at ${DateTime.now().toString().split(' ')[1].substring(0, 5)}'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Danger Zone
            Card(
              elevation: 4,
              color: Colors.red.withAlpha(13),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danger Zone',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const Divider(color: Colors.red),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Delete Account'),
                      subtitle: const Text('Permanently delete your admin account and all data'),
                      trailing: OutlinedButton(
                        onPressed: () => _showDeleteAccountDialog(context),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
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

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  void _resetProfileFields() {
    _nameController.text = 'Admin User';
    _emailController.text = 'admin@fitness.com';
    _phoneController.text = '+1 234 567 8900';
  }

  void _changePassword() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password changed successfully')),
    );
    
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    setState(() => _isChangingPassword = false);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: const Text(
          'This action is irreversible. All your data will be permanently deleted. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion - Coming Soon')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}