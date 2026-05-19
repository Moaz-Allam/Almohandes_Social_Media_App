import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/linkedin_logo.dart';
import '../../shared/widgets/linked_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../state/app_scope.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _email;
  bool _isSubmitting = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(
      text: widget.initialEmail.contains('@') ? widget.initialEmail.trim() : '',
    );
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_isSubmitting) {
      return;
    }
    final email = _email.text.trim();
    if (email.isEmpty) {
      AppSnack.error(context, 'أدخل بريدك الإلكتروني');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      AppSnack.error(
        context,
        'صيغة البريد الإلكتروني غير صحيحة. استخدم صيغة مثل name@example.com',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AppScope.read(context).repositories.auth.sendPasswordReset(
        email: email,
      );
      if (!mounted) {
        return;
      }
      setState(() => _sent = true);
      AppSnack.success(
        context,
        'تم إرسال رابط استعادة كلمة المرور إلى $email. تحقق من صندوق الوارد وكذلك من البريد المهمل',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnack.error(
        context,
        error,
        fallback:
            'تعذر إرسال رابط الاستعادة. تأكد من صحة البريد ومن اتصالك بالإنترنت',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          children: [
            Row(
              children: [
                const LinkedInLogo(scale: .78),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'إغلاق',
                ),
              ],
            ),
            const SizedBox(height: 42),
            Text(
              'استعادة كلمة المرور',
              style: TextStyle(
                color: context.appText,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أدخل بريدك الإلكتروني وسنرسل لك رابطا لتعيين كلمة مرور جديدة.',
              style: TextStyle(
                color: context.appMuted,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            LinkedTextField(
              label: 'البريد الإلكتروني',
              hint: 'name@example.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: _isSubmitting ? 'جاري الإرسال...' : 'إرسال رابط الاستعادة',
              onPressed: _sendResetLink,
              isLoading: _isSubmitting,
            ),
            if (_sent) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appPaleBlue,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.blue),
                ),
                child: Text(
                  'افتح الرابط من بريدك الإلكتروني على هذا الجهاز، ثم أدخل كلمة المرور الجديدة داخل التطبيق.',
                  style: TextStyle(
                    color: context.appText,
                    height: 1.45,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
