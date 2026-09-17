import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/dio_client.dart';
import '../models/demo_models.dart';

class NotificationsSheet {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _NotificationsContent();
      },
    );
  }
}

class _NotificationsContent extends StatefulWidget {
  const _NotificationsContent();

  @override
  State<_NotificationsContent> createState() => _NotificationsContentState();
}

class _NotificationsContentState extends State<_NotificationsContent> {
  final Dio _dio = GetIt.I<DioClient>().dio;
  List<ClientNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _dio.get('/fitness/api/client-notifications/');
      if (res.statusCode == 200 && res.data is Map && res.data['notifications'] is List) {
        final list = (res.data['notifications'] as List).map((item) {
          Color parsedColor = const Color(0xFF2C4BFF);
          if (item['color'] != null) {
            try {
              final colStr = item['color'].toString().replaceAll('#', '').replaceAll('0x', '');
              parsedColor = Color(int.parse(colStr, radix: 16));
            } catch (_) {}
          }
          return ClientNotification(
            icon: item['icon'] ?? '🔔',
            title: item['title'] ?? 'Notification',
            body: item['body'] ?? '',
            time: item['time'] ?? 'Today',
            color: parsedColor,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _notifications = list;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notifications';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101426),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: const Color(0xFF252D5A), width: 1.2),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B487A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (!_isLoading && _notifications.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E274A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF252D5A)),
                            ),
                            child: Text(
                              '${_notifications.length}',
                              style: const TextStyle(
                                color: Color(0xFF00C9FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8E99B7), size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1E2648), height: 1),
              Expanded(
                child: _buildBody(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C9FF)),
        ),
      );
    }

    if (_error != null && _notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 40),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF252D5A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF161C36),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF252D5A)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF8E99B7), size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'No notifications yet',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                "You're all caught up! Activity updates, routines, and reminders will appear here.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8E99B7), fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: const Color(0xFF00C9FF),
      backgroundColor: const Color(0xFF161C36),
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 40),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _NotifEntry(n: _notifications[index]);
        },
      ),
    );
  }
}

class _NotifEntry extends StatelessWidget {
  const _NotifEntry({required this.n});
  final ClientNotification n;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141A32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF252D5A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: n.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: n.color.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text(n.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2240),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        n.time,
                        style: const TextStyle(
                          color: Color(0xFF8E99B7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  n.body,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.35,
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

