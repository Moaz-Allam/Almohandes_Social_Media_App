import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/account_type.dart';
import '../../models/network_person.dart';
import '../../state/app_scope.dart';
import '../home/widgets/home_top_bar.dart';
import '../profile/profile_screen.dart';
import 'invitations_screen.dart';
import 'widgets/network_card.dart';

enum _NetworkCategory { engineers, companies }

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
  _NetworkCategory _category = _NetworkCategory.engineers;

  static const _engineers = [
    NetworkPerson(
      name: 'مريانا جونز',
      title: 'مهندسة مدنية · تصميم وإشراف',
      color: AppColors.blue,
      badge: 'متاحة',
      contextLine: 'بغداد · خبرة 4 سنوات',
    ),
    NetworkPerson(
      name: 'مازن محمود',
      title: 'مهندس كهرباء مواقع',
      color: AppColors.darkBlue,
      badge: 'مشاريع',
      contextLine: 'البصرة · أنظمة قدرة',
    ),
    NetworkPerson(
      name: 'جاكسون نوكس',
      title: 'مهندس ميكانيك تشغيل',
      color: AppColors.muted,
      contextLine: 'أربيل · خبرة 6 سنوات',
    ),
    NetworkPerson(
      name: 'أندرو مارتن',
      title: 'مهندس حاسوب وأنظمة',
      color: AppColors.black,
      badge: 'متاح',
      contextLine: 'السليمانية · حلول رقمية',
    ),
    NetworkPerson(
      name: 'سارة خليل',
      title: 'مهندسة مساحة',
      color: AppColors.blue,
      contextLine: 'النجف · أعمال ميدانية',
    ),
    NetworkPerson(
      name: 'كريم يوسف',
      title: 'مهندس معماري',
      color: AppColors.darkBlue,
      badge: 'تصميم',
      contextLine: 'كربلاء · نمذجة BIM',
    ),
  ];

  static const _companies = [
    NetworkPerson(
      name: 'نيل لابس',
      title: 'استوديو منتجات رقمية',
      color: AppColors.blue,
      badge: 'شركة',
      contextLine: 'القاهرة · 18 ألف متابع',
      actionLabel: 'متابعة',
      isCompany: true,
    ),
    NetworkPerson(
      name: 'كود القاهرة',
      title: 'حلول برمجية للمؤسسات',
      color: AppColors.darkBlue,
      badge: 'توظف',
      contextLine: 'هجين · 12 مشروع',
      actionLabel: 'متابعة',
      isCompany: true,
    ),
    NetworkPerson(
      name: 'مصممون عرب',
      title: 'مجتمع تصميم وتجربة مستخدم',
      color: AppColors.muted,
      contextLine: 'مجتمع مهني',
      actionLabel: 'متابعة',
      isCompany: true,
    ),
    NetworkPerson(
      name: 'فينتك مصر',
      title: 'منصة مشاريع مالية تقنية',
      color: AppColors.black,
      badge: 'جديد',
      contextLine: 'عن بعد · فرص تدريب',
      actionLabel: 'متابعة',
      isCompany: true,
    ),
  ];

  List<_NetworkCategory> _categoriesFor(AccountType accountType) {
    return switch (accountType) {
      AccountType.engineer => const [
        _NetworkCategory.engineers,
        _NetworkCategory.companies,
      ],
      AccountType.company => const [_NetworkCategory.engineers],
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

  List<NetworkPerson> _visibleProfiles(_NetworkCategory category) {
    return switch (category) {
      _NetworkCategory.engineers => _engineers,
      _NetworkCategory.companies => _companies,
    };
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
          name: person.name,
          headline: person.title,
          color: person.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountType = accountTypeFromProfile(AppScope.watch(context).profile);
    final categories = _categoriesFor(accountType);
    final selectedCategory = _effectiveCategory(accountType);
    final visibleProfiles = selectedCategory == null
        ? const <NetworkPerson>[]
        : _visibleProfiles(selectedCategory);

    return Column(
      children: [
        HomeTopBar(onMenu: widget.onMenu, onMessages: widget.onMessages),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (selectedCategory == null) ...[
                const _NetworkAccessEmptyState(),
              ] else ...[
                _SimpleNavRow(
                  title: 'الدعوات',
                  subtitle: 'لديك 5 دعوات معلقة',
                  onTap: () => _openInvitations(context),
                ),
                const Divider(height: 9, thickness: 8, color: AppColors.soft),
                if (categories.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _NetworkCategoryTabs(
                      selected: selectedCategory,
                      onChanged: (value) => setState(() => _category = value),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text(
                      'مهندسون',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: visibleProfiles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: .62,
                  ),
                  itemBuilder: (context, index) => NetworkCard(
                    person: visibleProfiles[index],
                    onTap: () => _openProfile(context, visibleProfiles[index]),
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
            'الشبكة متاحة للمهندسين والشركات فقط',
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

class _NetworkCategoryTabs extends StatelessWidget {
  const _NetworkCategoryTabs({required this.selected, required this.onChanged});

  final _NetworkCategory selected;
  final ValueChanged<_NetworkCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          _NetworkCategoryTab(
            label: 'مهندسون',
            selected: selected == _NetworkCategory.engineers,
            onTap: () => onChanged(_NetworkCategory.engineers),
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
