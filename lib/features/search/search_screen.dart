import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/feed_post_model.dart';
import '../../models/network_person.dart';
import '../../models/project_item.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../state/app_scope.dart';
import '../feed/post_detail_screen.dart';
import '../home/widgets/home_top_bar.dart';
import '../network/network_screen.dart';
import '../profile/profile_screen.dart';
import '../projects/project_application_screen.dart';

enum SearchFilter {
  people('الأشخاص'),
  projects('المشاريع'),
  posts('المنشورات');

  const SearchFilter(this.label);

  final String label;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.initialQuery = '',
    this.onMenu,
    this.onMessages,
  });

  final String initialQuery;

  /// When both [onMenu] and [onMessages] are provided the screen renders in
  /// "embedded" mode for the bottom-nav search tab: a [HomeTopBar] instead of
  /// a back button, no autofocus, and no surrounding [Scaffold] (the shell
  /// supplies it). When omitted it renders as a standalone pushed route
  /// (the desktop search field), with a back button and autofocus.
  final VoidCallback? onMenu;
  final VoidCallback? onMessages;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _query;
  // Debounced mirror of _query.text. The result queries fire against this, not
  // every keystroke — keeps the input responsive and avoids a network round
  // trip per character.
  final ValueNotifier<String> _debouncedQuery = ValueNotifier('');
  Timer? _debounceTimer;
  SearchFilter _filter = SearchFilter.people;

  bool get _embedded => widget.onMenu != null && widget.onMessages != null;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery);
    _debouncedQuery.value = widget.initialQuery;
    _query.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _query.removeListener(_onQueryChanged);
    _query.dispose();
    _debouncedQuery.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _debouncedQuery.value = _query.text;
    });
  }

  void _openNetwork() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          body: NetworkScreen(
            onMenu: () => Navigator.of(routeContext).maybePop(),
            onMessages: widget.onMessages ?? () {},
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        if (_embedded)
          HomeTopBar(onMenu: widget.onMenu!, onMessages: widget.onMessages!),
        _SearchHeader(
          controller: _query,
          autofocus: !_embedded,
          showBackButton: !_embedded,
        ),
        SizedBox(
          height: 58,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final filter = SearchFilter.values[index];
              return ChoiceChip(
                label: Text(filter.label),
                selected: _filter == filter,
                selectedColor: AppColors.paleBlue,
                side: BorderSide(
                  color: _filter == filter ? AppColors.blue : context.appBorder,
                ),
                labelStyle: TextStyle(
                  color: _filter == filter
                      ? AppColors.darkBlue
                      : context.appText,
                  fontWeight: FontWeight.w800,
                ),
                showCheckmark: false,
                onSelected: (_) => setState(() => _filter = filter),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemCount: SearchFilter.values.length,
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<String>(
            valueListenable: _debouncedQuery,
            builder: (context, query, _) {
              if (query.trim().isEmpty) {
                return _SearchPrompt(
                  onBrowseNetwork: _embedded ? _openNetwork : null,
                );
              }
              return _SearchResults(filter: _filter, query: query);
            },
          ),
        ),
      ],
    );

    if (_embedded) {
      return body;
    }
    return Scaffold(body: SafeArea(child: body));
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.autofocus,
    required this.showBackButton,
  });

  final TextEditingController controller;
  final bool autofocus;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      autofocus: autofocus,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: 'ابحث في المهندس',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: context.appSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.blue),
        ),
      ),
    );

    return Container(
      padding: showBackButton
          ? const EdgeInsets.fromLTRB(8, 8, 12, 8)
          : const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: showBackButton
          ? Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'رجوع',
                ),
                Expanded(child: field),
              ],
            )
          : field,
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.filter, required this.query});

  final SearchFilter filter;
  final String query;

  @override
  Widget build(BuildContext context) {
    return switch (filter) {
      SearchFilter.people => _PeopleResults(query: query),
      SearchFilter.projects => _ProjectResults(query: query),
      SearchFilter.posts => _PostResults(query: query),
    };
  }
}

class _PeopleResults extends StatefulWidget {
  const _PeopleResults({required this.query});

  final String query;

