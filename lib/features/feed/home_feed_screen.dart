import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/layout_breakpoints.dart';
import '../../models/app_tab.dart';
import '../../models/feed_post_model.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/app_scope.dart';
import '../home/widgets/home_top_bar.dart';
import 'widgets/feed_post_card.dart';
import 'widgets/stories_strip.dart';
import 'widgets/web_composer_prompt.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({
    super.key,
    required this.onMenu,
    required this.onMessages,
  });

  final VoidCallback onMenu;
  final VoidCallback onMessages;

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  late Future<List<FeedPostModel>> _postsFuture;
  bool _didStartLoading = false;
  int _lastFeedVersion = 0;
  int _lastFollowVersion = 0;

  @override
  void initState() {
    super.initState();
    _postsFuture = Future.value(const <FeedPostModel>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.watch(context);
    final followChanged = controller.followVersion != _lastFollowVersion;
    final shouldRefresh = !_didStartLoading ||
        controller.feedVersion != _lastFeedVersion ||
        followChanged;
    if (!shouldRefresh) {
      return;
    }
    _didStartLoading = true;
    _lastFeedVersion = controller.feedVersion;
    _lastFollowVersion = controller.followVersion;
    _postsFuture = controller.repositories.feed.fetchHomeFeed(
      forceRefresh: true,
    );
  }

  Future<void> _refresh() async {
    final controller = AppScope.read(context);
    final future = controller.repositories.feed.fetchHomeFeed(
      forceRefresh: true,
    );
    _lastFeedVersion = controller.feedVersion;
    _lastFollowVersion = controller.followVersion;
    setState(() {
      _postsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    // Layout-driven gate: desktop/tablet width gets the inline composer
    // prompt above the feed; phone-sized viewports keep the bottom-nav
    // composer tab and skip the prompt.
    final isDesktopLayout = LayoutBreakpoints.isDesktop(context);
    return Column(
      children: [
        HomeTopBar(onMenu: widget.onMenu, onMessages: widget.onMessages),
        if (isDesktopLayout)
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: WebComposerPrompt(),
          ),
        Expanded(
          child: FutureBuilder<List<FeedPostModel>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              final isInitialLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData;
              if (isInitialLoading) {
                return const _HomeFeedSkeleton();
              }
              final posts = snapshot.data ?? const <FeedPostModel>[];
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  // +1 for the stories strip header. When the feed is empty
                  // we add a single empty-state row instead of a post list.
                  itemCount: 1 + (posts.isEmpty ? 1 : posts.length),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const StoriesStrip();
                    }
                    if (posts.isEmpty) {
                      return const _FeedEmptyState();
                    }
                    final post = posts[index - 1];
                    return FeedPostCard(
                      key: ValueKey('feed-post-${post.id}'),
                      post: post,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
      child: Column(
        children: [
          const Icon(Icons.article_outlined, color: AppColors.muted, size: 46),
          const SizedBox(height: 12),
          const Text(
            'لا توجد منشورات بعد',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'ابدأ بمشاركة منشور أو ريل ليظهر هنا.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () =>
                AppScope.read(context).selectTab(AppTab.composer),
            icon: const Icon(Icons.add),
            label: const Text('إنشاء منشور'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeFeedSkeleton extends StatelessWidget {
  const _HomeFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        StoriesStrip(),
        FeedPostSkeleton(),
        FeedPostSkeleton(),
        FeedPostSkeleton(),
      ],
    );
  }
}
