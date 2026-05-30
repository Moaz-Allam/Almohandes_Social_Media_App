import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/managed_listing.dart';
import '../../state/app_scope.dart';
import 'listing_applicants_screen.dart';

/// Owner view: every project and job the current user created, each showing how
/// many people applied / were matched. Tapping a listing opens its applicants,
/// where the owner can view profiles and match people.
class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late Future<List<ManagedListing>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value(const <ManagedListing>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _load();
  }

  Future<List<ManagedListing>> _load() async {
    final app = AppScope.read(context);
    final results = await Future.wait<List<ManagedListing>>([
      app.repositories.projects.fetchMyProjects(),
      app.repositories.jobs.fetchMyJobs(),
    ]);
    return [...results[0], ...results[1]];
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openApplicants(ManagedListing listing) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingApplicantsScreen(listing: listing),
      ),
    );
    if (!mounted) {
      return;
    }
    // Counts / completion state may have changed after matching.
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appText,
        title: const Text(
          'مشاريعي ووظائفي',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<List<ManagedListing>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final listings = snapshot.data ?? const <ManagedListing>[];
          if (listings.isEmpty) {
            return _EmptyState(onRefresh: _refresh);
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              itemCount: listings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _ListingCard(
                listing: listings[index],
                onTap: () => _openApplicants(listings[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.onTap});

  final ManagedListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = listing.title.isEmpty
        ? (listing.isProject ? 'مشروع' : 'وظيفة')
        : listing.title;
    return Material(
      color: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: context.appBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: context.appSurfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  listing.isProject
                      ? Icons.folder_special_outlined
                      : Icons.work_outline_rounded,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CompletionChip(completed: listing.isCompleted),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${listing.isProject ? 'مشروع' : 'وظيفة'}'
                      '${listing.subtitle.isEmpty ? '' : ' · ${listing.subtitle}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.appMuted),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatPill(
                          icon: Icons.group_outlined,
                          label: '${listing.applicationsCount} متقدم',
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          icon: Icons.verified_outlined,
                          label: '${listing.acceptedCount} مطابقة',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionChip extends StatelessWidget {
  const _CompletionChip({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed ? AppColors.blue : const Color(0xFF1E8E3E);
    final label = completed ? 'مكتمل' : 'مفتوح';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.blue),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.work_history_outlined, color: AppColors.muted, size: 46),
          SizedBox(height: 12),
          Text(
            'لم تنشئ أي مشروع أو وظيفة بعد',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'أنشئ مشروعاً أو وظيفة لتظهر هنا مع طلبات المتقدمين',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
