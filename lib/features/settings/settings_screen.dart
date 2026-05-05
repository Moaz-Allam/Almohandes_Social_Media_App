import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/settings_item.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _sections = [
    SettingsItem(
      icon: Icons.account_circle_outlined,
      title: 'تفضيلات الحساب',
      subtitle: 'خيارات إدارة حسابك وتجربتك على لينكدإن',
    ),
    SettingsItem(
      icon: Icons.lock_outline,
      title: 'تسجيل الدخول والأمان',
      subtitle: 'التحكم في تسجيل الدخول والحفاظ على أمان الحساب',
    ),
    SettingsItem(
      icon: Icons.visibility_outlined,
      title: 'الظهور',
      subtitle: 'تحكم في من يرى نشاطك ومعلوماتك على لينكدإن',
    ),
    SettingsItem(
      icon: Icons.mail_outline,
      title: 'التواصل',
      subtitle: 'إعدادات البريد والدعوات والإشعارات',
    ),
    SettingsItem(
      icon: Icons.shield_outlined,
      title: 'خصوصية البيانات',
      subtitle: 'تحكم في كيفية استخدام لينكدإن لبياناتك العامة والوظيفية',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 58,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.border)),
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
                    onPressed: () {},
                    icon: const Icon(Icons.help),
                    tooltip: 'مساعدة',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _sections.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final section = _sections[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    leading: Icon(section.icon, color: AppColors.muted),
                    title: Text(
                      section.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      section.subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14.5,
                        height: 1.25,
                      ),
                    ),
                    onTap: () {},
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
