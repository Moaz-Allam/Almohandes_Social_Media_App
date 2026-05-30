import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/applicant_request.dart';
import '../../models/managed_listing.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_snack.dart';
import '../../state/app_scope.dart';
import '../profile/profile_screen.dart';

/// Normalized applicant shown to a listing owner, regardless of whether the
/// listing is a project or a job.
class _Applicant {
  const _Applicant({
    required this.applicationId,
    required this.profileId,
    required this.name,
    required this.title,
    required this.message,
    required this.status,
    required this.color,
    this.avatarUrl,
  });

  final String applicationId;
  final String profileId;
  final String name;
  final String title;
  final String message;
  final String status;
  final Color color;
  final String? avatarUrl;

  bool get isAccepted => status == 'accepted';
}

/// Proposals/applications on a listing the current user owns. The owner can
/// open each applicant's profile and match (accept) them. A job allows a single
/// match; a project allows up to its engineers-needed count.
class ListingApplicantsScreen extends StatefulWidget {
  const ListingApplicantsScreen({super.key, required this.listing});

  final ManagedListing listing;

  @override
  State<ListingApplicantsScreen> createState() =>
      _ListingApplicantsScreenState();
}

class _ListingApplicantsScreenState extends State<ListingApplicantsScreen> {
  late Future<List<_Applicant>> _future;
  final Set<String> _matchedAppIds = {};
  final Set<String> _matchingIds = {};
  bool _didStartLoading = false;

  @override
  void initState() {
    super.initState();
    _future = Future.value(const <_Applicant>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartLoading) {
      return;
    }
    _didStartLoading = true;
    _future = _load();
  }

  ManagedListing get listing => widget.listing;

  int get _remainingSlots {
    final base = listing.remainingSlots - _matchedAppIds.length;
    return base < 0 ? 0 : base;
  }

  Future<List<_Applicant>> _load({bool forceRefresh = false}) async {
    final app = AppScope.read(context);
    if (listing.isProject) {
      final rows = await app.repositories.projects.fetchProjectApplications(
        listing.id,
        forceRefresh: forceRefresh,
      );
      return [
        for (final r in rows)
          _Applicant(
            applicationId: r.id,
            profileId: r.profileId,
            name: r.name,
            title: r.title,
            message: r.message,
            status: r.status,
            color: r.color,
            avatarUrl: r.avatarUrl,
          ),
      ];
    }
    final rows = await app.repositories.jobs.fetchJobApplications(listing.id);
    return [
      for (final ApplicantRequest r in rows)
        _Applicant(
          applicationId: r.applicationId,
          profileId: r.profileId,
          name: r.name,
          title: r.title,
          message: r.message,
          status: r.status,
          color: r.color,
          avatarUrl: r.avatarUrl,
        ),
    ];
  }

  Future<void> _refresh() async {
    setState(() => _future = _load(forceRefresh: true));
    await _future;
  }

  void _openProfile(_Applicant applicant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          profileId: applicant.profileId,
          name: applicant.name,
          headline: applicant.title,
          color: applicant.color,
          avatarUrl: applicant.avatarUrl,
          initialConnectionStatus: 'none',
        ),
      ),
    );
  }

  Future<void> _match(_Applicant applicant) async {
    if (applicant.applicationId.isEmpty ||
        _matchingIds.contains(applicant.applicationId)) {
      return;
    }
    setState(() => _matchingIds.add(applicant.applicationId));
    final app = AppScope.read(context);
    try {
      if (listing.isProject) {
        await app.repositories.projects.matchProjectApplicant(
          applicant.applicationId,
        );
      } else {
        await app.repositories.jobs.matchJobApplicant(applicant.applicationId);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _matchedAppIds.add(applicant.applicationId);
        _matchingIds.remove(applicant.applicationId);
      });
      AppSnack.success(context, 'تمت مطابقة ${applicant.name}');
      // The status changed server-side; reload to reflect it.
      _future = _load(forceRefresh: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _matchingIds.remove(applicant.applicationId));
      AppSnack.error(context, error, fallback: 'تعذر إتمام المطابقة الآن');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appText,
        title: Text(
          listing.isProject ? 'طلبات المشروع' : 'طلبات الوظيفة',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          _ListingHeader(listing: listing, remainingSlots: _remainingSlots),
          Expanded(
            child: FutureBuilder<List<_Applicant>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final applicants = snapshot.data ?? const <_Applicant>[];
                if (applicants.isEmpty) {
                  return const _NoApplicants();
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    itemCount: applicants.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final applicant = applicants[index];
                      final matched =
                          applicant.isAccepted ||
                          _matchedAppIds.contains(applicant.applicationId);
                      return _ApplicantCard(
                        applicant: applicant,
                        matched: matched,
                        matching: _matchingIds.contains(
                          applicant.applicationId,
                        ),
                        canMatch: !matched && _remainingSlots > 0,
                        onProfile: () => _openProfile(applicant),
                        onMatch: () => _match(applicant),
                      );
                    },
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

class _ListingHeader extends StatelessWidget {
  const _ListingHeader({required this.listing, required this.remainingSlots});

  final ManagedListing listing;
  final int remainingSlots;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              listing.isProject
                  ? Icons.folder_special_outlined
                  : Icons.work_outline_rounded,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title.isEmpty
                      ? (listing.isProject ? 'مشروع' : 'وظيفة')
                      : listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  listing.isCompleted
                      ? 'مكتمل · تمت المطابقة'
                      : 'المتبقي: $remainingSlots · المتقدمون: '
                            '${listing.applicationsCount}',
                  style: TextStyle(
                    color: listing.isCompleted ? AppColors.blue : context.appMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({
    required this.applicant,
    required this.matched,
    required this.matching,
    required this.canMatch,
    required this.onProfile,
    required this.onMatch,
  });

  final _Applicant applicant;
  final bool matched;
  final bool matching;
  final bool canMatch;
  final VoidCallback onProfile;
  final VoidCallback onMatch;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: matched ? AppColors.blue : context.appBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppAvatar(
                  name: applicant.name,
                  radius: 26,
                  color: applicant.color,
                  imageUrl: applicant.avatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        applicant.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.appMuted),
                      ),
                    ],
                  ),
                ),
                if (matched)
                  const Icon(Icons.verified_rounded, color: AppColors.blue),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              applicant.message.isEmpty
                  ? 'لا توجد رسالة مرفقة'
                  : applicant.message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appText, height: 1.45),
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
                  child: FilledButton.icon(
                    onPressed: (matched || !canMatch || matching)
                        ? null
                        : onMatch,
                    icon: matching
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            matched
                                ? Icons.check_circle
                                : Icons.handshake_outlined,
                            size: 18,
                          ),
                    label: Text(matched ? 'تمت المطابقة' : 'مطابقة'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      disabledBackgroundColor: context.appSurfaceAlt,
                      disabledForegroundColor: context.appMuted,
                    ),
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

class _NoApplicants extends StatelessWidget {
  const _NoApplicants();

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
              'لا توجد طلبات بعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
