import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/profile_content_item.dart';

class ProfileContentPreview extends StatelessWidget {
  const ProfileContentPreview({
    super.key,
    required this.tabs,
    required this.onExplore,
  });

  static const double height = 340;
  static const int previewItemLimit = 2;

  final List<ProfileContentTabData> tabs;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DefaultTabController(
        length: tabs.length,
        child: Column(
          children: [
            ProfileContentTabBar(labels: [for (final tab in tabs) tab.label]),
            const SizedBox(height: 14),
            SizedBox(
              height: 216,
              child: TabBarView(
                children: [
                  for (final tab in tabs)
                    ProfileContentList(
                      items: tab.items.take(previewItemLimit).toList(),
                      scrollable: false,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onExplore,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('استكشاف كل المحتوى'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
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

class ProfileContentTabBar extends StatelessWidget {
  const ProfileContentTabBar({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(23),
      ),
      child: TabBar(
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(20),
        ),
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.blue,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        tabs: [for (final label in labels) Tab(text: label)],
      ),
    );
  }
}

class ProfileContentList extends StatelessWidget {
  const ProfileContentList({
    super.key,
    required this.items,
    this.scrollable = true,
  });

  final List<ProfileContentItem> items;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد محتوى لعرضه الآن.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.35),
        ),
      );
    }

    if (!scrollable) {
      return ClipRect(
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              ProfileContentTile(item: items[index]),
              if (index != items.length - 1) const Divider(height: 18),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      itemBuilder: (context, index) => ProfileContentTile(item: items[index]),
      separatorBuilder: (context, index) => const Divider(height: 24),
      itemCount: items.length,
    );
  }
}

class ProfileContentTile extends StatelessWidget {
  const ProfileContentTile({super.key, required this.item});

  final ProfileContentItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(item.icon, color: AppColors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 5),
              Text(
                item.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
