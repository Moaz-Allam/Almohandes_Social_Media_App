import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/countries.dart';
import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';
import '../auth/widgets/auth_inputs.dart';
import '../auth/widgets/auth_scaffold.dart';
import 'add_phone_otp_screen.dart';

enum _ContactKind { email, phone }

/// Lets a signed-in user attach another sign-in credential to their account:
///   • an email — verified by a confirmation link sent to the inbox.
///   • a phone  — verified by an OTP (handled in [AddPhoneOtpScreen]).
///
/// Both use Supabase's native `updateUser` change flows, so the new credential
/// becomes usable for sign-in once verified.
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  _ContactKind _kind = _ContactKind.email;

  final _email = TextEditingController();
  final _phoneController = TextEditingController();
  Country _country = defaultCountry;
  String _phoneValue = '';

  bool _loading = false;
  String? _error;

  bool get _emailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  bool get _phoneValid => _phoneValue.length >= 7;

  bool get _canSubmit =>
      !_loading &&
      (_kind == _ContactKind.email ? _emailValid : _phoneValid);

  String get _fullPhone {
    final normalized =
        _phoneValue.startsWith('0') ? _phoneValue.substring(1) : _phoneValue;
    return '${_country.dialCode}$normalized';
  }

  @override
  void dispose() {
    _email.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AppScope.read(context).repositories.auth;
      if (_kind == _ContactKind.email) {
        await auth.addEmailToCurrentUser(email: _email.text.trim());
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'أرسلنا رابط تفعيل إلى ${_email.text.trim()}. '
                'افتح الرابط من بريدك لإكمال الإضافة.',
              ),
            ),
          );
        return;
      }
      // Phone: send the OTP, then verify it on the next screen.
      await auth.startPhoneChange(phone: _fullPhone);
      if (!mounted) return;
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AddPhoneOtpScreen(phone: _fullPhone),
        ),
      );
      if (verified != true || !mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('تم تأكيد رقم هاتفك. يمكنك تسجيل الدخول به لاحقًا.'),
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
    final isEmail = _kind == _ContactKind.email;
    return AuthScaffold(
      icon: isEmail ? Icons.alternate_email_rounded : Icons.smartphone_rounded,
      title: 'إضافة وسيلة دخول',
      subtitle: isEmail
          ? 'أضِف بريدًا إلكترونيًا للدخول به لاحقًا.\nسنرسل رابط تفعيل إلى بريدك.'
          : 'أضِف رقم هاتف للدخول به لاحقًا.\nسنرسل رمز تحقق عبر رسالة نصية.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<_ContactKind>(
            segments: const [
              ButtonSegment(
                value: _ContactKind.email,
                label: Text('بريد إلكتروني'),
                icon: Icon(Icons.email_outlined, size: 18),
              ),
              ButtonSegment(
                value: _ContactKind.phone,
                label: Text('رقم هاتف'),
                icon: Icon(Icons.phone_outlined, size: 18),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              setState(() {
                _kind = selection.first;
                _error = null;
              });
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primaryGlow;
                }
                return AppColors.surfaceDark;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.inkDark;
              }),
              side: WidgetStateProperty.all(
                const BorderSide(color: AppColors.borderDark),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (isEmail)
            AuthTextField(
              controller: _email,
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.alternate_email_rounded,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) {
                if (_canSubmit) _submit();
              },
            )
          else
            PhoneInputRow(
              controller: _phoneController,
              country: _country,
              onChanged: (v) => setState(() {
                _phoneValue = v;
                _error = null;
              }),
              onCountryChanged: (c) => setState(() => _country = c),
            ),
          if (_error != null) AuthErrorText(message: _error!),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: isEmail ? 'إرسال رابط التحقق' : 'إرسال رمز التحقق',
            loading: _loading,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
