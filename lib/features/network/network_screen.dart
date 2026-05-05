import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/network_person.dart';
import '../home/widgets/home_top_bar.dart';
import '../profile/profile_screen.dart';
import 'invitations_screen.dart';
import 'widgets/network_card.dart';

class NetworkScreen extends StatelessWidget {
  const NetworkScreen({
    super.key,
    required this.onMenu,
    required this.onMessages,
  });

  final VoidCallback onMenu;
  final VoidCallback onMessages;

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

  static const _people = [
    NetworkPerson(
      name: 'مريانا جونز',
      title: 'مصممة منتجات · uxui_design',
      color: Color(0xFF617E84),
      badge: 'متاحة',
    ),
    NetworkPerson(
      name: 'مازن محمود',
      title: 'مطور Front-end أول',
      color: Color(0xFF8D64BC),
      badge: 'يوظف',
    ),
    NetworkPerson(
      name: 'جاكسون نوكس',
      title: 'مهندس SRE في ArtLife',
      color: Color(0xFFB66F4C),
    ),
    NetworkPerson(
      name: 'أندرو مارتن',
      title: 'أخصائي اكتساب مواهب',
      color: Color(0xFF5D8E64),
      badge: 'متاح',
    ),
    NetworkPerson(
      name: 'سارة خليل',
      title: 'محللة بيانات',
      color: Color(0xFFD16A6A),
    ),
    NetworkPerson(
      name: 'كريم يوسف',
      title: 'مدير مبيعات B2B',
      color: Color(0xFF3E7BA6),
      badge: 'يوظف',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeTopBar(onMenu: onMenu, onMessages: onMessages),
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  'أشخاص قد تعرفهم من جامعة القاهرة (قسم نظم المعلومات)',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: _people.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: .62,
                ),
                itemBuilder: (context, index) => NetworkCard(
                  person: _people[index],
                  onTap: () => _openProfile(context, _people[index]),
                ),
              ),
            ],
          ),
        ),
      ],
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
