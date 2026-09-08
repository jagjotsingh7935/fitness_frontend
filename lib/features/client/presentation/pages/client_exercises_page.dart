import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/network/dio_client.dart';
import '../widgets/client_scaffold.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class CategoryModel {
  final int id;
  final String name;
  final String? iconUrl;

  const CategoryModel({required this.id, required this.name, this.iconUrl});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        iconUrl: json['icon_url'] as String?,
      );
}

class ExerciseDetailModel {
  final int id;
  final String title;
  final String description;
  final String? videoUrl;
  final String? thumbnailUrl;
  final List<CategoryModel> categories;
  final int durationSeconds;

  const ExerciseDetailModel({
    required this.id,
    required this.title,
    required this.description,
    this.videoUrl,
    this.thumbnailUrl,
    required this.categories,
    required this.durationSeconds,
  });

  factory ExerciseDetailModel.fromJson(Map<String, dynamic> json) =>
      ExerciseDetailModel(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        videoUrl: json['video_url'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .toList(),
        durationSeconds: json['duration_seconds'] as int? ?? 0,
      );
}

class WorkoutPlanModel {
  final int id;
  final ExerciseDetailModel exerciseDetail;
  final String dayDisplay;
  final int dayOfWeek;
  final int sets;
  final int reps;
  final int timePerRepSeconds;
  final int order;
  final String? notes;
  final bool isActive;

  const WorkoutPlanModel({
    required this.id,
    required this.exerciseDetail,
    required this.dayDisplay,
    required this.dayOfWeek,
    required this.sets,
    required this.reps,
    required this.timePerRepSeconds,
    required this.order,
    this.notes,
    required this.isActive,
  });

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) =>
      WorkoutPlanModel(
        id: json['id'] as int,
        exerciseDetail: ExerciseDetailModel.fromJson(
            json['exercise_detail'] as Map<String, dynamic>),
        dayDisplay: json['day_display'] as String? ?? '',
        dayOfWeek: json['day_of_week'] as int? ?? 0,
        sets: json['sets'] as int? ?? 0,
        reps: json['reps'] as int? ?? 0,
        timePerRepSeconds: json['time_per_rep_seconds'] as int? ?? 0,
        order: json['order'] as int? ?? 0,
        notes: json['notes'] as String?,
        isActive: json['is_active'] as bool? ?? false,
      );

  int get estimatedSeconds => sets * reps * timePerRepSeconds;

