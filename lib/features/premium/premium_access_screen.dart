import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';
import 'payment_webview_screen.dart';
import 'premium_dashboard_screen.dart';

class PremiumAccessScreen extends StatefulWidget {
  const PremiumAccessScreen({super.key});

  @override
  State<PremiumAccessScreen> createState() => _PremiumAccessScreenState();
}

class _PremiumAccessScreenState extends State<PremiumAccessScreen> {
  static const _items = [
    (Icons.engineering_outlined, 'بوت الهندسة الذكي'),
    (Icons.menu_book_outlined, 'محاضرات نظرية'),
    (Icons.build_outlined, 'محاضرات عملية'),
    (Icons.school_outlined, 'تدريب وتطوير'),
    (Icons.description_outlined, 'ملاحظات عامة'),
    (Icons.library_books_outlined, 'المكتبة الهندسية (قريبا)'),
  ];

  bool _isStartingPayment = false;

  Future<void> _startPayment() async {
    if (_isStartingPayment) {
      return;
    }
    setState(() => _isStartingPayment = true);
    final app = AppScope.read(context);
    try {
      final checkout = await app.repositories.subscriptions
          .createPremiumCheckout();
      if (!mounted) {
        return;
      }
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(checkout: checkout),
        ),
      );
      if (verified != true || !mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('تم تفعيل Premium بنجاح')));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PremiumDashboardScreen()),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              userErrorMessage(error, fallback: 'تعذر تجهيز الدفع الآن'),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isStartingPayment = false);
      }
    }
  }

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
              child: Column(
                children: [
                  FilledButton.icon(
                    onPressed: _isStartingPayment ? null : _startPayment,
                    icon: _isStartingPayment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.payments_outlined),
                    label: Text(
                      _isStartingPayment
                          ? 'جاري تجهيز الدفع...'
                          : 'الدفع وتفعيل Premium',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _isStartingPayment
                          ? AppColors.muted
                          : AppColors.blue,
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
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
