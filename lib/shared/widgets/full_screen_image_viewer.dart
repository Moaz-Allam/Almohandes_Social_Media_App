import 'package:flutter/material.dart';

import 'media_preview.dart';

/// Full-screen, pinch-to-zoom viewer for post / chat images (and video).
/// Open it with [FullScreenImageViewer.open].
class FullScreenImageViewer extends StatelessWidget {
  const FullScreenImageViewer({
    super.key,
    required this.mediaUrl,
    this.mediaType = 'image',
  });

  final String mediaUrl;
  final String mediaType;

  static Future<void> open(
    BuildContext context, {
    required String mediaUrl,
    String mediaType = 'image',
  }) {
    if (mediaUrl.trim().isEmpty) {
      return Future.value();
    }
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullScreenImageViewer(
          mediaUrl: mediaUrl,
          mediaType: mediaType,
        ),
      ),
    );
  }

  bool get _isVideo => mediaType == 'video' || mediaType == 'reel';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: MediaPreview(
                  mediaUrl: mediaUrl,
                  mediaType: mediaType,
                  fit: BoxFit.contain,
                  autoplay: _isVideo,
                  showVideoControls: _isVideo,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'إغلاق',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