  String get formattedDuration {
    final mins = estimatedSeconds ~/ 60;
    final secs = estimatedSeconds % 60;
    if (mins == 0) return '${secs}s';
    if (secs == 0) return '${mins}m';
    return '${mins}m ${secs}s';
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class ClientExercisesPage extends StatefulWidget {
  const ClientExercisesPage({super.key});

  @override
  State<ClientExercisesPage> createState() => _ClientExercisesPageState();
}

class _ClientExercisesPageState extends State<ClientExercisesPage> {
  final Dio _dio = GetIt.I<DioClient>().dio;

  List<WorkoutPlanModel> _allPlans = [];
  List<WorkoutPlanModel> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _fetchWorkoutPlans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkoutPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _dio.get(
        '/fitness/api/my-workout-plans/',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data as List<dynamic>
            : (response.data['results'] as List<dynamic>);

        final plans = data
            .map((p) => WorkoutPlanModel.fromJson(p as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        final catSet = <String>{};
        for (final p in plans) {
          for (final c in p.exerciseDetail.categories) {
            catSet.add(c.name);
          }
        }

        setState(() {
          _allPlans = plans;
          _categories = ['All', ...catSet.toList()..sort()];
          _applyFilter();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load exercises: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMsg = 'Failed to load exercises';
      if (e.response?.statusCode == 401) {
        errorMsg = 'Session expired. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMsg = 'Workout plans not found.';
      } else if (e.response?.data != null) {
        errorMsg = e.response!.data.toString();
      }
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchQuery.toLowerCase();
    _filtered = _allPlans.where((p) {
      final matchesCat = _selectedCategory == 'All' ||
          p.exerciseDetail.categories.any((c) => c.name == _selectedCategory);

      final title = p.exerciseDetail.title.toLowerCase();
      final desc = p.exerciseDetail.description.toLowerCase();
      final notes = (p.notes ?? '').toLowerCase();

      final matchesSearch = query.isEmpty ||
          title.contains(query) ||
          desc.contains(query) ||
          notes.contains(query);

      return matchesCat && matchesSearch;
    }).toList();
  }

  void _selectCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
      _applyFilter();
    });
  }

  void _openVideo(WorkoutPlanModel plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VideoBottomSheet(plan: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClientScaffold(
      greeting: 'Your Plan',
      title: 'Exercises',
      onRefresh: _fetchWorkoutPlans,
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
                onChanged: (val) {
                  _searchQuery = val.trim();
                  setState(() => _applyFilter());
                },
                decoration: InputDecoration(
                  hintText: 'Search exercises by name, muscle, notes...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE5C07B), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            setState(() => _applyFilter());
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),

          // 2. Category Chips
          _CategoryChips(
            categories: _categories,
            selected: _selectedCategory,
            onSelect: _selectCategory,
          ),
          const SizedBox(height: 10),

          // 3. Counter & Section Header
          Row(
            children: [
              Text(
                "Today's Exercises",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
              ),
              const Spacer(),
              Text(
                '${_filtered.length} of ${_allPlans.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (_searchQuery.isNotEmpty || _selectedCategory != 'All') ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedCategory = 'All';
                    setState(() => _applyFilter());
                  },
                  child: const Text('Reset', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          if (_isLoading)
            const _LoadingState()
          else if (_errorMessage != null)
            _ErrorState(message: _errorMessage!, onRetry: _fetchWorkoutPlans)
          else if (_filtered.isEmpty)
            _searchQuery.isNotEmpty || _selectedCategory != 'All'
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text('No exercises match your search', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _selectedCategory = 'All';
                              setState(() => _applyFilter());
                            },
                            child: const Text('Clear Filters', style: TextStyle(color: Color(0xFF00F5A0))),
                          ),
                        ],
                      ),
                    ),
                  )
                : const _EmptyState()
          else
            _ExerciseList(plans: _filtered, onTap: _openVideo),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category chips
// ---------------------------------------------------------------------------

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return ChoiceChip(
            label: Text(
              cat,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelect(cat),
            selectedColor: const Color(0xFFE94560),
            backgroundColor: const Color(0xFF161B30),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFFE94560)
                  : Colors.white.withValues(alpha: 0.12),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise list
// ---------------------------------------------------------------------------

class _ExerciseList extends StatelessWidget {
  final List<WorkoutPlanModel> plans;
  final ValueChanged<WorkoutPlanModel> onTap;

  const _ExerciseList({required this.plans, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) =>
          _ExerciseCard(plan: plans[i], onTap: () => onTap(plans[i])),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise card (Luxury Obsidian Titanium Design)
// ---------------------------------------------------------------------------

class _ExerciseCard extends StatelessWidget {
  final WorkoutPlanModel plan;
  final VoidCallback onTap;

  const _ExerciseCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ex = plan.exerciseDetail;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF181D33),
            Color(0xFF121527),
            Color(0xFF0C0E1B),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5C07B).withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: const Color(0xFFE94560).withValues(alpha: 0.15),
          highlightColor: const Color(0xFFE5C07B).withValues(alpha: 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cinematic Video Thumbnail with Play Button
              _Thumbnail(
                thumbnailUrl: ex.thumbnailUrl,
                dayDisplay: plan.dayDisplay,
                durationSeconds: ex.durationSeconds,
                order: plan.order,
              ),

              // 2. Card Content Body
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            ex.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE94560).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFFE94560),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Stats Row (Sets, Reps, Estimated Time)
                    _StatsRow(plan: plan),

                    // Categories Micro-tags
                    if (ex.categories.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _CategoryRow(categories: ex.categories),
                    ],

                    // Coach Instructions / Notes
                    if (plan.notes != null && plan.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _NotesRow(notes: plan.notes!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thumbnail (Cinematic 16:9 Aspect Ratio with Frosted Glass Badge)
// ---------------------------------------------------------------------------

class _Thumbnail extends StatelessWidget {
  final String? thumbnailUrl;
  final String dayDisplay;
  final int durationSeconds;
  final int order;

  const _Thumbnail({
    this.thumbnailUrl,
    required this.dayDisplay,
    required this.durationSeconds,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
            Image.network(
              thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          else
            _placeholder(),

          // Smooth gradient overlay for cinematic contrast
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),

          // Center Play Button with Gold Rim
          Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE5C07B).withValues(alpha: 0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE94560).withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          // Top-Left Order & Day Badge
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00F5A0).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fitness_center_rounded, color: Color(0xFF00F5A0), size: 11),
                  const SizedBox(width: 4),
                  Text(
                    dayDisplay.isNotEmpty ? dayDisplay : 'Ex #$order',
                    style: const TextStyle(
                      color: Color(0xFF00F5A0),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom-Right Duration Tag
          if (durationSeconds > 0)
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFFE5C07B), size: 11),
                    const SizedBox(width: 4),
                    Text(
                      '${durationSeconds}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2238), Color(0xFF101424)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.fitness_center, color: Colors.white24, size: 42),
        ),
      );
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  final WorkoutPlanModel plan;
  const _StatsRow({required this.plan});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _StatPill(
              icon: Icons.repeat_rounded,
              label: '${plan.sets} Sets',
              color: const Color(0xFF00F5A0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatPill(
              icon: Icons.fitness_center_rounded,
              label: '${plan.reps} Reps',
              color: const Color(0xFFE5C07B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatPill(
              icon: Icons.timer_outlined,
              label: plan.formattedDuration,
              color: const Color(0xFFFF5252),
            ),
          ),
        ],
      );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

class _CategoryRow extends StatelessWidget {
  final List<CategoryModel> categories;
  const _CategoryRow({required this.categories});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 5,
        children: categories
            .map(
              (c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5C07B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5C07B).withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  c.name,
                  style: const TextStyle(
                    color: Color(0xFFE5C07B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      );
}

class _NotesRow extends StatelessWidget {
  final String notes;
  const _NotesRow({required this.notes});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF101424),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.tips_and_updates_rounded, size: 14, color: Color(0xFFE5C07B)),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                notes,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Video bottom sheet (Luxury Theme)
// ---------------------------------------------------------------------------

class _VideoBottomSheet extends StatefulWidget {
  final WorkoutPlanModel plan;

  const _VideoBottomSheet({required this.plan});

  @override
  State<_VideoBottomSheet> createState() => _VideoBottomSheetState();
}

class _VideoBottomSheetState extends State<_VideoBottomSheet> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = widget.plan.exerciseDetail.videoUrl;
    if (url == null || url.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.play();
      if (mounted) {
        setState(() {
          _controller = ctrl;
          _isInitialized = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final ctrl = _controller;
    if (ctrl == null) return;
    setState(() {
      ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.plan.exerciseDetail;
    final plan = widget.plan;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1322),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            // Gold drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5C07B).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Video player
            _VideoPlayer(
              controller: _controller,
              isInitialized: _isInitialized,
              hasError: _hasError,
              thumbnailUrl: ex.thumbnailUrl,
              onTap: _togglePlay,
            ),

            // Details — scrollable
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Title + Day Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          ex.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          plan.dayDisplay.isNotEmpty ? plan.dayDisplay : 'Workout',
                          style: const TextStyle(
                            color: Color(0xFF00F5A0),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats Row
                  _StatsRow(plan: plan),

                  // Description
                  if (ex.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Instructions & Form',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ex.description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ],

                  // Notes
                  if (plan.notes != null && plan.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _NotesRow(notes: plan.notes!),
                  ],

                  // Categories
                  if (ex.categories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _CategoryRow(categories: ex.categories),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Video player widget
// ---------------------------------------------------------------------------

class _VideoPlayer extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool isInitialized;
  final bool hasError;
  final String? thumbnailUrl;
  final VoidCallback onTap;

  const _VideoPlayer({
    required this.controller,
    required this.isInitialized,
    required this.hasError,
    required this.thumbnailUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = width * 9 / 16;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isInitialized && controller != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller!.value.size.width,
                    height: controller!.value.size.height,
                    child: VideoPlayer(controller!),
                  ),
                ),
              )
            else if (hasError)
              _ErrorVideoPlaceholder(thumbnailUrl: thumbnailUrl)
            else
              _LoadingVideoPlaceholder(thumbnailUrl: thumbnailUrl),

            if (isInitialized && controller != null)
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller!,
                builder: (_, value, __) => AnimatedOpacity(
                  opacity: value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: _PlayIcon(),
                ),
              )
            else if (!hasError)
              _PlayIcon(),

            if (isInitialized && controller != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: controller!,
                  builder: (_, value, __) {
                    final total = value.duration.inMilliseconds;
                    final pos = value.position.inMilliseconds;
                    final progress = total > 0 ? pos / total : 0.0;
                    return LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFE94560)),
                      minHeight: 3.5,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5C07B), width: 1.5),
        ),
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
      );
}

class _LoadingVideoPlaceholder extends StatelessWidget {
  final String? thumbnailUrl;
  const _LoadingVideoPlaceholder({this.thumbnailUrl});

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnailUrl != null)
            Image.network(thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _bg())
          else
            _bg(),
          Container(color: Colors.black54),
          const Center(child: CircularProgressIndicator(color: Color(0xFFE94560))),
        ],
      );

  Widget _bg() => Container(color: const Color(0xFF101424));
}

class _ErrorVideoPlaceholder extends StatelessWidget {
  final String? thumbnailUrl;
  const _ErrorVideoPlaceholder({this.thumbnailUrl});

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnailUrl != null)
            Image.network(thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _bg())
          else
            _bg(),
          Container(color: Colors.black54),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 40),
                SizedBox(height: 8),
                Text('Video unavailable', style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        ],
      );

  Widget _bg() => Container(color: const Color(0xFF101424));
}

// ---------------------------------------------------------------------------
// State widgets
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560))),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF161B30),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.fitness_center_rounded, size: 38, color: Color(0xFFE5C07B)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No exercises assigned yet',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your trainer will assign your customized workout routine shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ]),
        ),
      );
}