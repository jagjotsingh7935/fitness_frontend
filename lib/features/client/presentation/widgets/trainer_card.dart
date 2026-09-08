import 'package:flutter/material.dart';

class TrainerCard extends StatelessWidget {
  final Map<String, dynamic>? trainerData;

  const TrainerCard({super.key, this.trainerData});

  @override
  Widget build(BuildContext context) {
    final name = trainerData?['name']?.toString().isNotEmpty == true
        ? trainerData!['name'].toString()
        : 'Assigned Coach';
    
    final specialization = trainerData?['specialization']?.toString().isNotEmpty == true
        ? trainerData!['specialization'].toString()
        : 'Personal Trainer & Nutritionist';

    String initials = 'FC';
    final parts = name.trim().split(' ');
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      if (parts.length > 1 && parts[1].isNotEmpty) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
      }
    }

    final bool isAssigned = trainerData != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141828),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5C07B).withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE94560), Color(0xFF8B0D2A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE94560).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  specialization,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00F5A0).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00F5A0).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              isAssigned ? 'COACH' : 'ACTIVE',
              style: const TextStyle(
                color: Color(0xFF00F5A0),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

