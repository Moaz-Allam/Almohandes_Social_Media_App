import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_snack.dart';
import '../../state/app_scope.dart';
import 'widgets/composer_top_bar.dart';

class JobFormScreen extends StatefulWidget {
  const JobFormScreen({super.key});

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _requirementsController = TextEditingController();
  String _jobType = 'full-time';
  String _category = 'مدني';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final app = AppScope.read(context);
      final profileId = app.profile?.id;
      if (profileId == null) throw 'سجل الدخول أولا';

      await Supabase.instance.client.from('jobs').insert({
        'profile_id': profileId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'company_name': _companyController.text.trim(),
        'location': _locationController.text.trim(),
        'job_type': _jobType,
        'category': _category,
        'salary_range': _salaryController.text.trim(),
        'requirements': _requirementsController.text.trim(),
      });

      if (!mounted) return;
      AppSnack.success(context, 'تم نشر الوظيفة بنجاح');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(context, error, fallback: 'تعذر نشر الوظيفة الآن');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: Column(
        children: [
          ComposerTopBar(
            title: 'إضافة وظيفة',
            onClose: () => Navigator.of(context).pop(),
            actionLabel: 'نشر',
            onAction: _submit,
            actionEnabled: !_isSubmitting,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'عنوان الوظيفة',
                    hint: 'مثال: مهندس مدني موقع',
                    validator: (v) => v?.isEmpty == true ? 'هذا الحقل مطلوب' : null,
                  ),
                  _buildTextField(
                    controller: _companyController,
                    label: 'اسم الشركة',
                    hint: 'مثال: شركة الرافدين للمقاولات',
                  ),
                  _buildTextField(
                    controller: _locationController,
                    label: 'الموقع',
                    hint: 'مثال: بغداد - الكرادة',
                  ),
                  _buildDropdown(
                    label: 'نوع العمل',
                    value: _jobType,
                    items: {
                      'full-time': 'دوام كامل',
                      'part-time': 'دوام جزئي',
                      'contract': 'عقد',
                      'freelance': 'عمل حر',
                      'internship': 'تدريب',
                    },
                    onChanged: (v) => setState(() => _jobType = v!),
                  ),
                  _buildDropdown(
                    label: 'التصنيف',
                    value: _category,
                    items: {
                      'مدني': 'مدني',
                      'معماري': 'معماري',
                      'كهرباء': 'كهرباء',
                      'ميكانيك': 'ميكانيك',
                      'تقنية': 'تقنية',
                    },
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  _buildTextField(
                    controller: _salaryController,
                    label: 'الراتب المتوقع',
                    hint: 'مثال: 1000 - 1500 دولار',
                  ),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'وصف الوظيفة',
                    hint: 'اشرح تفاصيل الوظيفة والمسؤوليات...',
                    minLines: 4,
                    validator: (v) => v?.isEmpty == true ? 'هذا الحقل مطلوب' : null,
                  ),
                  _buildTextField(
                    controller: _requirementsController,
                    label: 'المتطلبات',
                    hint: 'مثال: خبرة 3 سنوات، إجادة الأوتوكاد...',
                    minLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int minLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines == 1 ? 1 : 10,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.entries.map((e) {
          return DropdownMenuItem(value: e.key, child: Text(e.value));
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
