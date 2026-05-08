import 'package:video_player/video_player.dart';

final class PreparedVideoController {
  const PreparedVideoController(this.controller);

  final VideoPlayerController controller;

  Future<void> dispose() => controller.dispose();
}

Future<PreparedVideoController> prepareVideoController(String mediaUrl) async {
  return PreparedVideoController(
    VideoPlayerController.networkUrl(Uri.parse(mediaUrl)),
  );
}
