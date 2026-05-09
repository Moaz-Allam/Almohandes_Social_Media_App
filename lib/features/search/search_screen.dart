import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/account_type.dart';
import '../../models/feed_post_model.dart';
import '../../models/network_person.dart';
import '../../models/project_item.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../state/app_scope.dart';
import '../feed/post_detail_screen.dart';
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
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _query;
  SearchFilter _filter = SearchFilter.people;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              decoration: BoxDecoration(
                color: context.appSurface,
                border: Border(bottom: BorderSide(color: context.appBorder)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'رجوع',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      autofocus: true,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'ابحث في المهندس',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: context.appSurfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
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
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 58,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final filter = SearchFilter.values[index];
                  return ChoiceChip(
                    label: Text(filter.label),
                    selected: _filter == filter,
                    selectedColor: AppColors.paleBlue,
                    side: BorderSide(
                      color: _filter == filter
                          ? AppColors.blue
                          : context.appBorder,
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
              child: _SearchResults(filter: _filter, query: _query.text),
            ),
          ],
        ),
      ),
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

class _PeopleResults extends StatelessWidget {
  const _PeopleResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final accountType = accountTypeFromProfile(AppScope.watch(context).profile);
    return FutureBuilder<List<NetworkPerson>>(
      future: AppScope.read(context).repositories.profiles.fetchNetworkProfiles(
        viewerType: accountType,
        companies: false,
      ),
      builder: (context, snapshot) {
        final rows = _filterPeople(
          snapshot.data ?? const <NetworkPerson>[],
          query,
        );
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
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

  List<NetworkPerson> _filterPeople(List<NetworkPerson> rows, String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return rows;
    }
    return [
      for (final row in rows)
        if (row.name.contains(normalized) || row.title.contains(normalized))
          row,
    ];
  }
}

class _ProjectResults extends StatelessWidget {
  const _ProjectResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProjectItem>>(
      future: AppScope.read(context).repositories.projects.fetchProjects(),
      builder: (context, snapshot) {
        final rows = _filterProjects(
          snapshot.data ?? const <ProjectItem>[],
          query,
        );
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
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

  List<ProjectItem> _filterProjects(List<ProjectItem> rows, String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return rows;
    }
    return [
      for (final row in rows)
        if (row.title.contains(normalized) || row.tagline.contains(normalized))
          row,
    ];
  }
}

class _PostResults extends StatelessWidget {
  const _PostResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FeedPostModel>>(
      future: AppScope.read(context).repositories.feed.fetchHomeFeed(),
      builder: (context, snapshot) {
        final rows = _filterPosts(
          snapshot.data ?? const <FeedPostModel>[],
          query,
        );
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
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

  List<FeedPostModel> _filterPosts(List<FeedPostModel> rows, String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return rows;
    }
    return [
      for (final row in rows)
        if (row.body.contains(normalized) || row.name.contains(normalized)) row,
    ];
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'لا توجد $label بعد',
        style: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