  @override
  State<_PeopleResults> createState() => _PeopleResultsState();
}

class _PeopleResultsState extends State<_PeopleResults> {
  Future<List<NetworkPerson>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void didUpdateWidget(covariant _PeopleResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      setState(() => _future = _load());
    }
  }

  Future<List<NetworkPerson>> _load() {
    return AppScope.read(context).repositories.profiles.searchPeople(
      widget.query,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NetworkPerson>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data ?? const <NetworkPerson>[];
        if (rows.isEmpty) {
          return const _EmptySearchResult(label: 'أشخاص');
        }
        return ListView.separated(
          padding: const EdgeInsets.only(top: 4),
          itemBuilder: (context, index) {
            final row = rows[index];
            return ListTile(
              leading: AppAvatar(
                name: row.name,
                radius: 22,
                color: row.color,
                imageUrl: row.avatarUrl,
              ),
              title: Text(
                row.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                row.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    profileId: row.id,
                    name: row.name,
                    headline: row.title,
                    color: row.color,
                    avatarUrl: row.avatarUrl,
                    initialConnectionStatus: row.connectionStatus,
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (context, index) =>
              Divider(height: 1, indent: 72, color: context.appBorder),
          itemCount: rows.length,
        );
      },
    );
  }
}

class _ProjectResults extends StatefulWidget {
  const _ProjectResults({required this.query});

  final String query;

  @override
  State<_ProjectResults> createState() => _ProjectResultsState();
}

class _ProjectResultsState extends State<_ProjectResults> {
  Future<List<ProjectItem>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void didUpdateWidget(covariant _ProjectResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      setState(() => _future = _load());
    }
  }

  Future<List<ProjectItem>> _load() {
    return AppScope.read(context).repositories.projects.searchJobs(
      widget.query,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProjectItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data ?? const <ProjectItem>[];
        if (rows.isEmpty) {
          return const _EmptySearchResult(label: 'مشاريع');
        }
        return ListView.separated(
          padding: const EdgeInsets.only(top: 4),
          itemBuilder: (context, index) {
            final row = rows[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: context.appPaleBlue,
                child: const Icon(Icons.work, color: AppColors.blue),
              ),
              title: Text(
                row.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                row.tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProjectApplicationScreen(project: row),
                ),
              ),
            );
          },
          separatorBuilder: (context, index) =>
              Divider(height: 1, indent: 72, color: context.appBorder),
          itemCount: rows.length,
        );
      },
    );
  }
}

class _PostResults extends StatefulWidget {
  const _PostResults({required this.query});

  final String query;

  @override
  State<_PostResults> createState() => _PostResultsState();
}

class _PostResultsState extends State<_PostResults> {
  Future<List<FeedPostModel>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void didUpdateWidget(covariant _PostResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      setState(() => _future = _load());
    }
  }

  Future<List<FeedPostModel>> _load() {
    return AppScope.read(context).repositories.feed.searchPosts(widget.query);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FeedPostModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data ?? const <FeedPostModel>[];
        if (rows.isEmpty) {
          return const _EmptySearchResult(label: 'منشورات');
        }
        return ListView.separated(
          padding: const EdgeInsets.only(top: 4),
          itemBuilder: (context, index) {
            final row = rows[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: context.appPaleBlue,
                child: const Icon(Icons.article, color: AppColors.blue),
              ),
              title: Text(
                row.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                row.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PostDetailScreen(post: row)),
              ),
            );
          },
          separatorBuilder: (context, index) =>
              Divider(height: 1, indent: 72, color: context.appBorder),
          itemCount: rows.length,
        );
      },
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt({this.onBrowseNetwork});

  /// When provided, shows an entry to browse the full network screen — keeps
  /// people/companies browsing and invitations reachable from the search tab.
  final VoidCallback? onBrowseNetwork;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 44, color: context.appMuted),
            const SizedBox(height: 12),
            Text(
              'ابحث عن الأشخاص والمشاريع والمنشورات',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (onBrowseNetwork != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onBrowseNetwork,
                icon: const Icon(Icons.groups_outlined),
                label: const Text(
                  'تصفح الشبكة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'لا توجد $label مطابقة',
        style: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
