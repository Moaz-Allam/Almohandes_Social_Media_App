import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/job_item.dart';
import '../home/widgets/home_top_bar.dart';
import 'widgets/job_card.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key, required this.onMenu, required this.onMessages});

  final VoidCallback onMenu;
  final VoidCallback onMessages;

  static const _jobs = [
    JobItem(
      title: 'مصمم منتجات أول',
      company: 'NilePay · القاهرة · هجين',
      detail: 'تطابق قوي مع مهاراتك في Figma وبحث المستخدم',
    ),
    JobItem(
      title: 'مطور Flutter',
      company: 'Cairo Mobility · عن بعد',
      detail: 'تم نشرها قبل ساعتين · 35 متقدما',
    ),
    JobItem(
      title: 'مدير منتج مساعد',
      company: 'MENA Commerce · الجيزة',
      detail: 'تحتاج خبرة في تحليل البيانات وتجارب الدفع',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeTopBar(
          onMenu: onMenu,
          onMessages: onMessages,
          hint: 'ابحث عن وظيفة',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark),
                      label: const Text('وظائفي'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.tune),
                      label: const Text('تفضيلات'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blue,
                        side: const BorderSide(color: AppColors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'وظائف موصى بها لك',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              for (final job in _jobs) JobCard(job: job),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paleBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.blue,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'فعّل تنبيهات الوظائف لتصلك الفرص المناسبة فور نشرها.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text('تفعيل')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
