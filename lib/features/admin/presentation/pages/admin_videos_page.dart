import 'package:flutter/material.dart';

class AdminVideosPage extends StatefulWidget {
  const AdminVideosPage({super.key});

  @override
  State<AdminVideosPage> createState() => _AdminVideosPageState();
}

class _AdminVideosPageState extends State<AdminVideosPage> {
  final List<Map<String, dynamic>> _videos = [
    {
      'id': '1',
      'title': 'Beginner Workout Guide',
      'category': 'Weight Loss',
      'duration': '15:30',
      'thumbnail': 'https://via.placeholder.com/300x200/blue/white?text=Workout+1',
      'url': 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      'createdAt': '2024-01-15',
    },
    {
      'id': '2',
      'title': 'Nutrition Basics',
      'category': 'Diabetes',
      'duration': '12:45',
      'thumbnail': 'https://via.placeholder.com/300x200/green/white?text=Nutrition',
      'url': 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      'createdAt': '2024-01-20',
    },
    {
      'id': '3',
      'title': 'Advanced Cardio',
      'category': 'Muscle Building',
      'duration': '20:00',
      'thumbnail': 'https://via.placeholder.com/300x200/purple/white?text=Cardio',
      'url': 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      'createdAt': '2024-02-01',
    },
  ];

  final _categories = ['Weight Loss', 'Weight Gain', 'Diabetes', 'Muscle Building', 'Endurance', 'Flexibility'];
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Videos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddVideoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedFilter == 'All',
                    onSelected: (selected) {
                      setState(() => _selectedFilter = 'All');
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._categories.map((category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: _selectedFilter == category,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = selected ? category : 'All');
                      },
                    ),
                  )),
                ],
              ),
            ),
          ),
          
          // Video grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                if (_selectedFilter != 'All' && video['category'] != _selectedFilter) {
                  return const SizedBox.shrink();
                }
                return _buildVideoCard(video);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Stack(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  image: DecorationImage(
                    image: NetworkImage(video['thumbnail']),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    color: Colors.black.withAlpha(77),
                  ),
                  child: const Center(
                    child: Icon(Icons.play_circle, size: 48, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(179),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video['duration'],
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          
          // Video info
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video['category'],
                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow, size: 20, color: Colors.green),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Playing: ${video['title']}')),
                        );
                      },
                      tooltip: 'Preview',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                      onPressed: () => _showEditVideoDialog(context, video),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _showDeleteDialog(context, video['title']),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVideoDialog(BuildContext context) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    String selectedCategory = _categories[0];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Video'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Video Title'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) => selectedCategory = value!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Video URL',
                  hintText: 'https://example.com/video.mp4',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Supported: YouTube, Vimeo, or direct MP4 links',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video added successfully (Demo)')),
              );
            },
            child: const Text('Add Video'),
          ),
        ],
      ),
    );
  }

  void _showEditVideoDialog(BuildContext context, Map<String, dynamic> video) {
    final titleController = TextEditingController(text: video['title']);
    String selectedCategory = video['category'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Video Title'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) => selectedCategory = value!,
            ),
          ],
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
                const SnackBar(content: Text('Video updated successfully (Demo)')),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title deleted (Demo)')),
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