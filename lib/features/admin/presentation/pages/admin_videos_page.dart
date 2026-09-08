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
      'title': 'Beginner Full Body Workout Guide',
      'category': 'Weight Loss',
      'duration': '15:30',
      'thumbnail': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400',
      'url': 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      'views': '1.2k',
    },
    {
      'id': '2',
      'title': 'Essential Nutrition & Metabolism Basics',
      'category': 'Weight Loss',
      'duration': '12:45',
      'thumbnail': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400',
      'url': 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      'views': '850',
    },
    {
      'id': '3',
      'title': 'Hypertrophy & Strength Lifting Masterclass',
      'category': 'Muscle Building',
      'duration': '20:00',
      'thumbnail': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
      'url': 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      'views': '2.4k',
    },
    {
      'id': '4',
      'title': 'High-Intensity Interval Sprint Protocols',
      'category': 'Endurance',
      'duration': '18:15',
      'thumbnail': 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=400',
      'url': 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      'views': '980',
    },
    {
      'id': '5',
      'title': 'Dynamic Joint Mobility & Recovery Yoga',
      'category': 'Flexibility',
      'duration': '25:00',
      'thumbnail': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
      'url': 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      'views': '1.5k',
    },
  ];

  final _categories = ['All', 'Weight Loss', 'Muscle Building', 'Endurance', 'Flexibility'];
  String _selectedFilter = 'All';

  void _showAddVideoModal() {
    final titleCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    String selCat = 'Weight Loss';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
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
                        'Upload Master Exercise Video',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
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
                        _buildInputField('Video Title', titleCtrl, icon: Icons.title_rounded),
                        const SizedBox(height: 14),
                        _buildInputField('Duration (e.g. 15:30)', durationCtrl, icon: Icons.timer_outlined),
                        const SizedBox(height: 14),
                        const Text(
                          'Category',
                          style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Weight Loss', 'Muscle Building', 'Endurance', 'Flexibility'].map((cat) {
                            final isSel = selCat == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSel,
                              selectedColor: const Color(0xFF00F5A0),
                              backgroundColor: const Color(0xFF161B36),
                              labelStyle: TextStyle(
                                color: isSel ? Colors.black : Colors.white70,
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                                fontSize: 12,
                              ),
                              onSelected: (s) => setModalState(() => selCat = cat),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              if (titleCtrl.text.trim().isEmpty) return;
                              setState(() {
                                _videos.insert(0, {
                                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                                  'title': titleCtrl.text.trim(),
                                  'category': selCat,
                                  'duration': durationCtrl.text.trim().isNotEmpty ? durationCtrl.text.trim() : '10:00',
                                  'thumbnail': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400',
                                  'url': '',
                                  'views': 'New',
                                });
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Video uploaded successfully!'),
                                  backgroundColor: Color(0xFF00F5A0),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F5A0),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Publish Video', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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

  Widget _buildInputField(String label, TextEditingController ctrl, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 16, color: Colors.white38) : null,
            filled: true,
            fillColor: const Color(0xFF161B36),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00F5A0), width: 1.2)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredVideos = _selectedFilter == 'All'
        ? _videos
        : _videos.where((v) => v['category'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0D1A),
        elevation: 0,
        title: const Text(
          'Video Media Library',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF00F5A0), size: 26),
            onPressed: _showAddVideoModal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            height: 46,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSel = _selectedFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSel,
                    selectedColor: const Color(0xFF00F5A0),
                    backgroundColor: const Color(0xFF131830),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.black : Colors.white70,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSel ? const Color(0xFF00F5A0) : Colors.white.withValues(alpha: 0.08),
                    ),
                    onSelected: (_) => setState(() => _selectedFilter = cat),
                  ),
                );
              },
            ),
          ),

          // Video Grid (100% Overflow-Safe)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.70, // Gives plenty of vertical height to eliminate overflow
              ),
              itemCount: filteredVideos.length,
              itemBuilder: (context, index) {
                final video = filteredVideos[index];
                return _buildVideoCard(video);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131830),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with Play overlay & Duration badge
          Stack(
            children: [
              Container(
                height: 95,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E2640), Color(0xFF0F1326)],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    size: 38,
                    color: Color(0xFF00F5A0),
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    video['duration'] ?? '10:00',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),

          // Content Box
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    video['title'] ?? 'Exercise Video',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      video['category'] ?? 'Category',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${video['views'] ?? ''} views',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 10,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFFF4B72)),
                        onPressed: () {
                          setState(() => _videos.remove(video));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}