import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/project_item.dart';
import '../../models/saved_content.dart';
import '../../state/app_scope.dart';
import 'project_application_success_screen.dart';

class ProjectApplicationScreen extends StatefulWidget {
  const ProjectApplicationScreen({super.key, required this.project});

  final ProjectItem project;

  @override
  State<ProjectApplicationScreen> createState() =>
      _ProjectApplicationScreenState();
}

class _ProjectApplicationScreenState extends State<ProjectApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  int _attachments = 0;
  final List<String> _attachmentNames = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _addAttachment() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _attachmentNames.addAll(result.files.map((file) => file.name));
      _attachments = _attachmentNames.length;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت إضافة ${result.files.length} ملفات')),
    );
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final project = widget.project;
    final appController = AppScope.read(context);
    final appliedIds = await appController.repositories.projects
        .fetchAppliedProjectIds(forceRefresh: true);
    if (appliedIds.contains(project.id)) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لقد قدمت على هذا المشروع مسبقا')),
      );
      return;
    }
    try {
      await appController.repositories.projects.applyToProject(
        project: project,
        subject: _subject.text,
        message: _description.text,
        attachmentsCount: _attachments,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ الطلب محليا وتعذر إرساله الآن: $error')),
      );
    }
    await appController.saveAppliedProject(
      SavedContent(
        id: 'applied-project:${project.id}',
        type: SavedContentType.project,
        title: project.title,
        subtitle: 'تم التقديم · ${project.postedBy}',
        detail:
            '${project.category} · ${project.type} · ${project.workMode} · $_attachments ملفات',
      ),
    );

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProjectApplicationSuccessScreen(project: project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appText,
        title: const Text(
          'التقديم على مشروع',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.appSurfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    project.tagline,
                    style: TextStyle(color: context.appMuted, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _subject,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'اكتب عنوانا لرسالة التقديم';
                }
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'عنوان الرسالة',
                hintText: 'مثال: مهتم بدور مهندس موقع في المشروع',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              minLines: 6,
              maxLines: 9,
              validator: (value) {
                if (value == null || value.trim().length < 20) {
                  return 'اكتب وصفا أوضح لخبرتك وسبب التقديم';
                }
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'وصف التقديم',
                hintText:
                    'اشرح خبرتك، المهارات المناسبة، وما يمكنك تقديمه للفريق.',
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _addAttachment,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _attachments == 0
                    ? 'رفع ملفات للتقديم'
                    : 'تمت إضافة $_attachments ملفات',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue,
                minimumSize: const Size.fromHeight(46),
                side: const BorderSide(color: AppColors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
            ),
            if (_attachmentNames.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final name in _attachmentNames.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        color: AppColors.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(_isSubmitting ? 'جار الإرسال...' : 'إرسال التقديم'),
            ),
          ],
        ),
      ),
    );
  }
}
