import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import '../painters/post_media_painter.dart';

class MediaPreview extends StatelessWidget {
  const MediaPreview({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    this.fit = BoxFit.cover,
    this.fallbackLabel,
    this.autoplay = false,
    this.showVideoControls = false,
  });

  final String mediaUrl;
  final String mediaType;
  final BoxFit fit;
  final String? fallbackLabel;
  final bool autoplay;
  final bool showVideoControls;

  bool get _hasMedia => mediaUrl.trim().isNotEmpty;
  bool get _isVideo => mediaType == 'video' || mediaType == 'reel';

  @override
  Widget build(BuildContext context) {
    final bytes = _bytesFromDataUrl(mediaUrl);
    if (_hasMedia && _isVideo) {
      return _VideoFramePreview(
        mediaUrl: mediaUrl,
        fit: fit,
        fallbackLabel: fallbackLabel,
        autoplay: autoplay,
        showControls: showVideoControls,
      );
    }
    if (bytes != null && !_isVideo) {
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _FallbackMedia(isVideo: _isVideo, label: fallbackLabel),
      );
    }
    if (_hasMedia && !_isVideo && !mediaUrl.startsWith('data:')) {
      return Image.network(
        mediaUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _FallbackMedia(isVideo: _isVideo, label: fallbackLabel),
      );
    }
    return _FallbackMedia(isVideo: _isVideo, label: fallbackLabel);
  }

  Uint8List? _bytesFromDataUrl(String value) {
    if (!value.startsWith('data:')) {
      return null;
    }
    final comma = value.indexOf(',');
    if (comma == -1) {
      return null;
    }
    try {
      return base64Decode(value.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }
}

class _VideoFramePreview extends StatefulWidget {
  const _VideoFramePreview({
    required this.mediaUrl,
    required this.fit,
    required this.autoplay,
    required this.showControls,
    this.fallbackLabel,
  });

  final String mediaUrl;
  final BoxFit fit;
  final bool autoplay;
  final bool showControls;
  final String? fallbackLabel;

  @override
  State<_VideoFramePreview> createState() => _VideoFramePreviewState();
}

class _VideoFramePreviewState extends State<_VideoFramePreview> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant _VideoFramePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaUrl != widget.mediaUrl) {
      _controller?.dispose();
      _controller = null;
      _failed = false;
      _initialize();
      return;
    }
    if (oldWidget.autoplay != widget.autoplay) {
      _syncPlayback();
    }
  }

  Future<void> _initialize() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.mediaUrl),
      );
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(widget.showControls ? 1 : 0);
      await _syncPlayback();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  Future<void> _syncPlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (widget.autoplay) {
      await controller.play();
    } else {
      await controller.pause();
    }
    if (mounted && widget.showControls) {
      setState(() {});
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return _FallbackMedia(isVideo: true, label: widget.fallbackLabel);
    }
    if (controller == null || !controller.value.isInitialized) {
      return const _VideoLoadingSkeleton();
    }
    final video = FittedBox(
      fit: widget.fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
    if (!widget.showControls) {
      return video;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          video,
          if (!controller.value.isPlaying)
            Center(
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .42),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoLoadingSkeleton extends StatelessWidget {
  const _VideoLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackMedia extends StatelessWidget {
  const _FallbackMedia({required this.isVideo, this.label});

  final bool isVideo;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: PostMediaPainter()),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .48),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVideo ? Icons.play_arrow : Icons.image_outlined,
                  color: AppColors.white,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  label ?? (isVideo ? 'فيديو' : 'صورة'),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
