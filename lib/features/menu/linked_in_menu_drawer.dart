import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/notification_item_model.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../state/app_scope.dart';
import '../messages/messages_screen.dart';
import '../notifications/notifications_screen.dart';
import '../auth/phone_login_screen.dart';
import '../premium/premium_dashboard_screen.dart';
import '../premium/premium_access_screen.dart';
import '../profile/profile_screen.dart';
import '../saved/saved_items_screen.dart';

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
    final app = AppScope.read(context);
    await navigator.maybePop();
    if (!navigator.mounted) {
      return;
    }
    navigator.push(
      MaterialPageRoute(
        builder: (_) => app.canAccessPremiumDashboard
            ? const PremiumDashboardScreen()
            : const PremiumAccessScreen(),
      ),
    );
  }

  Future<void> _openSavedItems(BuildContext context) async {
    final navigator = Navigator.of(context);
    await navigator.maybePop();
    navigator.push(MaterialPageRoute(builder: (_) => const SavedItemsScreen()));
  }

  Future<void> _signOut(BuildContext context) async {
    await AppScope.read(context).signOut();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final profile = controller.profile;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : 'المستخدم';
    final role = profile?.role.isNotEmpty == true ? profile!.role : null;

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppAvatar(
                      name: name,
                      radius: 30,
                      color: AppColors.darkBlue,
                      badge: role,
                      imageUrl: profile?.avatarUrl,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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
            // The premium dashboard entry is only relevant to admins (full
            // access) and engineers (who may need to subscribe). Every other
            // account type never sees it.
            if (controller.isEngineer || controller.isAdmin) ...[
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
                  controller.canAccessPremiumDashboard
                      ? 'لوحة Premium'
                      : 'الوصول إلى Premium',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onTap: () => _openPremiumDashboard(context),
              ),
              Divider(height: 1, color: context.appBorder),
            ],
            ListTile(
              leading: const Icon(
                Icons.bookmark_outline,
                color: AppColors.muted,
              ),
              title: const Text(
                'المحفوظات',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.blue),
              onTap: () => _openSavedItems(context),
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
            _SidebarNotificationsList(
              future: controller.repositories.notifications
                  .fetchNotifications(),
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

class _SidebarNotificationsList extends StatelessWidget {
  const _SidebarNotificationsList({required this.future});

  final Future<List<NotificationItemModel>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NotificationItemModel>>(
      future: future,
      builder: (context, snapshot) {
        final items = (snapshot.data ?? const <NotificationItemModel>[])
            .take(4)
            .toList();
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              'جاري تحميل الإشعارات...',
              style: TextStyle(color: AppColors.muted),
            ),
          );
        }
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Text(
              'لا توجد إشعارات بعد',
              style: TextStyle(color: AppColors.muted),
            ),
          );
        }
        return Column(
          children: [
            for (final item in items)
              _SidebarNotification(
                icon: item.unread
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none,
                text: item.title,
                time: item.time,
              ),
          ],
        );
      },
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
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.blue,
        size: 18,
      ),
      onTap: () {},
    );
  }
}
