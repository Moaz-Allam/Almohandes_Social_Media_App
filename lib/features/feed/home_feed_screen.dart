import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/layout_breakpoints.dart';
import '../../models/feed_post_model.dart';
import '../../models/project_item.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/app_scope.dart';
import '../home/widgets/home_top_bar.dart';
import '../jobs/job_application_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../projects/widgets/project_card.dart';
import '../projects/project_application_screen.dart';
import '../projects/project_detail_screen.dart';
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
  static const _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  List<dynamic> _items = const [];
  bool _didStartLoading = false;
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _offset = 0;
  // Bumped on every (re)load so a slow in-flight request from a previous
  // filter / refresh can't overwrite the current list when it resolves.
  int _loadToken = 0;
  int _lastFeedVersion = 0;
  int _lastFollowVersion = 0;
  int _selectedFilterIndex = 0;
  // Ids of jobs the current user already applied to, used to show "تم التقديم".
  Set<String> _appliedJobIds = const <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
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
    _loadInitial();
  }

  /// Only the post feeds (home / following / professionals) and jobs support
  /// server-side offset paging. Projects load a single page.
  bool _supportsPagination(int index) =>
      index == 0 || index == 1 || index == 2 || index == 4;

  Future<List<dynamic>> _fetchPage({
    required int offset,
    required bool forceRefresh,
  }) {
    final app = AppScope.read(context);
    return switch (_selectedFilterIndex) {
      0 => app.repositories.feed
          .fetchHomeFeed(forceRefresh: forceRefresh, offset: offset),
      1 => app.repositories.feed
          .fetchFollowingFeed(forceRefresh: forceRefresh, offset: offset),
      2 => app.repositories.feed
          .fetchProfessionalsFeed(forceRefresh: forceRefresh, offset: offset),
      3 => app.repositories.projects.fetchProjects(forceRefresh: forceRefresh),
      4 => _fetchJobs(forceRefresh: forceRefresh, offset: offset),
      _ => app.repositories.feed
          .fetchHomeFeed(forceRefresh: forceRefresh, offset: offset),
    };
  }

  Future<void> _loadInitial({bool forceRefresh = true}) async {
    final token = ++_loadToken;
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _hasMore = false;
      _offset = 0;
    });
    List<dynamic> page;
    try {
      page = await _fetchPage(offset: 0, forceRefresh: forceRefresh);
    } catch (_) {
      page = const [];
    }
    if (!mounted || token != _loadToken) {
      return;
    }
    setState(() {
      _items = List<dynamic>.from(page);
      _offset = _pageSize;
      _hasMore = _supportsPagination(_selectedFilterIndex) && page.isNotEmpty;
      _isInitialLoading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _isInitialLoading || !_hasMore) {
      return;
    }
    if (!_supportsPagination(_selectedFilterIndex)) {
      return;
    }
    final token = _loadToken;
    setState(() => _isLoadingMore = true);
    List<dynamic> page;
    try {
      page = await _fetchPage(offset: _offset, forceRefresh: false);
    } catch (_) {
      page = const [];
    }
    if (!mounted || token != _loadToken) {
      return;
    }
    setState(() {
      final existingKeys = _items.map(_itemKey).toSet();
      final fresh = [
        for (final item in page)
          if (!existingKeys.contains(_itemKey(item))) item,
      ];
      _items = [..._items, ...fresh];
      _offset += _pageSize;
      _hasMore = page.isNotEmpty;
      _isLoadingMore = false;
    });
  }

  /// Stable identity for de-duping appended pages across types.
  String _itemKey(dynamic item) {
    if (item is FeedPostModel) {
      return 'post:${item.id}';
    }
    if (item is ProjectItem) {
      return 'project:${item.id}';
    }
    if (item is Map) {
      return 'job:${item['id']}';
    }
    return '${item.hashCode}';
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      _loadMore();
    }
  }

  Future<List<dynamic>> _fetchJobs({
    bool forceRefresh = false,
    int offset = 0,
  }) async {
    if (offset == 0) {
      _appliedJobIds = await AppScope.read(
        context,
      ).repositories.jobs.fetchAppliedJobIds(forceRefresh: forceRefresh);
    }
    final client = Supabase.instance.client;
    try {
      final rows = await client
          .from('jobs')
          .select('*, profiles(full_name, avatar_url, role)')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + _pageSize - 1);
      return rows;
    } catch (_) {
      return [];
    }
  }

  Future<void> _refresh() async {
    final controller = AppScope.read(context);
    _lastFeedVersion = controller.feedVersion;
    _lastFollowVersion = controller.followVersion;
    await _loadInitial(forceRefresh: true);
  }

  void _onFilterChanged(int index) {
    if (_selectedFilterIndex == index) return;
    setState(() {
      _selectedFilterIndex = index;
    });
    _loadInitial(forceRefresh: false);
  }

  Future<void> _openProjectApplication(ProjectItem project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectApplicationScreen(project: project),
      ),
    );
    if (!mounted) {
      return;
    }
    _loadInitial(forceRefresh: true);
  }

  Future<void> _openJobApplication(Map<String, dynamic> job) async {
    final applied = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => JobApplicationScreen(job: job),
      ),
    );
    if (!mounted) {
      return;
    }
    if (applied == true) {
      AppSnack.success(context, 'تم إرسال طلب التوظيف بنجاح');
      _loadInitial(forceRefresh: true);
    }
  }

  Future<void> _openProjectDetail(ProjectItem project, bool canApply) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(project: project, canApply: canApply),
      ),
    );
    if (!mounted) {
      return;
    }
    // Applying / matching from the detail page may change the feed state.
    _loadInitial(forceRefresh: true);
  }

  Future<void> _openJobDetail(
    Map<String, dynamic> job, {
    required bool isOwn,
    required bool didApply,
  }) async {
    final applied = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(
          job: job,
          isOwn: isOwn,
          didApply: didApply,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    if (applied == true) {
      AppSnack.success(context, 'تم إرسال طلب التوظيف بنجاح');
      _loadInitial(forceRefresh: true);
    }
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
          child: _isInitialLoading
              ? const _HomeFeedSkeleton()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: _buildList(myProfileId),
                ),
        ),
      ],
    );
  }

  Widget _buildList(String? myProfileId) {
    final hasItems = _items.isNotEmpty;
    final showLoader = _isLoadingMore && hasItems;
    // 2 leading slots (stories strip + filter bar), then items (or one empty
    // state row), then an optional trailing load-more spinner.
    final itemCount = 2 + (hasItems ? _items.length : 1) + (showLoader ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: itemCount,
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
        if (!hasItems) {
          return _FeedEmptyState(filterIndex: _selectedFilterIndex);
        }
        if (showLoader && index == itemCount - 1) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = _items[index - 2];

        if (item is FeedPostModel) {
          return FeedPostCard(
            key: ValueKey('feed-post-${item.id}'),
            post: item,
          );
        } else if (item is ProjectItem) {
          final canApply = item.profileId != myProfileId;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ProjectCard(
              project: item,
              onApply: () => _openProjectApplication(item),
              onTap: () => _openProjectDetail(item, canApply),
              canApply: canApply,
            ),
          );
        } else if (item is Map<String, dynamic>) {
          // Basic Job Card
          final didApply = _appliedJobIds.contains('${item['id'] ?? ''}');
          final isOwn = '${item['profile_id'] ?? ''}' == myProfileId;
          return _JobListItem(
            job: item,
            isOwn: isOwn,
            didApply: didApply,
            onApply: () => _openJobApplication(item),
            onTap: () => _openJobDetail(item, isOwn: isOwn, didApply: didApply),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _JobListItem extends StatelessWidget {
  const _JobListItem({
    required this.job,
    required this.isOwn,
    required this.didApply,
    required this.onApply,
    required this.onTap,
  });
  final Map<String, dynamic> job;
  final bool isOwn;
  final bool didApply;
  final VoidCallback onApply;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profiles = job['profiles'] as Map<String, dynamic>?;
    final companyName = job['company_name'] ?? profiles?['full_name'] ?? 'شركة';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${job['title']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$companyName · ${job['location'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_jobTypeLabel('${job['job_type'] ?? ''}').isNotEmpty)
                      _JobTag(label: _jobTypeLabel('${job['job_type'] ?? ''}')),
                    if ('${job['category'] ?? ''}'.trim().isNotEmpty)
                      _JobTag(label: '${job['category']}'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _buildAction(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAction() {
    if (isOwn) {
      return const OutlinedButton(
        onPressed: null,
        child: Text(
          'هذه وظيفتك',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    if (didApply) {
      return const OutlinedButton(
        onPressed: null,
        child: Text(
          'تم التقديم',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return FilledButton(
      onPressed: onApply,
      child: const Text(
        'تقديم الآن',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Maps the stored job-type code to its Arabic label (same mapping the job
/// form and detail page use). Returns the raw value if unknown.
String _jobTypeLabel(String raw) {
  return switch (raw.trim()) {
    '' => '',
    'full-time' => 'دوام كامل',
    'part-time' => 'دوام جزئي',
    'contract' => 'عقد',
    'freelance' => 'عمل حر',
    'internship' => 'تدريب',
    _ => raw.trim(),
  };
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
                : 'لا توجد منشورات لعرضها هنا حاليا.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appMuted, height: 1.45),
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
