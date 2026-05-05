import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircleAvatar(
          radius: 46,
          backgroundColor: AppColors.blue,
          child: Text(
            'in',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
