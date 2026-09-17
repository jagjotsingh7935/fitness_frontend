import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/dio_client.dart';

class HydrationCard extends StatefulWidget {
  const HydrationCard({super.key, this.onUpdated});

  final VoidCallback? onUpdated;

  @override
  State<HydrationCard> createState() => _HydrationCardState();
}

class _HydrationCardState extends State<HydrationCard> {
  final Dio _dio = GetIt.I<DioClient>().dio;
  
  int _filledCount = 0;
  int _totalCups = 8; // Default target
  bool _isLoading = true;
  String? _errorMessage;
  String? _todayLogId;

  @override
  void initState() {
    super.initState();
    _fetchHydrationData();
  }

  Future<void> _fetchHydrationData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Fetch hydration targets for the client
      final targetsResponse = await _dio.get('/fitness/api/hydration-targets/');
      
      if (targetsResponse.statusCode == 200) {
        final targetsData = targetsResponse.data;
        List<dynamic> targets = [];
        
        if (targetsData is Map && targetsData.containsKey('results')) {
          targets = targetsData['results'];
        } else if (targetsData is List) {
          targets = targetsData;
        }
        
        // Get today's target (day_of_week: 0 = Monday, need to adjust)
        final todayWeekday = DateTime.now().weekday;
        // Convert Flutter weekday (1-7, Monday=1) to backend weekday (0-6, Monday=0)
        final backendWeekday = todayWeekday - 1;
        
        final todayTarget = targets.firstWhere(
          (t) => t['day_of_week'] == backendWeekday,
          orElse: () => null,
        );
        
        if (todayTarget != null) {
          _totalCups = todayTarget['target_cups'] ?? 8;
        }
      }

      // Fetch today's hydration log
      final logsResponse = await _dio.get('/fitness/api/hydration-logs/');
      
      if (logsResponse.statusCode == 200) {
        final logsData = logsResponse.data;
        List<dynamic> logs = [];
        
        if (logsData is Map && logsData.containsKey('results')) {
          logs = logsData['results'];
        } else if (logsData is List) {
          logs = logsData;
        }
        
        // Find today's log
        final todayLog = logs.firstWhere(
          (log) => log['date'] == today,
          orElse: () => null,
        );
        
        if (todayLog != null) {
          _filledCount = todayLog['actual_cups'] ?? 0;
          _todayLogId = todayLog['id'].toString();
        } else {
          _filledCount = 0;
          _todayLogId = null;
        }
      }
      
      setState(() => _isLoading = false);
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Network error occurred';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateHydrationLog(int newFilledCount) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    try {
      if (_todayLogId != null) {
        // Update existing log
        final response = await _dio.put(
          '/fitness/api/hydration-logs/$_todayLogId/',
          data: {
            'date': today,
            'actual_cups': newFilledCount,
            'notes': 'Updated from app',
          },
        );
        
        if (response.statusCode == 200) {
          setState(() {
            _filledCount = newFilledCount;
          });
          widget.onUpdated?.call();
        } else {
          throw Exception('Failed to update hydration log');
        }
      } else {
        // Create new log
        final response = await _dio.post(
          '/fitness/api/hydration-logs/',
          data: {
            'date': today,
            'actual_cups': newFilledCount,
            'notes': 'Logged from app',
          },
        );
        
        if (response.statusCode == 201) {
          final logData = response.data;
          setState(() {
            _filledCount = newFilledCount;
            _todayLogId = logData['id'].toString();
          });
          widget.onUpdated?.call();
        } else {
          throw Exception('Failed to create hydration log');
        }
      }
    } on DioException catch (e) {
      String errorMsg = 'Error updating hydration';
      if (e.response?.data != null) {
        errorMsg = e.response!.data.toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMsg')),
        );
      }
      // Refresh data to ensure consistency
      _fetchHydrationData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      _fetchHydrationData();
    }
  }

  void _toggleCup(int index) {
    final isCurrentlyFilled = index < _filledCount;
    int newFilledCount;
    
    if (isCurrentlyFilled) {
      // Remove this cup and all cups after it
      newFilledCount = index;
    } else {
      // Add this cup (fill up to this cup)
      newFilledCount = index + 1;
    }
    
    _updateHydrationLog(newFilledCount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D3B6E), Color(0xFF1565C0)],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D3B6E), Color(0xFF1565C0)],
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              'Error loading hydration data',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchHydrationData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0D3B6E),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D3B6E), Color(0xFF1565C0)],
        ),
        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '💧 Water Intake',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              Text(
                '$_filledCount / $_totalCups cups',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(_totalCups, (i) {
              final filled = i < _filledCount;
              return _WaterCup(
                filled: filled,
                onTap: () => _toggleCup(i),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Progress indicator
          LinearProgressIndicator(
            value: _filledCount / _totalCups,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text(
            '${((_filledCount / _totalCups) * 100).toInt()}% of daily goal',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WaterCup extends StatelessWidget {
  const _WaterCup({required this.filled, required this.onTap});

  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 44,
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: filled
                ? const Color(0xFF42A5F5)
                : Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
          color: filled
              ? const Color(0xFF42A5F5).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                height: filled ? 30 : 0,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(6),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF42A5F5).withValues(alpha: 0.6),
                      const Color(0xFF2196F3).withValues(alpha: 0.85),
                    ],
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