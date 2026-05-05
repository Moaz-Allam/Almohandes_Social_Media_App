import 'package:flutter/material.dart';

import '../../models/app_tab.dart';
import '../../state/app_scope.dart';
import '../composer/composer_screen.dart';
import '../feed/home_feed_screen.dart';
import '../jobs/jobs_screen.dart';
import '../menu/linked_in_menu_drawer.dart';
import '../messages/messages_screen.dart';
import '../network/network_screen.dart';
import '../reels/reels_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/linked_bottom_navigation.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  void _openMessages(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MessagesScreen()));
  }

  void _openSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    final content = switch (controller.selectedTab) {
      AppTab.feed => HomeFeedScreen(
        onMenu: () => scaffoldKey.currentState?.openDrawer(),
        onMessages: () => _openMessages(context),
      ),
      AppTab.network => NetworkScreen(
        onMenu: () => scaffoldKey.currentState?.openDrawer(),
        onMessages: () => _openMessages(context),
      ),
      AppTab.composer => ComposerScreen(
        onClose: () => controller.selectTab(AppTab.feed),
      ),
      AppTab.reels => ReelsScreen(
        onMenu: () => scaffoldKey.currentState?.openDrawer(),
        onMessages: () => _openMessages(context),
      ),
      AppTab.jobs => JobsScreen(
        onMenu: () => scaffoldKey.currentState?.openDrawer(),
        onMessages: () => _openMessages(context),
      ),
    };

    return Scaffold(
      key: scaffoldKey,
      drawer: LinkedInMenuDrawer(onSettings: () => _openSettings(context)),
      body: content,
      bottomNavigationBar: LinkedBottomNavigation(
        selectedTab: controller.selectedTab,
        onChanged: controller.selectTab,
      ),
    );
  }
}
