import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../home/main_shell.dart';

class SignUpSuccessScreen extends StatefulWidget {
  const SignUpSuccessScreen({super.key});

  @override
  State<SignUpSuccessScreen> createState() => _SignUpSuccessScreenState();
}

class _SignUpSuccessScreenState extends State<SignUpSuccessScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.blue,
                  child: Icon(Icons.check, color: Colors.white, size: 44),
                ),
                SizedBox(height: 18),
                Text(
                  'تم إنشاء الحساب بنجاح',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'سيتم نقلك إلى الصفحة الرئيسية الآن.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
