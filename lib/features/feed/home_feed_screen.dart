import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/feed_post_model.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/app_scope.dart';
import '../home/widgets/home_top_bar.dart';
import 'widgets/feed_post_card.dart';
import 'widgets/stories_strip.dart';

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

  @override
  void initState() {
    super.initState();
    _postsFuture = Future.value(const <FeedPostModel>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartLoading) {
      return;
    }
    _didStartLoading = true;
    _postsFuture = AppScope.read(context).repositories.feed.fetchHomeFeed();
  }

  Future<void> _refresh() async {
    setState(() {
      _postsFuture = AppScope.read(
        context,
      ).repositories.feed.fetchHomeFeed(forceRefresh: true);
    });
    await _postsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeTopBar(onMenu: widget.onMenu, onMessages: widget.onMessages),
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
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    const StoriesStrip(),
                    if (posts.isEmpty)
                      const _FeedEmptyState()
                    else
                      for (final post in posts) FeedPostCard(post: post),
                  ],
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
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 70, 24, 24),
      child: Column(
        children: [
          Icon(Icons.article_outlined, color: AppColors.muted, size: 46),
          SizedBox(height: 12),
          Text(
            'لا توجد منشورات بعد',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'ستظهر منشورات المستخدمين هنا بعد إضافتها في Supabase.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.45),
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
