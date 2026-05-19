import 'package:flutter/material.dart';

import '../../models/app_tab.dart';
import '../../state/app_scope.dart';
import '../composer/composer_screen.dart';
import '../feed/home_feed_screen.dart';
import '../menu/linked_in_menu_drawer.dart';
import '../messages/messages_screen.dart';
import '../network/network_screen.dart';
import '../projects/projects_screen.dart';
import '../reels/reels_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/linked_bottom_navigation.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // Tracks which tabs have been visited at least once. Tabs that haven't
  // been visited render an empty placeholder so they don't pay any
  // bootstrap cost (network, video controller init, etc.). Once visited,
  // they stay mounted to make subsequent switches instant.
  final Set<AppTab> _visitedTabs = {AppTab.feed};

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _openMessages() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MessagesScreen()));
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  int _indexOf(AppTab tab) {
    return switch (tab) {
      AppTab.feed => 0,
      AppTab.network => 1,
      AppTab.composer => 2,
      AppTab.reels => 3,
      AppTab.projects => 4,
    };
  }

  Widget _buildTab(AppTab tab) {
    if (!_visitedTabs.contains(tab)) {
      return const SizedBox.shrink();
    }
    return switch (tab) {
      AppTab.feed => HomeFeedScreen(onMenu: _openDrawer, onMessages: _openMessages),
      AppTab.network => NetworkScreen(onMenu: _openDrawer, onMessages: _openMessages),
      AppTab.composer => ComposerScreen(
          onClose: () => AppScope.read(context).selectTab(AppTab.feed),
        ),
      AppTab.reels => ReelsScreen(onMenu: _openDrawer, onMessages: _openMessages),
      AppTab.projects => ProjectsScreen(onMenu: _openDrawer, onMessages: _openMessages),
    };
  }

  void _onTabChanged(AppTab tab) {
    if (!_visitedTabs.contains(tab)) {
      setState(() => _visitedTabs.add(tab));
    } else if (tab == AppTab.composer) {
      // Composer should always start fresh — drop and re-create.
      setState(() {
        _visitedTabs.remove(AppTab.composer);
        _visitedTabs.add(AppTab.composer);
      });
    }
    AppScope.read(context).selectTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    return Scaffold(
      key: _scaffoldKey,
      drawer: LinkedInMenuDrawer(onSettings: _openSettings),
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
