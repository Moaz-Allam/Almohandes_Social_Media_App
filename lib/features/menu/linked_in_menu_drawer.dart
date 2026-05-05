import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../state/app_scope.dart';
import '../messages/messages_screen.dart';
import '../notifications/notifications_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../premium/premium_dashboard_screen.dart';
import '../profile/profile_screen.dart';

class LinkedInMenuDrawer extends StatelessWidget {
  const LinkedInMenuDrawer({super.key, required this.onSettings});

  final VoidCallback onSettings;

  Future<void> _openMyProfile(BuildContext context) async {
    final navigator = Navigator.of(context);
    await navigator.maybePop();
    navigator.push(MaterialPageRoute(builder: (_) => const ProfileScreen.me()));
  }

  Future<void> _openAllNotifications(BuildContext context) async {
    final navigator = Navigator.of(context);
    await navigator.maybePop();
    navigator.push(
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          body: NotificationsScreen(
            onMenu: () => Navigator.of(routeContext).maybePop(),
            onMessages: () {
              Navigator.of(
                routeContext,
              ).push(MaterialPageRoute(builder: (_) => const MessagesScreen()));
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openPremiumDashboard(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final app = AppScope.read(context);
    final wasUnlocked = app.hasPremiumLibrary;

    app.unlockPremiumLibrary();
    await navigator.maybePop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            wasUnlocked ? 'تم فتح لوحة Premium' : 'تم تفعيل Premium بنجاح',
          ),
          duration: const Duration(milliseconds: 900),
        ),
      );
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!navigator.mounted) {
      return;
    }
    navigator.push(
      MaterialPageRoute(builder: (_) => const PremiumDashboardScreen()),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await AppScope.read(context).signOut();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);

    return Drawer(
      width: 304,
      backgroundColor: context.appSurface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            InkWell(
              onTap: () => _openMyProfile(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppAvatar(
                      name: 'ريم حسن',
                      radius: 30,
                      color: AppColors.darkBlue,
                      badge: 'يوظف',
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ريم حسن',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'عرض الملف · الإعدادات',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 13,
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
            ),
            Divider(height: 1, color: context.appBorder),
            ListTile(
              leading: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              title: Text(
                controller.hasPremiumLibrary
                    ? 'لوحة Premium'
                    : 'الوصول إلى Premium',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onTap: () => _openPremiumDashboard(context),
            ),
            Divider(height: 1, color: context.appBorder),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'آخر الإشعارات',
                style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            const _SidebarNotification(
              icon: Icons.person_add_alt,
              text: 'لديك 5 دعوات تواصل جديدة',
              time: 'الآن',
            ),
            const _SidebarNotification(
              icon: Icons.thumb_up_alt_outlined,
              text: 'أحمد تفاعل مع منشورك',
              time: 'قبل 12 دقيقة',
            ),
            const _SidebarNotification(
              icon: Icons.work_outline,
              text: 'مشروع جديد يناسب مهاراتك',
              time: 'قبل ساعة',
            ),
            const _SidebarNotification(
              icon: Icons.smart_display_outlined,
              text: 'ريل جديد من ريم حسن',
              time: 'اليوم',
            ),
            Divider(height: 1, color: context.appBorder),
            ListTile(
              title: const Text(
                'عرض كل الإشعارات',
                style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.blue),
              onTap: () => _openAllNotifications(context),
            ),
            Divider(height: 1, color: context.appBorder),
            ListTile(
              leading: const Icon(
                Icons.settings_outlined,
                color: AppColors.muted,
              ),
              title: const Text(
                'الإعدادات',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              onTap: () {
                Navigator.of(context).maybePop();
                onSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.muted),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNotification extends StatelessWidget {
  const _SidebarNotification({
    required this.icon,
    required this.text,
    required this.time,
  });

  final IconData icon;
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: context.appMuted, size: 22),
      title: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        time,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.appMuted, fontSize: 12),
      ),
      onTap: () {},
    );
  }
}
