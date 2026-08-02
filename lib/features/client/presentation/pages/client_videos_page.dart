import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/demo_models.dart';
import '../widgets/client_scaffold.dart';
import '../widgets/section_header.dart';
import '../widgets/video_cards.dart';

class ClientVideosPage extends StatelessWidget {
  const ClientVideosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ClientScaffold(
      greeting: 'From Your Trainer',
      title: 'Videos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FeaturedVideoCard(),
          const SectionHeader(title: 'Workout Tutorials', actionLabel: 'All ›'),
          const VideoCards(items: DemoClientData.videosWorkoutTutorials),
          const SectionHeader(title: 'Diet & Nutrition', actionLabel: 'All ›'),
          const VideoCards(items: DemoClientData.videosDietNutrition),
          const SectionHeader(title: 'Recovery & Wellness', actionLabel: 'All ›'),
          const VideoCards(items: DemoClientData.videosRecoveryWellness),
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

