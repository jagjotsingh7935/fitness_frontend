import 'package:flutter/material.dart';

import '../../data/models/client_profile_dto.dart';

class AssignedCoachesSheet {
  static Future<void> show(
    BuildContext context, {
    required ClientProfileDto? profile,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AssignedCoachesContent(profile: profile),
    );
  }
}

class _AssignedCoachesContent extends StatelessWidget {
  const _AssignedCoachesContent({required this.profile});

  final ClientProfileDto? profile;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final coaches = profile?.activeTrainers ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1326),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9F43).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF9F43).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: Color(0xFFFF9F43),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Assigned Coaches',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your dedicated fitness mentors & trainers',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (coaches.isEmpty) ...[
                    // Empty State
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141829),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 32,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Self-Guided Training Mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'You do not have a dedicated coach assigned yet. Your gym administrator will connect you with a certified coach who will tailor customized workout and diet plans for you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // List of coaches
                    ...coaches.map((trainer) {
                      final name = trainer['name']?.toString().isNotEmpty == true
                          ? trainer['name'].toString()
                          : 'Personal Trainer';
                      final spec = trainer['specialization']?.toString().isNotEmpty == true
                          ? trainer['specialization'].toString()
                          : 'Strength & Conditioning Specialist';

                      String initials = 'TR';
                      final parts = name.trim().split(' ');
                      if (parts.isNotEmpty && parts[0].isNotEmpty) {
                        if (parts.length > 1 && parts[1].isNotEmpty) {
                          initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                        } else {
                          initials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141829),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFF9F43).withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF9F43), Color(0xFFFF5252)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFF00F5A0).withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: const Text(
                                              'ACTIVE COACH',
                                              style: TextStyle(
                                                color: Color(0xFF00F5A0),
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        spec,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C0F1E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.verified_user_rounded, color: Color(0xFF00F5A0), size: 18),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Certified & Connected · Tailoring your exercises and nutrition',
                                      style: TextStyle(color: Colors.white70, fontSize: 11.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
