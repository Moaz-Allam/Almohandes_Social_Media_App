import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/account_type.dart';
import '../../models/project_draft.dart';
import '../../shared/widgets/app_snack.dart';
import '../../state/app_scope.dart';
import 'widgets/composer_top_bar.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _pageController = PageController();
  final _formKeys = List.generate(
    _projectSteps.length,
    (_) => GlobalKey<FormState>(),
  );
  final _draft = _ProjectDraft();
  int _step = 0;
  int _attachments = 0;
  final List<String> _attachmentNames = [];
  bool _isSubmitting = false;

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

  Future<void> _next() async {
    final isValid = _formKeys[_step].currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) {
      return;
    }
    if (_isLastStep) {
      await _submit();
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

  Future<void> _addAttachment() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnack.error(context, error, fallback: 'تعذر اختيار المرفقات الآن');
      return;
    }
    if (result == null || result.files.isEmpty) {
      return;
    }
    final files = result.files;
    if (!mounted) {
      return;
    }
    setState(() {
      _attachmentNames
        ..clear()
        ..addAll(
          files.map((file) => file.name.isEmpty ? 'مرفق بدون اسم' : file.name),
        );
      _attachments = _attachmentNames.length;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت إضافة المرفقات')));
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await AppScope.read(
        context,
      ).repositories.projects.createProject(_draft.toData(_attachments));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تمت مشاركة المشروع')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnack.error(context, error, fallback: 'تعذر نشر المشروع الآن');
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountType = accountTypeFromProfile(AppScope.watch(context).profile);
    if (!accountType.canPostProjects) {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: Column(
          children: [
            ComposerTopBar(
              title: 'مشاركة مشروع',
              onClose: () => Navigator.of(context).maybePop(),
            ),
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'مشاركة المشاريع متاحة للمهندسين والشركات فقط',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appBackground,
      body: Column(
        children: [
          ComposerTopBar(
            title: 'مشاركة مشروع',
            onClose: () => Navigator.of(context).maybePop(),
            actionLabel: _isSubmitting
                ? 'جار النشر...'
                : _isLastStep
                ? 'نشر'
                : 'التالي',
            onAction: _next,
            actionEnabled: !_isSubmitting,
          ),
          LinearProgressIndicator(
            value: (_step + 1) / _projectSteps.length,
            minHeight: 4,
            backgroundColor: context.appSurfaceAlt,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ProjectStepView(
                  formKey: _formKeys[0],
                  title: '1. أساسيات المشروع',
                  subtitle: 'اجعلها خفيفة وسريعة حتى يفهم المهندس الفكرة.',
                  children: [
                    _ProjectTextField(
                      controller: _draft.title,
                      label: 'عنوان المشروع',
                      hint: 'مثال: منصة مطابقة مشاريع تقنية',
                      isRequired: true,
                    ),
                    _ProjectTextField(
                      controller: _draft.tagline,
                      label: 'وصف قصير / جملة واحدة',
                      hint: 'لخص المشروع في سطر واضح',
                      isRequired: true,
                    ),
                    _DropdownField(
                      label: 'تصنيف المشروع',
                      value: _draft.category,
                      values: _projectCategories,
                      onChanged: (value) =>
                          setState(() => _draft.category = value),
                    ),
                    _DropdownField(
                      label: 'نوع المشروع',
                      value: _draft.projectType,
                      values: _projectTypes,
                      onChanged: (value) =>
                          setState(() => _draft.projectType = value),
                    ),
                    _DropdownField(
                      label: 'نمط العمل',
                      value: _draft.workMode,
                      values: _workModes,
                      onChanged: (value) =>
                          setState(() => _draft.workMode = value),
                    ),
                    _ProjectTextField(
                      controller: _draft.location,
                      label: 'الموقع إن وجد',
                      hint: 'بغداد، البصرة، موقعي، هجين...',
                    ),
                  ],
                ),
                _ProjectStepView(
                  formKey: _formKeys[1],
                  title: '2. نظرة عامة على المشروع',
                  subtitle: 'هذه هي مساحة عرض الفكرة وقيمتها.',
                  children: [
                    _ProjectTextField(
                      controller: _draft.fullDescription,
                      label: 'الوصف الكامل للمشروع',
                      hint: 'اشرح المشروع والسياق والنتيجة المطلوبة',
                      minLines: 5,
                      isRequired: true,
                    ),
                    _ProjectTextField(
                      controller: _draft.problem,
                      label: 'المشكلة التي يحلها',
                      hint: 'ما الألم أو الاحتياج الذي يعالجه؟',
                      minLines: 3,
                      isRequired: true,
                    ),
                    _ProjectTextField(
                      controller: _draft.goals,
                      label: 'الأهداف / النتيجة المتوقعة',
                      hint: 'اكتب ما يجب الوصول إليه في نهاية المشروع',
                      minLines: 3,
                    ),
                    _ProjectTextField(
                      controller: _draft.audience,
                      label: 'المستخدمون المستهدفون',
                      hint: 'من سيستخدم هذا المشروع؟',
                    ),
                    _DropdownField(
                      label: 'المرحلة الحالية',
                      value: _draft.stage,
                      values: _stages,
                      onChanged: (value) =>
                          setState(() => _draft.stage = value),
                    ),
                    _AssetsSelector(
                      selected: _draft.assets,
                      onToggle: (asset) {
                        setState(() {
                          _draft.assets.contains(asset)
                              ? _draft.assets.remove(asset)
                              : _draft.assets.add(asset);
                        });
                      },
                    ),
                    OutlinedButton.icon(
                      onPressed: _addAttachment,
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        _attachments == 0
                            ? 'رفع مرفقات'
                            : 'تمت إضافة $_attachments مرفقات',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blue,
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(color: AppColors.blue),
                      ),
                    ),
                    if (_attachmentNames.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final name in _attachmentNames.take(4))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.insert_drive_file_outlined,
                                color: AppColors.blue,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.appMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
                _ProjectStepView(
                  formKey: _formKeys[2],
                  title: '3. المهارات والتقنيات',
                  subtitle: 'هذه البيانات مهمة جدا للمطابقة مع المهندسين.',
                  children: [
                    _ProjectTextField(
                      controller: _draft.requiredSkills,
                      label: 'المهارات المطلوبة',
                      hint: 'إشراف مدني، قراءة مخططات، سلامة موقع...',
                      minLines: 3,
                      isRequired: true,
                    ),
                    _ProjectTextField(
                      controller: _draft.preferredSkills,
                      label: 'المهارات المفضلة',
                      hint: 'اختيارية لكن تساعد على الاختيار',
                      minLines: 3,
                    ),
                    _ProjectTextField(
                      controller: _draft.techStack,
                      label: 'الأدوات والمعدات',
                      hint: 'BIM، أوتوكاد، معدات صب، أجهزة مساحة...',
                      isRequired: true,
                    ),
                    _DropdownField(
                      label: 'مستوى الخبرة',
                      value: _draft.seniority,
                      values: _seniorityLevels,
                      onChanged: (value) =>
                          setState(() => _draft.seniority = value),
                    ),
                    _ProjectTextField(
                      controller: _draft.years,
                      label: 'سنوات الخبرة',
                      hint: 'مثال: 1-3 سنوات',
                    ),
                    _ProjectTextField(
                      controller: _draft.certifications,
                      label: 'الشهادات - اختياري',
                      hint: 'سلامة مهنية، نقابة المهندسين، تشغيل آليات...',
                    ),
                  ],
                ),
                _ProjectStepView(
                  formKey: _formKeys[3],
                  title: '4. الفريق والأدوار المطلوبة',
                  subtitle: 'وضح شكل التعاون والمسؤوليات المتوقعة.',
                  children: [
                    _ProjectTextField(
                      controller: _draft.engineersNeeded,
                      label: 'عدد المهندسين المطلوب',
                      hint: 'مثال: 2',
                      isRequired: true,
                    ),
                    _ProjectTextField(
                      controller: _draft.roles,
                      label: 'الأدوار المحددة',
                      hint: 'مهندس موقع، كهربائي، سباك، مشغل آلية...',
                      minLines: 3,
                      isRequired: true,
                    ),
                    _ProjectTextField(
                      controller: _draft.responsibilities,
                      label: 'مسؤوليات كل دور',
                      hint: 'اشرح ما سيفعله كل عضو في الفريق',
                      minLines: 4,
                    ),
                    _ProjectTextField(
                      controller: _draft.currentTeamSize,
                      label: 'حجم الفريق الحالي',
                      hint: 'مثال: مهندس موقع + كهربائي + مشغل آلية',
                    ),
                    _ToolsSelector(
                      selected: _draft.collaborationTools,
                      onToggle: (tool) {
                        setState(() {
                          _draft.collaborationTools.contains(tool)
                              ? _draft.collaborationTools.remove(tool)
                              : _draft.collaborationTools.add(tool);
                        });
                      },
                    ),
                  ],
                ),
                _ProjectStepView(
                  formKey: _formKeys[4],
                  title: '5. الجدول والالتزام',
                  subtitle: 'ساعد المتقدمين على فهم الوقت المطلوب.',
                  children: [
                    _ProjectTextField(
                      controller: _draft.startDate,
                      label: 'تاريخ البدء',
                      hint: 'مثال: يونيو 2026',
                    ),
                    _ProjectTextField(
                      controller: _draft.duration,
                      label: 'المدة المتوقعة',
                      hint: 'مثال: 8 أسابيع',
                    ),
                    _DropdownField(
                      label: 'الالتزام الأسبوعي',
                      value: _draft.weeklyCommitment,
                      values: _commitments,
                      onChanged: (value) =>
                          setState(() => _draft.weeklyCommitment = value),
                    ),
                    _ProjectTextField(
                      controller: _draft.milestones,
                      label: 'المراحل الرئيسية',
                      hint: 'تجهيز الموقع، صب الأساس، الاستلام...',
                      minLines: 4,
                    ),
                    _DropdownField(
                      label: 'درجة الاستعجال',
                      value: _draft.urgency,
                      values: _urgencyLevels,
                      onChanged: (value) =>
                          setState(() => _draft.urgency = value),
                    ),
                  ],
                ),
                _ProjectStepView(
                  formKey: _formKeys[5],
                  title: '6. الميزانية والتعويض',
                  subtitle: 'كن واضحا بخصوص الدفع أو نموذج المقابل.',
                  children: [
                    _DropdownField(
                      label: 'مدفوع / غير مدفوع',
                      value: _draft.paidStatus,
                      values: _paidStatuses,
                      onChanged: (value) =>
                          setState(() => _draft.paidStatus = value),
                    ),
                    _ProjectTextField(
                      controller: _draft.budgetRange,
                      label: 'نطاق الميزانية',
                      hint: 'مثال: 800 - 1200',
                    ),
                    _DropdownField(
                      label: 'نموذج الدفع',
                      value: _draft.paymentModel,
                      values: _paymentModels,
                      onChanged: (value) =>
                          setState(() => _draft.paymentModel = value),
                    ),
                    _ProjectTextField(
                      controller: _draft.currency,
                      label: 'العملة',
                      hint: 'EGP, USD, EUR',
                    ),
                    _ProjectTextField(
                      controller: _draft.bonus,
                      label: 'حوافز إضافية',
                      hint: 'مكافأة إطلاق، أسهم، عمولة...',
                    ),
                  ],
                ),
                _ProjectStepView(
                  formKey: _formKeys[6],
                  title: '7. المعاينة والنشر',
                  subtitle: 'هذه المعاينة هي ما سيراه المهندسون قبل التقديم.',
                  children: [
                    _ProjectPreview(draft: _draft, attachments: _attachments),
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
                      onPressed: _isSubmitting ? null : _previous,
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
                      onPressed: _isSubmitting ? null : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        _isSubmitting
                            ? 'جار النشر...'
                            : _isLastStep
                            ? 'نشر المشروع'
                            : 'التالي',
                      ),
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
            style: TextStyle(color: context.appMuted, height: 1.35),
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
      maxLines: minLines == 1 ? 1 : 6,
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

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in values)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _AssetsSelector extends StatelessWidget {
  const _AssetsSelector({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return _ChipSelector(
      title: 'الأصول الموجودة',
      options: const ['مخططات', 'جداول كميات', 'صور الموقع', 'تصاريح'],
      selected: selected,
      onToggle: onToggle,
    );
  }
}

class _ToolsSelector extends StatelessWidget {
  const _ToolsSelector({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return _ChipSelector(
      title: 'أدوات التعاون',
      options: const ['واتساب', 'تقرير يومي', 'ملفات مشتركة', 'اجتماع أسبوعي'],
      selected: selected,
      onToggle: onToggle,
    );
  }
}

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              FilterChip(
                label: Text(option),
                selected: selected.contains(option),
                selectedColor: AppColors.paleBlue,
                checkmarkColor: AppColors.blue,
                side: BorderSide(color: context.appBorder),
                onSelected: (_) => onToggle(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProjectPreview extends StatelessWidget {
  const _ProjectPreview({required this.draft, required this.attachments});

  final _ProjectDraft draft;
  final int attachments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.title.text.isEmpty ? 'عنوان المشروع' : draft.title.text,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            draft.tagline.text.isEmpty
                ? 'سيظهر وصفك المختصر هنا.'
                : draft.tagline.text,
            style: TextStyle(color: context.appMuted, height: 1.35),
          ),
          const SizedBox(height: 14),
          _PreviewLine('التصنيف', draft.category),
          _PreviewLine('النوع', draft.projectType),
          _PreviewLine('نمط العمل', draft.workMode),
          _PreviewLine('المرحلة', draft.stage),
          _PreviewLine('المهارات المطلوبة', draft.requiredSkills.text),
          _PreviewLine('الأدوات والمعدات', draft.techStack.text),
          _PreviewLine('الأدوار', draft.roles.text),
          _PreviewLine('الالتزام', draft.weeklyCommitment),
          _PreviewLine(
            'التعويض',
            '${draft.paidStatus} · ${draft.paymentModel}',
          ),
          _PreviewLine('المرفقات', '$attachments'),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? 'غير محدد' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                color: context.appMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

final class _ProjectDraft {
  final title = TextEditingController();
  final tagline = TextEditingController();
  String category = _projectCategories.first;
  String projectType = _projectTypes.first;
  String workMode = _workModes.first;
  final location = TextEditingController();
  final fullDescription = TextEditingController();
  final problem = TextEditingController();
  final goals = TextEditingController();
  final audience = TextEditingController();
  String stage = _stages.first;
  final assets = <String>{};
  final requiredSkills = TextEditingController();
  final preferredSkills = TextEditingController();
  final techStack = TextEditingController();
  String seniority = _seniorityLevels.first;
  final years = TextEditingController();
  final certifications = TextEditingController();
  final engineersNeeded = TextEditingController();
  final roles = TextEditingController();
  final responsibilities = TextEditingController();
  final currentTeamSize = TextEditingController();
  final collaborationTools = <String>{};
  final startDate = TextEditingController();
  final duration = TextEditingController();
  String weeklyCommitment = _commitments.first;
  final milestones = TextEditingController();
  String urgency = _urgencyLevels.first;
  String paidStatus = _paidStatuses.first;
  final budgetRange = TextEditingController();
  String paymentModel = _paymentModels.first;
  final currency = TextEditingController();
  final bonus = TextEditingController();

  ProjectDraftData toData(int attachmentsCount) {
    return ProjectDraftData(
      title: title.text,
      tagline: tagline.text,
      category: category,
      projectType: projectType,
      workMode: workMode,
      location: location.text,
      fullDescription: fullDescription.text,
      problem: problem.text,
      goals: goals.text,
      audience: audience.text,
      stage: stage,
      assets: Set.unmodifiable(assets),
      requiredSkills: requiredSkills.text,
      preferredSkills: preferredSkills.text,
      techStack: techStack.text,
      seniority: seniority,
      years: years.text,
      certifications: certifications.text,
      engineersNeeded: engineersNeeded.text,
      roles: roles.text,
      responsibilities: responsibilities.text,
      currentTeamSize: currentTeamSize.text,
      collaborationTools: Set.unmodifiable(collaborationTools),
      startDate: startDate.text,
      duration: duration.text,
      weeklyCommitment: weeklyCommitment,
      milestones: milestones.text,
      urgency: urgency,
      paidStatus: paidStatus,
      budgetRange: budgetRange.text,
      paymentModel: paymentModel,
      currency: currency.text,
      bonus: bonus.text,
      attachmentsCount: attachmentsCount,
    );
  }

  void dispose() {
    title.dispose();
    tagline.dispose();
    location.dispose();
    fullDescription.dispose();
    problem.dispose();
    goals.dispose();
    audience.dispose();
    requiredSkills.dispose();
    preferredSkills.dispose();
    techStack.dispose();
    years.dispose();
    certifications.dispose();
    engineersNeeded.dispose();
    roles.dispose();
    responsibilities.dispose();
    currentTeamSize.dispose();
    startDate.dispose();
    duration.dispose();
    milestones.dispose();
    budgetRange.dispose();
    currency.dispose();
    bonus.dispose();
  }
}

const _projectSteps = [
  'basics',
  'overview',
  'skills',
  'team',
  'timeline',
  'budget',
  'preview',
];

const _projectCategories = [
  'مدني',
  'معماري',
  'كهرباء',
  'ميكانيك',
  'مساحة',
  'تشطيبات',
  'آليات',
  'سلامة',
  'برنامج',
  'تطبيق',
  'أخرى',
];

const _projectTypes = [
  'تعاون مشروع',
  'دوام جزئي',
  'دوام كامل',
  'تدريب ميداني',
  'بحث وتطوير',
  'تعاون مقاولين',
];

const _workModes = ['عن بعد', 'هجين', 'موقعي'];
const _stages = ['فكرة', 'تخطيط', 'تجهيز', 'تنفيذ', 'تسليم'];
const _seniorityLevels = ['مبتدئ', 'متوسط', 'خبير', 'قائد فريق'];
const _commitments = ['<10 ساعات', '10-20 ساعة', 'دوام كامل'];
const _urgencyLevels = ['مرن', 'قريب', 'عاجل'];
const _paidStatuses = ['مدفوع', 'غير مدفوع'];
const _paymentModels = [
  'بالساعة',
  'مبلغ ثابت',
  'دفعات مراحل',
  'نسبة من الإيراد',
  'مكافأة تدريب',
];
