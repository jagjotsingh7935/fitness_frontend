import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum StatChangeDirection { up, down, neutral }

class StatCardModel {
  const StatCardModel({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
    required this.changeLabel,
    this.changeDirection = StatChangeDirection.neutral,
    this.unit = '',
  });

  final String value;
  final String label;
  final Widget icon;
  final Color accent;
  final String changeLabel;
  final StatChangeDirection changeDirection;
  final String unit;
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.model, this.onTap});

  final StatCardModel model;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color changeFg;
    Color changeBg;

    if (model.changeDirection == StatChangeDirection.up) {
      changeFg = const Color(0xFF00F5A0);
      changeBg = const Color(0xFF00F5A0).withValues(alpha: 0.12);
    } else if (model.changeDirection == StatChangeDirection.down) {
      changeFg = const Color(0xFF38BDF8);
      changeBg = const Color(0xFF38BDF8).withValues(alpha: 0.12);
    } else {
      changeFg = model.accent;
      changeBg = model.accent.withValues(alpha: 0.12);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF131830),
            borderRadius: BorderRadius.circular(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar: Icon + Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: model.accent.withValues(alpha: 0.15),
                    ),
                    alignment: Alignment.center,
                    child: IconTheme(
                      data: IconThemeData(color: model.accent, size: 14),
                      child: model.icon,
                    ),
                  ),
                  if (model.changeLabel.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: changeBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          model.changeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: changeFg,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const Spacer(),

              // Value & Unit
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      model.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (model.unit.isNotEmpty) ...[
                      const SizedBox(width: 2),
                      Text(
                        model.unit,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 1),

              // Sub-label
              Text(
                model.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
