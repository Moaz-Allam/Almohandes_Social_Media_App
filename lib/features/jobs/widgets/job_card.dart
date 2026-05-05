import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/job_item.dart';

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job});

  final JobItem job;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.business, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  job.company,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Text(
                  job.detail,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.bookmark_border, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
