import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';

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

    // Simulating network delay for progress dummy data
    await Future.delayed(const Duration(milliseconds: 800));

    final dummyProgressData = [
      {
        'id': 101,
        'name': 'Alex Johnson',
        'email': 'alex.j@example.com',
        'target': 'Weight Loss',
        'workouts_done': 12,
        'total_workouts': 15,
      },
      {
        'id': 102,
        'name': 'Sarah Miller',
        'email': 'sarah.m@test.com',
        'target': 'Muscle Gain',
        'workouts_done': 4,
        'total_workouts': 15,
      },
      {
        'id': 103,
        'name': 'Michael Chen',
        'email': 'm.chen@fitness.org',
        'target': 'Endurance',
        'workouts_done': 15,
        'total_workouts': 15,
      },
      {
        'id': 104,
        'name': 'Emma Wilson',
        'email': 'emma.w@mail.com',
        'target': 'Flexibility',
        'workouts_done': 8,
        'total_workouts': 15,
      },
    ];

    setState(() {
      _clients = dummyProgressData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          'Client Progress',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF111111),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchClients,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94560),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _clients.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No clients assigned yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _clients.length,
                      itemBuilder: (context, index) {
                        final client = _clients[index];
                        return _buildProgressCard(client);
                      },
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFE94560).withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE94560).withOpacity(0.12),
                  radius: 24,
                  child: Text(
                    client['name'].toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client['name'] ?? 'Unknown Client',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      Text(
                        client['email'] ?? '',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Plan Completion', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('${(completion * 100).toInt()}%',
                    style: const TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: completion,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: const Color(0xFFE94560),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Workouts', '$workoutsDone/$totalWorkouts', Icons.fitness_center),
                _buildStatItem(
                  'Status',
                  completion >= 1.0 ? 'Done' : (isActive ? 'Active' : 'Pending'),
                  Icons.bolt,
                ),
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
        Icon(icon, size: 18, color: Colors.white38),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}