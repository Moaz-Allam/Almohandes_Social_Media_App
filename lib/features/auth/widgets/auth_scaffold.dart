import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Shared dark-theme scaffold used by every screen in the phone-first auth
/// flow. Matches the design mockups: solid near-black background, a small
/// progress-dot row at the top, a glowing icon header, then the screen's
/// title + subtitle, then [child] (the inputs/CTA).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.stepCount = 0,
    this.currentStep = 0,
    this.showBack = true,
    this.footer,
  });

  /// Icon shown inside the glowing rounded header tile.
  final IconData icon;
  final String title;
  final String subtitle;

  /// Main body — usually fields + a primary button.
  final Widget child;

  /// When > 0, renders a horizontal row of [stepCount] dots and fills the
  /// first [currentStep] of them with the primary glow color. Pass `0` to
  /// hide the indicator entirely (login screens, single-step flows, …).
  final int stepCount;
  final int currentStep;

  /// Optional bottom row, e.g. "already have an account? log in" links.
  final Widget? footer;

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            if (showBack)
                              _RoundIconButton(
                                icon: Icons.arrow_back_rounded,
                                onTap: () => Navigator.of(context).maybePop(),
                              )
                            else
                              const SizedBox(width: 40),
                            const Spacer(),
                            if (stepCount > 0)
                              _StepDots(
                                count: stepCount,
                                current: currentStep,
                              )
                            else
                              const SizedBox(width: 40),
                            const Spacer(),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _HeaderIcon(icon: icon),
                        const SizedBox(height: 22),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mutedDark,
                          ),
                        ),
                        const SizedBox(height: 32),
                        child,
                        if (footer != null) ...[
                          const Spacer(),
                          const SizedBox(height: 16),
                          footer!,
                        ] else
                          const Spacer(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Icon(icon, color: AppColors.inkDark, size: 20),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryGlow : AppColors.borderDark,
            borderRadius: BorderRadius.circular(4),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primaryGlow.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [AppColors.primaryGlow, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGlow.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
