import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ProfileCompleteness extends StatelessWidget {
  const ProfileCompleteness({
    super.key,
    required this.skills,
    required this.languages,
  });

  final int skills;
  final int languages;

  @override
  Widget build(BuildContext context) {
    final completion = (70 + (skills * 3) + (languages * 2)).clamp(70, 100);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: AppColors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'جاهزية الملف الشخصي',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text('$completion%'),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: completion / 100,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ),
        ],
      ),
    );
  }
}
