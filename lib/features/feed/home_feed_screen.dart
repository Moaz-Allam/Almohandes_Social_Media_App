import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/layout_breakpoints.dart';
import '../../models/app_tab.dart';
import '../../models/feed_post_model.dart';
import '../../models/project_item.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/app_scope.dart';
import '../home/widgets/home_top_bar.dart';
import '../projects/widgets/project_card.dart';
import '../projects/project_application_screen.dart';
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
  late Future<List<dynamic>> _contentFuture;
  bool _didStartLoading = false;
  int _lastFeedVersion = 0;
  int _lastFollowVersion = 0;
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _contentFuture = Future.value(const []);
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
    _loadContent();
  }

  void _loadContent({bool forceRefresh = true}) {
    final app = AppScope.read(context);
    setState(() {
      _contentFuture = switch (_selectedFilterIndex) {
        0 => app.repositories.feed.fetchHomeFeed(forceRefresh: forceRefresh),
        1 => app.repositories.feed.fetchFollowingFeed(forceRefresh: forceRefresh),
        2 => app.repositories.feed.fetchProfessionalsFeed(forceRefresh: forceRefresh),
        3 => app.repositories.projects.fetchProjects(forceRefresh: forceRefresh),
        4 => _fetchJobs(forceRefresh: forceRefresh),
        _ => app.repositories.feed.fetchHomeFeed(forceRefresh: forceRefresh),
      };
    });
  }

  Future<List<dynamic>> _fetchJobs({bool forceRefresh = false}) async {
    final client = Supabase.instance.client;
    try {
      final rows = await client
          .from('jobs')
          .select('*, profiles(full_name, avatar_url, role)')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return rows;
    } catch (_) {
      return [];
    }
  }

  Future<void> _refresh() async {
    final controller = AppScope.read(context);
    _lastFeedVersion = controller.feedVersion;
    _lastFollowVersion = controller.followVersion;
    _loadContent(forceRefresh: true);
    await _contentFuture;
  }

  void _onFilterChanged(int index) {
    if (_selectedFilterIndex == index) return;
    setState(() {
      _selectedFilterIndex = index;
    });
    _loadContent(forceRefresh: false);
  }

  Future<void> _openProjectApplication(ProjectItem project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectApplicationScreen(project: project),
      ),
    );
    _loadContent(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopLayout = LayoutBreakpoints.isDesktop(context);
    final myProfileId = AppScope.watch(context).profile?.id;

    return Column(
      children: [
        HomeTopBar(onMenu: widget.onMenu, onMessages: widget.onMessages),
        if (isDesktopLayout)
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: WebComposerPrompt(),
          ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _contentFuture,
            builder: (context, snapshot) {
              final isInitialLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData;
              if (isInitialLoading) {
                return const _HomeFeedSkeleton();
              }
              final items = snapshot.data ?? const [];
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: 2 + (items.isEmpty ? 1 : items.length),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const StoriesStrip();
                    }
                    if (index == 1) {
                      return _CategoryFilterBar(
                        selectedIndex: _selectedFilterIndex,
                        onChanged: _onFilterChanged,
                      );
                    }
                    if (items.isEmpty) {
                      return _FeedEmptyState(filterIndex: _selectedFilterIndex);
                    }
                    final item = items[index - 2];

                    if (item is FeedPostModel) {
                      return FeedPostCard(
                        key: ValueKey('feed-post-${item.id}'),
                        post: item,
                      );
                    } else if (item is ProjectItem) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ProjectCard(
                          project: item,
                          onApply: () => _openProjectApplication(item),
                          canApply: item.profileId != myProfileId,
                        ),
                      );
                    } else if (item is Map<String, dynamic>) {
                      // Basic Job Card
                      return _JobListItem(job: item);
                    }
                    return const SizedBox.shrink();
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

class _JobListItem extends StatelessWidget {
  const _JobListItem({required this.job});
  final Map<String, dynamic> job;

  @override
  Widget build(BuildContext context) {
    final profiles = job['profiles'] as Map<String, dynamic>?;
    final companyName = job['company_name'] ?? profiles?['full_name'] ?? 'شركة';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${job['title']}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '$companyName · ${job['location'] ?? ''}',
            style: TextStyle(color: context.appMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _JobTag(label: '${job['job_type']}'),
              const SizedBox(width: 8),
              _JobTag(label: '${job['category']}'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                // TODO: Open Job Application
              },
              child: const Text('تقديم الآن'),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobTag extends StatelessWidget {
  const _JobTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _categories = [
    'الكل',
    'أتابعه',
    'الحرفيين',
    'المشاريع',
    'الوظائف',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.appPrimary
                    : context.appSurfaceAlt,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? context.appPrimary
                      : context.appBorder.withValues(alpha: 0.6),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: context.appPrimary.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : context.appText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState({required this.filterIndex});
  final int filterIndex;

  @override
  Widget build(BuildContext context) {
    final showCreateButton = filterIndex != 1; // Show for all except 'Following'

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.appPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_outlined,
              color: context.appPrimary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد منشورات بعد',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            filterIndex == 1 
                ? 'لم يقم من تتابعهم بنشر أي شيء بعد.'
                : 'ابدأ بمشاركة منشور أو ريل ليظهر هنا.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appMuted, height: 1.45),
          ),
          if (showCreateButton) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () =>
                  AppScope.read(context).selectTab(AppTab.feed),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إنشاء منشور'),
            ),
          ],
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
