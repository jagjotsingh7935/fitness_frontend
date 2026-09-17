import 'package:flutter/material.dart';

import '../../../../core/services/notification_service.dart';

class DailyRemindersSheet {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _DailyRemindersModal(),
    );
  }
}

class _DailyRemindersModal extends StatefulWidget {
  const _DailyRemindersModal();

  @override
  State<_DailyRemindersModal> createState() => _DailyRemindersModalState();
}

class _DailyRemindersModalState extends State<_DailyRemindersModal> {
  bool _dailyFitnessAlert = true;
  bool _hydrationAlerts = true;
  bool _workoutAlerts = true;
  bool _streakAlerts = true;
  bool _isSendingTest = false;

  Future<void> _sendTestAlert() async {
    setState(() => _isSendingTest = true);
    try {
      await NotificationService().showNotification(
        id: 999,
        title: '🔔 FLUX Daily Reminder',
        body: 'Do not forget to complete your daily fitness diet goals!',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test notification sent! Check your notification bar.'),
            backgroundColor: Color(0xFF00F5A0),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingTest = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
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
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFF38BDF8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Daily Reminders & Alerts',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Automated notifications for fitness goals & habits',
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
                children: [
                  // 12 PM Alert Card
                  _buildReminderCard(
                    icon: Icons.access_time_filled_rounded,
                    iconBg: const Color(0xFFE5C07B).withValues(alpha: 0.15),
                    iconColor: const Color(0xFFE5C07B),
                    title: 'Daily Fitness Goals (12:00 PM)',
                    subtitle: 'Scheduled daily alert: "Do not forget to complete your daily fitness diet goals"',
                    badge: '12:00 PM DAILY',
                    value: _dailyFitnessAlert,
                    onChanged: (v) => setState(() => _dailyFitnessAlert = v),
                  ),

                  const SizedBox(height: 12),

                  // Hydration Alert Card
                  _buildReminderCard(
                    icon: Icons.water_drop_rounded,
                    iconBg: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                    iconColor: const Color(0xFF00F5A0),
                    title: 'Hydration Target Alerts',
                    subtitle: 'Periodic reminders to drink water and reach your daily target cups',
                    badge: 'HOURLY CHECK',
                    value: _hydrationAlerts,
                    onChanged: (v) => setState(() => _hydrationAlerts = v),
                  ),

                  const SizedBox(height: 12),

                  // Workout Alert Card
                  _buildReminderCard(
                    icon: Icons.fitness_center_rounded,
                    iconBg: const Color(0xFFFF9F43).withValues(alpha: 0.15),
                    iconColor: const Color(0xFFFF9F43),
                    title: 'Workout Routine Alerts',
                    subtitle: 'Notifications when your coach updates exercises or on workout days',
                    badge: 'MORNING ALERT',
                    value: _workoutAlerts,
                    onChanged: (v) => setState(() => _workoutAlerts = v),
                  ),

                  const SizedBox(height: 12),

                  // Streak Alert Card
                  _buildReminderCard(
                    icon: Icons.local_fire_department_rounded,
                    iconBg: const Color(0xFFFF4B72).withValues(alpha: 0.15),
                    iconColor: const Color(0xFFFF4B72),
                    title: 'Streak & Milestone Celebrations',
                    subtitle: 'Instant alerts when unlocking badges and maintaining day streaks',
                    badge: 'REAL-TIME',
                    value: _streakAlerts,
                    onChanged: (v) => setState(() => _streakAlerts = v),
                  ),

                  const SizedBox(height: 24),

                  // Test notification button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isSendingTest ? null : _sendTestAlert,
                      icon: _isSendingTest
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00F5A0)),
                            )
                          : const Icon(Icons.send_rounded, size: 18, color: Color(0xFF00F5A0)),
                      label: const Text(
                        'Send Test 12 PM Alert Now',
                        style: TextStyle(
                          color: Color(0xFF00F5A0),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF00F5A0), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: const Color(0xFF00F5A0).withValues(alpha: 0.06),
                      ),
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

  Widget _buildReminderCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141829),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value ? iconColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
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
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF00F5A0),
            activeTrackColor: const Color(0xFF00F5A0).withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white10,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
