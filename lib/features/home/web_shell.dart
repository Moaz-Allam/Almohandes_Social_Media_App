import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/layout_breakpoints.dart';
import '../../models/app_tab.dart';
import '../../models/message_item.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/linkedin_logo.dart';
import '../../state/app_scope.dart';
import '../feed/home_feed_screen.dart';
import '../messages/messages_screen.dart';
import '../network/network_screen.dart';
import '../../models/notification_item_model.dart';
import '../premium/premium_access_screen.dart';
import '../premium/premium_dashboard_screen.dart';
import '../profile/profile_connections_screen.dart';
import '../profile/profile_screen.dart';
import '../projects/projects_screen.dart';
import '../reels/reels_screen.dart';
import '../saved/saved_items_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

/// LinkedIn-style web/desktop layout.
class WebShell extends StatefulWidget {
  const WebShell({super.key});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _openMessages() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessagesScreen()));
  }

  void _openProfile() {
    AppScope.read(context).selectTab(AppTab.profile);
  }

  void _openSearch() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
  }

  void _openSavedItems() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedItemsScreen()));
  }

  Future<void> _signOut() async {
    await AppScope.read(context).signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _noOpMenu() {}

  Widget _bodyFor(AppTab tab) {
    return switch (tab) {
      AppTab.feed => HomeFeedScreen(
        onMenu: _noOpMenu,
        onMessages: _openMessages,
      ),
      AppTab.search => NetworkScreen(
        onMenu: _noOpMenu,
        onMessages: _openMessages,
      ),
      AppTab.reels => ReelsScreen(
        onMenu: _noOpMenu,
        onMessages: _openMessages,
      ),
      AppTab.dashboard => const PremiumDashboardScreen(),
      AppTab.profile => const ProfileScreen.me(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final showRightRail = LayoutBreakpoints.showRightRail(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBackground = isDark ? const Color(0xFF000000) : const Color(0xFFF4F2EE);

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _WebTopBar(
              selectedTab: controller.selectedTab,
              onChangeTab: controller.selectTab,
              onOpenMessages: _openMessages,
              onOpenProfile: _openProfile,
              onOpenSettings: _openSettings,
              onSignOut: _signOut,
              onOpenSearch: _openSearch,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1184),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 224,
                          child: _WebLeftRail(
                            onOpenProfile: _openProfile,
                            onOpenConnections: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProfileConnectionsScreen()),
                            ),
                            onOpenSavedItems: _openSavedItems,
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 580),
                            child: Container(
                              color: pageBackground,
                              child: _bodyFor(controller.selectedTab),
                            ),
                          ),
                        ),
                        if (showRightRail) ...[
                          const SizedBox(width: 22),
                          const SizedBox(width: 280, child: _WebRightRail()),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebTopBar extends StatelessWidget {
  const _WebTopBar({
    required this.selectedTab,
    required this.onChangeTab,
    required this.onOpenMessages,
    required this.onOpenProfile,
    required this.onOpenSettings,
    required this.onSignOut,
    required this.onOpenSearch,
  });

  final AppTab selectedTab;
  final ValueChanged<AppTab> onChangeTab;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSettings;
  final Future<void> Function() onSignOut;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.watch(context).profile;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: SizedBox(
        height: 56,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1184),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const LinkedInLogo(scale: .8),
                  const SizedBox(width: 10),
                  Expanded(child: _SearchField(onTap: onOpenSearch)),
                  const SizedBox(width: 12),
                  _WebNavItem(
                    icon: Icons.home_filled,
                    label: 'الرئيسية',
                    selected: selectedTab == AppTab.feed,
                    onPressed: () => onChangeTab(AppTab.feed),
                  ),
                  _WebNavItem(
                    icon: Icons.search,
                    label: 'البحث',
                    selected: selectedTab == AppTab.search,
                    onPressed: () => onChangeTab(AppTab.search),
                  ),
                  _WebNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'لوحة التحكم',
                    selected: selectedTab == AppTab.dashboard,
                    onPressed: () => onChangeTab(AppTab.dashboard),
                  ),
                  _WebNavItem(
                    icon: Icons.movie_filter_outlined,
                    label: 'reels',
                    selected: selectedTab == AppTab.reels,
                    onPressed: () => onChangeTab(AppTab.reels),
                  ),
                  _MessagesNavItem(onPressed: onOpenMessages),
                  const VerticalDivider(width: 24, indent: 12, endIndent: 12),
                  _ProfileNavItem(
                    profileName: profile?.fullName ?? '',
                    avatarUrl: profile?.avatarUrl,
                    onOpenProfile: onOpenProfile,
                    onOpenSettings: onOpenSettings,
                    onSignOut: onSignOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Material(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: context.appMuted),
                const SizedBox(width: 8),
                Text('بحث', style: TextStyle(color: context.appMuted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebNavItem extends StatelessWidget {
  const _WebNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.appText : context.appMuted;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2,
                width: double.infinity,
                color: selected ? context.appText : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesNavItem extends StatefulWidget {
  const _MessagesNavItem({required this.onPressed});
  final VoidCallback onPressed;
  @override
  State<_MessagesNavItem> createState() => _MessagesNavItemState();
}

class _MessagesNavItemState extends State<_MessagesNavItem> {
  Future<List<MessageItem>>? _future;
  int? _lastVersion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.watch(context);
    if (_future == null || _lastVersion != controller.messageStateVersion) {
      _lastVersion = controller.messageStateVersion;
      _future = controller.repositories.messages.fetchConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MessageItem>>(
      future: _future,
      builder: (context, snapshot) {
        final unread = (snapshot.data ?? []).fold<int>(0, (sum, item) => sum + (item.unreadCount > 0 ? item.unreadCount : 0));
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _WebNavItem(icon: Icons.chat_bubble, label: 'الرسائل', selected: false, onPressed: widget.onPressed),
            if (unread > 0) const PositionedDirectional(top: 4, end: 12, child: _UnreadBadge()),
          ],
        );
      },
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge();
  @override
  Widget build(BuildContext context) {
    return Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle));
  }
}

class _ProfileNavItem extends StatelessWidget {
  const _ProfileNavItem({
    required this.profileName,
    required this.avatarUrl,
    required this.onOpenProfile,
    required this.onOpenSettings,
    required this.onSignOut,
  });

  final String profileName;
  final String? avatarUrl;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSettings;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'حسابي',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      onSelected: (value) async {
        switch (value) {
          case 'profile': onOpenProfile();
          case 'settings': onOpenSettings();
          case 'signout': await onSignOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: AppAvatar(name: profileName.isEmpty ? 'أنا' : profileName, radius: 18, color: AppColors.darkBlue, imageUrl: avatarUrl),
            title: Text(profileName.isEmpty ? 'ملفي الشخصي' : profileName, style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: const Text('عرض الملف الشخصي'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'settings', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.settings_outlined), title: Text('الإعدادات'))),
        const PopupMenuItem(value: 'signout', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.logout, color: Colors.redAccent), title: Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent)))),
      ],
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            AppAvatar(name: profileName.isEmpty ? 'أنا' : profileName, radius: 12, color: AppColors.darkBlue, imageUrl: avatarUrl),
            const SizedBox(height: 2),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('أنا', style: TextStyle(color: context.appMuted, fontSize: 12, fontWeight: FontWeight.w800)), Icon(Icons.arrow_drop_down, color: context.appMuted, size: 18)]),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _WebLeftRail extends StatelessWidget {
  const _WebLeftRail({required this.onOpenProfile, required this.onOpenConnections, required this.onOpenSavedItems});
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenConnections;
  final VoidCallback onOpenSavedItems;

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.watch(context).profile;
    final name = (profile?.fullName.isNotEmpty ?? false) ? profile!.fullName : 'ملفي الشخصي';
    final headline = profile == null || profile.headline.isEmpty ? 'استكمل ملفك الشخصي' : profile.headline;
    return Column(
      children: [
        _RailCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SizedBox(height: 56, child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.darkBlue.withValues(alpha: .9), AppColors.blue.withValues(alpha: .8)])))),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Column(
                  children: [
                    AppAvatar(name: name, radius: 30, color: AppColors.darkBlue, imageUrl: profile?.avatarUrl),
                    const SizedBox(height: 8),
                    InkWell(onTap: onOpenProfile, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(children: [Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.appText, fontWeight: FontWeight.w900, fontSize: 15)), const SizedBox(height: 4), Text(headline, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.appMuted, fontSize: 12, height: 1.35))]))),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: context.appBorder),
                    _RailStat(label: 'مشاهدات الملف', value: '${profile?.followersCount ?? 0}'),
                    _RailStat(label: 'اتصالات', value: '${profile?.followingCount ?? 0}', onTap: onOpenConnections),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _RailCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_RailLinkRow(icon: Icons.bookmark_outline, label: 'العناصر المحفوظة', onTap: onOpenSavedItems), const SizedBox(height: 6), _RailLinkRow(icon: Icons.people_alt_outlined, label: 'الاتصالات والمتابعون', onTap: onOpenConnections)])),
      ],
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: context.appSurface, border: Border.all(color: context.appBorder), borderRadius: BorderRadius.circular(10)), clipBehavior: Clip.antiAlias, padding: padding ?? const EdgeInsets.all(14), child: child);
  }
}

