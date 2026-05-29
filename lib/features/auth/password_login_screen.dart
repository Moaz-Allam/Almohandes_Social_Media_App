import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';
import 'widgets/auth_inputs.dart';
import 'widgets/auth_scaffold.dart';

/// Login step 2 — collect the password and call the AppController, which
/// signs the user in and triggers the navigation flip in [AppController].
class PasswordLoginScreen extends StatefulWidget {
  const PasswordLoginScreen({super.key, required this.phone});

  final String phone;

  @override
  State<PasswordLoginScreen> createState() => _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends State<PasswordLoginScreen> {
  final _password = TextEditingController();
  bool _showPwd = false;
  bool _loading = false;
  String? _error;

  bool get _valid => _password.text.isNotEmpty && !_loading;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AppScope.read(context).signInWithPassword(
        phone: widget.phone,
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
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
      icon: Icons.lock_outline_rounded,
      title: 'كلمة المرور',
      subtitle: 'أدخل كلمة المرور للحساب\n${widget.phone}',
      stepCount: 2,
      currentStep: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _password,
            hint: 'كلمة المرور',
            obscure: !_showPwd,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_valid) _submit();
            },
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
          if (_error != null) AuthErrorText(message: _error!),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: 'دخول',
            loading: _loading,
            onPressed: _valid ? _submit : null,
          ),
        ],
      ),
    );
  }
}
