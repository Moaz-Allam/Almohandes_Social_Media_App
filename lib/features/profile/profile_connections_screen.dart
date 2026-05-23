import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/message_item.dart';
import '../../models/network_person.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../state/app_scope.dart';
import '../messages/chat_screen.dart';
import 'profile_screen.dart';

/// Three-tab page surfaced by tapping any of the stats on your own profile.
/// Tab 0: followers (who follows me). Tab 1: connections (accepted). Tab 2:
/// following (the people I follow). The connections tab shows a Message
/// button on each row, the others don't.
class ProfileConnectionsScreen extends StatefulWidget {
  const ProfileConnectionsScreen({super.key, this.initialTab = 0});

  /// 0 = followers, 1 = connections, 2 = following.
  final int initialTab;

  @override
  State<ProfileConnectionsScreen> createState() =>
      _ProfileConnectionsScreenState();
}

class _ProfileConnectionsScreenState extends State<ProfileConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Future<List<NetworkPerson>>? _followersFuture;
  Future<List<NetworkPerson>>? _connectionsFuture;
  Future<List<NetworkPerson>>? _followingFuture;
  bool _didStart = false;
  int _lastFollowVersion = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.watch(context);
    final followChanged = controller.followVersion != _lastFollowVersion;
    if (!_didStart) {
      _didStart = true;
      _lastFollowVersion = controller.followVersion;
      final repo = controller.repositories.profiles;
      _followersFuture = repo.fetchMyFollowers();
      _connectionsFuture = repo.fetchMyConnections();
      _followingFuture = repo.fetchMyFollowing(forceRefresh: true);
    } else if (followChanged) {
      _lastFollowVersion = controller.followVersion;
      final repo = controller.repositories.profiles;
      setState(() {
        _followingFuture = repo.fetchMyFollowing(forceRefresh: true);
        _followersFuture = repo.fetchMyFollowers(forceRefresh: true);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshFollowers() async {
    final repo = AppScope.read(context).repositories.profiles;
    final future = repo.fetchMyFollowers(forceRefresh: true);
    setState(() => _followersFuture = future);
    await future;
  }

  Future<void> _refreshConnections() async {
    final repo = AppScope.read(context).repositories.profiles;
    final future = repo.fetchMyConnections(forceRefresh: true);
    setState(() => _connectionsFuture = future);
    await future;
  }

  Future<void> _refreshFollowing() async {
    final repo = AppScope.read(context).repositories.profiles;
    final future = repo.fetchMyFollowing(forceRefresh: true);
    setState(() => _followingFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appText,
        title: const Text(
          'شبكتي',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.blue,
          unselectedLabelColor: context.appMuted,
          indicatorColor: AppColors.blue,
          tabs: const [
            Tab(text: 'المتابعون'),
            Tab(text: 'الاتصالات'),
            Tab(text: 'الذين أتابعهم'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PeopleTab(
            future: _followersFuture,
            onRefresh: _refreshFollowers,
            emptyMessage:
                'لا يوجد متابعون بعد. شارك المنشورات لتزيد فرص متابعتك',
            emptyIcon: Icons.person_outline,
            showMessageButton: false,
          ),
          _PeopleTab(
            future: _connectionsFuture,
            onRefresh: _refreshConnections,
            emptyMessage:
                'لا توجد اتصالات بعد. أرسل طلب تواصل من صفحة "شبكتي"',
            emptyIcon: Icons.people_alt_outlined,
            showMessageButton: true,
          ),
          _PeopleTab(
            future: _followingFuture,
            onRefresh: _refreshFollowing,
            emptyMessage:
                'لا تتابع أحدا بعد. تابع حسابات لرؤية منشوراتهم في تبويب "الذين تتابعهم"',
            emptyIcon: Icons.person_add_alt_outlined,
            showMessageButton: false,
          ),
        ],
      ),
    );
  }
}

class _PeopleTab extends StatelessWidget {
  const _PeopleTab({
    required this.future,
    required this.onRefresh,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.showMessageButton,
  });

  final Future<List<NetworkPerson>>? future;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool showMessageButton;

  void _openProfile(BuildContext context, NetworkPerson person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          profileId: person.id,
          name: person.name,
          headline: person.title,
          color: person.color,
          avatarUrl: person.avatarUrl,
          initialConnectionStatus: person.connectionStatus,
        ),
      ),
    );
  }

  void _openChat(BuildContext context, NetworkPerson person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          contact: MessageItem(
            // ChatScreen resolves or creates the actual conversation via
            // `_actualConversationId` using this `connection:<profileId>`
            // sentinel, same pattern as project_requests_screen.
            conversationId: 'connection:${person.id}',
            profileId: person.id,
            name: person.name,
            preview: person.title,
            time: '',
            unread: false,
            color: person.color,
            avatarUrl: person.avatarUrl,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NetworkPerson>>(
      future: future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final people = snapshot.data ?? const <NetworkPerson>[];
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : people.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 70),
                      children: [
                        Icon(emptyIcon, color: AppColors.muted, size: 48),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            emptyMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.appMuted,
                              fontWeight: FontWeight.w800,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: people.length,
                      separatorBuilder: (context, _) =>
                          Divider(height: 1, color: context.appBorder),
                      itemBuilder: (context, index) {
                        final person = people[index];
                        return ListTile(
                          onTap: () => _openProfile(context, person),
                          leading: AppAvatar(
                            name: person.name,
                            radius: 24,
                            color: person.color,
                            imageUrl: person.avatarUrl,
                          ),
                          title: Text(
                            person.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            person.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: context.appMuted),
                          ),
                          trailing: showMessageButton
                              ? FilledButton.icon(
                                  onPressed: () => _openChat(context, person),
                                  icon: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 18,
                                  ),
                                  label: const Text('رسالة'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.blue,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.chevron_left),
                        );
                      },
                    ),
        );
      },
    );
  }
}
