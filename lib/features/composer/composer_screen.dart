import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/account_type.dart';
import '../../models/app_tab.dart';
import '../../shared/errors/user_error_message.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/media_preview.dart';
import '../../state/app_scope.dart';
import 'project_form_screen.dart';
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
  String _mediaUrl = '';
  String _mediaType = 'text';
  String _mediaName = '';

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
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  List<_ComposerOption> _optionsFor(AccountType accountType) {
    return [
      for (final option in _allOptions)
        if (option.action != _ComposerAction.project ||
            accountType.canPostProjects)
          option,
    ];
  }

  Future<void> _publishPost() async {
    final content = _contentController.text.trim();
    if ((content.isEmpty && _mediaUrl.isEmpty) || _isPublishing) {
      return;
    }
    setState(() => _isPublishing = true);
    final repositories = AppScope.read(context).repositories;
    try {
      if (_mediaType == 'reel') {
        await repositories.reels.createReel(
          caption: content,
          videoUrl: _mediaUrl,
        );
      } else {
        await repositories.feed.createPost(
          content: content,
          mediaUrl: _mediaUrl,
          mediaType: _mediaType,
        );
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mediaType == 'reel' ? 'تم نشر الريل' : 'تم النشر بنجاح',
          ),
        ),
      );
      if (_mediaType == 'reel') {
        AppScope.read(context).selectTab(AppTab.reels);
      } else {
        widget.onClose();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userErrorMessage(error, fallback: 'تعذر نشر المحتوى الآن'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  Future<void> _pickMedia(_ComposerAction action) async {
    final XFile? picked;
    final List<int> bytes;
    final String mimeType;
    final String mediaName;
    try {
      final picker = ImagePicker();
      picked = action == _ComposerAction.photo
          ? await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1400,
              imageQuality: 82,
            )
          : await picker.pickVideo(source: ImageSource.gallery);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userErrorMessage(error, fallback: 'تعذر اختيار الملف الآن'),
          ),
        ),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _mediaUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
      _mediaType = action == _ComposerAction.photo ? 'image' : 'reel';
      _mediaName = mediaName;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action == _ComposerAction.photo
              ? 'تمت إضافة الصورة'
              : 'تمت إضافة الفيديو',
        ),
      ),
    );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('مشاركة المشاريع متاحة للمهندسين والشركات فقط'),
            ),
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

    return Column(
      children: [
        ComposerTopBar(
          title: 'مشاركة منشور',
          onClose: widget.onClose,
          onAction: _publishPost,
          actionEnabled:
              (_contentController.text.trim().isNotEmpty ||
                  _mediaUrl.isNotEmpty) &&
              !_isPublishing,
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
                      Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.muted),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.public,
                              size: 16,
                              color: AppColors.muted,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'أي شخص',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_drop_down, color: AppColors.muted),
                          ],
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
                onChanged: (_) => setState(() {}),
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

enum _ComposerAction { photo, reel, project }
