import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../features/home/main_shell.dart';
import '../../shared/widgets/linkedin_logo.dart';
import '../../shared/widgets/linked_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../state/app_scope.dart';
import '../../state/signup_controller.dart';
import 'widgets/info_note.dart';
import 'widgets/section_label.dart';
import 'widgets/selectable_wrap.dart';
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

  String _stepLabel(int step) =>
      'الخطوة ${step + 1} من ${SignupController.totalSteps}';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _form,
      builder: (context, _) {
        final isEngineer = _form.accountType == SignupAccountType.engineer;

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
                            'اختر نوع الحساب وابدأ في بناء مشاريع هندسية حقيقية.',
                        children: [
                          _AccountTypeSelector(
                            value: _form.accountType,
                            onChanged: _form.setAccountType,
                          ),
                          const SizedBox(height: 18),
                          if (isEngineer) ...[
                            LinkedTextField(
                              label: 'الاسم الكامل',
                              controller: _form.fullName,
                            ),
                            const SizedBox(height: 14),
                            LinkedTextField(
                              label: 'البريد الإلكتروني',
                              hint: 'name@example.com',
                              controller: _form.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ] else ...[
                            LinkedTextField(
                              label: 'اسم الشركة',
                              controller: _form.companyName,
                            ),
                            const SizedBox(height: 14),
                            LinkedTextField(
                              label: 'بريد العمل',
                              hint: 'team@company.com',
                              controller: _form.workEmail,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ],
                          const SizedBox(height: 14),
                          LinkedTextField(
                            label: 'كلمة المرور',
                            controller: _form.password,
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          const InfoNote(
                            icon: Icons.engineering_outlined,
                            text:
                                'المهندس يربط الشركات والمهندسين عبر مشاريع تقنية حقيقية، وليس عبر السير الذاتية وحدها.',
                          ),
                        ],
                      ),
                      SignupPage(
                        step: _stepLabel(1),
                        title: isEngineer ? 'ملفك الهندسي' : 'معلومات المنظمة',
                        subtitle: isEngineer
                            ? 'عرّف تخصصك ومستوى خبرتك والمهارات التي تريد استخدامها في المشاريع.'
                            : 'أضف معلومات تساعد المهندسين على فهم شركتك ونوع المشاريع التي تنشئها.',
                        children: isEngineer
                            ? [
                                const SectionLabel('التخصص'),
                                SelectableWrap(
                                  values: const [
                                    'Frontend',
                                    'Backend',
                                    'Full Stack',
                                    'Embedded Systems',
                                    'AI/ML',
                                    'Robotics',
                                    'DevOps',
                                    'UI/UX',
                                    'Cybersecurity',
                                  ],
                                  selected: {_form.specialization.text},
                                  onChanged: _form.setSpecialization,
                                ),
                                const SizedBox(height: 18),
                                const SectionLabel('مستوى الخبرة'),
                                SelectableWrap(
                                  values: const [
                                    'Student',
                                    'Beginner',
                                    'Intermediate',
                                    'Advanced',
                                  ],
                                  selected: {_form.experienceLevel},
                                  onChanged: _form.setExperienceLevel,
                                ),
                                const SizedBox(height: 18),
                                const SectionLabel('المهارات'),
                                SelectableWrap(
                                  values: const [
                                    'React',
                                    'C++',
                                    'Python',
                                    'TensorFlow',
                                    'FPGA',
                                    'Docker',
                                    'Flutter',
                                    'Figma',
                                  ],
                                  selected: _form.skills,
                                  onChanged: _form.toggleSkill,
                                ),
                              ]
                            : [
                                LinkedTextField(
                                  label: 'الصناعة',
                                  hint: 'Software, Robotics, AI...',
                                  controller: _form.industry,
                                ),
                                const SizedBox(height: 18),
                                const SectionLabel('حجم الشركة'),
                                SelectableWrap(
                                  values: const [
                                    '1-10',
                                    '11-50',
                                    '51-200',
                                    '200+',
                                  ],
                                  selected: {_form.companySize},
                                  onChanged: _form.setCompanySize,
                                ),
                                const SizedBox(height: 18),
                                LinkedTextField(
                                  label: 'الدولة',
                                  controller: _form.country,
                                ),
                              ],
                      ),
                      SignupPage(
                        step: _stepLabel(2),
                        title: 'تفاصيل اختيارية',
                        subtitle: isEngineer
                            ? 'أضف روابط تثبت عملك وتساعد الفرق على تقييم مساهماتك.'
                            : 'أضف روابط ووصفا قصيرا حتى تظهر شركتك بوضوح للمهندسين.',
                        children: isEngineer
                            ? [
                                LinkedTextField(
                                  label: 'GitHub',
                                  controller: _form.github,
                                ),
                                const SizedBox(height: 14),
                                LinkedTextField(
                                  label: 'LinkedIn',
                                  controller: _form.linkedIn,
                                ),
                                const SizedBox(height: 14),
                                LinkedTextField(
                                  label: 'موقع المحفظة',
                                  controller: _form.portfolio,
                                ),
                                const SizedBox(height: 14),
                                LinkedTextField(
                                  label: 'نبذة قصيرة',
                                  controller: _form.bio,
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 12),
                                _UploadToggle(
                                  icon: Icons.description_outlined,
                                  label: 'رفع السيرة الذاتية',
                                  value: _form.resumeUploaded,
                                  onPressed: () => _form.setResumeUploaded(
                                    !_form.resumeUploaded,
                                  ),
                                ),
                              ]
                            : [
                                LinkedTextField(
                                  label: 'موقع الشركة',
                                  controller: _form.website,
                                ),
                                const SizedBox(height: 14),
                                LinkedTextField(
                                  label: 'LinkedIn الشركة',
                                  controller: _form.companyLinkedIn,
                                ),
                                const SizedBox(height: 14),
                                LinkedTextField(
                                  label: 'وصف قصير',
                                  controller: _form.shortDescription,
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 12),
                                _UploadToggle(
                                  icon: Icons.image_outlined,
                                  label: 'رفع شعار الشركة',
                                  value: _form.logoUploaded,
                                  onPressed: () => _form.setLogoUploaded(
                                    !_form.logoUploaded,
                                  ),
                                ),
                              ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
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
                          onPressed: _form.isLastStep
                              ? _complete
                              : _form.nextStep,
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

class _AccountTypeSelector extends StatelessWidget {
  const _AccountTypeSelector({required this.value, required this.onChanged});

  final SignupAccountType value;
  final ValueChanged<SignupAccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final type in SignupAccountType.values) ...[
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 86,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: value == type ? AppColors.paleBlue : AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: value == type ? AppColors.blue : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      type == SignupAccountType.engineer
                          ? Icons.engineering
                          : Icons.business,
                      color: AppColors.blue,
                    ),
                    const Spacer(),
                    Text(
                      type.label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (type != SignupAccountType.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _UploadToggle extends StatelessWidget {
  const _UploadToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(value ? Icons.check_circle : icon),
      label: Text(value ? 'تم: $label' : label),
      style: OutlinedButton.styleFrom(
        foregroundColor: value ? AppColors.blue : AppColors.muted,
        minimumSize: const Size.fromHeight(46),
        side: BorderSide(color: value ? AppColors.blue : AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
      ),
    );
  }
}
