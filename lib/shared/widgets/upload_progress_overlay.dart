import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/storage/upload_progress_controller.dart';

/// Wraps the active route stack and paints an upload-progress bar across
/// the top of the screen while any media upload is in flight.
///
/// The Supabase Storage SDK doesn't expose per-byte progress, so this is an
/// indeterminate bar — the goal is to give the user clear visual proof that
/// "something is happening" so they don't feel the app is stuck while a
/// reel/story uploads.
class UploadProgressOverlay extends StatelessWidget {
  const UploadProgressOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: AnimatedBuilder(
              animation: UploadProgressController.instance,
              builder: (context, _) {
                final controller = UploadProgressController.instance;
                final visible = controller.isUploading;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    final offset = Tween<Offset>(
                      begin: const Offset(0, -1),
                      end: Offset.zero,
                    ).animate(animation);
                    return SlideTransition(
                      position: offset,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: visible
                      ? _UploadBar(
                          key: const ValueKey('upload-bar'),
                          label: controller.latestLabel ?? 'جاري الرفع…',
                          extraCount: controller.activeCount - 1,
                        )
                      : const SizedBox(
                          key: ValueKey('upload-bar-empty'),
                          height: 0,
                          width: double.infinity,
                        ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadBar extends StatelessWidget {
  const _UploadBar({super.key, required this.label, required this.extraCount});

  final String label;
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    final caption = extraCount > 0 ? '$label  (+$extraCount)' : label;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        decoration: BoxDecoration(
          color: AppColors.darkBlue.withValues(alpha: .94),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(99)),
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  backgroundColor: Color(0x33FFFFFF),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
