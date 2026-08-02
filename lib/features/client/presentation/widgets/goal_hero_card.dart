import 'dart:math' as math;

import 'package:flutter/material.dart';

class GoalHeroCard extends StatelessWidget {
  const GoalHeroCard({
    super.key,
    required this.goalBadge,
    required this.title,
    required this.subtitle,
    required this.burned,
    required this.remaining,
    required this.donePct,
    required this.onStartWorkout,
  });

  final String goalBadge;
  final String title;
  final String subtitle;
  final String burned;
  final String remaining;
  final int donePct;
  final VoidCallback onStartWorkout;

  @override
  Widget build(BuildContext context) {
    final pct = (donePct.clamp(0, 100)) / 100.0;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A2AFF),
            Color(0xFF7C3AED),
            Color(0xFF9C27B0),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: _Bubble(size: 160, alpha: 0.07),
          ),
          Positioned(
            bottom: -30,
            left: 20,
            child: _Bubble(size: 100, alpha: 0.05),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      goalBadge.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  const Spacer(),
                  const Text('🔥', style: TextStyle(fontSize: 26)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.6,
                    ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _GoalStat(value: burned, label: 'Burned')),
                  const SizedBox(width: 10),
                  Expanded(child: _GoalStat(value: remaining, label: 'Remaining')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GoalStat(
                      value: '$donePct%',
                      label: 'Done',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ProgressRing(pct: pct, label: '$donePct%'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keep pushing!',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "3 exercises left today.\nYou're on track! 💪",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                                height: 1.3,
                              ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonal(
                          onPressed: onStartWorkout,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.18),
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow, size: 14),
                              SizedBox(width: 6),
                              Text('Start Workout'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.alpha});
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

class _GoalStat extends StatelessWidget {
  const _GoalStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.pct, required this.label});
  final double pct;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: CustomPaint(
        painter: _RingPainter(pct: pct),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 1),
              Text(
                'DONE',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.pct});
  final double pct;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.15);

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);

    final sweep = (math.pi * 2) * pct.clamp(0, 1);
    final shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, Color(0xFFC4B5FD)],
    ).createShader(rect);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.pct != pct;
}

