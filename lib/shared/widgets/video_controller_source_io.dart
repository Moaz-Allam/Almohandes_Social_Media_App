import 'dart:convert';
import 'dart:io';

import 'package:video_player/video_player.dart';

final class PreparedVideoController {
  const PreparedVideoController(
    this.controller, {
    this.tempDirectory,
    this.tempFile,
  });

  final VideoPlayerController controller;
  final Directory? tempDirectory;
  final File? tempFile;

  Future<void> dispose() async {
    await controller.dispose();
    final file = tempFile;
    if (file == null) {
      return;
    }
    try {
      if (await file.exists()) {
        await file.delete();
      }
      final directory = tempDirectory;
      if (directory != null && await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (_) {
      // Temporary playback files can be cleaned up by the OS if deletion fails.
    }
  }
}

Future<PreparedVideoController> prepareVideoController(String mediaUrl) async {
  if (!mediaUrl.startsWith('data:')) {
    return PreparedVideoController(
      VideoPlayerController.networkUrl(Uri.parse(mediaUrl)),
    );
  }

  final comma = mediaUrl.indexOf(',');
  if (comma == -1) {
    return PreparedVideoController(
      VideoPlayerController.networkUrl(Uri.parse(mediaUrl)),
    );
  }

  final header = mediaUrl.substring(0, comma).toLowerCase();
  final bytes = base64Decode(mediaUrl.substring(comma + 1));
  final extension = _extensionForDataHeader(header);
  final directory = await Directory.systemTemp.createTemp('tradeflow_video_');
  final file = File(
    '${directory.path}${Platform.pathSeparator}video_${DateTime.now().microsecondsSinceEpoch}.$extension',
  );
  await file.writeAsBytes(bytes, flush: true);
  return PreparedVideoController(
    VideoPlayerController.file(file),
    tempDirectory: directory,
    tempFile: file,
  );
}

String _extensionForDataHeader(String header) {
  if (header.contains('webm')) {
    return 'webm';
  }
  if (header.contains('quicktime') || header.contains('mov')) {
    return 'mov';
  }
  if (header.contains('m4v')) {
    return 'm4v';
  }
  return 'mp4';
}
