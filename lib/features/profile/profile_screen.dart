import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/feed_post_model.dart';
import '../../models/project_item.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/media_preview.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/app_scope.dart';
import '../feed/post_detail_screen.dart';
import '../messages/messages_screen.dart';
import '../projects/project_requests_screen.dart';

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
    this.avatarUrl,
    this.initialConnectionStatus = 'none',
  });

  const ProfileScreen.me({super.key})
    : name = '',
      headline = '',
      color = AppColors.darkBlue,
      profileId = null,
      location = 'العراق',
      isMe = true,
      isConnectionRequest = false,
      avatarUrl = null,
      initialConnectionStatus = 'none';

  final String name;
  final String headline;
  final Color color;
  final String? profileId;
  final String location;
  final bool isMe;
  final bool isConnectionRequest;
  final String? avatarUrl;
  final String initialConnectionStatus;

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
    final effectiveAbout = isMe
        ? (currentProfile?.about.isNotEmpty == true
              ? currentProfile!.about
              : effectiveHeadline)
        : headline;
    final effectiveSkills = isMe
        ? (currentProfile?.skills.toList(growable: false) ?? const <String>[])
        : const <String>[];
    final effectiveAvatarUrl = isMe ? currentProfile?.avatarUrl : avatarUrl;
    final effectiveCoverUrl = isMe ? currentProfile?.coverUrl : null;
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
                    about: effectiveAbout,
                    avatarUrl: effectiveAvatarUrl,
                    coverUrl: effectiveCoverUrl,
                    isMe: isMe,
                    followersCount: currentProfile?.followersCount ?? 0,
                    connectionsCount: currentProfile?.followingCount ?? 0,
                    initialConnectionStatus: initialConnectionStatus,
                  ),
                  Divider(height: 10, thickness: 10, color: context.appSoft),
                  _ProfileWorkspace(
                    profileId: effectiveProfileId,
                    isMe: isMe,
                    headline: effectiveHeadline,
                    about: effectiveAbout,
                    location: effectiveLocation,
                    skills: effectiveSkills,
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
      return 'ملفك الشخصي';
    }
    if (profile.headline.isNotEmpty) {
      return profile.headline;
    }
    if (profile.role.isNotEmpty) {
      return profile.role;
    }
    return 'ملفك الشخصي';
  }
}

class _ProfileHero extends StatefulWidget {
  const _ProfileHero({
    required this.profileId,
    required this.name,
    required this.headline,
    required this.color,
    required this.location,
    required this.about,
    required this.avatarUrl,
    required this.coverUrl,
    required this.isMe,
    required this.followersCount,
    required this.connectionsCount,
    required this.initialConnectionStatus,
  });

  final String? profileId;
  final String name;
  final String headline;
  final Color color;
  final String location;
  final String about;
  final String? avatarUrl;
  final String? coverUrl;
  final bool isMe;
  final int followersCount;
  final int connectionsCount;
  final String initialConnectionStatus;

