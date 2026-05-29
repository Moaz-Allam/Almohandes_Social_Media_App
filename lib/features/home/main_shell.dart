import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/layout_breakpoints.dart';
import '../../models/app_tab.dart';
import '../../state/app_scope.dart';
import '../feed/home_feed_screen.dart';
import '../messages/messages_screen.dart';
import '../premium/premium_dashboard_screen.dart';
import '../reels/reels_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import 'web_shell.dart';
import 'widgets/linked_bottom_navigation.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    // Pick the LinkedIn-style web shell on desktop widths, the bottom-nav
    // mobile shell otherwise. Same theme/colors/state across both.
    if (LayoutBreakpoints.isDesktop(context)) {
      return const WebShell();
    }
    return const _MobileShell();
  }
}

class _MobileShell extends StatefulWidget {
  const _MobileShell();

  @override
  State<_MobileShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MobileShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // Tracks which tabs have been visited at least once. Tabs that haven't
  // been visited render an empty placeholder so they don't pay any
  // bootstrap cost (network, video controller init, etc.). Once visited,
  // they stay mounted to make subsequent switches instant.
  final Set<AppTab> _visitedTabs = {AppTab.feed};

  void _openDrawer() {
    AppScope.read(context).selectTab(AppTab.profile);
  }

  void _openMessages() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MessagesScreen()));
  }

  int _indexOf(AppTab tab) {
    return switch (tab) {
      AppTab.feed => 0,
      AppTab.search => 1,
      AppTab.dashboard => 2,
      AppTab.reels => 3,
      AppTab.profile => 4,
    };
  }

  Widget _buildTab(AppTab tab) {
    if (!_visitedTabs.contains(tab)) {
      return const SizedBox.shrink();
    }
    final controller = AppScope.read(context);
    return switch (tab) {
      AppTab.feed => HomeFeedScreen(onMenu: _openDrawer, onMessages: _openMessages),
      AppTab.search => SearchScreen(onMenu: _openDrawer, onMessages: _openMessages),
      AppTab.dashboard => PremiumDashboardScreen(onMenu: _openDrawer, onMessages: _openMessages),
      AppTab.reels => ReelsScreen(onMenu: _openDrawer, onMessages: _openMessages),
      AppTab.profile => ProfileScreen(
        name: controller.profile?.fullName ?? '',
        headline: controller.profile?.headline ?? '',
        color: context.appPrimary,
        onMenu: _openDrawer,
        isMe: true,
      ),
    };
  }

  void _onTabChanged(AppTab tab) {
    if (!_visitedTabs.contains(tab)) {
      setState(() => _visitedTabs.add(tab));
    }
    AppScope.read(context).selectTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _indexOf(controller.selectedTab),
        children: [
          for (final tab in AppTab.values) _buildTab(tab),
        ],
      ),
      bottomNavigationBar: LinkedBottomNavigation(
        selectedTab: controller.selectedTab,
        onChanged: _onTabChanged,
      ),
    );
  }
}
