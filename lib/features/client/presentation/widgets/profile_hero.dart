import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/client_profile_dto.dart';

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    this.profile,
    this.onEditProfile,
  });

  final ClientProfileDto? profile;
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context) {
    final name = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : (profile?.email.isNotEmpty == true ? profile!.email : 'Fitness Client');

    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';

    final email = profile?.email ?? '';
    final phone = profile?.phone ?? '';
    final address = profile?.address ?? '';

    final categories = profile?.categories ?? const [];

    final double? curW = _parseDouble(profile?.weight);
    final double? tgtW = _parseDouble(profile?.preferredWeight);
    String? progressDiff;
    if (curW != null && tgtW != null) {
      final diff = curW - tgtW;
      if (diff > 0) {
        progressDiff = '-${diff.toStringAsFixed(1)} kg to goal';
      } else if (diff < 0) {
        progressDiff = '+${(-diff).toStringAsFixed(1)} kg to goal';
      } else {
        progressDiff = '🎯 Goal Reached!';
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF161B36),
            Color(0xFF0F1326),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            blurRadius: 25,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name + Edit Action
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00F5A0), Color(0xFF6366F1)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F5A0).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F1326),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5A0),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0F1326), width: 2),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.black,
                        size: 9,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Name & User Handle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // Edit Profile Button
              if (onEditProfile != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEditProfile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: Color(0xFF818CF8),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Color(0xFF818CF8),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Contact Details Chips (Wrap ensures ZERO horizontal overflow)
          if (phone.isNotEmpty || address.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (phone.isNotEmpty)
                  _ContactChip(
                    icon: Icons.phone_outlined,
                    label: phone,
                  ),
                if (address.isNotEmpty)
                  _ContactChip(
                    icon: Icons.location_on_outlined,
                    label: address,
                  ),
              ],
            ),
          ],

          // Categories Goal Tags (Wrap ensures ZERO horizontal overflow)
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: categories.map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5A0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00F5A0).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎯 ', style: TextStyle(fontSize: 10)),
                      Text(
                        cat.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00F5A0),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 14),

          // Quick Body Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroStatItem(
                    val: '${profile?.weight ?? '--'}',
                    unit: 'kg',
                    lbl: 'Current',
                  ),
                ),
                Container(
                  width: 1,
                  height: 26,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: _HeroStatItem(
                    val: '${profile?.preferredWeight ?? '--'}',
                    unit: 'kg',
                    lbl: 'Target',
                    accentColor: const Color(0xFF00F5A0),
                  ),
                ),
                Container(
                  width: 1,
                  height: 26,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: _HeroStatItem(
                    val: '${profile?.bmi ?? '--'}',
                    unit: '',
                    lbl: 'BMI',
                    accentColor: const Color(0xFF818CF8),
                  ),
                ),
                if (progressDiff != null) ...[
                  Container(
                    width: 1,
                    height: 26,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _HeroStatItem(
                      val: progressDiff,
                      unit: '',
                      lbl: 'Target Status',
                      accentColor: const Color(0xFFFF9F43),
                      isCompact: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: Colors.white60,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  const _HeroStatItem({
    required this.val,
    required this.unit,
    required this.lbl,
    this.accentColor,
    this.isCompact = false,
  });

  final String val;
  final String unit;
  final String lbl;
  final Color? accentColor;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  val,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isCompact ? 12 : 14.5,
                    color: accentColor ?? Colors.white,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            lbl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
