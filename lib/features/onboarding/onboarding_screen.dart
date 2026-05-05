import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/onboarding_slide.dart';
import '../../shared/painters/onboarding_scene_painter.dart';
import '../../shared/widgets/linkedin_logo.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/social_button.dart';
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
          'اكتشف مشاريع مبتكرة من شركات وفرق ناشئة في البرمجيات والذكاء الاصطناعي والأنظمة المدمجة والروبوتات.',
    ),
    OnboardingSlide(
      title: 'ابنوا معا',
      subtitle:
          'اعمل مع مهندسين داخل مساحات تعاون، تابع التقدم، شارك الأفكار، وساهم في منتجات ذات معنى.',
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
              const SizedBox(height: 8),
              SocialButton(
                label: 'المتابعة بواسطة Apple',
                icon: Icons.apple,
                onPressed: _openSignIn,
              ),
              const SizedBox(height: 8),
              SocialButton.google(
                label: 'المتابعة بواسطة Google',
                onPressed: _openSignIn,
              ),
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
                color: AppColors.ink,
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
                  color: AppColors.muted,
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
            color: selected ? AppColors.muted : Colors.white,
            border: Border.all(color: AppColors.muted),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