class _RailStat extends StatelessWidget {
  const _RailStat({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: context.appMuted, fontSize: 12.5)), Text(value, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w900))])));
  }
}

class _RailLinkRow extends StatelessWidget {
  const _RailLinkRow({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Icon(icon, color: context.appText, size: 18), const SizedBox(width: 10), Expanded(child: Text(label, style: TextStyle(color: context.appText, fontWeight: FontWeight.w900, fontSize: 13)))])));
  }
}

class _WebRightRail extends StatelessWidget {
  const _WebRightRail();
  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_PremiumRailCard(isPremium: controller.hasPremiumLibrary, onOpen: () { Navigator.of(context).push(MaterialPageRoute(builder: (_) => controller.hasPremiumLibrary ? const PremiumDashboardScreen() : const PremiumAccessScreen())); }), const SizedBox(height: 8), const _RecentNotificationsCard()]);
  }
}

class _PremiumRailCard extends StatelessWidget {
  const _PremiumRailCard({required this.isPremium, required this.onOpen});
  final bool isPremium;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? const LinearGradient(colors: [Color(0xFF1B1B1B), Color(0xFF0C2240)]) : const LinearGradient(colors: [Color(0xFFFFF7DC), Color(0xFFFFE9A8)]);
    final borderColor = isDark ? const Color(0xFFB68A2C) : const Color(0xFFD7A93C);
    return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor), gradient: gradient), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: isDark ? const Color(0xFFB68A2C).withValues(alpha: .25) : const Color(0xFFFFDB85), border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.workspace_premium, color: isDark ? const Color(0xFFE6BE5C) : const Color(0xFF8A5A00))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('المهندس Premium', style: TextStyle(color: isDark ? const Color(0xFFFFE7A6) : const Color(0xFF5C3A00), fontWeight: FontWeight.w900, fontSize: 15)), const SizedBox(height: 2), Text('لوحة تحكم خاصة، مكتبة دورات، AI مساعد المهندس', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF7A5A1E), fontSize: 12, height: 1.35))]))]), const SizedBox(height: 14), SizedBox(width: double.infinity, height: 38, child: FilledButton(onPressed: onOpen, style: FilledButton.styleFrom(backgroundColor: isDark ? const Color(0xFFE6BE5C) : const Color(0xFF8A5A00), foregroundColor: isDark ? const Color(0xFF1B1B1B) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text(isPremium ? 'افتح لوحة Premium' : 'اشترك في Premium', style: const TextStyle(fontWeight: FontWeight.w900))))])));
  }
}

