import 'package:flutter/material.dart';

class AdminDietPlansPage extends StatelessWidget {
  const AdminDietPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Plans'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create Diet Plan - Coming Soon')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Manage Diet Plans',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Create and assign diet plans to clients'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Create New Diet Plan'),
            ),
          ],
        ),
      ),
    );
  }
}