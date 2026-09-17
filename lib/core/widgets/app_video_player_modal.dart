import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../network/api_constants.dart';

String sanitizeVideoUrl(String? rawUrl) {
  if (rawUrl == null || rawUrl.trim().isEmpty) return '';
  String url = rawUrl.trim();

  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    final base = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;
    final path = url.startsWith('/') ? url : '/$url';
    url = '$base$path';
  } else if (url.contains('localhost:8000') || url.contains('127.0.0.1:8000')) {
    final base = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;
    url = url.replaceFirst(RegExp(r'https?://(localhost|127\.0\.0\.1):8000'), base);
  }

  try {
    return Uri.encodeFull(url);
  } catch (_) {
    return url;
  }
}

void showAppVideoPlayerModal(
  BuildContext context, {
  required String title,
  required String videoUrl,
  String? category,
}) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AppVideoPlayerModal(
      title: title,
      videoUrl: videoUrl,
      category: category,
    ),
  );
}

class AppVideoPlayerModal extends StatefulWidget {
  final String title;
  final String videoUrl;
  final String? category;

  const AppVideoPlayerModal({
    super.key,
    required this.title,
    required this.videoUrl,
    this.category,
  });

  @override
  State<AppVideoPlayerModal> createState() => _AppVideoPlayerModalState();
}

class _AppVideoPlayerModalState extends State<AppVideoPlayerModal> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = sanitizeVideoUrl(widget.videoUrl);
    if (url.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    final oldCtrl = _controller;
    _controller = null;
    if (oldCtrl != null) {
      oldCtrl.removeListener(_onControllerUpdate);
      try {
        await oldCtrl.pause();
        await oldCtrl.dispose();
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isInitialized = false;
        _hasError = false;
      });
    }

    VideoPlayerController? ctrl;
    try {
      ctrl = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'FluxFitnessApp/1.0',
        },
      );

      await ctrl.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Video connection timed out');
        },
      );

      if (_isDisposed || !mounted) {
        try {
          await ctrl.pause();
          await ctrl.dispose();
        } catch (_) {}
        return;
      }

      ctrl.setLooping(true);
      ctrl.addListener(_onControllerUpdate);

      setState(() {
        _controller = ctrl;
        _isInitialized = true;
        _hasError = false;
      });

      await ctrl.play();
    } catch (e) {
      debugPrint('AppVideoPlayer error: $e');
      if (ctrl != null) {
        try {
          await ctrl.dispose();
        } catch (_) {}
      }
      if (mounted && !_isDisposed) {
        setState(() {
          _controller = null;
          _isInitialized = false;
          _hasError = true;
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted || _isDisposed) return;
    final ctrl = _controller;
    if (ctrl != null && ctrl.value.hasError) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    final ctrl = _controller;
    _controller = null;
    if (ctrl != null) {
      ctrl.removeListener(_onControllerUpdate);
      ctrl.pause().catchError((_) {});
      ctrl.dispose().catchError((_) {});
    }
    super.dispose();
  }

  void _togglePlay() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    setState(() {
      ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = width * 9 / 16;
    final ctrl = _controller;
    final isReady = _isInitialized &&
        ctrl != null &&
        ctrl.value.isInitialized &&
        !ctrl.value.hasError &&
        ctrl.value.size.width > 0 &&
        ctrl.value.size.height > 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.40,
      maxChildSize: 0.90,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1322),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Video player area
            GestureDetector(
              onTap: isReady ? _togglePlay : null,
              child: Container(
                width: width,
                height: height,
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isReady)
                      Center(
                        child: AspectRatio(
                          aspectRatio: ctrl.value.aspectRatio > 0 ? ctrl.value.aspectRatio : 16 / 9,
                          child: VideoPlayer(ctrl),
                        ),
                      )
                    else if (_hasError)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 36),
                            const SizedBox(height: 6),
                            const Text(
                              'Unable to load video',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _initVideo,
                              icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF00F5A0)),
                              label: const Text('Retry', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 12, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Center(child: CircularProgressIndicator(color: Color(0xFFE94560))),

                    // Play / Pause indicator
                    if (isReady)
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: ctrl,
                        builder: (_, value, __) => AnimatedOpacity(
                          opacity: value.isPlaying ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE5C07B), width: 1.5),
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                          ),
                        ),
                      ),

                    // Progress bar
                    if (isReady)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: ctrl,
                          builder: (_, value, __) {
                            final total = value.duration.inMilliseconds;
                            final pos = value.position.inMilliseconds;
                            final progress = total > 0 ? pos / total : 0.0;
                            return LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFE94560)),
                              minHeight: 3.5,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Video Details
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (widget.category != null && widget.category!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            widget.category!,
                            style: const TextStyle(
                              color: Color(0xFF00F5A0),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Exercise Demo Video',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
