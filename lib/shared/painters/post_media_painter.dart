import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class PostMediaPainter extends CustomPainter {
  const PostMediaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final rect = Offset.zero & size;
    final gradient = const LinearGradient(
      colors: [Color(0xFF5B3B28), Color(0xFFB26F38), Color(0xFFE1C6A5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    paint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
    paint.shader = null;

    paint.color = const Color(0xBB2B1B14);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .56, size.width, size.height * .44),
      paint,
    );
    paint.color = const Color(0xFFE6D0AF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .12,
          size.height * .66,
          size.width * .76,
          size.height * .07,
        ),
        const Radius.circular(6),
      ),
      paint,
    );
    paint.color = const Color(0xFF1E2731);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .38,
          size.height * .34,
          size.width * .28,
          size.height * .24,
        ),
        const Radius.circular(6),
      ),
      paint,
    );
    paint.color = const Color(0xFFF2F5F8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .4,
          size.height * .36,
          size.width * .24,
          size.height * .18,
        ),
        const Radius.circular(3),
      ),
      paint,
    );
    paint.color = AppColors.blue;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .42,
        size.height * .39,
        size.width * .2,
        size.height * .025,
      ),
      paint,
    );
    paint.color = const Color(0xFFE45E5E);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .44,
        size.height * .43,
        size.width * .12,
        size.height * .055,
      ),
      paint,
    );
    paint.color = const Color(0xFFF5D6B8);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .06,
        size.height * .62,
        size.width * .18,
        size.height * .16,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .24,
        size.height * .64,
        size.width * .16,
        size.height * .13,
      ),
      paint,
    );
    paint.color = const Color(0xFFFFE8BA);
    for (var i = 0; i < 5; i++) {
      final x = size.width * (.34 + i * .13);
      canvas.drawCircle(Offset(x, size.height * .14), 9, paint);
      paint.strokeWidth = 2;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * .14), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
