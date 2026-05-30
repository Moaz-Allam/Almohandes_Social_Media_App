import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';
import '../auth/widgets/auth_inputs.dart';
import '../auth/widgets/auth_scaffold.dart';

/// Verifies the OTP sent when attaching a new [phone] to the signed-in account.
/// Pops `true` on success so the caller can confirm and return to Settings.
class AddPhoneOtpScreen extends StatefulWidget {
  const AddPhoneOtpScreen({super.key, required this.phone});

  final String phone;

  @override
  State<AddPhoneOtpScreen> createState() => _AddPhoneOtpScreenState();
}

class _AddPhoneOtpScreenState extends State<AddPhoneOtpScreen> {
  static const _length = 6;
  static const _cooldownSeconds = 60;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;
  Timer? _ticker;
  int _remaining = _cooldownSeconds;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_length, (_) => TextEditingController());
    _nodes = List.generate(_length, (_) => FocusNode());
    _startCooldown();
  }

  void _startCooldown() {
    _ticker?.cancel();
    setState(() => _remaining = _cooldownSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= 1;
        if (_remaining <= 0) _ticker?.cancel();
      });
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _ticker?.cancel();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();
  bool get _complete => _code.length == _length && !_loading;

  void _onChanged(int i, String value) {
    if (value.isNotEmpty && i < _length - 1) {
      _nodes[i + 1].requestFocus();
    } else if (value.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AppScope.read(context).repositories.auth;
      await auth.confirmPhoneChange(phone: widget.phone, code: _code);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_remaining > 0) return;
    setState(() => _error = null);
    try {
      final auth = AppScope.read(context).repositories.auth;
      await auth.startPhoneChange(phone: widget.phone);
      if (!mounted) return;
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceAltDark,
          content: Text(
            'تم إرسال رمز جديد عبر رسالة نصية',
            style: TextStyle(color: AppColors.inkDark),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      icon: Icons.sms_outlined,
      title: 'رمز التحقق',
      subtitle:
          'أدخل الرمز المكوّن من ٦ أرقام\nالذي أرسلناه إلى ${widget.phone}',
      stepCount: 2,
      currentStep: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_length, _otpBox),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: _loading || _remaining > 0 ? null : _resend,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedDark,
                  ),
                  children: [
                    const TextSpan(text: 'لم يصلك الرمز؟ '),
                    TextSpan(
                      text: _remaining > 0
                          ? 'إعادة الإرسال خلال $_remaining ث'
                          : 'إعادة الإرسال',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _remaining > 0
                            ? AppColors.mutedDark
                            : AppColors.primaryGlow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_error != null) AuthErrorText(message: _error!),
          const SizedBox(height: 16),
          AuthPrimaryButton(
            label: 'تحقق',
            loading: _loading,
            onPressed: _complete ? _submit : null,
          ),
        ],
      ),
    );
  }

  Widget _otpBox(int i) {
    final filled = _controllers[i].text.isNotEmpty;
    return Container(
      width: 48,
      height: 60,
      decoration: BoxDecoration(
        color: filled ? AppColors.surfaceAltDark : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: filled ? AppColors.primaryGlow : AppColors.borderDark,
          width: filled ? 1.4 : 1,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: AppColors.primaryGlow.withValues(alpha: 0.25),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _controllers[i],
        focusNode: _nodes[i],
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        cursorColor: AppColors.primaryGlow,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.inkDark,
          height: 1.0,
        ),
        onChanged: (v) => _onChanged(i, v),
        decoration: const InputDecoration(
          counterText: '',
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
