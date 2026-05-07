import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/feed_post_model.dart';
import '../../models/project_item.dart';
import '../../models/saved_content.dart';
import '../../shared/painters/card_pattern_painter.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/app_scope.dart';
import '../feed/post_detail_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.name,
    required this.headline,
    required this.color,
    this.profileId,
    this.location = 'العراق',
    this.isMe = false,
    this.isConnectionRequest = false,
  });

  const ProfileScreen.me({super.key})
    : name = '',
      headline = '',
      color = AppColors.darkBlue,
      profileId = null,
      location = 'العراق',
      isMe = true,
      isConnectionRequest = false;

  final String name;
  final String headline;
  final Color color;
  final String? profileId;
  final String location;
  final bool isMe;
  final bool isConnectionRequest;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.watch(context);
    final currentProfile = app.profile;
    final effectiveName = isMe
        ? ((currentProfile?.fullName.isNotEmpty ?? false)
              ? currentProfile!.fullName
              : 'المستخدم')
        : name;
    final effectiveHeadline = isMe
        ? _currentHeadline(currentProfile)
        : headline;
    final effectiveLocation = isMe
        ? (currentProfile?.location.isNotEmpty == true
              ? currentProfile!.location
              : 'العراق')
        : location;
    final effectiveProfileId = isMe ? currentProfile?.id : profileId;
    final effectiveColor = isMe ? AppColors.darkBlue : color;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: context.appSurface,
              foregroundColor: context.appText,
              leading: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'رجوع',
              ),
              title: Text(
                effectiveName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHero(
                    profileId: effectiveProfileId,
                    name: effectiveName,
                    headline: effectiveHeadline,
                    color: effectiveColor,
                    location: effectiveLocation,
                    isMe: isMe,
                    followersCount: currentProfile?.followersCount ?? 0,
                    connectionsCount: currentProfile?.followingCount ?? 0,
                  ),
                  Divider(height: 10, thickness: 10, color: context.appSoft),
                  _ProfileWorkspace(
                    profileId: effectiveProfileId,
                    isMe: isMe,
                    headline: effectiveHeadline,
                    location: effectiveLocation,
                    savedItems: isMe ? app.savedItems : const <SavedContent>[],
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _currentHeadline(dynamic profile) {
    if (profile == null) {
      return 'ملفك على منصة المهندس';
    }
    if (profile.headline.isNotEmpty) {
      return profile.headline;
    }
    if (profile.role.isNotEmpty) {
      return profile.role;
    }
    return 'ملفك على منصة المهندس';
  }
}

class _ProfileHero extends StatefulWidget {
  const _ProfileHero({
    required this.profileId,
    required this.name,
    required this.headline,
    required this.color,
    required this.location,
    required this.isMe,
    required this.followersCount,
    required this.connectionsCount,
  });

  final String? profileId;
  final String name;
  final String headline;
  final Color color;
  final String location;
  final bool isMe;
  final int followersCount;
  final int connectionsCount;

  @override
  State<_ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<_ProfileHero> {
  bool _connectionPending = false;

  Future<void> _requestConnection() async {
    setState(() => _connectionPending = true);
    final id = widget.profileId;
    if (id != null && id.isNotEmpty) {
      await AppScope.read(context).repositories.profiles.requestConnection(id);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إرسال طلب التواصل إلى ${widget.name}')),
    );
  }

  void _openEditProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _followProfile() async {
    final id = widget.profileId;
    if (id != null && id.isNotEmpty) {
      await AppScope.read(context).repositories.profiles.followProfile(id);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت المتابعة')));
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 92,
              child: CustomPaint(
                painter: CardPatternPainter(color: widget.color),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: .32),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            PositionedDirectional(
              top: 42,
              start: 18,
              child: AppAvatar(
                name: widget.name,
                radius: 58,
                color: widget.color,
                badge: isMe ? 'أنا' : null,
              ),
            ),
            if (isMe)
              PositionedDirectional(
                top: 18,
                end: 18,
                child: CircleAvatar(
                  backgroundColor: context.appSurface,
                  child: IconButton(
                    onPressed: _openEditProfile,
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.blue,
                      size: 18,
                    ),
                    tooltip: 'تعديل',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 74),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, height: 1.3),
              ),
              const SizedBox(height: 6),
              Text(widget.location, style: TextStyle(color: context.appMuted)),
              const SizedBox(height: 8),
              Text(
                isMe
                    ? '${widget.followersCount} متابع · ${widget.connectionsCount} اتصال'
                    : 'ملف عام',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (!isMe) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _connectionPending
                            ? null
                            : _requestConnection,
                        style: FilledButton.styleFrom(
                          backgroundColor: !_connectionPending
                              ? AppColors.blue
                              : context.appSoft,
                          disabledBackgroundColor: context.appSoft,
                          disabledForegroundColor: context.appMuted,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          _connectionPending ? 'قيد الانتظار' : 'تواصل',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _followProfile,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.blue,
                          minimumSize: const Size.fromHeight(46),
                          side: const BorderSide(color: AppColors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('متابعة'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

enum _ProfileTab { posts, about, savedOrProjects }

enum _ProfileViewMode { grid, media, list }

class _ProfileWorkspace extends StatefulWidget {
  const _ProfileWorkspace({
    required this.profileId,
    required this.isMe,
    required this.headline,
    required this.location,
    required this.savedItems,
  });

  final String? profileId;
  final bool isMe;
  final String headline;
  final String location;
  final List<SavedContent> savedItems;

  @override
  State<_ProfileWorkspace> createState() => _ProfileWorkspaceState();
}

class _ProfileWorkspaceState extends State<_ProfileWorkspace> {
  _ProfileTab _tab = _ProfileTab.posts;
  _ProfileViewMode _viewMode = _ProfileViewMode.grid;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileSegmentedTabs(
            selected: _tab,
            isMe: widget.isMe,
            onChanged: (value) => setState(() => _tab = value),
          ),
          if (_tab == _ProfileTab.posts) ...[
            const SizedBox(height: 18),
            _ProfileViewModeTabs(
              selected: _viewMode,
              onChanged: (value) => setState(() => _viewMode = value),
            ),
          ],
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _ProfileTabBody(
              key: ValueKey('${_tab.name}-${_viewMode.name}'),
              profileId: widget.profileId,
              tab: _tab,
              viewMode: _viewMode,
              isMe: widget.isMe,
              headline: widget.headline,
              location: widget.location,
              savedItems: widget.savedItems,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSegmentedTabs extends StatelessWidget {
  const _ProfileSegmentedTabs({
    required this.selected,
    required this.isMe,
    required this.onChanged,
  });

  final _ProfileTab selected;
  final bool isMe;
  final ValueChanged<_ProfileTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          for (final tab in _ProfileTab.values) ...[
            Expanded(
              child: _ProfileSegmentTab(
                label: _tabLabel(tab, isMe),
                icon: _tabIcon(tab, isMe),
                selected: selected == tab,
                onTap: () => onChanged(tab),
              ),
            ),
            if (tab != _ProfileTab.values.last) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  String _tabLabel(_ProfileTab tab, bool isMe) {
    return switch (tab) {
      _ProfileTab.posts => 'المنشورات',
      _ProfileTab.about => 'نبذة',
      _ProfileTab.savedOrProjects => isMe ? 'المحفوظات' : 'المشاريع',
    };
  }

  IconData _tabIcon(_ProfileTab tab, bool isMe) {
    return switch (tab) {
      _ProfileTab.posts => Icons.videocam_outlined,
      _ProfileTab.about => Icons.description_outlined,
      _ProfileTab.savedOrProjects =>
        isMe ? Icons.bookmark_outline : Icons.folder_special_outlined,
    };
  }
}

class _ProfileSegmentTab extends StatelessWidget {
  const _ProfileSegmentTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.white : context.appMuted;
    final background = selected ? AppColors.blue : Colors.transparent;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 16),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileViewModeTabs extends StatelessWidget {
  const _ProfileViewModeTabs({required this.selected, required this.onChanged});

  final _ProfileViewMode selected;
  final ValueChanged<_ProfileViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          for (final mode in _ProfileViewMode.values)
            Expanded(
              child: _ProfileViewModeButton(
                mode: mode,
                selected: selected == mode,
                onTap: () => onChanged(mode),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileViewModeButton extends StatelessWidget {
  const _ProfileViewModeButton({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final _ProfileViewMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.appText : context.appMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Tooltip(
              message: _modeLabel(mode),
              child: Icon(_modeIcon(mode), color: color, size: 24),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: selected ? AppColors.blue : Colors.transparent,
          ),
        ],
      ),
    );
  }

  IconData _modeIcon(_ProfileViewMode mode) {
    return switch (mode) {
      _ProfileViewMode.grid => Icons.grid_on,
      _ProfileViewMode.media => Icons.image_outlined,
      _ProfileViewMode.list => Icons.view_module_outlined,
    };
  }

  String _modeLabel(_ProfileViewMode mode) {
    return switch (mode) {
      _ProfileViewMode.grid => 'شبكة',
      _ProfileViewMode.media => 'وسائط',
      _ProfileViewMode.list => 'قائمة',
    };
  }
}

class _ProfileTabBody extends StatelessWidget {
  const _ProfileTabBody({
    super.key,
    required this.profileId,
    required this.tab,
    required this.viewMode,
    required this.isMe,
    required this.headline,
    required this.location,
    required this.savedItems,
  });

  final String? profileId;
  final _ProfileTab tab;
  final _ProfileViewMode viewMode;
  final bool isMe;
  final String headline;
  final String location;
  final List<SavedContent> savedItems;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      _ProfileTab.posts => _ProfilePosts(profileId: profileId, mode: viewMode),
      _ProfileTab.about => _ProfileAboutPanel(
        headline: headline,
        location: location,
      ),
      _ProfileTab.savedOrProjects =>
        isMe
            ? _SavedGrid(savedItems: savedItems)
            : _ProfileProjects(profileId: profileId),
    };
  }
}

class _ProfilePosts extends StatelessWidget {
  const _ProfilePosts({required this.profileId, required this.mode});

  final String? profileId;
  final _ProfileViewMode mode;

  @override
  Widget build(BuildContext context) {
    final id = profileId;
    if (id == null || id.isEmpty) {
      return const _EmptyProfileGrid(
        icon: Icons.grid_on,
        message: 'لا توجد منشورات بعد',
      );
    }
    return FutureBuilder<List<FeedPostModel>>(
      future: AppScope.read(context).repositories.feed.fetchProfilePosts(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const FeedPostSkeleton();
        }
        final posts = snapshot.data ?? const <FeedPostModel>[];
        if (posts.isEmpty) {
          return const _EmptyProfileGrid(
            icon: Icons.grid_on,
            message: 'لا توجد منشورات بعد',
          );
        }
        return _ProfilePostsGrid(posts: posts, mode: mode);
      },
    );
  }
}

class _ProfilePostsGrid extends StatelessWidget {
  const _ProfilePostsGrid({required this.posts, required this.mode});

  final List<FeedPostModel> posts;
  final _ProfileViewMode mode;

  void _openPost(BuildContext context, FeedPostModel post) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
  }

  @override
  Widget build(BuildContext context) {
    if (mode == _ProfileViewMode.list) {
      return Column(
        children: [
          for (var index = 0; index < posts.length; index++) ...[
            ListTile(
              onTap: () => _openPost(context, posts[index]),
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.appSurfaceAlt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: AppColors.blue,
                ),
              ),
              title: Text(
                posts[index].body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                '${posts[index].reactions} تفاعل · ${posts[index].comments}',
              ),
            ),
            if (index != posts.length - 1)
              Divider(height: 18, color: context.appBorder),
          ],
        ],
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return InkWell(
            key: ValueKey('profile-post-card-${post.id}'),
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openPost(context, post),
            child: Ink(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.appSurfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.appBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Icon(
                      mode == _ProfileViewMode.media
                          ? Icons.image_outlined
                          : Icons.article_outlined,
                      color: AppColors.blue,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    mode == _ProfileViewMode.media ? post.body : post.name,
                    maxLines: mode == _ProfileViewMode.media ? 4 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: mode == _ProfileViewMode.media ? 11 : 12,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileProjects extends StatelessWidget {
  const _ProfileProjects({required this.profileId});

  final String? profileId;

  @override
  Widget build(BuildContext context) {
    final id = profileId;
    if (id == null || id.isEmpty) {
      return const _EmptyProfileGrid(
        icon: Icons.folder_special_outlined,
        message: 'لا توجد مشاريع بعد',
      );
    }
    return FutureBuilder<List<ProjectItem>>(
      future: AppScope.read(
        context,
      ).repositories.projects.fetchProjectsForProfile(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const ProjectCardSkeleton();
        }
        final projects = snapshot.data ?? const <ProjectItem>[];
        if (projects.isEmpty) {
          return const _EmptyProfileGrid(
            icon: Icons.folder_special_outlined,
            message: 'لا توجد مشاريع بعد',
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: .9,
          ),
          itemCount: projects.length,
          itemBuilder: (context, index) => _ProfileContentCard(
            icon: Icons.folder_special_outlined,
            title: projects[index].title,
            subtitle: projects[index].tagline,
          ),
        );
      },
    );
  }
}

class _EmptyProfileGrid extends StatelessWidget {
  const _EmptyProfileGrid({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(color: context.appSurfaceAlt),
              child: Icon(icon, color: context.appMuted, size: 34),
            ),
          ),
          const Spacer(),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appMuted,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProfileAboutPanel extends StatelessWidget {
  const _ProfileAboutPanel({required this.headline, required this.location});

  final String headline;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileInfoCard(
          icon: Icons.person_outline,
          title: 'نبذة مختصرة',
          subtitle: headline.isEmpty ? 'لا توجد نبذة بعد' : headline,
        ),
        const SizedBox(height: 10),
        _ProfileInfoCard(
          icon: Icons.location_on_outlined,
          title: 'الموقع',
          subtitle: location,
        ),
      ],
    );
  }
}

class _SavedGrid extends StatelessWidget {
  const _SavedGrid({required this.savedItems});

  final List<SavedContent> savedItems;

  @override
  Widget build(BuildContext context) {
    final items = savedItems.map(_savedContentItem).toList();
    if (items.isEmpty) {
      return const _EmptyProfileGrid(
        icon: Icons.bookmark_outline,
        message: 'لا توجد محفوظات بعد',
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: .9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ProfileContentCard(
          icon: item.icon,
          title: item.title,
          subtitle: item.subtitle,
        );
      },
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: context.appMuted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileContentCard extends StatelessWidget {
  const _ProfileContentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.appSurfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.blue),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, height: 1.25),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.appMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

_ContentCardData _savedContentItem(SavedContent item) {
  final icon = switch (item.type) {
    SavedContentType.post => Icons.article_outlined,
    SavedContentType.reel => Icons.smart_display_outlined,
    SavedContentType.project => Icons.folder_special_outlined,
    SavedContentType.company => Icons.business_outlined,
  };
  final typeLabel = switch (item.type) {
    SavedContentType.post => 'منشور محفوظ',
    SavedContentType.reel => 'ريل محفوظ',
    SavedContentType.project => 'مشروع محفوظ',
    SavedContentType.company => 'شركة محفوظة',
  };

  return _ContentCardData(
    icon: icon,
    title: item.title,
    subtitle: '$typeLabel · ${item.subtitle}',
  );
}

final class _ContentCardData {
  const _ContentCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
