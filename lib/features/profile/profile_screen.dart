import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/profile_repository.dart';
import '../../models/feed_post_model.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/media_preview.dart';
import '../../state/app_scope.dart';
import '../composer/composer_screen.dart';
import '../composer/project_form_screen.dart';
import '../home/widgets/home_top_bar.dart';

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
    this.isPrivateProfile = false,
    this.onMenu,
    this.onMessages,
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
      initialConnectionStatus = 'none',
      isPrivateProfile = false,
      onMenu = null,
      onMessages = null;

  final String name;
  final String headline;
  final Color color;
  final String? profileId;
  final String location;
  final bool isMe;
  final bool isConnectionRequest;
  final String? avatarUrl;
  final String initialConnectionStatus;
  final bool isPrivateProfile;
  final VoidCallback? onMenu;
  final VoidCallback? onMessages;

  @override
  Widget build(BuildContext context) {
    final currentProfile = isMe ? AppScope.watch(context).profile : null;
    final effectiveName = isMe
        ? ((currentProfile?.fullName.isNotEmpty ?? false)
              ? currentProfile!.fullName
              : 'ملفي الشخصي')
        : (name.trim().isEmpty ? 'الملف الشخصي' : name);
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
    final effectiveColor = isMe ? context.appPrimary : color;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
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
                const SizedBox(height: 24),
                _ProfileWorkspace(
                  profileId: effectiveProfileId,
                  isMe: isMe,
                  headline: effectiveHeadline,
                  about: effectiveAbout,
                  location: effectiveLocation,
                  skills: effectiveSkills,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: isMe
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 16),
              child: FloatingActionButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComposerScreen(
                      onClose: () => Navigator.pop(context),
                    ),
                  ),
                ),
                backgroundColor: context.appPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
              ),
            )
          : null,
    );
  }

  String _currentHeadline(dynamic profile) {
    if (profile == null) return 'ملفك الشخصي';
    if (profile.headline.isNotEmpty) return profile.headline;
    if (profile.role.isNotEmpty) return profile.role;
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
  bool _isFollowing = false;
  ProfileStats _stats = ProfileStats.empty;

  @override
  void initState() {
    super.initState();
    _connectionStatus = widget.initialConnectionStatus;
    _loadStats();
  }

  Future<void> _loadStats() async {
    final id = widget.profileId;
    if (id == null) return;
    final stats = await AppScope.read(context).repositories.profiles.fetchProfileStats(id);
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.color.withValues(alpha: 0.25),
                    context.appPrimary.withValues(alpha: 0.15),
                    context.appSurface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.appBackground,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.appPrimary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: AppAvatar(
                    name: widget.name,
                    radius: 56,
                    color: widget.color,
                    imageUrl: widget.avatarUrl,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 60),
        Text(
          widget.name,
          style: TextStyle(
            color: context.appText,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.location,
              style: TextStyle(
                color: context.appMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.location_on_outlined,
              size: 14,
              color: context.appMuted,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatItem(label: 'متابع', count: _stats.followers),
            const SizedBox(width: 24),
            _StatItem(label: 'يتابع', count: _stats.following),
            const SizedBox(width: 24),
            _StatItem(label: 'اتصال', count: _stats.connections),
          ],
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.appSurfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.appBorder.withValues(alpha: 0.6),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.isMe ? 'تعديل الملف الشخصي' : 'الرسائل',
                    style: TextStyle(
                      color: context.appText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (widget.isMe) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => AppScope.read(context).signOut(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.appSurfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.appBorder.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: context.appMuted,
                      size: 20,
                    ),
                  ),
                ),
              ],
              if (!widget.isMe) ...[
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.appPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: context.appPrimary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: context.appText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: context.appMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

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
  int _selectedTab = 0;
  int _selectedSubTab = 0;

  final _tabs = [
    (label: 'المنشورات', icon: Icons.videocam_outlined),
    (label: 'نبذة', icon: Icons.description_outlined),
    (label: 'الأعمال', icon: Icons.image_outlined),
    (label: 'البرامج والتطبيقات', icon: Icons.memory_outlined),
  ];

  final _subTabs = [
    Icons.grid_view_rounded,
    Icons.image_outlined,
    Icons.movie_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1115),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _tabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedTab = i;
                        _selectedSubTab = 0;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedTab == i
                              ? const Color(0xFF1A1D23)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _tabs[i].icon,
                              size: 18,
                              color: _selectedTab == i
                                  ? Colors.white
                                  : context.appMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _tabs[i].label,
                              style: TextStyle(
                                color: _selectedTab == i
                                    ? Colors.white
                                    : context.appMuted,
                                fontWeight: _selectedTab == i
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_selectedTab == 0) ...[
          const SizedBox(height: 16),
          Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: context.appBorder.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                for (int i = 0; i < _subTabs.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSubTab = i),
                      child: Column(
                        children: [
                          Expanded(
                            child: Icon(
                              _subTabs[i],
                              color: _selectedSubTab == i
                                  ? Colors.white
                                  : context.appMuted,
                              size: 22,
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 2,
                            width: 60,
                            decoration: BoxDecoration(
                              color: _selectedSubTab == i
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0: // المنشورات
        if (_selectedSubTab == 0) {
          return _ProfilePostsGrid(profileId: widget.profileId);
        } else if (_selectedSubTab == 2) {
          return _ProfileReelsGrid(profileId: widget.profileId);
        }
        // Gallery sub-tab or default
        return _ProfilePostsGrid(profileId: widget.profileId);
      case 1: // نبذة
        return _ProfileAbout(about: widget.about, skills: widget.skills);
      case 2: // الأعمال
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.work_outline_rounded, size: 48, color: context.appMuted),
                const SizedBox(height: 16),
                Text(
                  'لا توجد أعمال لعرضها حالياً',
                  style: TextStyle(color: context.appMuted),
                ),
                if (widget.isMe) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProjectFormScreen()),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إضافة مشروع جديد'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.appPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      case 3: // البرامج والتطبيقات
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.developer_mode_rounded, size: 48, color: context.appMuted),
                const SizedBox(height: 16),
                Text(
                  'لا توجد برامج أو تطبيقات لعرضها حالياً',
                  style: TextStyle(color: context.appMuted),
                ),
                if (widget.isMe) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProjectFormScreen()),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إضافة برنامج/تطبيق'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.appPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      default:
        return const SizedBox();
    }
  }
}

class _ProfilePostsGrid extends StatelessWidget {
  const _ProfilePostsGrid({required this.profileId});
  final String? profileId;

  @override
  Widget build(BuildContext context) {
    if (profileId == null) return const SizedBox();
    return FutureBuilder<List<FeedPostModel>>(
      future: AppScope.read(context).repositories.feed.fetchProfilePosts(profileId!),
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Text(
              'لا توجد منشورات',
              style: TextStyle(color: context.appMuted),
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Container(
              decoration: BoxDecoration(
                color: context.appSurfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.appBorder.withValues(alpha: 0.5),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: MediaPreview(
                mediaUrl: post.mediaUrl,
                mediaType: post.mediaType,
                fallbackLabel: '',
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileReelsGrid extends StatelessWidget {
  const _ProfileReelsGrid({required this.profileId});
  final String? profileId;

  @override
  Widget build(BuildContext context) {
    if (profileId == null) return const SizedBox();
    return FutureBuilder(
      future: AppScope.read(context).repositories.reels.fetchReelsForProfile(profileId!),
      builder: (context, snapshot) {
        final reels = snapshot.data ?? [];
        if (reels.isEmpty) {
          return Center(
            child: Text(
              'لا توجد ريلز',
              style: TextStyle(color: context.appMuted),
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.7,
          ),
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final reel = reels[index];
            return Container(
              decoration: BoxDecoration(
                color: context.appSurfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.appBorder.withValues(alpha: 0.5),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: MediaPreview(
                mediaUrl: reel.videoUrl ?? '',
                mediaType: 'video',
                fallbackLabel: '',
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileAbout extends StatelessWidget {
  const _ProfileAbout({required this.about, required this.skills});
  final String about;
  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نبذة تعريفية',
            style: TextStyle(
              color: context.appText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            about.isEmpty ? 'لا توجد نبذة بعد' : about,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: context.appMuted,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'المهارات',
            style: TextStyle(
              color: context.appText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            textDirection: TextDirection.rtl,
            children: [
              for (final skill in skills)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: context.appPrimary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      color: context.appPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
