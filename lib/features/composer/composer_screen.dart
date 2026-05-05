import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/account_type.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../state/app_scope.dart';
import 'project_form_screen.dart';
import 'widgets/composer_top_bar.dart';

class ComposerScreen extends StatelessWidget {
  const ComposerScreen({super.key, required this.onClose});

  final VoidCallback onClose;

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

  List<_ComposerOption> _optionsFor(AccountType accountType) {
    return [
      for (final option in _allOptions)
        if (option.action != _ComposerAction.project ||
            accountType.canPostProjects)
          option,
    ];
  }

  void _handleOption(
    BuildContext context,
    _ComposerOption option,
    AccountType accountType,
  ) {
    switch (option.action) {
      case _ComposerAction.photo:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم اختيار إضافة صورة')));
        return;
      case _ComposerAction.reel:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم اختيار إضافة ريل')));
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
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProjectFormScreen()));
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountType = accountTypeFromProfile(AppScope.watch(context).profile);

    return Column(
      children: [
        ComposerTopBar(title: 'مشاركة منشور', onClose: onClose),
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
                maxLines: 12,
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
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
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
              leading: Icon(option.icon, color: AppColors.muted),
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
