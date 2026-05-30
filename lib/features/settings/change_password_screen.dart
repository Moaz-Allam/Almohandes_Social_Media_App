import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';
import '../auth/widgets/auth_inputs.dart';
import '../auth/widgets/auth_scaffold.dart';

/// Lets an already-signed-in user set a new password from Settings.
///
/// The user has an active session here, so `updateUser(password:)` rotates the
/// password in place and the session stays valid — they remain logged in with
/// the new credentials without re-entering their phone or an OTP. On success we
/// pop back to Settings (returning `true`) so the caller can confirm.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPwd = false;
  bool _loading = false;
  String? _error;

  bool get _valid =>
      _password.text.length >= 6 &&
      _password.text == _confirm.text &&
      !_loading;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text != _confirm.text) {
      setState(() => _error = 'كلمتا المرور غير متطابقتين');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AppScope.read(context).repositories.auth;
      await auth.resetPassword(newPassword: _password.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
      icon: Icons.password_rounded,
      title: 'تغيير كلمة المرور',
      subtitle:
          'أدخل كلمة مرور جديدة لحسابك.\nستبقى مسجّلاً للدخول بكلمة المرور الجديدة.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _password,
            hint: 'كلمة المرور الجديدة',
            obscure: !_showPwd,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            suffix: IconButton(
              icon: Icon(
                _showPwd
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.mutedDark,
                size: 20,
              ),
              onPressed: () => setState(() => _showPwd = !_showPwd),
            ),
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _confirm,
            hint: 'تأكيد كلمة المرور',
            obscure: !_showPwd,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_valid) _submit();
            },
          ),
          if (_password.text.isNotEmpty && _password.text.length < 6)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.mutedDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (_error != null) AuthErrorText(message: _error!),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: 'حفظ كلمة المرور',
            loading: _loading,
            onPressed: _valid ? _submit : null,
          ),
        ],
      ),
    );
  }
}
