import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/account_type.dart';
import '../../state/signup_controller.dart';
import 'specialization_signup_screen.dart';
import 'widgets/auth_inputs.dart';
import 'widgets/auth_scaffold.dart';

class AccountTypeSignupScreen extends StatelessWidget {
  const AccountTypeSignupScreen({super.key, required this.controller});

  final SignupController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return AuthScaffold(
          icon: Icons.account_circle_outlined,
          title: 'ما نوع حسابك؟',
          subtitle:
              'اختر نوع المستخدم المناسب. يمكنك اختيار نوع واحد فقط.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final type in AccountType.values
                  .where((type) => type != AccountType.admin)) ...[
                _TypeCard(
                  type: type,
                  selected: controller.userType == type,
                  onTap: () => controller.setUserType(type),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 16),
              AuthPrimaryButton(
                label: 'متابعة',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SpecializationSignupScreen(controller: controller),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceAltDark : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primaryGlow : AppColors.borderDark,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGlow.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryGlow
                    : AppColors.surfaceAltDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                type.icon,
                color: selected ? Colors.white : AppColors.mutedDark,
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
                      color: AppColors.inkDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.description,
                    style: const TextStyle(
                      color: AppColors.mutedDark,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: selected ? AppColors.primaryGlow : AppColors.mutedDark,
            ),
          ],
        ),
      ),
    );
  }
}
