import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class LinkedTextField extends StatelessWidget {
  const LinkedTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          minLines: maxLines > 1 ? 3 : null,
          keyboardType: keyboardType,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
