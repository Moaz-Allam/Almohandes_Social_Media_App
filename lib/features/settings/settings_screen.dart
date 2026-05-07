import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/settings_item.dart';
import '../../state/app_scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _sections = [
    SettingsItem(
      icon: Icons.account_circle_outlined,
      title: 'تفضيلات الحساب',
      subtitle: 'خيارات إدارة حسابك وتجربتك على المهندس',
    ),
    SettingsItem(
      icon: Icons.lock_outline,
      title: 'تسجيل الدخول والأمان',
      subtitle: 'التحكم في تسجيل الدخول والحفاظ على أمان الحساب',
    ),
    SettingsItem(
      icon: Icons.visibility_outlined,
      title: 'الظهور',
      subtitle: 'تحكم في من يرى نشاطك ومساهماتك على المهندس',
    ),
    SettingsItem(
      icon: Icons.mail_outline,
      title: 'التواصل',
      subtitle: 'إعدادات البريد والدعوات والإشعارات',
    ),
    SettingsItem(
      icon: Icons.shield_outlined,
      title: 'خصوصية البيانات',
      subtitle: 'تحكم في كيفية استخدام المهندس لبياناتك ومساهماتك',
    ),
  ];

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مساعدة'),
        content: const Text(
          'للدعم، افتح تذكرة من لوحة Supabase أو تواصل مع فريق إدارة منصة المهندس.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _openSection(BuildContext context, SettingsItem section) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(section.icon, color: AppColors.blue, size: 34),
              const SizedBox(height: 12),
              Text(
                section.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                section.subtitle,
                style: TextStyle(color: context.appMuted, height: 1.45),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('تم'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 58,
              decoration: BoxDecoration(
                color: context.appSurface,
                border: Border(bottom: BorderSide(color: context.appBorder)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'رجوع',
                  ),
                  const Expanded(
                    child: Text(
                      'الإعدادات',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showHelp(context),
                    icon: const Icon(Icons.help),
                    tooltip: 'مساعدة',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _sections.length + 1,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: context.appBorder),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      secondary: Icon(
                        controller.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode_outlined,
                        color: AppColors.blue,
                      ),
                      title: const Text(
                        'الوضع الداكن',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        controller.isDarkMode
                            ? 'التطبيق يستخدم ألوانا داكنة'
                            : 'فعّل تجربة مريحة في الإضاءة المنخفضة',
                        style: TextStyle(
                          color: context.appMuted,
                          fontSize: 14.5,
                          height: 1.25,
                        ),
                      ),
                      value: controller.isDarkMode,
                      activeThumbColor: AppColors.blue,
                      onChanged: controller.setDarkMode,
                    );
                  }
                  final section = _sections[index - 1];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    leading: Icon(section.icon, color: context.appMuted),
                    title: Text(
                      section.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      section.subtitle,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 14.5,
                        height: 1.25,
                      ),
                    ),
                    onTap: () => _openSection(context, section),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
