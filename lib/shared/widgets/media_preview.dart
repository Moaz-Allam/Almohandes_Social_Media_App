import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import '../painters/post_media_painter.dart';
import 'video_controller_source_stub.dart'
    if (dart.library.io) 'video_controller_source_io.dart';
import 'video_seek_bar.dart';

class MediaPreview extends StatelessWidget {
  const MediaPreview({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    this.fit = BoxFit.contain,
    this.fallbackLabel,
    this.autoplay = false,
    this.showVideoControls = false,
    this.cacheWidth,
    this.cacheHeight,
    this.muted,
    this.releaseController = false,
  });

  final String mediaUrl;
  final String mediaType;
  final BoxFit fit;
  final String? fallbackLabel;
  final bool autoplay;
  final bool showVideoControls;

  /// When true the underlying video controller is fully disposed (freeing the
  /// native decoder/buffers) instead of merely paused. Used to release reels
  /// when their whole tab is hidden — pausing alone keeps the decoder
  /// allocated. Flipping back to false re-initialises the controller.
  final bool releaseController;

  /// Decode hint in pixels. Pass roughly the on-screen size — decoding 4K
  /// images down to feed-card dimensions is one of the biggest sources of
  /// jank on lower-end devices.
  final int? cacheWidth;
  final int? cacheHeight;

  /// When set, overrides the default volume behaviour. `true` mutes the
  /// video, `false` unmutes; `null` keeps the legacy behaviour (volume on
  /// when controls are shown).
  final bool? muted;

  bool get _hasMedia => mediaUrl.trim().isNotEmpty;
  bool get _isVideo => mediaType == 'video' || mediaType == 'reel';

  @override
  Widget build(BuildContext context) {
    if (_hasMedia && _isVideo) {
      return _VideoFramePreview(
        mediaUrl: mediaUrl,
        fit: fit,
        fallbackLabel: fallbackLabel,
        autoplay: autoplay,
        showControls: showVideoControls,
        muted: muted,
        releaseController: releaseController,
      );
    }
    if (!_hasMedia) {
      return _FallbackMedia(isVideo: _isVideo, label: fallbackLabel);
    }
    if (mediaUrl.startsWith('data:')) {
      final bytes = _bytesFromDataUrl(mediaUrl);
      if (bytes == null) {
        return _FallbackMedia(isVideo: _isVideo, label: fallbackLabel);
      }
      return Image.memory(
        bytes,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            _FallbackMedia(isVideo: _isVideo, label: fallbackLabel),
      );
    }
    if (!mediaUrl.startsWith('http')) {
      return _FallbackMedia(isVideo: _isVideo, label: fallbackLabel);
    }
    return CachedNetworkImage(
      imageUrl: mediaUrl,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      fadeInDuration: const Duration(milliseconds: 160),
      placeholder: (_, _) => const ColoredBox(color: Color(0x11000000)),
      errorWidget: (context, error, stackTrace) =>
          _FallbackMedia(isVideo: _isVideo, label: fallbackLabel),
    );
  }

  Uint8List? _bytesFromDataUrl(String value) {
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
    this.muted,
    this.releaseController = false,
  });

  final String mediaUrl;
  final BoxFit fit;
  final bool autoplay;
  final bool showControls;
  final String? fallbackLabel;

  /// Explicit mute override. `null` falls back to legacy "follow controls"
  /// behaviour, where volume is 1 when controls are visible.
  final bool? muted;

  /// When true the controller is fully disposed (releasing the native
  /// decoder) instead of merely paused. Flipping back to false re-initialises.
  final bool releaseController;

  @override
  State<_VideoFramePreview> createState() => _VideoFramePreviewState();
}

class _VideoFramePreviewState extends State<_VideoFramePreview> {
  PreparedVideoController? _preparedController;
  VideoPlayerController? _controller;
  bool _failed = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.releaseController) {
      _initialize();
    }
  }

  @override
  void didUpdateWidget(covariant _VideoFramePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaUrl != widget.mediaUrl) {
      _disposePreparedController();
      _controller = null;
      _failed = false;
      if (!widget.releaseController) {
        _initialize();
      }
      return;
    }
    if (oldWidget.releaseController != widget.releaseController) {
      if (widget.releaseController) {
        // Tab hidden: tear the decoder down rather than leaving it allocated.
        _loadGeneration++;
        _disposePreparedController();
        _failed = false;
        if (mounted) {
          setState(() {});
        }
      } else {
        // Tab visible again: rebuild the controller from scratch.
        _initialize();
      }
      return;
    }
    if (oldWidget.showControls != widget.showControls ||
        oldWidget.muted != widget.muted) {
      unawaited(_controller?.setVolume(_targetVolume()));
    }
    if (oldWidget.autoplay != widget.autoplay) {
      _syncPlayback();
    }
  }

  double _targetVolume() {
    final muted = widget.muted;
    if (muted != null) {
      return muted ? 0 : 1;
    }
    return widget.showControls ? 1 : 0;
  }

  Future<void> _initialize() async {
    final generation = ++_loadGeneration;
    PreparedVideoController? prepared;
    try {
      prepared = await prepareVideoController(widget.mediaUrl);
      if (!mounted || generation != _loadGeneration) {
        unawaited(prepared.dispose());
        return;
      }
      final controller = prepared.controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(_targetVolume());
      if (!mounted || generation != _loadGeneration) {
        unawaited(prepared.dispose());
        return;
      }
      _preparedController = prepared;
      _controller = controller;
      prepared = null;
      await _syncPlayback();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (prepared != null) {
        unawaited(prepared.dispose());
      }
      if (mounted && generation == _loadGeneration) {
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
    _loadGeneration++;
    _disposePreparedController();
    super.dispose();
  }

  void _disposePreparedController() {
    final prepared = _preparedController;
    _preparedController = null;
    _controller = null;
    if (prepared != null) {
      unawaited(prepared.dispose());
    }
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
      // Even when controls are hidden we still need a transparent tap
      // capture on web: the underlying `VideoPlayer` is a `<video>`
      // platform-view element on Flutter Web that intercepts clicks at
      // the browser level. Without an overlay above it, taps never reach
      // any Flutter-side handler.
      return Stack(
        fit: StackFit.expand,
        children: [
          video,
          Positioned.fill(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayback,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        video,
        // ── Pointer overlay ───────────────────────────────────────
        // Always present, drawn ABOVE the platform-view video so
        // Flutter (not the browser <video>) gets the tap. The seek bar
        // and play icon sit on top of this layer, so they still receive
        // their own gestures.
        Positioned.fill(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlayback,
              child: const SizedBox.expand(),
            ),
          ),
        ),
        if (!controller.value.isPlaying)
          Center(
            child: IgnorePointer(
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
          ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 6,
          child: VideoSeekBar(
            controller: controller,
            showLabels: false,
          ),
        ),
      ],
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
