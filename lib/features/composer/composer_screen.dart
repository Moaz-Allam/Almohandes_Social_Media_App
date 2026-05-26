import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/storage/media_upload_service.dart';
import '../../models/account_type.dart';
import '../../models/app_tab.dart';
import '../../models/post_visibility.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/media_preview.dart';
import '../../state/app_scope.dart';
import 'project_form_screen.dart';
import 'job_form_screen.dart';
import 'widgets/composer_top_bar.dart';

class ComposerScreen extends StatefulWidget {
  const ComposerScreen({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends State<ComposerScreen> {
  final _contentController = TextEditingController();
  bool _isPublishing = false;
  bool _isUploadingMedia = false;
  String _mediaUrl = '';
  String _mediaType = 'text';
  String _mediaName = '';
  PostVisibility _visibility = PostVisibility.public;

  static const _allOptions = [
    _ComposerOption(Icons.image_outlined, 'إضافة صورة', _ComposerAction.photo),
    _ComposerOption(
      Icons.smart_display_outlined,
      'إضافة ريل',
      _ComposerAction.reel,
    ),
    _ComposerOption(
      Icons.folder_special_outlined,
      'إضافة مشروع',
      _ComposerAction.project,
    ),
    _ComposerOption(
      Icons.work_outline_rounded,
      'إضافة وظيفة',
      _ComposerAction.job,
    ),
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  List<_ComposerOption> _optionsFor(AccountType accountType) {
    final canPostSpecial = accountType == AccountType.engineer ||
        accountType == AccountType.company ||
        accountType == AccountType.admin;

    return [
      for (final option in _allOptions)
        if ((option.action != _ComposerAction.project &&
                option.action != _ComposerAction.job) ||
            canPostSpecial)
          option,
    ];
  }

  Future<void> _publishPost() async {
    final content = _contentController.text.trim();
    if ((content.isEmpty && _mediaUrl.isEmpty) || _isPublishing) {
      return;
    }
    setState(() => _isPublishing = true);
    final app = AppScope.read(context);
    final repositories = app.repositories;
    final wasReel = _mediaType == 'reel';
    try {
      if (wasReel) {
        await repositories.reels.createReel(
          caption: content,
          videoUrl: _mediaUrl,
        );
      } else {
        await repositories.feed.createPost(
          content: content,
          mediaUrl: _mediaUrl,
          mediaType: _mediaType,
          visibility: _visibility,
        );
      }
      if (!mounted) {
        return;
      }
      // Drop the composer draft so the user doesn't see their old content
      // when they come back to this tab. IndexedStack keeps the State
      // alive otherwise.
      _contentController.clear();
      setState(() {
        _mediaUrl = '';
        _mediaType = 'text';
        _mediaName = '';
        _visibility = PostVisibility.public;
      });
      // Tell downstream screens (feed/reels) to refetch on their next
      // didChangeDependencies — so the user lands on a feed that already
      // includes what they just posted.
      if (wasReel) {
        app.notifyReelsChanged();
      } else {
        app.notifyFeedChanged();
      }
      AppSnack.success(
        context,
        wasReel ? 'تم نشر الريل بنجاح' : 'تم نشر المنشور بنجاح',
      );
      if (wasReel) {
        app.selectTab(AppTab.reels);
      } else {
        widget.onClose();
      }
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

  Future<void> _pickMedia(_ComposerAction action) async {
    if (_isUploadingMedia) {
      return;
    }
    final XFile? picked;
    final Uint8List bytes;
    final String mimeType;
    final String mediaName;
    try {
      final picker = ImagePicker();
      picked = action == _ComposerAction.photo
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
      mimeType =
          picked.mimeType ??
          (action == _ComposerAction.photo ? 'image/jpeg' : 'video/mp4');
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
    final bucket = action == _ComposerAction.photo
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
        _mediaType = action == _ComposerAction.photo ? 'image' : 'reel';
        _mediaName = mediaName;
      });
      AppSnack.success(
        context,
        action == _ComposerAction.photo
            ? 'تم رفع الصورة. أكمل المنشور ثم اضغط نشر'
            : 'تم رفع الفيديو. أكمل المنشور ثم اضغط نشر',
      );
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

  Future<void> _pickVisibility() async {
    final picked = await showModalBottomSheet<PostVisibility>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 6),
              child: Text(
                'من يمكنه رؤية هذا المنشور؟',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
            for (final option in PostVisibility.values)
              RadioListTile<PostVisibility>(
                value: option,
                groupValue: _visibility,
                onChanged: (value) => Navigator.of(context).pop(value),
                title: Row(
                  children: [
                    Icon(
                      option == PostVisibility.public
                          ? Icons.public
                          : Icons.lock_outline,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      option.arabicLabel,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                subtitle: Text(option.arabicDescription),
                activeColor: AppColors.blue,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || picked == null || picked == _visibility) {
      return;
    }
    setState(() => _visibility = picked);
  }

  void _removeMedia() {
    setState(() {
      _mediaUrl = '';
      _mediaType = 'text';
      _mediaName = '';
    });
  }

  Future<void> _handleOption(
    BuildContext context,
    _ComposerOption option,
    AccountType accountType,
  ) async {
    switch (option.action) {
      case _ComposerAction.photo:
        await _pickMedia(option.action);
        return;
      case _ComposerAction.reel:
        await _pickMedia(option.action);
        return;
      case _ComposerAction.project:
        if (!accountType.canPostProjects) {
          AppSnack.info(
            context,
            'مشاركة المشاريع متاحة لحسابات المهندسين والشركات فقط. حدّث نوع الحساب من ملفك الشخصي إذا كنت مؤهلا',
          );
          return;
        }
        final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
        );
        if (created == true && mounted) {
          widget.onClose();
        }
        return;
      case _ComposerAction.job:
        // For now jobs use the same form or a simplified one, 
        // but user asked for different inputs. I will create a JobFormScreen.
        final createdJob = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const JobFormScreen()),
        );
        if (createdJob == true && mounted) {
          widget.onClose();
        }
        return;
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
    final role = profile?.role.isNotEmpty == true ? profile!.role : null;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: Column(
        children: [
          // The publish button enable-state is the only thing that depends on
          // the text field, so subscribe just the top bar to the controller
          // instead of rebuilding the whole composer on every keystroke.
          ListenableBuilder(
            listenable: _contentController,
            builder: (context, _) {
              return ComposerTopBar(
                title: 'مشاركة منشور',
                onClose: widget.onClose,
                onAction: _publishPost,
                actionEnabled:
                    (_contentController.text.trim().isNotEmpty ||
                        _mediaUrl.isNotEmpty) &&
                    !_isPublishing,
              );
            },
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAvatar(
                    name: name,
                    radius: 27,
                    color: AppColors.darkBlue,
                    badge: role,
                    imageUrl: profile?.avatarUrl,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _pickVisibility,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _contentController,
                minLines: 4,
                maxLines: 12,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: 'بماذا تريد أن تتحدث؟',
                  hintStyle: TextStyle(
                    fontSize: 21,
                    color: context.appMuted.withValues(alpha: .58),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (_mediaUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.55,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: MediaPreview(
                          mediaUrl: _mediaUrl,
                          mediaType: _mediaType,
                          fallbackLabel: _mediaType == 'reel' ? 'ريل' : 'صورة',
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: .55),
                        child: IconButton(
                          onPressed: _removeMedia,
                          icon: const Icon(Icons.close, color: Colors.white),
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
        _ComposerOptionsPanel(
          options: _optionsFor(accountType),
          onSelected: (option) => _handleOption(context, option, accountType),
        ),
      ],
    ),
    );
  }
}

class _ComposerOptionsPanel extends StatelessWidget {
  const _ComposerOptionsPanel({
    required this.options,
    required this.onSelected,
  });

  final List<_ComposerOption> options;
  final ValueChanged<_ComposerOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border.all(color: context.appBorder),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          for (final option in options)
            ListTile(
              leading: Icon(option.icon, color: context.appMuted),
              title: Text(
                option.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => onSelected(option),
            ),
        ],
      ),
    );
  }
}

final class _ComposerOption {
  const _ComposerOption(this.icon, this.label, this.action);

  final IconData icon;
  final String label;
  final _ComposerAction action;
}

enum _ComposerAction { photo, reel, project, job }
