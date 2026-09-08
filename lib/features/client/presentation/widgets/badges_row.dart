import 'package:flutter/material.dart';

class BadgeModel {
  const BadgeModel({
    required this.emoji,
    required this.name,
    required this.earned,
    this.description = '',
  });

  final String emoji;
  final String name;
  final bool earned;
  final String description;
}

class BadgesRow extends StatelessWidget {
  const BadgesRow({super.key, required this.badges, this.onBadgeTap});

  final List<BadgeModel> badges;
  final ValueChanged<BadgeModel>? onBadgeTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final b = badges[index];
          return GestureDetector(
            onTap: () {
              if (onBadgeTap != null) {
                onBadgeTap!(b);
              } else {
                _showBadgeDetails(context, b);
              }
            },
            child: _BadgeItem(badge: b),
          );
        },
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, BadgeModel badge) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF141829),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.earned
                      ? const Color(0xFFE5C07B).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: badge.earned
                        ? const Color(0xFFE5C07B)
                        : Colors.white24,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(badge.emoji, style: const TextStyle(fontSize: 34)),
              ),
              const SizedBox(height: 14),
              Text(
                badge.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                badge.earned ? '✅ Unlocked & Earned' : '🔒 Locked Milestone',
                style: TextStyle(
                  color: badge.earned ? const Color(0xFF00F5A0) : Colors.white38,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (badge.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  badge.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5C07B),
                  foregroundColor: const Color(0xFF101424),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({required this.badge});
  final BadgeModel badge;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        badge.earned ? const Color(0xFFE5C07B) : Colors.white.withValues(alpha: 0.15);
    final bg = badge.earned
        ? const Color(0xFFE5C07B).withValues(alpha: 0.12)
        : const Color(0xFF141829);

    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: badge.earned ? 2 : 1),
            color: bg,
            boxShadow: badge.earned
                ? [
                    BoxShadow(
                      color: const Color(0xFFE5C07B).withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            badge.emoji,
            style: TextStyle(
              fontSize: 24,
              color: badge.earned ? null : Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 66,
          child: Text(
            badge.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: badge.earned ? Colors.white : Colors.white38,
              fontSize: 10,
              fontWeight: badge.earned ? FontWeight.w700 : FontWeight.w500,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}

