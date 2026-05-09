import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class PremiumInfoScreen extends StatefulWidget {
  const PremiumInfoScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    this.showRequestForm = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> items;
  final bool showRequestForm;

  @override
  State<PremiumInfoScreen> createState() => _PremiumInfoScreenState();
}

class _PremiumInfoScreenState extends State<PremiumInfoScreen> {
  final _requestController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_isSubmitting) {
      return;
    }
    final value = _requestController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('اكتب تفاصيل الطلب أولاً')),
        );
      return;
    }
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) {
      return;
    }
    _requestController.clear();
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('تم حفظ طلب الاستشارة')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icon, color: AppColors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: context.appMuted,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final item in widget.items) ...[
            _InfoTile(text: item),
            const SizedBox(height: 10),
          ],
          if (widget.showRequestForm) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _requestController,
              minLines: 4,
              maxLines: 8,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                hintText: 'اكتب ملخص المشكلة أو السؤال القانوني',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitRequest,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_isSubmitting ? 'جاري الحفظ...' : 'إرسال الطلب'),
              style: FilledButton.styleFrom(
                backgroundColor: _isSubmitting
                    ? AppColors.muted
                    : AppColors.blue,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
