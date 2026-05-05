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
          Container(
            width: 28 * scale,
            height: 28 * scale,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(7 * scale),
            ),
            child: Icon(
              Icons.engineering,
              color: Colors.white,
              size: 18 * scale,
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
