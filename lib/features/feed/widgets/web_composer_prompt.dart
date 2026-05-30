import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/storage/media_upload_service.dart';
import '../../../models/account_type.dart';
import '../../../models/post_visibility.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_snack.dart';
import '../../../shared/widgets/media_preview.dart';
import '../../../state/app_scope.dart';
import '../../composer/project_form_screen.dart';

/// LinkedIn-style "what's on your mind?" prompt that sits above the home
/// feed tabs on the web layout. Tapping the prompt or any chip opens
/// [_WebComposerDialog], which is the *only* composer surface on web —
/// the user can write text, attach an image or reel, choose visibility,
/// and publish without ever leaving the feed.
class WebComposerPrompt extends StatelessWidget {
  const WebComposerPrompt({super.key});

  Future<void> _openDialog(
    BuildContext context, {
    _WebComposerStart focus = _WebComposerStart.text,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .45),
      builder: (context) => _WebComposerDialog(initialFocus: focus),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.watch(context).profile;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : 'المستخدم';
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border.all(color: context.appBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(
                name: name,
                radius: 22,
                color: AppColors.darkBlue,
                imageUrl: profile?.avatarUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _openDialog(context),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: context.appSurfaceAlt,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: context.appBorder),
                    ),
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'بماذا تريد أن تتحدث؟',
                      style: TextStyle(
                        color: context.appMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WebPromptAction(
                icon: Icons.image_outlined,
                label: 'صورة',
                color: const Color(0xFF378FE9),
                onTap: () =>
                    _openDialog(context, focus: _WebComposerStart.photo),
              ),
              _WebPromptAction(
                icon: Icons.smart_display_outlined,
                label: 'reel',
                color: const Color(0xFFC4762E),
                onTap: () =>
                    _openDialog(context, focus: _WebComposerStart.reel),
              ),
              _WebPromptAction(
                icon: Icons.folder_special_outlined,
                label: 'مشروع',
                color: const Color(0xFFE16745),
                onTap: () =>
                    _openDialog(context, focus: _WebComposerStart.project),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WebPromptAction extends StatelessWidget {
  const _WebPromptAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: context.appText,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _WebComposerStart { text, photo, reel, project }

class _WebComposerDialog extends StatefulWidget {
  const _WebComposerDialog({required this.initialFocus});

  final _WebComposerStart initialFocus;

  @override
  State<_WebComposerDialog> createState() => _WebComposerDialogState();
}

class _WebComposerDialogState extends State<_WebComposerDialog> {
  final _contentController = TextEditingController();
  final _textFocus = FocusNode();
  bool _isPublishing = false;
  bool _isUploadingMedia = false;
  String _mediaUrl = '';
  String _mediaType = 'text';
  String _mediaName = '';
  PostVisibility _visibility = PostVisibility.public;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _textFocus.requestFocus();
      switch (widget.initialFocus) {
        case _WebComposerStart.photo:
          _pickMedia(_WebComposerAction.photo);
        case _WebComposerStart.reel:
          _pickMedia(_WebComposerAction.reel);
        case _WebComposerStart.project:
          _openProjectForm();
        case _WebComposerStart.text:
          break;
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(_WebComposerAction action) async {
    if (_isUploadingMedia) {
      return;
    }
    final XFile? picked;
    final Uint8List bytes;
    final String mimeType;
    final String mediaName;
    try {
      final picker = ImagePicker();
      picked = action == _WebComposerAction.photo
          ? await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1080,
              imageQuality: 60,
            )
          : await picker.pickVideo(
              source: ImageSource.gallery,
              maxDuration: const Duration(seconds: 90),
            );
      if (picked == null) {
        return;
      }
      bytes = await picked.readAsBytes();
      mimeType = picked.mimeType ??
          (action == _WebComposerAction.photo ? 'image/jpeg' : 'video/mp4');
      mediaName = picked.name;
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnack.error(
        context,
        error,
        fallback:
            'تعذر اختيار الملف من المعرض. تأكد من منح صلاحية الوصول للصور',
      );
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _isUploadingMedia = true);
    final media = AppScope.read(context).repositories.media;
    final bucket = action == _WebComposerAction.photo
        ? MediaBucket.posts
        : MediaBucket.reels;
    try {
      final url = await media.uploadBytes(
        bucket: bucket,
        bytes: bytes,
        fileName: mediaName,
        mimeType: mimeType,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _mediaUrl = url;
        _mediaType = action == _WebComposerAction.photo ? 'image' : 'reel';
        _mediaName = mediaName;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnack.error(
        context,
        error,
        fallback:
            'تعذر رفع الملف. تحقق من حجم الملف ونوعه ومن الاتصال بالإنترنت',
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  Future<void> _openProjectForm() async {
    Navigator.of(context).pop();
    final navigator = Navigator.of(context, rootNavigator: true);
    await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
    );
  }

  void _removeMedia() {
    setState(() {
      _mediaUrl = '';
      _mediaType = 'text';
      _mediaName = '';
    });
  }

  Future<void> _pickVisibility() async {
    final picked = await showDialog<PostVisibility>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('من يمكنه رؤية هذا المنشور؟'),
        children: [
          for (final option in PostVisibility.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(option),
              child: Row(
                children: [
                  Icon(
                    option == PostVisibility.public
                        ? Icons.public
                        : Icons.lock_outline,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.arabicLabel,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          option.arabicDescription,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (!mounted || picked == null || picked == _visibility) {
      return;
    }
    setState(() => _visibility = picked);
  }

  Future<void> _publish() async {
    if (_isPublishing) {
      return;
    }
    final content = _contentController.text.trim();
    if (content.isEmpty && _mediaUrl.isEmpty) {
      return;
    }
    setState(() => _isPublishing = true);
    final app = AppScope.read(context);
    final wasReel = _mediaType == 'reel';
    try {
      if (wasReel) {
        await app.repositories.reels.createReel(
          caption: content,
          videoUrl: _mediaUrl,
        );
        app.notifyReelsChanged();
      } else {
        await app.repositories.feed.createPost(
          content: content,
          mediaUrl: _mediaUrl,
          mediaType: _mediaType,
          visibility: _visibility,
        );
        app.notifyFeedChanged();
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      AppSnack.success(
        context,
        wasReel ? 'تم نشر reel بنجاح' : 'تم نشر المنشور بنجاح',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnack.error(
        context,
        error,
        fallback:
            'تعذر نشر المحتوى. تحقق من الاتصال أو من حجم الملف وحاول مرة أخرى',
      );
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.watch(context);
    final profile = app.profile;
    final accountType = accountTypeFromProfile(profile);
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : 'المستخدم';
    final canPostProjects = accountType.canPostProjects;
    final canPublish =
        (_contentController.text.trim().isNotEmpty || _mediaUrl.isNotEmpty) &&
            !_isPublishing &&
            !_isUploadingMedia;
    return Dialog(
      backgroundColor: context.appSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 6),
              child: Row(
                children: [
                  AppAvatar(
                    name: name,
                    radius: 22,
                    color: AppColors.darkBlue,
                    imageUrl: profile?.avatarUrl,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _pickVisibility,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            height: 28,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.muted),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _visibility == PostVisibility.public
                                      ? Icons.public
                                      : Icons.lock_outline,
                                  size: 16,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _visibility.arabicLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'إغلاق',
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.appBorder),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ListenableBuilder so the post button enables as soon
                    // as the user types, without rebuilding the whole
                    // dialog on every keystroke.
                    ListenableBuilder(
                      listenable: _contentController,
                      builder: (context, _) {
                        return TextField(
                          controller: _contentController,
                          focusNode: _textFocus,
                          minLines: 6,
                          maxLines: 14,
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            hintText: 'بماذا تريد أن تتحدث؟',
                            hintStyle: TextStyle(
                              fontSize: 22,
                              color: context.appMuted.withValues(alpha: .55),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                    if (_isUploadingMedia) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'جاري رفع الملف...',
                            style: TextStyle(color: context.appMuted),
                          ),
                        ],
                      ),
                    ],
                    if (_mediaUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 1.55,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: MediaPreview(
                                mediaUrl: _mediaUrl,
                                mediaType: _mediaType,
                                fallbackLabel:
                                    _mediaType == 'reel' ? 'reel' : 'صورة',
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            top: 8,
                            end: 8,
                            child: CircleAvatar(
                              backgroundColor:
                                  Colors.black.withValues(alpha: .55),
                              child: IconButton(
                                onPressed: _removeMedia,
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                tooltip: 'إزالة',
                              ),
                            ),
                          ),
                          if (_mediaName.isNotEmpty)
                            PositionedDirectional(
                              start: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .55),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _mediaName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: context.appBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 14, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isUploadingMedia || _isPublishing
                        ? null
                        : () => _pickMedia(_WebComposerAction.photo),
                    tooltip: 'إضافة صورة',
                    icon: const Icon(
                      Icons.image_outlined,
                      color: Color(0xFF378FE9),
                    ),
                  ),
                  IconButton(
                    onPressed: _isUploadingMedia || _isPublishing
                        ? null
                        : () => _pickMedia(_WebComposerAction.reel),
                    tooltip: 'إضافة reel',
                    icon: const Icon(
                      Icons.smart_display_outlined,
                      color: Color(0xFFC4762E),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        canPostProjects && !_isPublishing ? _openProjectForm : null,
                    tooltip: canPostProjects
                        ? 'إضافة مشروع'
                        : 'مشاركة المشاريع متاحة للمهندسين والشركات فقط',
                    icon: const Icon(
                      Icons.folder_special_outlined,
                      color: Color(0xFFE16745),
                    ),
                  ),
                  const Spacer(),
                  // ListenableBuilder again so the button enables as soon
                  // as `canPublish` flips (text typed, media uploaded).
                  ListenableBuilder(
                    listenable: _contentController,
                    builder: (context, _) {
                      return FilledButton(
                        onPressed: canPublish ? _publish : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          disabledBackgroundColor: context.appSoft,
                          disabledForegroundColor: context.appMuted,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _isPublishing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'نشر',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _WebComposerAction { photo, reel }
