import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_snack.dart';
import '../../../state/app_scope.dart';

/// Opens the "report post" form as a modal bottom sheet.
///
/// The user must pick a reason (and may add optional details) before the
/// report is submitted. Returns `true` if a report was sent, otherwise
/// `false`/`null` when dismissed.
Future<bool?> showReportPostSheet(
  BuildContext context, {
  required String postId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appSurface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ReportPostSheet(postId: postId),
  );
}

class _ReportReason {
  const _ReportReason(this.label);
  final String label;
}

const _reasons = <_ReportReason>[
  _ReportReason('محتوى مزعج أو دعائي'),
  _ReportReason('محتوى مسيء أو غير لائق'),
  _ReportReason('معلومات مضللة أو خاطئة'),
  _ReportReason('تحرش أو خطاب كراهية'),
  _ReportReason('انتهاك حقوق الملكية'),
  _ReportReason('سبب آخر'),
];

class _ReportPostSheet extends StatefulWidget {
  const _ReportPostSheet({required this.postId});
  final String postId;

  @override
  State<_ReportPostSheet> createState() => _ReportPostSheetState();
}

class _ReportPostSheetState extends State<_ReportPostSheet> {
  int? _selected;
  final _detailsController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  String _composeReason() {
    final label = _reasons[_selected!].label;
    final details = _detailsController.text.trim();
    return details.isEmpty ? label : '$label — $details';
  }

  Future<void> _submit() async {
    if (_selected == null || _busy) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppScope.read(context).repositories.feed.reportPost(
            postId: widget.postId,
            reason: _composeReason(),
          );
      navigator.pop(true);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('تم إرسال البلاغ، شكراً لك')),
        );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnack.error(context, error, fallback: 'تعذر إرسال البلاغ الآن');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'الإبلاغ عن المنشور',
              style: TextStyle(
                color: context.appText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'اختر سبب الإبلاغ لمساعدتنا في مراجعة المحتوى',
              style: TextStyle(color: context.appMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _reasons.length; i++)
            RadioListTile<int>(
              value: i,
              groupValue: _selected,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _selected = value),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                _reasons[i].label,
                style: TextStyle(
                  color: context.appText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            enabled: !_busy,
            maxLines: 3,
            maxLength: 300,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'تفاصيل إضافية (اختياري)',
              filled: true,
              fillColor: context.appSurfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: (_selected == null || _busy) ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.flag_outlined, size: 18),
            label: const Text('إرسال البلاغ'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
