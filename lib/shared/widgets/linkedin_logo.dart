import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class LinkedInLogo extends StatelessWidget {
  const LinkedInLogo({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Linked',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 20 * scale,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Container(
            margin: EdgeInsetsDirectional.only(start: 1.5 * scale),
            padding: EdgeInsets.symmetric(
              horizontal: 2.5 * scale,
              vertical: 1 * scale,
            ),
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(1.5 * scale),
            ),
            child: Text(
              'in',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15 * scale,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