class _RecentNotificationsCard extends StatefulWidget {
  const _RecentNotificationsCard();
  @override
  State<_RecentNotificationsCard> createState() => _RecentNotificationsCardState();
}

class _RecentNotificationsCardState extends State<_RecentNotificationsCard> {
  Future<List<NotificationItemModel>>? _future;
  int? _lastVersion;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.watch(context);
    if (_future == null || _lastVersion != controller.notificationStateVersion) {
      _lastVersion = controller.notificationStateVersion;
      _future = controller.repositories.notifications.fetchNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RailCard(padding: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 8), child: Row(children: [const Icon(Icons.notifications, color: AppColors.blue, size: 18), const SizedBox(width: 8), Expanded(child: Text('الإشعارات الأخيرة', style: TextStyle(color: context.appText, fontWeight: FontWeight.w900)))])), Divider(height: 1, color: context.appBorder), FutureBuilder<List<NotificationItemModel>>(future: _future, builder: (context, snapshot) { final items = snapshot.data ?? []; if (items.isEmpty) return Padding(padding: const EdgeInsets.all(14), child: Text('لا توجد إشعارات حتى الآن', style: TextStyle(color: context.appMuted, fontSize: 12.5))); final visible = items.take(6).toList(); return Column(children: [for (var i = 0; i < visible.length; i++) ...[_NotificationRow(item: visible[i]), if (i != visible.length - 1) Divider(height: 1, color: context.appBorder)]]); })]));
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item});
  final NotificationItemModel item;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: context.appPaleBlue, shape: BoxShape.circle), child: const Icon(Icons.notifications_none, color: AppColors.blue, size: 16)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.appText, fontSize: 13, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(item.preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.appMuted, fontSize: 12, height: 1.35))]))]));
  }
}
