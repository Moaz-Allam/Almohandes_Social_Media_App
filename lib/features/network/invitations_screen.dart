import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/network_person.dart';
import '../../shared/widgets/app_avatar.dart';
import '../profile/profile_screen.dart';

class InvitationsScreen extends StatelessWidget {
  const InvitationsScreen({super.key});

  static const _requests = [
    NetworkPerson(
      name: 'سلمى فتحي',
      title: 'طالبة ثانوي في KFS STEM School',
      color: Color(0xFF7B5AA6),
      badge: '9 اتصالات مشتركة · قبل ساعة',
    ),
    NetworkPerson(
      name: 'أنس يونس',
      title: 'Obour STEM School 26',
      color: Color(0xFF5E7893),
      badge: '49 اتصالا مشتركا · أمس',
    ),
    NetworkPerson(
      name: 'ليلى عادل',
      title: 'مصممة واجهات مبتدئة',
      color: Color(0xFFD16A6A),
      badge: '12 اتصالا مشتركا · قبل يومين',
    ),
    NetworkPerson(
      name: 'يوسف زين',
      title: 'مطور Front-end',
      color: Color(0xFF3E7BA6),
      badge: '7 اتصالات مشتركة · هذا الأسبوع',
    ),
    NetworkPerson(
      name: 'نور خالد',
      title: 'محللة بيانات',
      color: Color(0xFF6DA064),
      badge: '3 اتصالات مشتركة · هذا الأسبوع',
    ),
    NetworkPerson(
      name: 'كريم حسن',
      title: 'مدير منتج مساعد',
      color: Color(0xFFB66F4C),
      badge: '22 اتصالا مشتركا · منذ أسبوع',
    ),
  ];

  void _openProfile(BuildContext context, NetworkPerson person) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          name: person.name,
          headline: person.title,
          color: person.color,
          isConnectionRequest: true,
        ),
      ),
    );
  }

  void _showDecision(BuildContext context, String action, String name) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$action طلب $name')));
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
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.border)),
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
              child: ListView.separated(
                itemCount: _requests.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final request = _requests[index];
                  return ListTile(
                    onTap: () => _openProfile(context, request),
                    contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                            request.badge ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted),
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
                            onPressed: () =>
                                _showDecision(context, 'رفضت', request.name),
                            icon: const Icon(Icons.close),
                            color: AppColors.muted,
                            tooltip: 'رفض الطلب',
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            onPressed: () =>
                                _showDecision(context, 'قبلت', request.name),
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
            ),
          ],
        ),
      ),
    );
  }
}
