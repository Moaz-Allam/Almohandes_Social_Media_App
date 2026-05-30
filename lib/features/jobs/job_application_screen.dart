import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/session/current_profile_resolver.dart';
import '../../shared/widgets/app_snack.dart';

/// Lets the signed-in user apply to a job posting by writing a row to
/// `public.job_applications` (`job_id`, `profile_id`, `cover_letter`).
///
/// The jobs feature is queried inline with the Supabase client (see
/// `HomeFeedScreen._fetchJobs`), so this screen follows the same approach
/// rather than introducing a dedicated repository. Pops with `true` when the
/// application is submitted so the caller can refresh / toast.
class JobApplicationScreen extends StatefulWidget {
  const JobApplicationScreen({super.key, required this.job});

  /// Raw job row from the `jobs` table (with embedded `profiles`).
  final Map<String, dynamic> job;

  @override
  State<JobApplicationScreen> createState() => _JobApplicationScreenState();
}

class _JobApplicationScreenState extends State<JobApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetter = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _coverLetter.dispose();
    super.dispose();
  }

  String get _jobId => '${widget.job['id'] ?? ''}';

  String get _jobTitle => '${widget.job['title'] ?? 'وظيفة'}';

  String get _companyName {
    final profiles = widget.job['profiles'];
    final embeddedName = profiles is Map ? profiles['full_name'] : null;
    final company = widget.job['company_name'] ?? embeddedName ?? 'شركة';
    return '$company';
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) {
      return;
    }
    if (_jobId.isEmpty) {
      AppSnack.error(context, 'تعذر تحديد الوظيفة');
      return;
    }

    setState(() => _isSubmitting = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final client = Supabase.instance.client;
    final profileId = await CurrentProfileResolver.instance.resolve(
      client: client,
    );
    if (!mounted) {
      return;
    }
    if (profileId == null) {
      setState(() => _isSubmitting = false);
      AppSnack.error(context, 'سجل الدخول أولا للتقديم على الوظيفة');
      return;
    }
    if ('${widget.job['profile_id'] ?? ''}' == profileId) {
      setState(() => _isSubmitting = false);
      AppSnack.error(context, 'لا يمكنك التقديم على وظيفتك');
      return;
    }

    try {
      await client.from('job_applications').insert({
        'job_id': _jobId,
        'profile_id': profileId,
        'cover_letter': _coverLetter.text.trim(),
        'status': 'pending',
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      // 23505 = unique_violation → already applied (unique(job_id, profile_id)).
      if (error.code == '23505') {
        AppSnack.info(context, 'لقد قدمت على هذه الوظيفة مسبقا');
      } else {
        AppSnack.error(context, error, fallback: 'تعذر إرسال طلب التوظيف الآن');
      }
      return;
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      AppSnack.error(context, error, fallback: 'تعذر إرسال طلب التوظيف الآن');
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appText,
        title: const Text(
          'التقديم على وظيفة',
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
                    _jobTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _companyName,
                    style: TextStyle(color: context.appMuted, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _coverLetter,
              minLines: 6,
              maxLines: 10,
              validator: (value) {
                if (value == null || value.trim().length < 20) {
                  return 'اكتب رسالة تعريفية أوضح لخبرتك وسبب التقديم';
                }
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'الرسالة التعريفية',
                hintText:
                    'اشرح خبرتك، المهارات المناسبة، وما يمكنك تقديمه للشركة.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                _isSubmitting ? 'جار الإرسال...' : 'إرسال الطلب',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
