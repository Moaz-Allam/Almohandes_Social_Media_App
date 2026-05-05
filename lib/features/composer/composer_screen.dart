import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_avatar.dart';

class ComposerScreen extends StatelessWidget {
  const ComposerScreen({super.key, required this.onClose});

  final VoidCallback onClose;

  static const _options = [
    _ComposerOption(Icons.image_outlined, 'إضافة صورة'),
    _ComposerOption(Icons.videocam_outlined, 'تصوير فيديو'),
    _ComposerOption(Icons.celebration_outlined, 'الاحتفال بمناسبة'),
    _ComposerOption(Icons.description_outlined, 'إضافة مستند'),
    _ComposerOption(Icons.work_outline, 'مشاركة أنك توظف'),
    _ComposerOption(Icons.badge_outlined, 'العثور على خبير'),
    _ComposerOption(Icons.poll_outlined, 'إنشاء استطلاع'),
    _ComposerOption(Icons.event_available_outlined, 'إنشاء حدث'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: 'إغلاق',
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'مشاركة منشور',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'نشر',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppAvatar(
                    name: 'ريم حسن',
                    radius: 27,
                    color: AppColors.darkBlue,
                    badge: 'يوظف',
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ريم حسن',
                        style: TextStyle(
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
              const TextField(
                minLines: 4,
                maxLines: 8,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: 'بماذا تريد أن تتحدث؟',
                  hintStyle: TextStyle(fontSize: 21, color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .04),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
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
                    for (final option in _options)
                      ListTile(
                        leading: Icon(option.icon, color: AppColors.muted),
                        title: Text(
                          option.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {},
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _ComposerOption {
  const _ComposerOption(this.icon, this.label);

  final IconData icon;
  final String label;
}
