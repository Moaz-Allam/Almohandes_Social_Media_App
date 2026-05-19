import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A scrub-friendly progress bar for a [VideoPlayerController].
///
/// Why this exists: Flutter's built-in [VideoProgressIndicator] is only a
/// few pixels tall, which makes precise tap-to-seek on a phone basically
/// impossible. This widget:
/// - Renders a slim visible bar.
/// - Listens directly to the controller (no parent setState churn).
/// - Provides a 28px-tall tap target via [SliderTheme] / [Slider].
/// - Seeks on tap-down AND drag (Material [Slider] does both natively).
/// - Optionally renders a `00:21 / 01:35` time label.
class VideoSeekBar extends StatefulWidget {
  const VideoSeekBar({
    super.key,
    required this.controller,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0x55FFFFFF),
    this.bufferedColor = const Color(0xAAFFFFFF),
    this.showLabels = true,
    this.labelColor = Colors.white,
    this.barHeight = 4,
  });

  final VideoPlayerController controller;
  final Color activeColor;
  final Color inactiveColor;
  final Color bufferedColor;
  final bool showLabels;
  final Color labelColor;
  final double barHeight;

  @override
  State<VideoSeekBar> createState() => _VideoSeekBarState();
}

class _VideoSeekBarState extends State<VideoSeekBar> {
  // Local position the user is dragging to. While dragging we display this
  // instead of the controller value so the thumb tracks the finger smoothly.
  double? _dragValue;
  bool _wasPlayingBeforeDrag = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final value = widget.controller.value;
        if (!value.isInitialized) {
          return SizedBox(height: widget.barHeight);
        }
        final durationMs = value.duration.inMilliseconds;
        if (durationMs <= 0) {
          return SizedBox(height: widget.barHeight);
        }
        final positionMs = _dragValue ??
            value.position.inMilliseconds.toDouble().clamp(0, durationMs).toDouble();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: widget.barHeight,
                activeTrackColor: widget.activeColor,
                inactiveTrackColor: widget.inactiveColor,
                secondaryActiveTrackColor: widget.bufferedColor,
                thumbColor: widget.activeColor,
                overlayColor: widget.activeColor.withValues(alpha: .18),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                // Stretches the tap target without making the track itself
                // visually thicker.
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: SizedBox(
                height: 28,
                child: Slider(
                  min: 0,
                  max: durationMs.toDouble(),
                  value: positionMs.toDouble(),
                  secondaryTrackValue: _bufferedMs(value, durationMs),
                  onChangeStart: (_) {
                    _wasPlayingBeforeDrag = widget.controller.value.isPlaying;
                    if (_wasPlayingBeforeDrag) {
                      widget.controller.pause();
                    }
                  },
                  onChanged: (ms) {
                    setState(() => _dragValue = ms);
                  },
                  onChangeEnd: (ms) async {
                    await widget.controller.seekTo(Duration(milliseconds: ms.toInt()));
                    if (_wasPlayingBeforeDrag) {
                      await widget.controller.play();
                    }
                    if (mounted) {
                      setState(() => _dragValue = null);
                    }
                  },
                ),
              ),
            ),
            if (widget.showLabels)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(Duration(milliseconds: positionMs.toInt())),
                      style: TextStyle(color: widget.labelColor, fontSize: 12),
                    ),
                    Text(
                      _formatDuration(value.duration),
                      style: TextStyle(color: widget.labelColor.withValues(alpha: .8), fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  double _bufferedMs(VideoPlayerValue value, int durationMs) {
    if (value.buffered.isEmpty) {
      return 0;
    }
    // Use the furthest buffered end-point we know about.
    var furthest = 0;
    for (final range in value.buffered) {
      final ms = range.end.inMilliseconds;
      if (ms > furthest) {
        furthest = ms;
      }
    }
    return furthest.toDouble().clamp(0, durationMs.toDouble());
  }
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
