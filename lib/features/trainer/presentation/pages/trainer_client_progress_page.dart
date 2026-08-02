import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';

class TrainerClientProgressPage extends StatefulWidget {
  const TrainerClientProgressPage({super.key});

  @override
  State<TrainerClientProgressPage> createState() => _TrainerClientProgressPageState();
}

class _TrainerClientProgressPageState extends State<TrainerClientProgressPage> {
  final Dio _dio = GetIt.I<DioClient>().dio;
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulating network delay for dummy data
    await Future.delayed(const Duration(milliseconds: 800));

    final dummyData = [
      {
        'client': 101,
        'client_name': 'Alex Johnson',
        'client_email': 'alex.j@example.com',
        'target': 'Weight Loss',
        'workouts_done': 12,
        'total_workouts': 15,
      },
      {
        'client': 102,
        'client_name': 'Sarah Miller',
        'client_email': 'sarah.m@test.com',
        'target': 'Muscle Gain',
        'workouts_done': 4,
        'total_workouts': 15,
      },
      {
        'client': 103,
        'client_name': 'Michael Chen',
        'client_email': 'm.chen@fitness.org',
        'target': 'Endurance',
        'workouts_done': 15,
        'total_workouts': 15,
      },
      {
        'client': 104,
        'client_name': 'Emma Wilson',
        'client_email': 'emma.w@mail.com',
        'target': 'Flexibility',
        'workouts_done': 8,
        'total_workouts': 15,
      },
      {
        'client': 105,
        'client_name': 'David Brown',
        'client_email': 'd.brown@provider.com',
        'target': 'General Fitness',
        'workouts_done': 2,
        'total_workouts': 15,
      },
    ];

    setState(() {
      _clients = dummyData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredClients = _clients.where((client) {
      final name = (client['client_name'] ?? '').toString().toLowerCase();
      final email = (client['client_email'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Client Progress', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFE94560)),
            onPressed: _fetchClients,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for a client...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFE94560)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : filteredClients.isEmpty
                        ? const Center(child: Text('No clients found', style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredClients.length,
                            itemBuilder: (context, index) {
                              final client = filteredClients[index];
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
    final double completion = workoutsDone / totalWorkouts;
    final String target = client['target'] ?? 'General Fitness';
    final bool isActive = completion > 0 && completion < 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE94560).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      (client['client_name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client['client_name'] ?? 'Unknown Client',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        client['client_email'] ?? '',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Plan Completion', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text('${(completion * 100).toInt()}%', style: const TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: completion,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: const Color(0xFFE94560),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Workouts', '$workoutsDone/$totalWorkouts', Icons.fitness_center),
                _buildStatItem('Status', completion >= 1.0 ? 'Finished' : (isActive ? 'Active' : 'Pending'), Icons.bolt),
                _buildStatItem('Target', target, Icons.track_changes),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white38),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}