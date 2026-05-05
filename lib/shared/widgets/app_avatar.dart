import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    required this.radius,
    required this.color,
    this.badge,
  });

  final String name;
  final double radius;
  final Color color;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().substring(0, 1);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: color,
          child: Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontSize: radius * .72,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (badge != null)
          PositionedDirectional(
            bottom: -3,
            end: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: badge == 'يوظف' ? AppColors.blue : AppColors.darkBlue,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
