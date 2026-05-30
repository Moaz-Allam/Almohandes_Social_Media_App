import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/feed_post_model.dart';
import '../../models/reel_item.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/media_preview.dart';
import '../../state/app_scope.dart';

/// Lets a user review everything they have posted (regular posts + reels)
/// and delete a single item or multiple items at once.
///
/// Reached from Settings ("حذف منشوراتي"). All deletions go through the
/// owner-only repository methods (`feed.deletePost` / `reels.deleteReel`)
/// which are protected by RLS, so a user can only ever remove their own
/// content here.
class MyPostsManagerScreen extends StatelessWidget {
  const MyPostsManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileId = AppScope.read(context).profile?.id;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appSurface,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'حذف منشوراتي',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'المنشورات'),
              Tab(text: 'reels'),
            ],
          ),
        ),
        body: profileId == null
            ? Center(
                child: Text(
                  'سجّل الدخول لإدارة منشوراتك',
                  style: TextStyle(color: context.appMuted),
                ),
              )
            : TabBarView(
                children: [
                  _ManagedGrid<FeedPostModel>(
                    key: const ValueKey('posts'),
                    load: ({bool forceRefresh = false}) => AppScope.read(context)
                        .repositories
                        .feed
                        .fetchProfilePosts(profileId, forceRefresh: forceRefresh),
                    idOf: (post) => post.id,
                    delete: (id) async {
                      final app = AppScope.read(context);
                      await app.repositories.feed.deletePost(id);
                      app.notifyFeedChanged();
                    },
                    emptyLabel: 'لا توجد منشورات',
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    tileBuilder: (post) => _PostTile(post: post),
                  ),
                  _ManagedGrid<ReelItem>(
                    key: const ValueKey('reels'),
                    load: ({bool forceRefresh = false}) => AppScope.read(context)
                        .repositories
                        .reels
                        .fetchReelsForProfile(profileId, forceRefresh: forceRefresh),
                    idOf: (reel) => reel.id,
                    delete: (id) async {
                      final app = AppScope.read(context);
                      await app.repositories.reels.deleteReel(id);
                      app.notifyReelsChanged();
                    },
                    emptyLabel: 'لا توجد reels',
                    crossAxisCount: 3,
                    childAspectRatio: 0.7,
                    tileBuilder: (reel) => _ReelTile(reel: reel),
                  ),
                ],
              ),
      ),
    );
  }
}

typedef _Loader<T> = Future<List<T>> Function({bool forceRefresh});

class _ManagedGrid<T> extends StatefulWidget {
  const _ManagedGrid({
    super.key,
    required this.load,
    required this.idOf,
    required this.delete,
    required this.tileBuilder,
    required this.emptyLabel,
    required this.crossAxisCount,
    required this.childAspectRatio,
  });

  final _Loader<T> load;
  final String Function(T item) idOf;
  final Future<void> Function(String id) delete;
  final Widget Function(T item) tileBuilder;
  final String emptyLabel;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  State<_ManagedGrid<T>> createState() => _ManagedGridState<T>();
}

class _ManagedGridState<T> extends State<_ManagedGrid<T>> {
  late Future<List<T>> _future;
  final Set<String> _selected = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  Future<void> _reload() async {
    setState(() {
      _selected.clear();
      _future = widget.load(forceRefresh: true);
    });
    await _future;
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.add(id)) {
        _selected.remove(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty || _busy) return;
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          count == 1
              ? 'سيتم حذف العنصر المحدد نهائياً. هل تريد المتابعة؟'
              : 'سيتم حذف $count عناصر نهائياً. هل تريد المتابعة؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final ids = _selected.toList();
    var failures = 0;
    for (final id in ids) {
      try {
        await widget.delete(id);
      } catch (_) {
        failures++;
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _reload();
    if (!mounted) return;
    if (failures == 0) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('تم الحذف')));
    } else {
      AppSnack.error(context, 'تعذر حذف $failures من العناصر');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_selected.isNotEmpty)
          Container(
            color: context.appSurface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _selected.clear()),
                  child: const Text('إلغاء التحديد'),
                ),
                const Spacer(),
                Text(
                  'محدد: ${_selected.length}',
                  style: TextStyle(
                    color: context.appText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _deleteSelected,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_outline, size: 18),
                  label: const Text('حذف'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: FutureBuilder<List<T>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    widget.emptyLabel,
                    style: TextStyle(color: context.appMuted),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: widget.childAspectRatio,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final id = widget.idOf(item);
                    final selected = _selected.contains(id);
                    return GestureDetector(
                      onTap: () => _toggle(id),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.blue
                                : context.appBorder.withValues(alpha: 0.5),
                            width: selected ? 2.5 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            widget.tileBuilder(item),
                            if (selected)
                              Container(
                                color: AppColors.blue.withValues(alpha: 0.25),
                              ),
                            PositionedDirectional(
                              top: 6,
                              start: 6,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected
                                      ? AppColors.blue
                                      : Colors.black.withValues(alpha: 0.35),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  selected
                                      ? Icons.check
                                      : Icons.circle_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});
  final FeedPostModel post;

  @override
  Widget build(BuildContext context) {
    if (post.mediaUrl.trim().isEmpty) {
      return Container(
        color: context.appSurfaceAlt,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Text(
          post.body,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: context.appText, fontSize: 12, height: 1.3),
        ),
      );
    }
    return MediaPreview(
      mediaUrl: post.mediaUrl,
      mediaType: post.mediaType,
      fit: BoxFit.cover,
      fallbackLabel: '',
    );
  }
}

class _ReelTile extends StatelessWidget {
  const _ReelTile({required this.reel});
  final ReelItem reel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appSurfaceAlt,
      child: MediaPreview(
        mediaUrl: reel.videoUrl ?? '',
        mediaType: 'video',
        fit: BoxFit.cover,
        fallbackLabel: '',
      ),
    );
  }
}
