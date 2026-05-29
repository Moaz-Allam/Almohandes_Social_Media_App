import 'package:flutter/material.dart';

import '../../core/data/countries.dart';
import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';
import 'reset_password_otp_screen.dart';
import 'widgets/auth_inputs.dart';
import 'widgets/auth_scaffold.dart';

/// Reset-password step 1 — collect the phone number and send an OTP.
class ResetPasswordPhoneScreen extends StatefulWidget {
  const ResetPasswordPhoneScreen({super.key});

  @override
  State<ResetPasswordPhoneScreen> createState() =>
      _ResetPasswordPhoneScreenState();
}

class _ResetPasswordPhoneScreenState extends State<ResetPasswordPhoneScreen> {
  final _controller = TextEditingController();
  Country _country = defaultCountry;
  String _value = '';
  bool _loading = false;
  String? _error;

  bool get _valid => _value.length >= 7 && !_loading;

  String get _fullPhone {
    final normalized = _value.startsWith('0') ? _value.substring(1) : _value;
    return '${_country.dialCode}$normalized';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AppScope.read(context).repositories.auth;
      // Check that the phone is registered first.
      final exists = await auth.phoneExists(_fullPhone);
      if (!mounted) return;
      if (!exists) {
        setState(() => _error = 'لا يوجد حساب بهذا الرقم.');
        return;
      }
      // Send OTP for password reset (shouldCreateUser: false).
      await auth.sendPasswordResetOtp(phone: _fullPhone);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordOtpScreen(phone: _fullPhone),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      icon: Icons.lock_reset_rounded,
      title: 'نسيت كلمة المرور',
      subtitle: 'أدخل رقم هاتفك المسجَّل وسنرسل لك\nرمز تحقق لإعادة تعيين كلمة المرور.',
      stepCount: 3,
      currentStep: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhoneInputRow(
            controller: _controller,
            country: _country,
            onChanged: (v) => setState(() {
              _value = v;
              _error = null;
            }),
            onCountryChanged: (c) => setState(() => _country = c),
          ),
          if (_error != null) AuthErrorText(message: _error!),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: 'إرسال رمز التحقق',
            loading: _loading,
            onPressed: _valid ? _next : null,
          ),
        ],
      ),
    );
  }
}
