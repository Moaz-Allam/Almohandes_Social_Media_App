import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../features/home/main_shell.dart';
import '../../models/account_type.dart';
import '../../shared/widgets/linkedin_logo.dart';
import '../../shared/widgets/linked_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../state/app_scope.dart';
import '../../state/signup_controller.dart';
import 'widgets/section_label.dart';
import 'widgets/signup_page.dart';

class SignUpFlowScreen extends StatefulWidget {
  const SignUpFlowScreen({super.key});

  @override
  State<SignUpFlowScreen> createState() => _SignUpFlowScreenState();
}

class _SignUpFlowScreenState extends State<SignUpFlowScreen> {
  late final SignupController _form;

  @override
  void initState() {
    super.initState();
    _form = SignupController();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await AppScope.read(context).completeSignUp(_form.toProfile());
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  void _goBack() {
    if (_form.step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    _form.previousStep();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handlePrimary() {
    if (_form.step == 0) {
      if (_form.displayName.text.trim().isEmpty ||
          _form.email.text.trim().isEmpty) {
        _showMessage('أكمل الاسم والبريد الإلكتروني أولا');
        return;
      }
      if (!_form.hasValidIraqiPhone) {
        _showMessage('رقم الهاتف يجب أن يكون رقم عراقي مثل 07xxxxxxxxx');
        return;
      }
      if (!_form.hasMatchingPasswords) {
        _showMessage('تأكد من كلمة المرور وتأكيدها');
        return;
      }
      _form.nextStep();
      return;
    }

    if (_form.step == 1) {
      if (!_form.hasValidOtp) {
        _showMessage('رمز التحقق التجريبي هو 123456');
        return;
      }
      _form.nextStep();
      return;
    }

    if (_form.isLastStep) {
      _complete();
      return;
    }
    _form.nextStep();
  }

  String _stepLabel(int step) =>
      'الخطوة ${step + 1} من ${SignupController.totalSteps}';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _form,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Row(
                    children: [
                      const LinkedInLogo(scale: .78),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst),
                        icon: const Icon(Icons.close),
                        tooltip: 'إغلاق',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: _form.progress,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.blue,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _form.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      SignupPage(
                        step: _stepLabel(0),
                        title: 'أساسيات الحساب',
                        subtitle:
                            'أدخل بياناتك الأساسية. رقم الهاتف يجب أن يكون عراقيا لتأكيد الحساب.',
                        children: [
                          LinkedTextField(
                            label: 'الاسم أو اسم الجهة',
                            controller: _form.displayName,
                          ),
                          const SizedBox(height: 14),
                          LinkedTextField(
                            label: 'البريد الإلكتروني',
                            hint: 'name@example.com',
                            controller: _form.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          LinkedTextField(
                            label: 'رقم الهاتف',
                            hint: '07',
                            controller: _form.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          LinkedTextField(
                            label: 'كلمة المرور',
                            controller: _form.password,
                            obscureText: true,
                          ),
                          const SizedBox(height: 14),
                          LinkedTextField(
                            label: 'تأكيد كلمة المرور',
                            controller: _form.confirmPassword,
                            obscureText: true,
                          ),
                        ],
                      ),
                      SignupPage(
                        step: _stepLabel(1),
                        title: 'تأكيد رقم الهاتف',
                        subtitle:
                            'أدخل رمز التحقق المرسل إلى ${_form.phone.text.isEmpty ? 'رقمك العراقي' : _form.phone.text}. الرمز التجريبي هو 123456.',
                        children: [
                          LinkedTextField(
                            label: 'رمز التحقق OTP',
                            hint: '123456',
                            controller: _form.otp,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => _showMessage(
                              'تم إرسال رمز تحقق جديد إلى رقمك العراقي',
                            ),
                            icon: const Icon(Icons.sms_outlined),
                            label: const Text('إعادة إرسال الرمز'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.blue,
                              minimumSize: const Size.fromHeight(46),
                              side: const BorderSide(color: AppColors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(23),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SignupPage(
                        step: _stepLabel(2),
                        title: 'ما نوع حسابك؟',
                        subtitle:
                            'اختر نوع المستخدم المناسب. يمكنك اختيار نوع واحد فقط.',
                        children: [
                          for (final type in AccountType.values) ...[
                            _UserTypeCard(
                              type: type,
                              selected: _form.userType == type,
                              onTap: () => _form.setUserType(type),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                      SignupPage(
                        step: _stepLabel(3),
                        title: _form.userType.specializationTitle,
                        subtitle: _form.userType.specializationSubtitle,
                        children: [
                          _OptionGrid(
                            values: _form.specializationOptions,
                            selected: _form.specialization,
                            onChanged: _form.setSpecialization,
                          ),
                        ],
                      ),
                      SignupPage(
                        step: _stepLabel(4),
                        title: 'محافظتك؟',
                        subtitle: 'اختر محافظتك داخل العراق.',
                        children: [
                          const SectionLabel('المحافظة'),
                          const SizedBox(height: 10),
                          _OptionGrid(
                            values: iraqiGovernorates,
                            selected: _form.governorate,
                            onChanged: _form.setGovernorate,
                            icon: Icons.location_on_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    border: Border(top: BorderSide(color: context.appBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _goBack,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.blue),
                              foregroundColor: AppColors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(_form.step == 0 ? 'رجوع' : 'السابق'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: _form.isLastStep ? 'إنهاء' : 'متابعة',
                          onPressed: _handlePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  const _UserTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final AccountType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? context.appPaleBlue : context.appSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.blue : context.appBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? AppColors.blue : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                type.icon,
                color: selected ? AppColors.white : AppColors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    type.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appMuted),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.chevron_right,
              color: selected ? AppColors.blue : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.values,
    required this.selected,
    required this.onChanged,
    this.icon,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth > 380;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final value in values)
              SizedBox(
                width: twoColumns
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth,
                child: _OptionTile(
                  label: value,
                  icon: icon ?? _iconFor(value),
                  selected: selected == value,
                  onTap: () => onChanged(value),
                ),
              ),
          ],
        );
      },
    );
  }

  IconData _iconFor(String value) {
    if (value.contains('كهرب') || value.contains('طاقة')) {
      return Icons.bolt_outlined;
    }
    if (value.contains('شركة') || value.contains('مقاول')) {
      return Icons.business_outlined;
    }
    if (value.contains('شفل') ||
        value.contains('كرين') ||
        value.contains('شاحنة') ||
        value.contains('بلدوزر') ||
        value.contains('دحالة') ||
        value.contains('شوكية')) {
      return Icons.local_shipping_outlined;
    }
    if (value.contains('حاسوب') || value.contains('كاميرات')) {
      return Icons.computer_outlined;
    }
    if (value.contains('نجار') ||
        value.contains('حداد') ||
        value.contains('سباك')) {
      return Icons.handyman_outlined;
    }
    return Icons.engineering_outlined;
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.appPaleBlue : context.appSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.blue : context.appBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.blue : context.appMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.blue : context.appText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.blue, size: 20),
          ],
        ),
      ),
    );
  }
}
