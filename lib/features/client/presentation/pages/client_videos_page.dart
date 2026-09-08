import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/demo_models.dart';
import '../widgets/client_scaffold.dart';
import '../widgets/section_header.dart';
import '../widgets/video_cards.dart';

class ClientVideosPage extends StatefulWidget {
  const ClientVideosPage({super.key});

  @override
  State<ClientVideosPage> createState() => _ClientVideosPageState();
}

class _ClientVideosPageState extends State<ClientVideosPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Workout Tutorials',
    'Diet & Nutrition',
    'Recovery & Wellness',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VideoModel> _filterList(List<VideoModel> source) {
    if (_searchQuery.isEmpty) return source;
    final q = _searchQuery.toLowerCase();
    return source.where((v) {
      return v.title.toLowerCase().contains(q) ||
          v.meta.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final workouts = _filterList(DemoClientData.videosWorkoutTutorials);
    final nutrition = _filterList(DemoClientData.videosDietNutrition);
    final recovery = _filterList(DemoClientData.videosRecoveryWellness);

    final totalVisible = (_selectedCategory == 'All' || _selectedCategory == 'Workout Tutorials' ? workouts.length : 0) +
        (_selectedCategory == 'All' || _selectedCategory == 'Diet & Nutrition' ? nutrition.length : 0) +
        (_selectedCategory == 'All' || _selectedCategory == 'Recovery & Wellness' ? recovery.length : 0);

    return ClientScaffold(
      greeting: 'From Your Trainer',
      title: 'Videos',
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() {});
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161B30),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE5C07B).withValues(alpha: 0.25),
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search video tutorials, guides, trainers...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE5C07B), size: 20),
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
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
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
                    backgroundColor: const Color(0xFF161B30),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFE94560) : Colors.white12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 3. Match Counter & Reset
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(
                  'Showing $totalVisible video${totalVisible == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_searchQuery.isNotEmpty || _selectedCategory != 'All')
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = 'All';
                      });
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Color(0xFF00F5A0), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          if (_searchQuery.isEmpty && _selectedCategory == 'All') ...[
            _FeaturedVideoCard(),
            const SizedBox(height: 14),
          ],

          if (totalVisible == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    const Icon(Icons.videocam_off_rounded, size: 54, color: Colors.white24),
                    const SizedBox(height: 12),
                    const Text('No videos match your search', style: TextStyle(color: Colors.white70, fontSize: 15)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _selectedCategory = 'All';
                        });
                      },
                      child: const Text('Clear Filters', style: TextStyle(color: Color(0xFF00F5A0))),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if ((_selectedCategory == 'All' || _selectedCategory == 'Workout Tutorials') && workouts.isNotEmpty) ...[
              const SectionHeader(title: 'Workout Tutorials', actionLabel: null),
              VideoCards(items: workouts),
              const SizedBox(height: 14),
            ],
            if ((_selectedCategory == 'All' || _selectedCategory == 'Diet & Nutrition') && nutrition.isNotEmpty) ...[
              const SectionHeader(title: 'Diet & Nutrition', actionLabel: null),
              VideoCards(items: nutrition),
              const SizedBox(height: 14),
            ],
            if ((_selectedCategory == 'All' || _selectedCategory == 'Recovery & Wellness') && recovery.isNotEmpty) ...[
              const SectionHeader(title: 'Recovery & Wellness', actionLabel: null),
              VideoCards(items: recovery),
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }
}

class _FeaturedVideoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1040), Color(0xFF2D1B69)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B4D), Color(0xFF1E1060)],
              ),
            ),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text('🏋️', style: TextStyle(fontSize: 60)),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.play_arrow, color: Color(0xFF1A1040)),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '28:45',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'FEATURED',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accent.withValues(alpha: 0.9),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Complete Upper Body Workout for Fat Loss',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Trainer Rahul · 28 min · Intermediate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.text2,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

