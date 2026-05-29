import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mappers/supabase_enum_mapper.dart';
import '../../data/storage/media_upload_service.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_snack.dart';
import '../../state/app_scope.dart';

/// Lets the signed-in user edit their profile: photo, cover, display name,
/// governorate, skills, and bio. Role is set at signup and shown read-only.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _skillInput = TextEditingController();
  String? _governorate;
  final List<String> _skills = [];
  bool _initialized = false;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _uploadingCover = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final profile = AppScope.read(context).profile;
    _name.text = profile?.fullName ?? '';
    _bio.text = profile?.about ?? '';
    final location = profile?.location.trim() ?? '';
    _governorate = iraqiGovernorates.contains(location) ? location : null;
    _skills
      ..clear()
      ..addAll(profile?.skills ?? const <String>{});
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _skillInput.dispose();
    super.dispose();
  }

  void _addSkill() {
    final value = _skillInput.text.trim();
    if (value.isEmpty) {
      return;
    }
    // Case-insensitive de-dupe so "حدادة" and " حدادة " don't both land.
    final exists = _skills.any(
      (s) => s.toLowerCase() == value.toLowerCase(),
    );
    setState(() {
      if (!exists) {
        _skills.add(value);
      }
      _skillInput.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  Future<void> _changeImage({required bool isAvatar}) async {
    if (_uploadingAvatar || _uploadingCover) {
      return;
    }
    final app = AppScope.read(context);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: isAvatar ? 640 : 1280,
        imageQuality: 70,
      );
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        if (isAvatar) {
          _uploadingAvatar = true;
        } else {
          _uploadingCover = true;
        }
      });
      final url = await app.repositories.media.uploadBytes(
        bucket: isAvatar ? MediaBucket.avatars : MediaBucket.covers,
        bytes: bytes,
        fileName: picked.name,
        mimeType: picked.mimeType ?? 'image/jpeg',
      );
      if (isAvatar) {
        await app.updateMyAvatar(url);
      } else {
        await app.updateMyCover(url);
      }
    } catch (error) {
      if (mounted) {
        AppSnack.error(context, error, fallback: 'تعذر تحديث الصورة الآن');
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingAvatar = false;
          _uploadingCover = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    // Commit any half-typed skill before saving so it isn't silently dropped.
    if (_skillInput.text.trim().isNotEmpty) {
      _addSkill();
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);
    final app = AppScope.read(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await app.updateMyProfileDetails(
        fullName: _name.text.trim(),
        governorate: _governorate,
        skills: List<String>.from(_skills),
        about: _bio.text.trim(),
      );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('تم حفظ التغييرات')),
      );
      navigator.maybePop();
    } catch (error) {
      if (mounted) {
        AppSnack.error(context, error, fallback: 'تعذر حفظ التغييرات الآن');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.watch(context).profile;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : 'ملفي الشخصي';

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text(
          'تعديل الملف الشخصي',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Cover + avatar.
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _changeImage(isAvatar: false),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.appSurfaceAlt,
                    image: (profile?.coverUrl?.isNotEmpty ?? false)
                        ? DecorationImage(
                            image: NetworkImage(profile!.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: _uploadingCover
                      ? const CircularProgressIndicator()
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_camera_outlined,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'تغيير الغلاف',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              PositionedDirectional(
                bottom: -44,
                start: 20,
                child: GestureDetector(
                  onTap: () => _changeImage(isAvatar: true),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: context.appBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AppAvatar(
                          name: name,
                          radius: 46,
                          color: context.appPrimary,
                          imageUrl: profile?.avatarUrl,
                        ),
                        if (_uploadingAvatar)
                          const CircularProgressIndicator()
                        else
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: context.appPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.appBackground,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.photo_camera_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 56),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile?.role.isNotEmpty ?? false) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: context.appSurfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profile!.role,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                _SectionLabel(text: 'الاسم'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    hintText: 'الاسم الكامل',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 2) {
                      return 'يرجى كتابة اسم صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _SectionLabel(text: 'المحافظة'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _governorate,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'اختر المحافظة',
                  ),
                  items: [
                    for (final gov in iraqiGovernorates)
                      DropdownMenuItem(value: gov, child: Text(gov)),
                  ],
                  onChanged: (value) => setState(() => _governorate = value),
                ),
                const SizedBox(height: 20),
                _SectionLabel(text: 'المهارات'),
                const SizedBox(height: 8),
                TextField(
                  controller: _skillInput,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.rtl,
                  onSubmitted: (_) => _addSkill(),
                  decoration: InputDecoration(
                    hintText: 'أضف مهارة ثم اضغط +',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addSkill,
                      tooltip: 'إضافة مهارة',
                    ),
                  ),
                ),
                if (_skills.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final skill in _skills)
                        Chip(
                          label: Text(skill),
                          onDeleted: () => _removeSkill(skill),
                          deleteIcon: const Icon(Icons.close, size: 18),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                _SectionLabel(text: 'نبذة'),
                const SizedBox(height: 8),
                TextField(
                  controller: _bio,
                  maxLines: 5,
                  minLines: 3,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    hintText: 'اكتب نبذة عنك...',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.appPrimary,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'حفظ التغييرات',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.appText,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
