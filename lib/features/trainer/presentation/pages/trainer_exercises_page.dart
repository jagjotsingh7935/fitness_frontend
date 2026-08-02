import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';

class TrainerExercisesPage extends StatefulWidget {
  const TrainerExercisesPage({super.key});

  @override
  State<TrainerExercisesPage> createState() => _TrainerExercisesPageState();
}

class _TrainerExercisesPageState extends State<TrainerExercisesPage> {
  final Dio _dio = GetIt.I<DioClient>().dio;
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _dio.get('/fitness/api/exercises/');
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> results = [];
        if (data is Map && data.containsKey('results')) {
          results = data['results'];
        } else if (data is List) {
          results = data;
        }

        setState(() {
          _exercises = results.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load exercises. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = _exercises.where((ex) {
      final title = (ex['title'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Exercise Library', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFE94560)),
            onPressed: _fetchExercises,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
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
                    : filteredExercises.isEmpty
                        ? const Center(child: Text('No exercises found', style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = filteredExercises[index];
                              return _buildExerciseCard(exercise);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final categories = exercise['category_names'] as List? ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
          child: exercise['thumbnail_url'] != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(exercise['thumbnail_url'], fit: BoxFit.cover),
                )
              : const Icon(Icons.fitness_center, color: Color(0xFFE94560)),
        ),
        title: Text(
          exercise['title'] ?? 'Unknown Exercise',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Duration: ${exercise['duration_seconds'] ?? 0}s',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: categories.map((cat) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cat.toString(),
                  style: const TextStyle(color: Color(0xFFE94560), fontSize: 10),
                ),
              )).toList(),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () {
          _showExerciseDetails(exercise);
        },
      ),
    );
  }

  void _showExerciseDetails(Map<String, dynamic> exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise['title'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              exercise['description'] ?? 'No description available.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}