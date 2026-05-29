import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';
import '../../state/signup_controller.dart';
import 'sign_up_success_screen.dart';
import 'widgets/auth_inputs.dart';
import 'widgets/auth_scaffold.dart';

class BioSignupScreen extends StatefulWidget {
  const BioSignupScreen({super.key, required this.controller});

  final SignupController controller;

  @override
  State<BioSignupScreen> createState() => _BioSignupScreenState();
}

class _BioSignupScreenState extends State<BioSignupScreen> {
  bool _loading = false;
  String? _error;

  SignupController get _form => widget.controller;

  Future<void> _finish() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AppScope.read(context).completeSignUp(
        _form.toProfile(),
        accountType: _form.userType,
        specialization: _form.specialization,
        phone: _form.fullPhone,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignUpSuccessScreen()),
        (_) => false,
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
          icon: Icons.description_outlined,
          title: 'نبذة ومهارات',
          subtitle:
              'أضف نبذة قصيرة ومهارات تظهر في ملفك الشخصي.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _form.about,
                hint: 'مثال: مهندس متخصص في المشاريع السكنية',
                keyboardType: TextInputType.multiline,
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 16),
              const Text(
                'المهارات',
                style: TextStyle(
                  color: AppColors.inkDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _SkillChips(
                values: _form.suggestedSkills,
                selected: _form.skills,
                onToggle: _form.toggleSkill,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      controller: _form.customSkill,
                      hint: 'مهارة إضافية',
                      onSubmitted: (_) => _form.addCustomSkill(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _AddSkillButton(onTap: _form.addCustomSkill),
                ],
              ),
              if (_error != null) AuthErrorText(message: _error!),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'إنهاء وإنشاء الحساب',
                loading: _loading,
                onPressed: _loading ? null : _finish,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkillChips extends StatelessWidget {
  const _SkillChips({
    required this.values,
    required this.selected,
    required this.onToggle,
  });

  final List<String> values;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          GestureDetector(
            onTap: () => onToggle(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected.contains(value)
                    ? AppColors.primaryGlow.withValues(alpha: 0.18)
                    : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected.contains(value)
                      ? AppColors.primaryGlow
                      : AppColors.borderDark,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected.contains(value)) ...[
                    const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.primaryGlow,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    value,
                    style: TextStyle(
                      color: selected.contains(value)
                          ? AppColors.primaryGlow
                          : AppColors.inkDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AddSkillButton extends StatelessWidget {
  const _AddSkillButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: AppColors.primaryGlow,
        ),
      ),
    );
  }
}
