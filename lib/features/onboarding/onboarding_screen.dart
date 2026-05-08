import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/onboarding_slide.dart';
import '../../shared/painters/onboarding_scene_painter.dart';
import '../../shared/privacy/privacy_policy_dialog.dart';
import '../../shared/widgets/linkedin_logo.dart';
import '../../shared/widgets/primary_button.dart';
import '../auth/sign_in_screen.dart';
import '../auth/sign_up_flow_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const _slides = [
    OnboardingSlide(
      title: 'انضم إلى مشاريع هندسية حقيقية',
      subtitle:
          'اكتشف مشاريع تنفيذ وتصميم وتشطيبات من شركات ومقاولين وفرق هندسية داخل العراق.',
    ),
    OnboardingSlide(
      title: 'ابنوا معا',
      subtitle:
          'اعمل مع مهندسين وحرفيين ومشغلي آليات، تابع التقدم، ونسق الأعمال حتى التسليم.',
    ),
    OnboardingSlide(
      title: 'ابن محفظتك الهندسية',
      subtitle:
          'حوّل مساهماتك في المشاريع إلى سجل موثق يثبت مهاراتك من خلال عمل حقيقي.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openJoin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignUpFlowScreen()));
  }

  void _openSignIn() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: LinkedInLogo(scale: .78),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) {
                    return _OnboardingSlide(copy: _slides[index], scene: index);
                  },
                ),
              ),
              _Dots(count: _slides.length, active: _page),
              const SizedBox(height: 28),
              PrimaryButton(label: 'انضم الآن', onPressed: _openJoin),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _openSignIn,
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => showPrivacyPolicyDialog(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.copy, required this.scene});

  final OnboardingSlide copy;
  final int scene;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 390;
        final illustrationHeight = compact
            ? (constraints.maxHeight * .4).clamp(110.0, 150.0)
            : 260.0;

        return Column(
          children: [
            if (!compact) const Spacer(),
            SizedBox(
              height: illustrationHeight,
              width: double.infinity,
              child: CustomPaint(painter: OnboardingScenePainter(scene)),
            ),
            SizedBox(height: compact ? 12 : 28),
            Text(
              copy.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appText,
                fontSize: compact ? 18 : 22,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 6 : 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 20),
              child: Text(
                copy.subtitle,
                textAlign: TextAlign.center,
                maxLines: compact ? 2 : 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appMuted,
                  fontSize: compact ? 12 : 14,
                  height: 1.4,
                ),
              ),
            ),
            if (!compact) const Spacer(),
          ],
        );
      },
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: selected ? 8 : 6,
          height: selected ? 8 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: selected ? context.appMuted : context.appSurface,
            border: Border.all(color: context.appMuted),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
