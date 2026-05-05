import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SearchPill extends StatelessWidget {
  const SearchPill({super.key, required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFF6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.muted, size: 22),
          const SizedBox(width: 8),
          Text(
            hint,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