  @override
  State<_ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<_ProfileHero> {
  late String _connectionStatus;

  @override
  void initState() {
    super.initState();
    _connectionStatus = widget.initialConnectionStatus;
    _loadConnectionStatus();
  }

  Future<void> _loadConnectionStatus() async {
    final id = widget.profileId;
    if (widget.isMe || id == null || id.isEmpty) {
      return;
    }
    final status = await AppScope.read(
      context,
    ).repositories.profiles.connectionStatus(id);
    if (mounted && status != 'none') {
      setState(() => _connectionStatus = status);
    }
  }

  Future<void> _requestConnection() async {
    setState(() => _connectionStatus = 'pending');
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

  Future<void> _openEditAbout() async {
    final controller = TextEditingController(text: widget.about);
    final about = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تعديل النبذة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 5,
              maxLines: 8,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'نبذة تعريفية',
                hintText: 'اكتب نبذة قصيرة تظهر في ملفك الشخصي',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (about == null || !mounted) {
      return;
    }
    await AppScope.read(context).updateMyAbout(about);
  }

  void _openAvatar() {
    _openMediaViewer(
      media: _ProfileMedia.avatar,
      imageUrl: widget.avatarUrl,
      title: 'صورة الملف الشخصي',
    );
  }

  void _openCover() {
    _openMediaViewer(
      media: _ProfileMedia.cover,
      imageUrl: widget.coverUrl,
      title: 'صورة الغلاف',
    );
  }

  void _openMediaViewer({
    required _ProfileMedia media,
    required String? imageUrl,
    required String title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ProfileMediaViewer(
          media: media,
          title: title,
          name: widget.name,
          color: widget.color,
          imageUrl: imageUrl,
          canEdit: widget.isMe,
        ),
      ),
    );
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

  void _openMessages() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MessagesScreen()));
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
            GestureDetector(
              onTap: isMe || (widget.coverUrl?.isNotEmpty ?? false)
                  ? _openCover
                  : null,
              child: SizedBox(
                width: double.infinity,
                height: 92,
                child: widget.coverUrl?.isNotEmpty == true
                    ? _ProfileImageView(
                        imageUrl: widget.coverUrl!,
                        fit: BoxFit.cover,
                        fallback: _PatternCover(color: widget.color),
                      )
                    : _PatternCover(color: widget.color),
              ),
            ),
            if (isMe)
              PositionedDirectional(
                top: 12,
                start: 18,
                child: _MediaEditHint(
                  icon: Icons.image_outlined,
                  label: 'الغلاف',
                  onTap: _openCover,
                ),
              ),
            PositionedDirectional(
              top: 42,
              start: 18,
              child: GestureDetector(
                onTap: isMe || (widget.avatarUrl?.isNotEmpty ?? false)
                    ? _openAvatar
                    : null,
                child: AppAvatar(
                  name: widget.name,
                  radius: 58,
                  color: widget.color,
                  badge: isMe ? 'أنا' : null,
                  imageUrl: widget.avatarUrl,
                ),
              ),
            ),
            if (isMe)
              PositionedDirectional(
                top: 112,
                start: 92,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: context.appSurface,
                  child: IconButton(
                    onPressed: _openAvatar,
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.blue,
                      size: 16,
                    ),
                    tooltip: 'تغيير الصورة',
                  ),
                ),
              ),
            if (isMe)
              PositionedDirectional(
                top: 18,
                end: 18,
                child: CircleAvatar(
                  backgroundColor: context.appSurface,
                  child: IconButton(
                    onPressed: _openEditAbout,
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.blue,
                      size: 18,
                    ),
                    tooltip: 'تعديل النبذة',
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
              GestureDetector(
                onTap: isMe ? _openMessages : null,
                child: Text(
                  isMe
                      ? '${widget.followersCount} متابع · ${widget.connectionsCount} اتصال'
                      : 'ملف عام',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!isMe) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _connectionStatus == 'none'
                            ? _requestConnection
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _connectionStatus == 'none'
                              ? AppColors.blue
                              : context.appSoft,
                          disabledBackgroundColor: context.appSoft,
                          disabledForegroundColor: context.appMuted,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(switch (_connectionStatus) {
                          'accepted' => 'متصل',
                          'pending' => 'قيد الانتظار',
                          _ => 'تواصل',
                        }),
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
    required this.about,
    required this.location,
    required this.skills,
  });

  final String? profileId;
  final bool isMe;
  final String headline;
  final String about;
  final String location;
  final List<String> skills;

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
              about: widget.about,
              location: widget.location,
              skills: widget.skills,
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
      _ProfileTab.savedOrProjects => isMe ? 'مشاريعي' : 'المشاريع',
    };
  }

  IconData _tabIcon(_ProfileTab tab, bool isMe) {
    return switch (tab) {
      _ProfileTab.posts => Icons.videocam_outlined,
      _ProfileTab.about => Icons.description_outlined,
      _ProfileTab.savedOrProjects =>
        isMe ? Icons.folder_special_outlined : Icons.folder_special_outlined,
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

    return SizedBox.expand(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          alignment: Alignment.center,
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
    required this.about,
    required this.location,
    required this.skills,
  });

  final String? profileId;
  final _ProfileTab tab;
  final _ProfileViewMode viewMode;
  final bool isMe;
  final String headline;
  final String about;
  final String location;
  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      _ProfileTab.posts => _ProfilePosts(profileId: profileId, mode: viewMode),
      _ProfileTab.about => _ProfileAboutPanel(
        headline: headline,
        about: about,
        location: location,
        skills: skills,
      ),
      _ProfileTab.savedOrProjects => _ProfileProjects(
        profileId: profileId,
        showRequests: isMe,
      ),
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
    final visiblePosts = mode == _ProfileViewMode.media
        ? posts.where((post) => post.showMedia).toList(growable: false)
        : posts;
    if (visiblePosts.isEmpty) {
      return const _EmptyProfileGrid(
        icon: Icons.image_outlined,
        message: 'لا توجد وسائط بعد',
      );
    }
    if (mode == _ProfileViewMode.list) {
      return Column(
        children: [
          for (var index = 0; index < visiblePosts.length; index++) ...[
            Builder(
              builder: (context) {
                final post = visiblePosts[index];
                return ListTile(
                  onTap: () => _openPost(context, post),
                  contentPadding: EdgeInsets.zero,
                  leading: _ProfilePostThumb(post: post, size: 48),
                  title: Text(
                    post.body.trim().isEmpty ? _postKindLabel(post) : post.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${_postKindLabel(post)} · ${post.reactions} تفاعل · ${post.comments}',
                  ),
                );
              },
            ),
            if (index != visiblePosts.length - 1)
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
        itemCount: visiblePosts.length,
        itemBuilder: (context, index) {
          final post = visiblePosts[index];
          return InkWell(
            key: ValueKey('profile-post-card-${post.id}'),
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openPost(context, post),
            child: _ProfilePostThumb(post: post),
          );
        },
      ),
    );
  }

  String _postKindLabel(FeedPostModel post) {
    if (post.isReel) {
      return 'ريل';
    }
    if (post.isImagePost || post.showMedia) {
      return 'صورة';
    }
    return 'منشور';
  }
}

class _ProfilePostThumb extends StatelessWidget {
  const _ProfilePostThumb({required this.post, this.size});

  final FeedPostModel post;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final child = post.showMedia
        ? Stack(
            fit: StackFit.expand,
            children: [
              MediaPreview(
                mediaUrl: post.mediaUrl,
                mediaType: post.mediaType,
                fallbackLabel: post.isReel ? 'ريل' : 'صورة',
              ),
              if (post.isReel)
                const Center(
                  child: Icon(Icons.play_circle, color: Colors.white, size: 34),
                ),
            ],
          )
        : Container(
            color: AppColors.blue,
            alignment: Alignment.center,
            child: const Text(
              'منشور',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.appSurfaceAlt,
            border: Border.all(color: context.appBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ProfileProjects extends StatelessWidget {
  const _ProfileProjects({required this.profileId, required this.showRequests});

  final String? profileId;
  final bool showRequests;

  void _openProject(BuildContext context, ProjectItem project) {
    if (!showRequests) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectRequestsScreen(project: project),
      ),
    );
  }

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
          itemBuilder: (context, index) {
            final project = projects[index];
            return _ProfileContentCard(
              icon: Icons.folder_special_outlined,
              title: project.title,
              subtitle: showRequests
                  ? 'اضغط لعرض طلبات المشروع'
                  : project.tagline,
              onTap: showRequests ? () => _openProject(context, project) : null,
            );
          },
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
  const _ProfileAboutPanel({
    required this.headline,
    required this.about,
    required this.location,
    required this.skills,
  });

  final String headline;
  final String about;
  final String location;
  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileInfoCard(
          icon: Icons.description_outlined,
          title: 'نبذة تعريفية',
          subtitle: about.isEmpty ? 'لا توجد نبذة بعد' : about,
        ),
        const SizedBox(height: 10),
        _ProfileInfoCard(
          icon: Icons.badge_outlined,
          title: 'المسمى',
          subtitle: headline.isEmpty ? 'غير محدد' : headline,
        ),
        const SizedBox(height: 10),
        _ProfileInfoCard(
          icon: Icons.location_on_outlined,
          title: 'الموقع',
          subtitle: location,
        ),
        if (skills.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ProfileSkillsCard(skills: skills),
        ],
      ],
    );
  }
}

