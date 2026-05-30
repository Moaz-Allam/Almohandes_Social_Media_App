import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/phone_login_screen.dart';
import '../../models/app_theme_mode.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/privacy/privacy_policy_dialog.dart';
import '../../state/app_scope.dart';
import '../applications/my_applications_screen.dart';
import '../saved/saved_items_screen.dart';
import 'my_posts_manager_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final Uri _whatsAppSupportUri = Uri.parse(
    'https://wa.me/9647800000000',
  );

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مساعدة'),
        content: const Text(
          'للدعم، افتح تذكرة من لوحة الإدارة أو تواصل مع فريق الدعم.',
        ),
        actions: [
          TextButton(
            onPressed: () => launchUrl(
              _whatsAppSupportUri,
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('واتساب +964 780 000 0000'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text(
          'سيتم حذف ملفك الشخصي وتسجيل خروجك من التطبيق. هل تريد المتابعة؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await AppScope.read(context).deleteAccount();
      if (!context.mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Account deleted'),
          content: const Text(
            'Your account and related app data were deleted. You will now return to onboarding.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      AppSnack.error(context, error, fallback: 'تعذر حذف الحساب الآن');
    }
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
                itemCount: 7,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: context.appBorder),
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return _ThemeSelectionTile(
                        themeMode: controller.themeMode,
                        onChanged: controller.setThemeMode,
                      );
                    case 1:
                      return _PrivateProfileTile(
                        isPrivate: controller.isProfilePrivate,
                        onChanged: controller.setProfilePrivate,
                      );
                    case 2:
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        leading: const Icon(
                          Icons.bookmark_outline_rounded,
                          color: AppColors.blue,
                        ),
                        title: const Text(
                          'المحفوظات',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          'المنشورات والعناصر التي حفظتها',
                          style: TextStyle(
                            color: context.appMuted,
                            fontSize: 14.5,
                            height: 1.25,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SavedItemsScreen(),
                          ),
                        ),
                      );
                    case 3:
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        leading: const Icon(
                          Icons.assignment_turned_in_outlined,
                          color: AppColors.blue,
                        ),
                        title: const Text(
                          'تقديماتي',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          'تابع حالة المشاريع والوظائف التي قدّمت عليها',
                          style: TextStyle(
                            color: context.appMuted,
                            fontSize: 14.5,
                            height: 1.25,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MyApplicationsScreen(),
                          ),
                        ),
                      );
                    case 4:
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        leading: const Icon(
                          Icons.delete_sweep_outlined,
                          color: AppColors.blue,
                        ),
                        title: const Text(
                          'حذف منشوراتي',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          'استعرض كل ما نشرته واحذف منشوراً أو عدة منشورات دفعة واحدة',
                          style: TextStyle(
                            color: context.appMuted,
                            fontSize: 14.5,
                            height: 1.25,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MyPostsManagerScreen(),
                          ),
                        ),
                      );
                    case 5:
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        leading: const Icon(
                          Icons.privacy_tip_outlined,
                          color: AppColors.blue,
                        ),
                        title: const Text(
                          'سياسة الخصوصية',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          'راجع كيفية استخدام بياناتك داخل التطبيق',
                          style: TextStyle(
                            color: context.appMuted,
                            fontSize: 14.5,
                            height: 1.25,
                          ),
                        ),
                        onTap: () => showPrivacyPolicyDialog(context),
                      );
                    case 6:
                    default:
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        leading: const Icon(
                          Icons.delete_forever_outlined,
                          color: Colors.redAccent,
                        ),
                        title: const Text(
                          'حذف الحساب',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          'حذف الملف الشخصي وتسجيل الخروج من التطبيق',
                          style: TextStyle(
                            color: context.appMuted,
                            fontSize: 14.5,
                            height: 1.25,
                          ),
                        ),
                        onTap: () => _deleteAccount(context),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelectionTile extends StatelessWidget {
  const _ThemeSelectionTile({
    required this.themeMode,
    required this.onChanged,
  });

  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onChanged;

  String _subtitleFor(BuildContext context) {
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    return switch (themeMode) {
      AppThemeMode.system =>
        platformBrightness == Brightness.dark
            ? 'تابع إعدادات النظام · حاليا داكن'
            : 'تابع إعدادات النظام · حاليا فاتح',
      AppThemeMode.light => 'التطبيق يستخدم الوضع الفاتح',
      AppThemeMode.dark => 'التطبيق يستخدم الوضع الداكن',
    };
  }

  IconData _iconFor() {
    return switch (themeMode) {
      AppThemeMode.system => Icons.brightness_auto,
      AppThemeMode.light => Icons.light_mode_outlined,
      AppThemeMode.dark => Icons.dark_mode,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_iconFor(), color: AppColors.blue),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مظهر التطبيق',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitleFor(context),
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 13.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<AppThemeMode>(
            segments: const [
              ButtonSegment(
                value: AppThemeMode.system,
                label: Text('تلقائي'),
                icon: Icon(Icons.brightness_auto, size: 18),
              ),
              ButtonSegment(
                value: AppThemeMode.light,
                label: Text('فاتح'),
                icon: Icon(Icons.light_mode_outlined, size: 18),
              ),
              ButtonSegment(
                value: AppThemeMode.dark,
                label: Text('داكن'),
                icon: Icon(Icons.dark_mode, size: 18),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) {
                onChanged(selection.first);
              }
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.blue;
                }
                return null;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return null;
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateProfileTile extends StatelessWidget {
  const _PrivateProfileTile({
    required this.isPrivate,
    required this.onChanged,
  });

  final bool isPrivate;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: isPrivate,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      activeColor: AppColors.blue,
      secondary: Icon(
        isPrivate ? Icons.lock : Icons.lock_open_outlined,
        color: AppColors.blue,
      ),
      title: const Text(
        'ملف خاص',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        isPrivate
            ? 'يرى غير المتصلين الاسم والصورة والنبذة فقط'
            : 'ملفك مرئي بالكامل لأي مستخدم على المنصة',
        style: TextStyle(color: context.appMuted, height: 1.35),
      ),
    );
  }
}
