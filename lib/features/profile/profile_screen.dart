import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/feed_post_model.dart';
import '../../models/saved_content.dart';
import '../../shared/painters/card_pattern_painter.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../state/app_scope.dart';
import '../feed/post_detail_screen.dart';
import 'models/profile_content_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.name,
    required this.headline,
    required this.color,
    this.location = 'بغداد، العراق',
    this.isMe = false,
    this.isConnectionRequest = false,
  });

  const ProfileScreen.me({super.key})
    : name = 'ريم حسن',
      headline = 'مهندسة مدنية · إدارة مواقع',
      color = AppColors.darkBlue,
      location = 'بغداد، العراق',
      isMe = true,
      isConnectionRequest = false;

  final String name;
  final String headline;
  final Color color;
  final String location;
  final bool isMe;
  final bool isConnectionRequest;

  @override
  Widget build(BuildContext context) {
    final savedItems = isMe
        ? AppScope.watch(context).savedItems
        : const <SavedContent>[];

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
                name,
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
                    name: name,
                    headline: headline,
                    color: color,
                    location: location,
                    isMe: isMe,
                  ),
                  if (isMe) ...[
                    Divider(height: 10, thickness: 10, color: context.appSoft),
                    _MyProfileWorkspace(savedItems: savedItems),
                    const SizedBox(height: 28),
                  ] else ...[
                    Divider(height: 10, thickness: 10, color: context.appSoft),
                    _PublicProfileWorkspace(
                      name: name,
                      headline: headline,
                      color: color,
                      location: location,
                    ),
                    Divider(height: 10, thickness: 10, color: context.appSoft),
                    const _ProfileSection(
                      title: 'الخبرة',
                      child: Column(
                        children: [
                          _ExperienceRow(
                            iconColor: AppColors.blue,
                            title: 'مهندس موقع',
                            company: 'شركة الرافدين للبناء · دوام كامل',
                            date: 'فبراير 2025 - الآن · سنة و4 أشهر',
                            place: 'بغداد، العراق',
                          ),
                          Divider(height: 28),
                          _ExperienceRow(
                            iconColor: AppColors.darkBlue,
                            title: 'متطوع',
                            company: 'مبادرة إعمار · دوام جزئي',
                            date: 'أغسطس 2025 - الآن · 10 أشهر',
                            place: 'البصرة، العراق',
                          ),
                          Divider(height: 28),
                          _ExperienceRow(
                            iconColor: AppColors.muted,
                            title: 'منسقة سلامة موقع',
                            company: 'مشروع طرق · مستقل',
                            date: 'أبريل 2025 - الآن',
                            place: 'أربيل، العراق',
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 10, thickness: 10, color: context.appSoft),
                    const _ProfileSection(
                      title: 'التعليم',
                      child: _ExperienceRow(
                        iconColor: AppColors.border,
                        title: 'جامعة بغداد',
                        company: 'بكالوريوس هندسة مدنية',
                        date: '2023 - 2027',
                        place: 'الدرجة: جيد جدا',
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatefulWidget {
  const _ProfileHero({
    required this.name,
    required this.headline,
    required this.color,
    required this.location,
    required this.isMe,
  });

  final String name;
  final String headline;
  final Color color;
  final String location;
  final bool isMe;

  @override
  State<_ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<_ProfileHero> {
  bool _connectionPending = false;

  void _requestConnection() {
    setState(() => _connectionPending = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إرسال طلب التواصل إلى ${widget.name}')),
    );
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
                badge: isMe ? 'متاح' : null,
              ),
            ),
            if (isMe)
              PositionedDirectional(
                top: 18,
                end: 18,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    onPressed: () {},
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
                isMe ? '2,900 متابع · 1,300 اتصال' : '370 اتصال',
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
                        onPressed: () {},
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

enum _MyProfileTab { posts, about, saved }

enum _MyProfileViewMode { grid, media, list }

extension _MyProfileTabInfo on _MyProfileTab {
  String get label {
    return switch (this) {
      _MyProfileTab.posts => 'المنشورات',
      _MyProfileTab.about => 'نبذة',
      _MyProfileTab.saved => 'المحفوظات',
    };
  }

  IconData get icon {
    return switch (this) {
      _MyProfileTab.posts => Icons.videocam_outlined,
      _MyProfileTab.about => Icons.description_outlined,
      _MyProfileTab.saved => Icons.bookmark_outline,
    };
  }
}

extension _MyProfileViewModeInfo on _MyProfileViewMode {
  IconData get icon {
    return switch (this) {
      _MyProfileViewMode.grid => Icons.grid_on,
      _MyProfileViewMode.media => Icons.image_outlined,
      _MyProfileViewMode.list => Icons.view_module_outlined,
    };
  }

  String get label {
    return switch (this) {
      _MyProfileViewMode.grid => 'شبكة',
      _MyProfileViewMode.media => 'وسائط',
      _MyProfileViewMode.list => 'قائمة',
    };
  }
}

class _MyProfileWorkspace extends StatefulWidget {
  const _MyProfileWorkspace({required this.savedItems});

  final List<SavedContent> savedItems;

  @override
  State<_MyProfileWorkspace> createState() => _MyProfileWorkspaceState();
}

class _MyProfileWorkspaceState extends State<_MyProfileWorkspace> {
  _MyProfileTab _tab = _MyProfileTab.posts;
  _MyProfileViewMode _viewMode = _MyProfileViewMode.grid;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MyProfileSegmentedTabs(
            selected: _tab,
            onChanged: (value) => setState(() => _tab = value),
          ),
          if (_tab == _MyProfileTab.posts) ...[
            const SizedBox(height: 18),
            _MyProfileViewModeTabs(
              selected: _viewMode,
              onChanged: (value) => setState(() => _viewMode = value),
            ),
          ],
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _MyProfileTabBody(
              key: ValueKey('${_tab.name}-${_viewMode.name}'),
              tab: _tab,
              viewMode: _viewMode,
              savedItems: widget.savedItems,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyProfileSegmentedTabs extends StatelessWidget {
  const _MyProfileSegmentedTabs({
    required this.selected,
    required this.onChanged,
  });

  final _MyProfileTab selected;
  final ValueChanged<_MyProfileTab> onChanged;

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
          for (final tab in _MyProfileTab.values) ...[
            Expanded(
              child: _MyProfileSegmentTab(
                tab: tab,
                selected: selected == tab,
                onTap: () => onChanged(tab),
              ),
            ),
            if (tab != _MyProfileTab.values.last) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _MyProfileSegmentTab extends StatelessWidget {
  const _MyProfileSegmentTab({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _MyProfileTab tab;
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
            Icon(tab.icon, color: foreground, size: 16),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                tab.label,
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

class _MyProfileViewModeTabs extends StatelessWidget {
  const _MyProfileViewModeTabs({
    required this.selected,
    required this.onChanged,
  });

  final _MyProfileViewMode selected;
  final ValueChanged<_MyProfileViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          for (final mode in _MyProfileViewMode.values)
            Expanded(
              child: _MyProfileViewModeButton(
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

class _MyProfileViewModeButton extends StatelessWidget {
  const _MyProfileViewModeButton({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final _MyProfileViewMode mode;
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
              message: mode.label,
              child: Icon(mode.icon, color: color, size: 24),
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
}

class _MyProfileTabBody extends StatelessWidget {
  const _MyProfileTabBody({
    super.key,
    required this.tab,
    required this.viewMode,
    required this.savedItems,
  });

  final _MyProfileTab tab;
  final _MyProfileViewMode viewMode;
  final List<SavedContent> savedItems;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      _MyProfileTab.posts => const _EmptyProfileGrid(
        icon: Icons.grid_on,
        message: 'لا توجد منشورات بعد',
      ),
      _MyProfileTab.about => const _MyProfileAboutPanel(),
      _MyProfileTab.saved => _MyProfileSavedGrid(savedItems: savedItems),
    };
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

class _MyProfileAboutPanel extends StatelessWidget {
  const _MyProfileAboutPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _MyProfileInfoCard(
          icon: Icons.person_outline,
          title: 'نبذة مختصرة',
          subtitle:
              'مهندسة مدنية تهتم بإدارة المواقع وتوثيق تقدم الأعمال بوضوح.',
        ),
        SizedBox(height: 10),
        _MyProfileInfoCard(
          icon: Icons.location_on_outlined,
          title: 'الموقع',
          subtitle: 'بغداد، العراق',
        ),
        SizedBox(height: 10),
        _MyProfileInfoCard(
          icon: Icons.groups_outlined,
          title: 'الشبكة',
          subtitle: '2,900 متابع · 1,300 اتصال',
        ),
      ],
    );
  }
}

class _MyProfileSavedGrid extends StatelessWidget {
  const _MyProfileSavedGrid({required this.savedItems});

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
        return _MyProfileContentCard(
          icon: item.icon,
          title: item.title,
          subtitle: item.subtitle,
        );
      },
    );
  }
}

class _MyProfileInfoCard extends StatelessWidget {
  const _MyProfileInfoCard({
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

class _MyProfileContentCard extends StatelessWidget {
  const _MyProfileContentCard({
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

enum _PublicProfileTab { posts, about, projects }

extension _PublicProfileTabInfo on _PublicProfileTab {
  String get label {
    return switch (this) {
      _PublicProfileTab.posts => 'المنشورات',
      _PublicProfileTab.about => 'نبذة',
      _PublicProfileTab.projects => 'المشاريع',
    };
  }

  IconData get icon {
    return switch (this) {
      _PublicProfileTab.posts => Icons.videocam_outlined,
      _PublicProfileTab.about => Icons.description_outlined,
      _PublicProfileTab.projects => Icons.folder_special_outlined,
    };
  }
}

class _PublicProfileWorkspace extends StatefulWidget {
  const _PublicProfileWorkspace({
    required this.name,
    required this.headline,
    required this.color,
    required this.location,
  });

  final String name;
  final String headline;
  final Color color;
  final String location;

  @override
  State<_PublicProfileWorkspace> createState() =>
      _PublicProfileWorkspaceState();
}

class _PublicProfileWorkspaceState extends State<_PublicProfileWorkspace> {
  _PublicProfileTab _tab = _PublicProfileTab.posts;
  _MyProfileViewMode _viewMode = _MyProfileViewMode.grid;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PublicProfileSegmentedTabs(
            selected: _tab,
            onChanged: (value) => setState(() => _tab = value),
          ),
          if (_tab == _PublicProfileTab.posts) ...[
            const SizedBox(height: 18),
            _MyProfileViewModeTabs(
              selected: _viewMode,
              onChanged: (value) => setState(() => _viewMode = value),
            ),
          ],
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _PublicProfileTabBody(
              key: ValueKey('${_tab.name}-${_viewMode.name}'),
              tab: _tab,
              viewMode: _viewMode,
              name: widget.name,
              headline: widget.headline,
              color: widget.color,
              location: widget.location,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicProfileSegmentedTabs extends StatelessWidget {
  const _PublicProfileSegmentedTabs({
    required this.selected,
    required this.onChanged,
  });

  final _PublicProfileTab selected;
  final ValueChanged<_PublicProfileTab> onChanged;

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
          for (final tab in _PublicProfileTab.values) ...[
            Expanded(
              child: _PublicProfileSegmentTab(
                tab: tab,
                selected: selected == tab,
                onTap: () => onChanged(tab),
              ),
            ),
            if (tab != _PublicProfileTab.values.last) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _PublicProfileSegmentTab extends StatelessWidget {
  const _PublicProfileSegmentTab({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _PublicProfileTab tab;
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
            Icon(tab.icon, color: foreground, size: 16),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                tab.label,
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

class _PublicProfileTabBody extends StatelessWidget {
  const _PublicProfileTabBody({
    super.key,
    required this.tab,
    required this.viewMode,
    required this.name,
    required this.headline,
    required this.color,
    required this.location,
  });

  final _PublicProfileTab tab;
  final _MyProfileViewMode viewMode;
  final String name;
  final String headline;
  final Color color;
  final String location;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      _PublicProfileTab.posts => _PublicProfilePostsGrid(
        posts: _publicProfilePosts(name, headline, color),
        viewMode: viewMode,
      ),
      _PublicProfileTab.about => _PublicProfileAboutPanel(
        headline: headline,
        location: location,
      ),
      _PublicProfileTab.projects => _PublicProfileProjectsGrid(
        projects: _publicProfileProjects(name),
      ),
    };
  }
}

class _PublicProfilePostsGrid extends StatelessWidget {
  const _PublicProfilePostsGrid({required this.posts, required this.viewMode});

  final List<FeedPostModel> posts;
  final _MyProfileViewMode viewMode;

  void _openPost(BuildContext context, FeedPostModel post) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
  }

  @override
  Widget build(BuildContext context) {
    if (viewMode == _MyProfileViewMode.list) {
      return Column(
        children: [
          for (var index = 0; index < posts.length; index++) ...[
            _PublicPostListTile(
              key: ValueKey('profile-post-list-tile-$index'),
              post: posts[index],
              onTap: () => _openPost(context, posts[index]),
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
          return _PublicPostSquareCard(
            key: ValueKey('profile-post-card-$index'),
            post: posts[index],
            showBody: viewMode == _MyProfileViewMode.media,
            onTap: () => _openPost(context, posts[index]),
          );
        },
      ),
    );
  }
}

class _PublicPostSquareCard extends StatelessWidget {
  const _PublicPostSquareCard({
    super.key,
    required this.post,
    required this.showBody,
    required this.onTap,
  });

  final FeedPostModel post;
  final bool showBody;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
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
                showBody ? Icons.image_outlined : Icons.article_outlined,
                color: AppColors.blue,
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              showBody ? post.body : post.name,
              maxLines: showBody ? 4 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.appText,
                fontSize: showBody ? 11 : 12,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicPostListTile extends StatelessWidget {
  const _PublicPostListTile({
    super.key,
    required this.post,
    required this.onTap,
  });

  final FeedPostModel post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: context.appSurfaceAlt,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.article_outlined, color: AppColors.blue),
      ),
      title: Text(
        post.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        '${post.reactions} تفاعل · ${post.comments}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PublicProfileAboutPanel extends StatelessWidget {
  const _PublicProfileAboutPanel({
    required this.headline,
    required this.location,
  });

  final String headline;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MyProfileInfoCard(
          icon: Icons.person_outline,
          title: 'نبذة مختصرة',
          subtitle: '$headline يعمل على مشاريع تنفيذ وتعاون ميداني.',
        ),
        const SizedBox(height: 10),
        _MyProfileInfoCard(
          icon: Icons.location_on_outlined,
          title: 'الموقع',
          subtitle: location,
        ),
        const SizedBox(height: 10),
        const _MyProfileInfoCard(
          icon: Icons.groups_outlined,
          title: 'الشبكة',
          subtitle: '370 اتصال · 8 علاقات مشتركة',
        ),
      ],
    );
  }
}

class _PublicProfileProjectsGrid extends StatelessWidget {
  const _PublicProfileProjectsGrid({required this.projects});

  final List<ProfileContentItem> projects;

  @override
  Widget build(BuildContext context) {
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
      itemBuilder: (context, index) {
        final item = projects[index];
        return _MyProfileContentCard(
          icon: item.icon,
          title: item.title,
          subtitle: item.subtitle,
        );
      },
    );
  }
}

List<FeedPostModel> _publicProfilePosts(
  String name,
  String headline,
  Color color,
) {
  return [
    FeedPostModel(
      name: name,
      headline: headline,
      time: 'قبل ساعتين',
      body: 'مشاركة عن تحديات متابعة التنفيذ اليومي وتنسيق فريق الموقع.',
      reactions: '398',
      comments: '64 تعليق',
      avatarColor: color,
      showMedia: false,
    ),
    FeedPostModel(
      name: name,
      headline: headline,
      time: 'قبل يوم',
      body: 'أسئلة عن توزيع الأدوار بين المهندس والحرفي ومشغل الآلية.',
      reactions: '91',
      comments: '22 تعليق',
      avatarColor: color,
      showMedia: true,
    ),
    FeedPostModel(
      name: name,
      headline: headline,
      time: 'قبل 3 أيام',
      body: 'قائمة مختصرة لأدوات التخطيط والتسليم الأسبوعي في الموقع.',
      reactions: '77',
      comments: '18 تعليق',
      avatarColor: color,
      showMedia: false,
    ),
  ];
}

List<ProfileContentItem> _publicProfileProjects(String name) {
  return [
    ProfileContentItem(
      icon: Icons.folder_special_outlined,
      title: 'مشروع تعاوني نشره $name',
      subtitle: 'مشروع · هجين',
      detail: 'مطلوب أعضاء فريق لديهم خبرة في التنفيذ والتواصل الميداني.',
    ),
    const ProfileContentItem(
      icon: Icons.folder_special_outlined,
      title: 'تجهيز مخططات تنفيذية لفريق صغير',
      subtitle: 'مشروع · عن بعد',
      detail: 'مشروع قصير لتنسيق المخططات قبل بدء التنفيذ.',
    ),
    const ProfileContentItem(
      icon: Icons.folder_special_outlined,
      title: 'متابعة أعمال تشطيب',
      subtitle: 'مشروع بحثي · بغداد',
      detail: 'تدريب عملي على التوثيق واختبار قوائم الفحص.',
    ),
  ];
}

ProfileContentItem _savedContentItem(SavedContent item) {
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

  return ProfileContentItem(
    icon: icon,
    title: item.title,
    subtitle: '$typeLabel · ${item.subtitle}',
    detail: item.detail,
  );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ExperienceRow extends StatelessWidget {
  const _ExperienceRow({
    required this.iconColor,
    required this.title,
    required this.company,
    required this.date,
    required this.place,
  });

  final Color iconColor;
  final String title;
  final String company;
  final String date;
  final String place;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.business_center, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(company, style: const TextStyle(fontSize: 16)),
              Text(date, style: TextStyle(color: context.appMuted)),
              Text(place, style: TextStyle(color: context.appMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
