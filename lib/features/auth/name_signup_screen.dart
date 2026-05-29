import 'package:flutter/material.dart';

import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';
import '../../state/signup_controller.dart';
import 'account_type_signup_screen.dart';
import 'widgets/auth_inputs.dart';
import 'widgets/auth_scaffold.dart';

/// Step 4 of the signup wizard — collects first + last name and writes
/// it to the freshly-created profile row. After this screen we hand off
/// to the profile-questions chain (account type → specialization → city
/// → bio/skills → finalize).
class NameSignupScreen extends StatefulWidget {
  const NameSignupScreen({super.key, required this.controller});

  final SignupController controller;

  @override
  State<NameSignupScreen> createState() => _NameSignupScreenState();
}

class _NameSignupScreenState extends State<NameSignupScreen> {
  bool _loading = false;
  String? _error;

  SignupController get _form => widget.controller;

  bool get _valid =>
      _form.firstName.text.trim().isNotEmpty &&
      _form.lastName.text.trim().isNotEmpty &&
      !_loading;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AppScope.read(context).repositories.auth;
      await auth.setFullNameForCurrentUser(fullName: _form.fullName);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AccountTypeSignupScreen(controller: _form),
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
    return AnimatedBuilder(
      animation: _form,
      builder: (context, _) {
        return AuthScaffold(
          icon: Icons.person_outline_rounded,
          title: 'ما اسمك؟',
          subtitle:
              'نود التعرف عليك لإكمال إنشاء حسابك.',
          stepCount: 4,
          currentStep: 4,
          showBack: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _form.firstName,
                hint: 'الاسم الأول',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _form.lastName,
                hint: 'اسم العائلة',
                prefixIcon: Icons.badge_outlined,
                textInputAction: TextInputAction.done,
              ),
              if (_error != null) AuthErrorText(message: _error!),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'متابعة',
                loading: _loading,
                onPressed: _valid ? _submit : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