class _ProfileSkillsCard extends StatelessWidget {
  const _ProfileSkillsCard({required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.blue),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'المهارات',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in skills)
                Chip(
                  label: Text(skill),
                  backgroundColor: context.appSurfaceAlt,
                  side: BorderSide(color: context.appBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  labelStyle: TextStyle(
                    color: context.appText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: context.appBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
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
        ),
      ),
    );
  }
}

class _PatternCover extends StatelessWidget {
  const _PatternCover({required Color color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: context.appSurfaceAlt),
      child: const SizedBox.expand(),
    );
  }
}

class _ProfileImageView extends StatelessWidget {
  const _ProfileImageView({
    required this.imageUrl,
    required this.fit,
    required this.fallback,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final bytes = _bytesFromDataUrl(imageUrl);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }
    return Image.network(
      imageUrl,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  Uint8List? _bytesFromDataUrl(String value) {
    if (!value.startsWith('data:')) {
      return null;
    }
    final comma = value.indexOf(',');
    if (comma == -1) {
      return null;
    }
    try {
      return base64Decode(value.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }
}

class _MediaEditHint extends StatelessWidget {
  const _MediaEditHint({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ProfileMedia { avatar, cover }

class _ProfileMediaViewer extends StatefulWidget {
  const _ProfileMediaViewer({
    required this.media,
    required this.title,
    required this.name,
    required this.color,
    required this.imageUrl,
    required this.canEdit,
  });

  final _ProfileMedia media;
  final String title;
  final String name;
  final Color color;
  final String? imageUrl;
  final bool canEdit;

  @override
  State<_ProfileMediaViewer> createState() => _ProfileMediaViewerState();
}

class _ProfileMediaViewerState extends State<_ProfileMediaViewer> {
  String? _imageUrl;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.imageUrl;
  }

  Future<void> _pickImage() async {
    if (_isPicking) {
      return;
    }
    setState(() => _isPicking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: widget.media == _ProfileMedia.cover ? 1400 : 720,
        imageQuality: 82,
      );
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      final mimeType = picked.mimeType ?? _mimeTypeFromPath(picked.path);
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
      if (!mounted) {
        return;
      }
      setState(() => _imageUrl = dataUrl);
      final app = AppScope.read(context);
      if (widget.media == _ProfileMedia.avatar) {
        await app.updateMyAvatar(dataUrl);
      } else {
        await app.updateMyCover(dataUrl);
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  String _mimeTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageUrl != null && _imageUrl!.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          if (widget.canEdit)
            IconButton(
              onPressed: _isPicking ? null : _pickImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              tooltip: 'اختيار صورة',
            ),
        ],
      ),
      body: Center(
        child: hasImage
            ? InteractiveViewer(
                child: _ProfileImageView(
                  imageUrl: _imageUrl!,
                  fit: BoxFit.contain,
                  fallback: _MediaPlaceholder(viewer: widget),
                ),
              )
            : _MediaPlaceholder(viewer: widget),
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: _isPicking ? null : _pickImage,
              backgroundColor: AppColors.blue,
              icon: _isPicking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(_isPicking ? 'جاري الاختيار...' : 'تغيير الصورة'),
            )
          : null,
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.viewer});

  final _ProfileMediaViewer viewer;

  @override
  Widget build(BuildContext context) {
    if (viewer.media == _ProfileMedia.avatar) {
      return AppAvatar(name: viewer.name, radius: 88, color: viewer.color);
    }
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: _PatternCover(color: viewer.color),
    );
  }
}
