import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/message_item.dart';
import '../../models/project_application_request.dart';
import '../../models/project_item.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../state/app_scope.dart';
import '../messages/chat_screen.dart';
import '../profile/profile_screen.dart';

class ProjectRequestsScreen extends StatefulWidget {
  const ProjectRequestsScreen({super.key, required this.project});

  final ProjectItem project;

  @override
  State<ProjectRequestsScreen> createState() => _ProjectRequestsScreenState();
}

class _ProjectRequestsScreenState extends State<ProjectRequestsScreen> {
  late Future<List<ProjectApplicationRequest>> _requestsFuture;
  final Set<String> _pendingConnectionIds = {};
  final Set<String> _connectingIds = {};

  @override
  void initState() {
    super.initState();
    _requestsFuture = Future.value(const <ProjectApplicationRequest>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _requestsFuture = _loadRequests();
  }

  Future<List<ProjectApplicationRequest>> _loadRequests({
    bool forceRefresh = false,
  }) {
    return AppScope.read(
      context,
    ).repositories.projects.fetchProjectApplications(
      widget.project.id,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _requestsFuture = _loadRequests(forceRefresh: true);
    });
    await _requestsFuture;
  }

  void _openProfile(ProjectApplicationRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          profileId: request.profileId,
          name: request.name,
          headline: request.title,
          color: request.color,
          avatarUrl: request.avatarUrl,
          initialConnectionStatus: 'none',
        ),
      ),
    );
  }

  Future<void> _connect(ProjectApplicationRequest request) async {
    if (request.profileId.isEmpty ||
        _connectingIds.contains(request.profileId)) {
      return;
    }
    setState(() => _connectingIds.add(request.profileId));
    try {
      await AppScope.read(
        context,
      ).repositories.profiles.requestConnection(request.profileId);
      if (mounted) {
        setState(() => _pendingConnectionIds.add(request.profileId));
      }
    } finally {
      if (mounted) {
        setState(() => _connectingIds.remove(request.profileId));
      }
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إرسال طلب تواصل إلى ${request.name}')),
    );
  }

  void _openChat(ProjectApplicationRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          contact: MessageItem(
            conversationId: 'connection:${request.profileId}',
            profileId: request.profileId,
            name: request.name,
            preview: request.title,
            time: '',
            unread: false,
            color: request.color,
            avatarUrl: request.avatarUrl,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appText,
        title: const Text(
          'طلبات المشروع',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appSurface,
              border: Border(bottom: BorderSide(color: context.appBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: project.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.folder_special_outlined,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.appMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ProjectApplicationRequest>>(
              future: _requestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final requests =
                    snapshot.data ?? const <ProjectApplicationRequest>[];
                if (requests.isEmpty) {
                  return const _NoProjectRequests();
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    itemCount: requests.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) => _RequestCard(
                      request: requests[index],
                      onProfile: () => _openProfile(requests[index]),
                      onConnect: () => _connect(requests[index]),
                      onMessage: () => _openChat(requests[index]),
                      pending: _pendingConnectionIds.contains(
                        requests[index].profileId,
                      ),
                      loading: _connectingIds.contains(
                        requests[index].profileId,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({
    required this.request,
    required this.onProfile,
    required this.onConnect,
    required this.onMessage,
    required this.pending,
    required this.loading,
  });

  final ProjectApplicationRequest request;
  final VoidCallback onProfile;
  final VoidCallback onConnect;
  final VoidCallback onMessage;
  final bool pending;
  final bool loading;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  Future<String>? _statusFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _statusFuture ??= AppScope.read(
      context,
    ).repositories.profiles.connectionStatus(widget.request.profileId);
  }

  ProjectApplicationRequest get request => widget.request;
  VoidCallback get onProfile => widget.onProfile;
  VoidCallback get onConnect => widget.onConnect;
  VoidCallback get onMessage => widget.onMessage;
  bool get pending => widget.pending;
  bool get loading => widget.loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: context.appBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppAvatar(
                  name: request.name,
                  radius: 26,
                  color: request.color,
                  imageUrl: request.avatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${request.title} · ${request.status}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.appMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.message.isEmpty ? 'لا توجد رسالة مرفقة' : request.message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appText, height: 1.45),
            ),
            const SizedBox(height: 10),
            Text(
              '${request.attachmentsCount} ملفات مرفقة',
              style: const TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onProfile,
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: const Text('الملف'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<String>(
                    future: _statusFuture,
                    builder: (context, snapshot) {
                      final connected = snapshot.data == 'accepted';
                      final isPending =
                          pending || loading || snapshot.data == 'pending';
                      return FilledButton.icon(
                        onPressed: connected
                            ? onMessage
                            : (isPending ? null : onConnect),
                        icon: loading
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                connected
                                    ? Icons.chat_bubble_outline
                                    : (isPending
                                          ? Icons.hourglass_top
                                          : Icons.person_add_alt),
                                size: 18,
                              ),
                        label: Text(
                          connected
                              ? 'راسل'
                              : (isPending ? 'قيد الانتظار' : 'تواصل'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: loading
                              ? AppColors.darkBlue
                              : AppColors.blue,
                          disabledBackgroundColor: context.appSurfaceAlt,
                          disabledForegroundColor: context.appMuted,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoProjectRequests extends StatelessWidget {
  const _NoProjectRequests();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, color: AppColors.muted, size: 48),
            SizedBox(height: 12),
            Text(
              'لا توجد طلبات لهذا المشروع بعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
