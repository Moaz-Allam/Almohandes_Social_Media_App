import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/account_type.dart';
import '../../models/network_person.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/app_scope.dart';
import '../home/widgets/home_top_bar.dart';
import '../profile/profile_screen.dart';
import 'invitations_screen.dart';
import 'widgets/network_card.dart';

enum _NetworkCategory { people, companies }

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({
    super.key,
    required this.onMenu,
    required this.onMessages,
  });

  final VoidCallback onMenu;
  final VoidCallback onMessages;

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  _NetworkCategory _category = _NetworkCategory.people;
  final Set<String> _pendingConnectionIds = {};
  final Set<String> _connectingIds = {};
  Future<List<NetworkPerson>>? _profilesFuture;
  String? _profilesFutureKey;

  List<_NetworkCategory> _categoriesFor(AccountType accountType) {
    return switch (accountType) {
      AccountType.engineer => const [
        _NetworkCategory.people,
        _NetworkCategory.companies,
      ],
      AccountType.company => const [
        _NetworkCategory.people,
        _NetworkCategory.companies,
      ],
      AccountType.admin => const [
        _NetworkCategory.people,
        _NetworkCategory.companies,
      ],
      AccountType.craftsman ||
      AccountType.worker ||
      AccountType.equipment => const [],
    };
  }

  _NetworkCategory? _effectiveCategory(AccountType accountType) {
    final categories = _categoriesFor(accountType);
    if (categories.isEmpty) {
      return null;
    }
    if (categories.contains(_category)) {
      return _category;
    }
    return categories.first;
  }

  Future<List<NetworkPerson>> _fetchProfiles(
    BuildContext context, {
    required AccountType accountType,
    required _NetworkCategory category,
    bool forceRefresh = false,
  }) {
    return AppScope.read(context).repositories.profiles.fetchNetworkProfiles(
      viewerType: accountType,
      companies: category == _NetworkCategory.companies,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<NetworkPerson>> _profilesFor(
    BuildContext context, {
    required AccountType accountType,
    required _NetworkCategory category,
  }) {
    final key = '${accountType.name}:${category.name}';
    if (_profilesFutureKey != key || _profilesFuture == null) {
      _profilesFutureKey = key;
      _profilesFuture = _fetchProfiles(
        context,
        accountType: accountType,
        category: category,
      );
    }
    return _profilesFuture!;
  }

  void _openInvitations(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InvitationsScreen()));
  }

  void _openProfile(BuildContext context, NetworkPerson person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          profileId: person.id,
          name: person.name,
          headline: person.title,
          color: person.color,
          avatarUrl: person.avatarUrl,
          initialConnectionStatus: _effectivePerson(person).connectionStatus,
        ),
      ),
    );
  }

  Future<void> _handleNetworkAction(
    BuildContext context,
    NetworkPerson person,
  ) async {
    if (person.isCompany) {
      await AppScope.read(
        context,
      ).repositories.profiles.followProfile(person.id);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تمت المتابعة')));
      return;
    }
    if (_connectingIds.contains(person.id)) {
      return;
    }
    setState(() => _connectingIds.add(person.id));
    try {
      await AppScope.read(
        context,
      ).repositories.profiles.requestConnection(person.id);
    } finally {
      if (context.mounted) {
        setState(() => _connectingIds.remove(person.id));
      }
    }
    if (!context.mounted) {
      return;
    }
    setState(() => _pendingConnectionIds.add(person.id));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم إرسال طلب التواصل')));
  }

  NetworkPerson _effectivePerson(NetworkPerson person) {
    if (!_pendingConnectionIds.contains(person.id)) {
      return person;
    }
    return NetworkPerson(
      id: person.id,
      profileId: person.profileId,
      name: person.name,
      title: person.title,
      color: person.color,
      badge: person.badge,
      contextLine: person.contextLine,
      actionLabel: 'قيد الانتظار',
      isCompany: person.isCompany,
      avatarUrl: person.avatarUrl,
      connectionStatus: 'pending',
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountType = accountTypeFromProfile(AppScope.watch(context).profile);
    final categories = _categoriesFor(accountType);
    final selectedCategory = _effectiveCategory(accountType);

    return Column(
      children: [
        HomeTopBar(onMenu: widget.onMenu, onMessages: widget.onMessages),
        Expanded(
          child: selectedCategory == null
              ? const _NetworkAccessEmptyState()
              : FutureBuilder<List<NetworkPerson>>(
                  future: _profilesFor(
                    context,
                    accountType: accountType,
                    category: selectedCategory,
                  ),
                  builder: (context, snapshot) {
                    final isLoading =
                        snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData;
                    final profiles = snapshot.data ?? const <NetworkPerson>[];

                    return RefreshIndicator(
                      onRefresh: () async {
                        _profilesFuture = _fetchProfiles(
                          context,
                          accountType: accountType,
                          category: selectedCategory,
                          forceRefresh: true,
                        );
                        await _profilesFuture;
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _SimpleNavRow(
                            title: 'الدعوات',
                            subtitle: 'طلبات التواصل الواردة',
                            onTap: () => _openInvitations(context),
                          ),
                          Divider(
                            height: 9,
                            thickness: 8,
                            color: context.appSoft,
                          ),
                          if (categories.length > 1)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                12,
                              ),
                              child: _NetworkCategoryTabs(
                                selected: selectedCategory,
                                onChanged: (value) {
                                  setState(() => _category = value);
                                },
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: Text(
                                'أشخاص',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          if (isLoading)
                            const _NetworkSkeletonGrid()
                          else if (profiles.isEmpty)
                            _NetworkEmptyProfiles(category: selectedCategory)
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: profiles.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: .68,
                                  ),
                              itemBuilder: (context, index) {
                                final person = _effectivePerson(
                                  profiles[index],
                                );
                                final canAct =
                                    !person.isPendingConnection &&
                                    !person.isConnected;
                                return NetworkCard(
                                  person: person,
                                  loading: _connectingIds.contains(person.id),
                                  onTap: () => _openProfile(context, person),
                                  onAction: canAct
                                      ? () => _handleNetworkAction(
                                          context,
                                          person,
                                        )
                                      : null,
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _NetworkAccessEmptyState extends StatelessWidget {
  const _NetworkAccessEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 90, 24, 24),
      child: Column(
        children: [
          Icon(Icons.lock_outline, color: AppColors.muted, size: 44),
          SizedBox(height: 14),
          Text(
            'لا تملك صلاحية مشاهدة شبكة المستخدمين',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'هذا النوع من الحساب لا يمكنه مشاهدة حسابات أخرى من صفحة شبكتي.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _NetworkEmptyProfiles extends StatelessWidget {
  const _NetworkEmptyProfiles({required this.category});

  final _NetworkCategory category;

  @override
  Widget build(BuildContext context) {
    final label = category == _NetworkCategory.companies ? 'شركات' : 'حسابات';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
      child: Column(
        children: [
          const Icon(
            Icons.person_search_outlined,
            color: AppColors.muted,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد $label متاحة الآن',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'ستظهر النتائج هنا بعد إضافة ملفات المستخدمين.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _NetworkSkeletonGrid extends StatelessWidget {
  const _NetworkSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: .68,
      ),
      itemBuilder: (context, index) => const NetworkCardSkeleton(),
    );
  }
}

class _NetworkCategoryTabs extends StatelessWidget {
  const _NetworkCategoryTabs({required this.selected, required this.onChanged});

  final _NetworkCategory selected;
  final ValueChanged<_NetworkCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          _NetworkCategoryTab(
            label: 'أشخاص',
            selected: selected == _NetworkCategory.people,
            onTap: () => onChanged(_NetworkCategory.people),
          ),
          _NetworkCategoryTab(
            label: 'شركات',
            selected: selected == _NetworkCategory.companies,
            onTap: () => onChanged(_NetworkCategory.companies),
          ),
        ],
      ),
    );
  }
}

class _NetworkCategoryTab extends StatelessWidget {
  const _NetworkCategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.blue,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleNavRow extends StatelessWidget {
  const _SimpleNavRow({
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.blue,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
