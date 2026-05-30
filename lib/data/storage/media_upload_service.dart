import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/repository_failure.dart';
import 'upload_progress_controller.dart';

enum MediaBucket {
  avatars('avatars', 'image/jpeg'),
  covers('covers', 'image/jpeg'),
  posts('posts', 'image/jpeg'),
  stories('stories', 'image/jpeg'),
  reels('stories', 'video/mp4'),
  voice('voice-messages', 'audio/mp4'),
  chatFiles('stories', 'application/octet-stream');

  const MediaBucket(this.id, this.defaultMime);

  final String id;
  final String defaultMime;
}

final class MediaUploadService {
  MediaUploadService({this.client});

  final SupabaseClient? client;

  Future<String> uploadBytes({
    required MediaBucket bucket,
    required Uint8List bytes,
    String? fileName,
    String? mimeType,
  }) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure('الاتصال بالخادم غير مهيأ');
    }
    final userId = remote.auth.currentUser?.id;
    if (userId == null) {
      throw const RepositoryFailure('سجل الدخول أولا لرفع الملف');
    }
    final resolvedMime = _resolveMime(fileName: fileName, hint: mimeType, fallback: bucket.defaultMime);
    final extension = _extensionFor(fileName: fileName, mime: resolvedMime);
    final storageKey = _buildKey(userId: userId, bucket: bucket, extension: extension);
    final ticket = UploadProgressController.instance.begin(
      _uploadLabel(bucket: bucket, fileName: fileName, byteCount: bytes.length),
    );
    try {
      await remote.storage.from(bucket.id).uploadBinary(
            storageKey,
            bytes,
            fileOptions: FileOptions(
              contentType: resolvedMime,
              upsert: false,
              cacheControl: '3600',
            ),
          );
      return remote.storage.from(bucket.id).getPublicUrl(storageKey);
    } on StorageException catch (error) {
      throw RepositoryFailure(_friendlyMessage(error), error);
    } catch (error) {
      throw RepositoryFailure('تعذر رفع الملف الآن', error);
    } finally {
      ticket.complete();
    }
  }

  String _uploadLabel({
    required MediaBucket bucket,
    String? fileName,
    required int byteCount,
  }) {
    final mb = (byteCount / (1024 * 1024)).toStringAsFixed(1);
    final base = switch (bucket) {
      MediaBucket.avatars => 'رفع الصورة الشخصية',
      MediaBucket.covers => 'رفع صورة الغلاف',
      MediaBucket.posts => 'رفع صورة المنشور',
      MediaBucket.stories => 'رفع القصة',
      MediaBucket.reels => 'رفع reel',
      MediaBucket.voice => 'رفع الرسالة الصوتية',
      MediaBucket.chatFiles => 'رفع الملف',
    };
    return '$base · $mb ميجابايت';
  }

  String _buildKey({
    required String userId,
    required MediaBucket bucket,
    required String extension,
  }) {
    final now = DateTime.now();
    final stamp = '${now.year}${_pad(now.month)}${_pad(now.day)}_${now.microsecondsSinceEpoch}';
    final folder = switch (bucket) {
      MediaBucket.reels => 'reels',
      MediaBucket.stories => 'stories',
      MediaBucket.chatFiles => 'chat',
      _ => bucket.id,
    };
    return '$userId/$folder/$stamp.$extension';
  }

  String _resolveMime({String? fileName, String? hint, required String fallback}) {
    if (hint != null && hint.isNotEmpty) {
      return hint;
    }
    if (fileName != null && fileName.isNotEmpty) {
      final guessed = lookupMimeType(fileName);
      if (guessed != null && guessed.isNotEmpty) {
        return guessed;
      }
    }
    return fallback;
  }

  String _extensionFor({String? fileName, required String mime}) {
    if (fileName != null) {
      final ext = p.extension(fileName).replaceFirst('.', '');
      if (ext.isNotEmpty) {
        return ext.toLowerCase();
      }
    }
    return switch (mime) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      'image/heic' || 'image/heif' => 'heic',
      'video/quicktime' => 'mov',
      'video/webm' => 'webm',
      'audio/mpeg' => 'mp3',
      'audio/webm' => 'webm',
      'audio/aac' => 'aac',
      'audio/wav' => 'wav',
      _ when mime.startsWith('video/') => 'mp4',
      _ when mime.startsWith('audio/') => 'm4a',
      _ when mime.startsWith('image/') => 'jpg',
      _ => 'bin',
    };
  }

  String _pad(int v) => v < 10 ? '0$v' : '$v';

  String _friendlyMessage(StorageException error) {
    final message = error.message.toLowerCase();
    if (message.contains('exceeded') || message.contains('too large')) {
      return 'الملف كبير جدا للرفع';
    }
    if (message.contains('mime')) {
      return 'نوع الملف غير مدعوم';
    }
    if (message.contains('not authorized') || message.contains('rls')) {
      return 'الصلاحيات لا تسمح برفع هذا الملف';
    }
    return 'تعذر رفع الملف الآن';
  }
}
