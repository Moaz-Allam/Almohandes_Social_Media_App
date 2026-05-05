import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/network_person.dart';
import '../home/widgets/home_top_bar.dart';
import '../profile/profile_screen.dart';
import 'invitations_screen.dart';
import 'widgets/network_card.dart';

enum _NetworkCategory { makers, companies }

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
  _NetworkCategory _category = _NetworkCategory.makers;

  static const _makers = [
    NetworkPerson(
      name: 'مريانا جونز',
      title: 'مصممة منتجات · uxui_design',
      color: AppColors.blue,
      badge: 'متاحة',
      contextLine: 'جامعة القاهرة',
    ),
    NetworkPerson(
      name: 'مازن محمود',
      title: 'مطور Front-end أول',
      color: AppColors.darkBlue,
      badge: 'يوظف',
      contextLine: 'مجتمع Flutter مصر',
    ),
    NetworkPerson(
      name: 'جاكسون نوكس',
      title: 'مهندس SRE في ArtLife',
      color: AppColors.muted,
      contextLine: 'خبرة 6 سنوات',
    ),
    NetworkPerson(
      name: 'أندرو مارتن',
      title: 'أخصائي اكتساب مواهب',
      color: AppColors.black,
      badge: 'متاح',
      contextLine: 'توظيف تقني',
    ),
    NetworkPerson(
      name: 'سارة خليل',
      title: 'محللة بيانات',
      color: AppColors.blue,
      contextLine: 'تحليلات المنتجات',
    ),
    NetworkPerson(
      name: 'كريم يوسف',
      title: 'مدير مبيعات B2B',
      color: AppColors.darkBlue,
      badge: 'يوظف',
      contextLine: 'نمو الأعمال',
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

  List<NetworkPerson> get _visibleProfiles {
    return switch (_category) {
      _NetworkCategory.makers => _makers,
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
    final visibleProfiles = _visibleProfiles;

    return Column(
      children: [
        HomeTopBar(onMenu: widget.onMenu, onMessages: widget.onMessages),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _SimpleNavRow(
                title: 'الدعوات',
                subtitle: 'لديك 5 دعوات معلقة',
                onTap: () => _openInvitations(context),
              ),
              const Divider(height: 9, thickness: 8, color: AppColors.soft),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: _NetworkCategoryTabs(
                  selected: _category,
                  onChanged: (value) => setState(() => _category = value),
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
          ),
        ),
      ],
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
            label: 'حرفي',
            selected: selected == _NetworkCategory.makers,
            onTap: () => onChanged(_NetworkCategory.makers),
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
