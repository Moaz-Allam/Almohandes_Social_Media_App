import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LinkedTextField extends StatefulWidget {
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
  State<LinkedTextField> createState() => _LinkedTextFieldState();
}

class _LinkedTextFieldState extends State<LinkedTextField> {
  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    final shouldObscure = widget.obscureText && _hidePassword;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: context.appMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: widget.controller,
          obscureText: shouldObscure,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.maxLines > 1 ? 3 : null,
          keyboardType: widget.keyboardType,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () {
                      setState(() => _hidePassword = !_hidePassword);
                    },
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    tooltip: _hidePassword
                        ? 'إظهار كلمة المرور'
                        : 'إخفاء كلمة المرور',
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
