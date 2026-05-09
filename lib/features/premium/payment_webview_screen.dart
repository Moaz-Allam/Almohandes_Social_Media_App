import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key, required this.checkout});

  final PremiumCheckout checkout;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasReturnedFromGateway = false;
  bool _isVerifying = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) {
              return;
            }
            setState(() {
              _isLoading = false;
              _errorText = 'تعذر تحميل صفحة الدفع الآن';
            });
          },
          onNavigationRequest: (request) {
            if (_isPaymentReturn(request.url)) {
              _showLocalPaymentResult();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(
        _paymentHtml(),
        baseUrl: widget.checkout.paymentResultUrl.origin,
      );
  }

  bool _isPaymentReturn(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }
    if (uri.queryParameters['action'] == 'payment-result') {
      return true;
    }
    if (uri.toString().startsWith(widget.checkout.paymentResultUrl.toString())) {
      return true;
    }
    return uri.path.contains('/switch-payment') &&
        uri.queryParameters.containsKey('resourcePath');
  }

  void _showLocalPaymentResult() {
    if (!mounted) {
      return;
    }
    setState(() {
      _hasReturnedFromGateway = true;
      _isLoading = false;
      _errorText = null;
    });
    _controller.loadHtmlString(_paymentReturnedHtml());
  }

  Future<void> _verifyPayment() async {
    if (_isVerifying) {
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorText = null;
    });
    try {
      final app = AppScope.read(context);
      await app.repositories.subscriptions.verifyPremiumCheckout(
        widget.checkout,
      );
      await app.refreshSessionData();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isVerifying = false;
        _errorText = userErrorMessage(
          error,
          fallback: 'لم يتم تأكيد الدفع بعد',
        );
      });
    }
  }

  String _paymentHtml() {
    final scriptUrl = const HtmlEscape().convert(
      widget.checkout.paymentWidgetUrl.toString(),
    );
    final resultUrl = const HtmlEscape().convert(
      widget.checkout.paymentResultUrl.toString(),
    );
    return '''
<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>دفع Premium</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #f5f7fb; color: #101828; }
    main { max-width: 560px; margin: 0 auto; padding: 20px 14px 90px; }
    h1 { font-size: 22px; margin: 0 0 8px; }
    p { color: #475467; line-height: 1.7; margin: 0 0 16px; }
    .panel { background: #fff; border: 1px solid #e4e7ec; border-radius: 8px; padding: 16px; }
  </style>
  <script>
    var wpwlOptions = { locale: "ar", style: "card" };
  </script>
  <script async src="$scriptUrl"></script>
</head>
<body>
  <main>
    <h1>دفع Premium</h1>
    <p>أدخل بيانات البطاقة لإكمال الاشتراك. بعد انتهاء الدفع اضغط تحقق من الدفع داخل التطبيق.</p>
    <section class="panel">
      <form action="$resultUrl" class="paymentWidgets" data-brands="VISA MASTER"></form>
    </section>
  </main>
</body>
</html>
''';
  }

  String _paymentReturnedHtml() {
    final checkoutId = const HtmlEscape().convert(widget.checkout.checkoutId);
    return '''
<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #f5f7fb; color: #101828; }
    main { max-width: 560px; margin: 0 auto; padding: 28px 16px 90px; }
    .panel { background: #fff; border: 1px solid #e4e7ec; border-radius: 8px; padding: 18px; }
    h1 { font-size: 22px; margin: 0 0 8px; }
    p { color: #475467; line-height: 1.7; margin: 0; }
    code { direction: ltr; display: block; margin-top: 12px; word-break: break-all; }
  </style>
</head>
<body>
  <main>
    <section class="panel">
      <h1>تم استلام نتيجة الدفع</h1>
      <p>اضغط تحقق من الدفع في الأسفل لتفعيل Premium.</p>
      <code>$checkoutId</code>
    </section>
  </main>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appText,
        title: const Text(
          'دفع Premium',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          if (_errorText != null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorText!,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: context.appSurface,
            border: Border(top: BorderSide(color: context.appBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isVerifying
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _isVerifying ? null : _verifyPayment,
                  icon: _isVerifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _hasReturnedFromGateway
                              ? Icons.verified_outlined
                              : Icons.payment_outlined,
                        ),
                  label: Text(
                    _isVerifying ? 'جاري التحقق...' : 'تحقق من الدفع',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
