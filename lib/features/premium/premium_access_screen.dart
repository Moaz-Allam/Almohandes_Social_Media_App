import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_scope.dart';

class PremiumAccessScreen extends StatelessWidget {
  const PremiumAccessScreen({super.key});

  static const _items = [
    (Icons.engineering_outlined, 'بوت الهندسة الذكي'),
    (Icons.menu_book_outlined, 'محاضرات نظرية'),
    (Icons.build_outlined, 'محاضرات عملية'),
    (Icons.school_outlined, 'تدريب وتطوير'),
    (Icons.description_outlined, 'ملاحظات عامة'),
    (Icons.library_books_outlined, 'المكتبة الهندسية (قريبا)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appText,
        title: const Text(
          'Premium',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
        itemCount: _items.length + 1,
        separatorBuilder: (context, index) =>
            Divider(height: 16, thickness: 16, color: context.appBackground),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FilledButton.icon(
                onPressed: () async {
                  await AppScope.read(context).unlockPremiumLibrary();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تفعيل Premium')),
                  );
                },
                icon: const Icon(Icons.payments_outlined),
                label: const Text('الدفع وتفعيل Premium'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            );
          }
          final item = _items[index];
          return Container(
            height: 82,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: context.appSurface,
              border: Border.all(color: context.appBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: .14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.$1, color: AppColors.blue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.$2,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(Icons.check, color: AppColors.blue),
              ],
            ),
          );
        },
      ),
    );
  }
}
