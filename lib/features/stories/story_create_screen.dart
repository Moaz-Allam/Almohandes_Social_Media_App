import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../data/storage/media_upload_service.dart';
import '../../shared/widgets/app_snack.dart';
import '../../state/app_scope.dart';

/// Full-page story creation screen.
///
/// Presents two options — camera capture or gallery pick — matching the
/// design mockup. After media is selected the file is uploaded and the
/// story is published automatically, then the screen pops back.
class StoryCreateScreen extends StatefulWidget {
  const StoryCreateScreen({super.key});

  @override
  State<StoryCreateScreen> createState() => _StoryCreateScreenState();
}

class _StoryCreateScreenState extends State<StoryCreateScreen> {
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;

    final picker = ImagePicker();
    XFile? picked;
    bool isVideo = false;

    try {
      // Try image first; if from camera we offer both via the source itself.
      picked = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        imageQuality: 60,
      );
    } catch (_) {
      // Camera / gallery permission denied or unavailable.
    }

    if (picked == null && mounted) {
      // If user cancelled image, let them try video when source is camera.
      if (source == ImageSource.camera) {
        try {
          picked = await picker.pickVideo(
            source: source,
            maxDuration: const Duration(seconds: 30),
          );
          isVideo = true;
        } catch (_) {}
      }
    }

    if (picked == null || !mounted) return;

    // Detect video by extension when picked from gallery.
    if (!isVideo) {
      final ext = picked.name.split('.').last.toLowerCase();
      isVideo = {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'}.contains(ext);
    }

    setState(() => _busy = true);

    try {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      final mimeType =
          picked.mimeType ?? (isVideo ? 'video/mp4' : 'image/jpeg');
      final media = AppScope.read(context).repositories.media;
      final url = await media.uploadBytes(
        bucket: isVideo ? MediaBucket.reels : MediaBucket.stories,
        bytes: bytes,
        fileName: picked.name,
        mimeType: mimeType,
      );
      if (!mounted) return;

      await AppScope.read(context).repositories.stories.createStory(
        content: '',
        mediaUrl: url,
        mediaType: isVideo ? 'video' : 'image',
      );
      if (!mounted) return;

      AppScope.read(context).notifyStoriesChanged();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر القصة')),
      );
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(context, error, fallback: 'تعذر نشر القصة الآن');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'إنشاء قصة',
          style: TextStyle(
            color: AppColors.inkDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: AppColors.inkDark),
        ),
      ),
      body: SafeArea(
        child: _busy
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryGlow),
                    SizedBox(height: 16),
                    Text(
                      'جاري نشر القصة…',
                      style: TextStyle(
                        color: AppColors.mutedDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    _OptionCard(
                      icon: Icons.camera_alt_rounded,
                      title: 'التقط صورة أو فيديو',
                      subtitle: 'استخدم الكاميرا مباشرة',
                      onTap: () => _pick(ImageSource.camera),
                    ),
                    const SizedBox(height: 16),
                    _OptionCard(
                      icon: Icons.photo_library_rounded,
                      title: 'اختر من المعرض',
                      subtitle: 'صور وفيديوهات من جهازك',
                      onTap: () => _pick(ImageSource.gallery),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderDark.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            // Text (RTL: text on the right, icon on the left visually).
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.inkDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.mutedDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGlow, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}
