import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../features/home/main_shell.dart';
import '../../shared/widgets/linkedin_logo.dart';
import '../../shared/widgets/linked_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../state/app_scope.dart';
import '../../state/signup_controller.dart';
import 'widgets/info_note.dart';
import 'widgets/live_profile_card.dart';
import 'widgets/profile_completeness.dart';
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
                        title: 'إنشاء حسابك',
                        subtitle:
                            'استخدم بريدا أو رقم هاتف لتأمين حسابك المهني.',
                        children: [
                          LinkedTextField(
                            label: 'البريد الإلكتروني',
                            hint: 'name@example.com',
                            controller: _form.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          LinkedTextField(
                            label: 'كلمة المرور',
                            controller: _form.password,
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          const InfoNote(
                            icon: Icons.lock_outline,
                            text:
                                'سنستخدم هذه البيانات لتسجيل الدخول وحماية الحساب فقط.',
                          ),
                        ],
                      ),
                      SignupPage(
                        step: _stepLabel(1),
                        title: 'من أنت؟',
                        subtitle:
                            'اكتب اسمك كما تريد أن يظهر لزملائك وأصحاب العمل.',
                        children: [
                          LinkedTextField(
                            label: 'الاسم الأول',
                            controller: _form.firstName,
                          ),
                          const SizedBox(height: 14),
                          LinkedTextField(
                            label: 'اسم العائلة',
                            controller: _form.lastName,
                          ),
                          const SizedBox(height: 18),
                          LiveProfileCard(
                            name:
                                '${_form.firstName.text} ${_form.lastName.text}',
                            headline: _form.headline.text,
                            location: _form.location.text,
                            openToWork: _form.openToWork,
                          ),
                        ],
                      ),
                      SignupPage(
                        step: _stepLabel(2),
                        title: 'العنوان المهني والموقع',
                        subtitle:
                            'هذه المعلومات تساعد الآخرين على فهم خبرتك بسرعة.',
                        children: [
                          LinkedTextField(
                            label: 'العنوان المهني',
                            controller: _form.headline,
                          ),
                          const SizedBox(height: 14),
                          LinkedTextField(
                            label: 'القطاع',
                            controller: _form.industry,
                          ),
                          const SizedBox(height: 14),
                          LinkedTextField(
                            label: 'المدينة والدولة',
                            controller: _form.location,
                          ),
                          const SizedBox(height: 14),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('متاحة لفرص عمل جديدة'),
                            subtitle: const Text(
                              'أضف شارة تظهر للموظفين وأصحاب العمل',
                            ),
                            value: _form.openToWork,
                            activeThumbColor: AppColors.blue,
                            onChanged: _form.setOpenToWork,
                          ),
                        ],
                      ),
                      SignupPage(
                        step: _stepLabel(3),
                        title: 'الخبرة الحالية',
                        subtitle:
                            'أضف آخر دور عمل حتى تكتمل بطاقة ملفك الشخصي.',
                        children: [
                          LinkedTextField(
                            label: 'المسمى الوظيفي',
                            controller: _form.role,
                          ),
                          const SizedBox(height: 14),
                          LinkedTextField(
                            label: 'الشركة أو جهة العمل',
                            controller: _form.company,
                          ),
                          const SizedBox(height: 14),
                          LinkedTextField(
                            label: 'وصف مختصر للخبرة',
                            controller: _form.experience,
                            maxLines: 4,
                          ),
                        ],
                      ),
                      SignupPage(
                        step: _stepLabel(4),
                        title: 'التعليم والمهارات',
                        subtitle:
                            'اختر المهارات واللغات التي تريد إبرازها في ملفك.',
                        children: [
                          LinkedTextField(
                            label: 'الجامعة أو المعهد',
                            controller: _form.school,
                          ),
                          const SizedBox(height: 14),
                          LinkedTextField(
                            label: 'الدرجة أو التخصص',
                            controller: _form.degree,
                          ),
                          const SizedBox(height: 18),
                          const SectionLabel('المهارات'),
                          SelectableWrap(
                            values: const [
                              'تصميم واجهات',
                              'إدارة منتجات',
                              'تحليل بيانات',
                              'Figma',
                              'Flutter',
                              'مبيعات B2B',
                              'بحث المستخدم',
                              'قيادة فرق',
                            ],
                            selected: _form.skills,
                            onChanged: _form.toggleSkill,
                          ),
                          const SizedBox(height: 18),
                          const SectionLabel('اللغات'),
                          SelectableWrap(
                            values: const [
                              'العربية',
                              'الإنجليزية',
                              'الفرنسية',
                              'الألمانية',
                            ],
                            selected: _form.languages,
                            onChanged: _form.toggleLanguage,
                          ),
                        ],
                      ),
                      SignupPage(
                        step: _stepLabel(5),
                        title: 'النبذة وإعدادات الظهور',
                        subtitle: 'لمسة أخيرة تجعل ملفك جاهزا للظهور والتواصل.',
                        children: [
                          LinkedTextField(
                            label: 'نبذة عنك',
                            controller: _form.about,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 14),
                          LinkedTextField(
                            label: 'رابط الموقع أو المحفظة',
                            controller: _form.website,
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('إظهار الملف في نتائج البحث'),
                            subtitle: const Text(
                              'يسمح للزملاء والموظفين بالعثور عليك',
                            ),
                            value: _form.profilePublic,
                            activeThumbColor: AppColors.blue,
                            onChanged: _form.setProfilePublic,
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('إرسال تنبيهات وظائف مناسبة'),
                            subtitle: const Text(
                              'حسب الموقع والقطاع والمهارات المختارة',
                            ),
                            value: _form.jobAlerts,
                            activeThumbColor: AppColors.blue,
                            onChanged: _form.setJobAlerts,
                          ),
                          const SizedBox(height: 10),
                          ProfileCompleteness(
                            skills: _form.skills.length,
                            languages: _form.languages.length,
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
