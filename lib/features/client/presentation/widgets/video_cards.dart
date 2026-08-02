import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/demo_models.dart';

class VideoCards extends StatelessWidget {
  const VideoCards({super.key, required this.items});

  final List<VideoModel> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _VideoCard(model: items[i]),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.model});
  final VideoModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: model.gradient,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(model.emoji, style: const TextStyle(fontSize: 36)),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.play_arrow,
                          color: model.gradient.first,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.meta,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.text2,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 8,
              top: 110 - 32 - 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  model.duration,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

