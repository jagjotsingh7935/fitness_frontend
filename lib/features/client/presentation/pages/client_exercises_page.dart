import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/network/dio_client.dart';
import '../widgets/client_scaffold.dart';
import '../widgets/section_header.dart';

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

  List<String> _categories = ['All'];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _fetchWorkoutPlans();
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
    if (_selectedCategory == 'All') {
      _filtered = List.from(_allPlans);
    } else {
      _filtered = _allPlans
          .where((p) => p.exerciseDetail.categories
              .any((c) => c.name == _selectedCategory))
          .toList();
    }
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategoryChips(
            categories: _categories,
            selected: _selectedCategory,
            onSelect: _selectCategory,
          ),
          const SectionHeader(title: "Today's Exercises"),
          if (_isLoading)
            const _LoadingState()
          else if (_errorMessage != null)
            _ErrorState(message: _errorMessage!, onRetry: _fetchWorkoutPlans)
          else if (_filtered.isEmpty)
            const _EmptyState()
          else
            _ExerciseList(plans: _filtered, onTap: _openVideo),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Video bottom sheet
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
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF16213E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
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
                  // Title + day
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          ex.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DayBadge(day: plan.dayDisplay),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Stats
                  _StatsRow(plan: plan),

                  // Description
                  if (ex.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      ex.description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        height: 1.5,
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

class _VideoPlayer extends StatefulWidget {
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
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = width * 9 / 16;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video or fallback
            if (widget.isInitialized && widget.controller != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: widget.controller!.value.size.width,
                    height: widget.controller!.value.size.height,
                    child: VideoPlayer(widget.controller!),
                  ),
                ),
              )
            else if (widget.hasError)
              _ErrorVideoPlaceholder(thumbnailUrl: widget.thumbnailUrl)
            else
              _LoadingVideoPlaceholder(thumbnailUrl: widget.thumbnailUrl),

            // Play / pause overlay
            if (widget.isInitialized && widget.controller != null)
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: widget.controller!,
                builder: (_, value, __) => AnimatedOpacity(
                  opacity: value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: _PlayIcon(),
                ),
              )
            else if (!widget.hasError)
              _PlayIcon(),

            // Progress bar at bottom
            if (widget.isInitialized && widget.controller != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: widget.controller!,
                  builder: (_, value, __) {
                    final total = value.duration.inMilliseconds;
                    final pos = value.position.inMilliseconds;
                    final progress = total > 0 ? pos / total : 0.0;
                    return LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFE94560)),
                      minHeight: 3,
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
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 1.5),
        ),
        child:
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
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
            Image.network(thumbnailUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _bg())
          else
            _bg(),
          Container(color: Colors.black45),
          const Center(
              child: CircularProgressIndicator(color: Color(0xFFE94560))),
        ],
      );

  Widget _bg() => Container(color: const Color(0xFF0F3460));
}

class _ErrorVideoPlaceholder extends StatelessWidget {
  final String? thumbnailUrl;
  const _ErrorVideoPlaceholder({this.thumbnailUrl});

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnailUrl != null)
            Image.network(thumbnailUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _bg())
          else
            _bg(),
          Container(color: Colors.black54),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_off_rounded,
                    color: Colors.white54, size: 40),
                SizedBox(height: 8),
                Text('Video unavailable',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        ],
      );

  Widget _bg() => Container(color: const Color(0xFF0F3460));
}

// ---------------------------------------------------------------------------
// Category chips
// ---------------------------------------------------------------------------

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryChips(
      {required this.categories,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) => onSelect(cat),
            selectedColor: const Color(0xFFE94560),
            backgroundColor: const Color(0xFF1A1A2E),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
            side: BorderSide(
              color:
                  isSelected ? const Color(0xFFE94560) : Colors.white24,
            ),
            shape: const StadiumBorder(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) =>
          _ExerciseCard(plan: plans[i], onTap: () => onTap(plans[i])),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise card
// ---------------------------------------------------------------------------

class _ExerciseCard extends StatelessWidget {
  final WorkoutPlanModel plan;
  final VoidCallback onTap;

  const _ExerciseCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ex = plan.exerciseDetail;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Thumbnail(thumbnailUrl: ex.thumbnailUrl),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          ex.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DayBadge(day: plan.dayDisplay),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _StatsRow(plan: plan),
                  if (ex.categories.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _CategoryRow(categories: ex.categories),
                  ],
                  if (plan.notes != null && plan.notes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _NotesRow(notes: plan.notes!),
                  ],
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
// Thumbnail (card)
// ---------------------------------------------------------------------------

class _Thumbnail extends StatelessWidget {
  final String? thumbnailUrl;

  const _Thumbnail({this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 160,
          width: double.infinity,
          child: thumbnailUrl != null
              ? Image.network(thumbnailUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
              : _placeholder(),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 1.5),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF0F3460),
        child: const Center(
          child:
              Icon(Icons.fitness_center, color: Colors.white30, size: 48),
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
          _StatChip(icon: Icons.repeat_rounded, label: '${plan.sets} sets'),
          const SizedBox(width: 8),
          _StatChip(icon: Icons.tag_rounded, label: '${plan.reps} reps'),
          const SizedBox(width: 8),
          _StatChip(
              icon: Icons.timer_outlined, label: plan.formattedDuration),
        ],
      );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE94560).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: const Color(0xFFE94560).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFFE94560)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _DayBadge extends StatelessWidget {
  final String day;
  const _DayBadge({required this.day});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(day,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      );
}

class _CategoryRow extends StatelessWidget {
  final List<CategoryModel> categories;
  const _CategoryRow({required this.categories});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 4,
        children: categories
            .map((c) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(c.name,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ))
            .toList(),
      );
}

class _NotesRow extends StatelessWidget {
  final String notes;
  const _NotesRow({required this.notes});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 13, color: Colors.white38),
          const SizedBox(width: 5),
          Expanded(
            child: Text(notes,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontStyle: FontStyle.italic)),
          ),
        ],
      );
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
          child: CircularProgressIndicator(color: Colors.white),
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
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560)),
              child: const Text('Retry'),
            ),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(children: [
            Icon(Icons.fitness_center, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No exercises assigned yet',
                style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
}