import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/network_person.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../state/app_scope.dart';
import '../profile/profile_screen.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  late Future<List<NetworkPerson>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = Future.value(const <NetworkPerson>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _requestsFuture = AppScope.read(
      context,
    ).repositories.profiles.fetchIncomingConnectionRequests();
  }

  void _openProfile(BuildContext context, NetworkPerson person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          profileId: person.profileId ?? person.id,
          name: person.name,
          headline: person.title,
          color: person.color,
          isConnectionRequest: true,
        ),
      ),
    );
  }

  Future<void> _answer(NetworkPerson request, bool accept) async {
    await AppScope.read(context).repositories.profiles.answerConnectionRequest(
      requestId: request.id,
      accept: accept,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _requestsFuture = AppScope.read(context).repositories.profiles
          .fetchIncomingConnectionRequests(forceRefresh: true);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(accept ? 'تم قبول الطلب' : 'تم رفض الطلب')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  const Expanded(
                    child: Text(
                      'الدعوات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<NetworkPerson>>(
                future: _requestsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final requests = snapshot.data ?? const <NetworkPerson>[];
                  if (requests.isEmpty) {
                    return const _EmptyInvitations();
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _requestsFuture = AppScope.read(context)
                            .repositories
                            .profiles
                            .fetchIncomingConnectionRequests(
                              forceRefresh: true,
                            );
                      });
                      await _requestsFuture;
                    },
                    child: ListView.separated(
                      itemCount: requests.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: context.appBorder),
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return ListTile(
                          onTap: () => _openProfile(context, request),
                          contentPadding: const EdgeInsets.fromLTRB(
                            14,
                            12,
                            14,
                            12,
                          ),
                          leading: GestureDetector(
                            onTap: () => _openProfile(context, request),
                            child: AppAvatar(
                              name: request.name,
                              radius: 34,
                              color: request.color,
                            ),
                          ),
                          title: GestureDetector(
                            onTap: () => _openProfile(context, request),
                            child: Text(
                              request.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          subtitle: GestureDetector(
                            onTap: () => _openProfile(context, request),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  request.badge ?? request.contextLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: SizedBox(
                            width: 112,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton.outlined(
                                  onPressed: () => _answer(request, false),
                                  icon: const Icon(Icons.close),
                                  color: AppColors.muted,
                                  tooltip: 'رفض الطلب',
                                ),
                                const SizedBox(width: 8),
                                IconButton.outlined(
                                  onPressed: () => _answer(request, true),
                                  icon: const Icon(Icons.check),
                                  color: AppColors.blue,
                                  tooltip: 'قبول الطلب',
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
        ),
      ),
    );
  }
}

class _EmptyInvitations extends StatelessWidget {
  const _EmptyInvitations();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_alt, color: AppColors.muted, size: 46),
            SizedBox(height: 12),
            Text(
              'لا توجد دعوات بعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text(
              'ستظهر طلبات التواصل الواردة هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
