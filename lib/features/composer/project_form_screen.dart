import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'widgets/composer_top_bar.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _pageController = PageController();
  final _formKeys = List.generate(3, (_) => GlobalKey<FormState>());
  final _draft = _ProjectDraft();
  int _step = 0;

  bool get _isLastStep => _step == _projectSteps.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    _draft.dispose();
    super.dispose();
  }

  Future<void> _goToStep(int step) async {
    setState(() => _step = step);
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    final isValid = _formKeys[_step].currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    if (_isLastStep) {
      _submit();
      return;
    }
    _goToStep(_step + 1);
  }

  void _previous() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    _goToStep(_step - 1);
  }

  void _submit() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت مشاركة المشروع')));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          ComposerTopBar(
            title: 'مشاركة مشروع',
            onClose: () => Navigator.of(context).maybePop(),
            actionLabel: _isLastStep ? 'نشر' : 'التالي',
            onAction: _next,
          ),
          LinearProgressIndicator(
            value: (_step + 1) / _projectSteps.length,
            minHeight: 4,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ProjectStepView(
                  formKey: _formKeys[0],
                  title: _projectSteps[0].title,
                  subtitle: _projectSteps[0].subtitle,
                  children: [
                    _ProjectTextField(
                      controller: _draft.name,
                      label: 'اسم المشروع',
                      hint: 'مثال: منصة متابعة فرص العمل',
                      isRequired: true,
                    ),
                    _ProjectTextField(
                      controller: _draft.category,
                      label: 'نوع المشروع',
                      hint: 'تطبيق موبايل، موقع، لوحة تحكم...',
                      isRequired: true,
                    ),
                    _ProjectTextField(
                      controller: _draft.summary,
                      label: 'وصف مختصر',
                      hint: 'ما المشكلة التي يحلها المشروع؟',
                      minLines: 3,
                      isRequired: true,
                    ),
                  ],
                ),
                _ProjectStepView(
                  formKey: _formKeys[1],
                  title: _projectSteps[1].title,
                  subtitle: _projectSteps[1].subtitle,
                  children: [
                    _ProjectTextField(
                      controller: _draft.role,
                      label: 'دورك في المشروع',
                      hint: 'مصمم منتج، مطور، قائد فريق...',
                      isRequired: true,
                    ),
                    _ProjectTextField(
                      controller: _draft.tools,
                      label: 'الأدوات والتقنيات',
                      hint: 'Flutter, Firebase, Figma',
                      isRequired: true,
                    ),
                    _ProjectTextField(
                      controller: _draft.team,
                      label: 'الفريق أو المتعاونون',
                      hint: 'اذكر الأسماء أو اكتب مشروع فردي',
                    ),
                    _ProjectTextField(
                      controller: _draft.duration,
                      label: 'مدة التنفيذ',
                      hint: 'مثال: 6 أسابيع',
                    ),
                  ],
                ),
                _ProjectStepView(
                  formKey: _formKeys[2],
                  title: _projectSteps[2].title,
                  subtitle: _projectSteps[2].subtitle,
                  children: [
                    _ProjectTextField(
                      controller: _draft.projectUrl,
                      label: 'رابط المشروع',
                      hint: 'https://example.com',
                    ),
                    _ProjectTextField(
                      controller: _draft.repositoryUrl,
                      label: 'رابط المستودع أو الملف',
                      hint: 'GitHub, Behance, Dribbble...',
                    ),
                    _ProjectTextField(
                      controller: _draft.outcome,
                      label: 'النتائج والأثر',
                      hint: 'اذكر الأرقام، التعلم، أو ما تم تحسينه',
                      minLines: 3,
                      isRequired: true,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _draft.openToFeedback,
                      onChanged: (value) {
                        setState(() => _draft.openToFeedback = value);
                      },
                      activeThumbColor: AppColors.blue,
                      activeTrackColor: AppColors.surface,
                      title: const Text(
                        'أرغب في استقبال تعليقات على المشروع',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previous,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blue,
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(color: AppColors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(_step == 0 ? 'إلغاء' : 'السابق'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(_isLastStep ? 'نشر المشروع' : 'التالي'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectStepView extends StatelessWidget {
  const _ProjectStepView({
    required this.formKey,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, height: 1.35),
          ),
          const SizedBox(height: 22),
          for (final child in children) ...[child, const SizedBox(height: 14)],
        ],
      ),
    );
  }
}

class _ProjectTextField extends StatelessWidget {
  const _ProjectTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.minLines = 1,
    this.isRequired = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines == 1 ? 1 : 5,
      textInputAction: minLines == 1 ? TextInputAction.next : null,
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'هذا الحقل مطلوب';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

final class _ProjectStepMeta {
  const _ProjectStepMeta({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

final class _ProjectDraft {
  final name = TextEditingController();
  final category = TextEditingController();
  final summary = TextEditingController();
  final role = TextEditingController();
  final tools = TextEditingController();
  final team = TextEditingController();
  final duration = TextEditingController();
  final projectUrl = TextEditingController();
  final repositoryUrl = TextEditingController();
  final outcome = TextEditingController();
  bool openToFeedback = true;

  void dispose() {
    name.dispose();
    category.dispose();
    summary.dispose();
    role.dispose();
    tools.dispose();
    team.dispose();
    duration.dispose();
    projectUrl.dispose();
    repositoryUrl.dispose();
    outcome.dispose();
  }
}

const _projectSteps = [
  _ProjectStepMeta(
    title: 'أساسيات المشروع',
    subtitle: 'أضف الاسم والنوع والوصف الذي يشرح الفكرة بسرعة.',
  ),
  _ProjectStepMeta(
    title: 'الدور وطريقة التنفيذ',
    subtitle: 'وضح مساهمتك والأدوات والمدة حتى يفهم الزائر حجم العمل.',
  ),
  _ProjectStepMeta(
    title: 'النتائج والروابط',
    subtitle: 'اربط المشروع بمصدره واذكر الأثر أو الدروس المهمة.',
  ),
];
