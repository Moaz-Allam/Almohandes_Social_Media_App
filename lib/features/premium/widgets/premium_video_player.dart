import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../models/premium_course.dart';

class PremiumVideoPlayer extends StatefulWidget {
  const PremiumVideoPlayer({super.key, required this.video});

  final PremiumVideo video;

  @override
  State<PremiumVideoPlayer> createState() => _PremiumVideoPlayerState();
}

class _PremiumVideoPlayerState extends State<PremiumVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _isReady = false;
  bool _isMuted = false;
  double _playbackSpeed = 1;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
          ..initialize().then((_) {
            if (!mounted) {
              return;
            }
            setState(() => _isReady = true);
          });
    _controller.addListener(_onVideoChanged);
  }

  void _onVideoChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onVideoChanged)
      ..dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (!_isReady) {
      return;
    }
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  Future<void> _seekBy(Duration offset) async {
    if (!_isReady) {
      return;
    }
    await _controller.seekTo(
      _clampDuration(
        _controller.value.position + offset,
        _controller.value.duration,
      ),
    );
  }

  Future<void> _restart() async {
    if (!_isReady) {
      return;
    }
    await _controller.seekTo(Duration.zero);
    await _controller.play();
  }

  Future<void> _toggleMute() async {
    if (!_isReady) {
      return;
    }
    final nextMuted = !_isMuted;
    await _controller.setVolume(nextMuted ? 0 : 1);
    setState(() => _isMuted = nextMuted);
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    if (!_isReady) {
      return;
    }
    await _controller.setPlaybackSpeed(speed);
    setState(() => _playbackSpeed = speed);
  }

  Duration _clampDuration(Duration value, Duration max) {
    if (value < Duration.zero) {
      return Duration.zero;
    }
    if (max > Duration.zero && value > max) {
      return max;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.black),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isReady)
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              else
                const CircularProgressIndicator(color: AppColors.white),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: _togglePlayback),
                ),
              ),
              _CenterPlaybackButton(
                isReady: _isReady,
                isPlaying: _controller.value.isPlaying,
                onTap: _togglePlayback,
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: _PremiumVideoControls(
                  controller: _controller,
                  isReady: _isReady,
                  isMuted: _isMuted,
                  playbackSpeed: _playbackSpeed,
                  onTogglePlayback: _togglePlayback,
                  onBackward: () => _seekBy(const Duration(seconds: -10)),
                  onForward: () => _seekBy(const Duration(seconds: 10)),
                  onRestart: _restart,
                  onToggleMute: _toggleMute,
                  onSpeedChanged: _setPlaybackSpeed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterPlaybackButton extends StatelessWidget {
  const _CenterPlaybackButton({
    required this.isReady,
    required this.isPlaying,
    required this.onTap,
  });

  final bool isReady;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return const SizedBox.shrink();
    }
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .54),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: AppColors.white,
          size: 34,
        ),
      ),
    );
  }
}

class _PremiumVideoControls extends StatelessWidget {
  const _PremiumVideoControls({
    required this.controller,
    required this.isReady,
    required this.isMuted,
    required this.playbackSpeed,
    required this.onTogglePlayback,
    required this.onBackward,
    required this.onForward,
    required this.onRestart,
    required this.onToggleMute,
    required this.onSpeedChanged,
  });

  final VideoPlayerController controller;
  final bool isReady;
  final bool isMuted;
  final double playbackSpeed;
  final VoidCallback onTogglePlayback;
  final VoidCallback onBackward;
  final VoidCallback onForward;
  final VoidCallback onRestart;
  final VoidCallback onToggleMute;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return const SizedBox.shrink();
    }

    final value = controller.value;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: .78),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: AppColors.blue,
              bufferedColor: Colors.white54,
              backgroundColor: Colors.white24,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
          Row(
            children: [
              Text(
                _formatDuration(value.position),
                style: const TextStyle(color: AppColors.white, fontSize: 12),
              ),
              const SizedBox(width: 4),
              const Text(
                '/',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDuration(value.duration),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              _SpeedMenu(
                selectedSpeed: playbackSpeed,
                onChanged: onSpeedChanged,
              ),
              _ControlIconButton(
                icon: Icons.replay,
                label: 'إعادة من البداية',
                onTap: onRestart,
              ),
              _ControlIconButton(
                icon: isMuted ? Icons.volume_off : Icons.volume_up,
                label: isMuted ? 'تشغيل الصوت' : 'كتم الصوت',
                onTap: onToggleMute,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlIconButton(
                icon: Icons.replay_10,
                label: 'رجوع 10 ثوان',
                onTap: onBackward,
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onTogglePlayback,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.white,
                    size: 29,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ControlIconButton(
                icon: Icons.forward_10,
                label: 'تقديم 10 ثوان',
                onTap: onForward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _ControlIconButton extends StatelessWidget {
  const _ControlIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.white, size: 22),
      ),
    );
  }
}

class _SpeedMenu extends StatelessWidget {
  const _SpeedMenu({required this.selectedSpeed, required this.onChanged});

  static const _speeds = [.75, 1.0, 1.25, 1.5, 2.0];

  final double selectedSpeed;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: 'سرعة التشغيل',
      initialValue: selectedSpeed,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final speed in _speeds)
          PopupMenuItem<double>(value: speed, child: Text('${speed}x')),
      ],
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${selectedSpeed}x',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
