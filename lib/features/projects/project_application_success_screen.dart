import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/project_item.dart';

class ProjectApplicationSuccessScreen extends StatelessWidget {
  const ProjectApplicationSuccessScreen({super.key, required this.project});

  final ProjectItem project;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'تم إرسال طلبك بنجاح',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                'تمت إضافة "${project.title}" إلى المحفوظات في ملفك الشخصي حتى تتابع حالة التقديم بسهولة.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('العودة إلى المشاريع'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
