import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'models/profile_content_item.dart';
import 'widgets/profile_content_tabs.dart';

class ProfileContentScreen extends StatelessWidget {
  const ProfileContentScreen({
    super.key,
    required this.ownerName,
    required this.tabs,
  });

  final String ownerName;
  final List<ProfileContentTabData> tabs;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.ink,
          title: Text(
            'كل محتوى $ownerName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(62),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: ProfileContentTabBar(
                labels: [for (final tab in tabs) tab.label],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            for (final tab in tabs) ProfileContentList(items: tab.items),
          ],
        ),
      ),
    );
  }
}
