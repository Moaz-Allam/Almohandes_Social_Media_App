import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class LinkedInLogo extends StatelessWidget {
  const LinkedInLogo({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8 * scale),
            child: Image.asset(
              'assets/branding/app_logo.png',
              width: 34 * scale,
              height: 34 * scale,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 7 * scale),
          Text(
            'المهندس',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 22 * scale,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
