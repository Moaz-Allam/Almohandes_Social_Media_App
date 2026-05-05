import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SearchPill extends StatelessWidget {
  const SearchPill({super.key, required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: context.appMuted, size: 22),
          const SizedBox(width: 8),
          Text(
            hint,
            style: TextStyle(
              color: context.appText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
