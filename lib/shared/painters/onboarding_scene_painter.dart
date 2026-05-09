import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class OnboardingScenePainter extends CustomPainter {
  const OnboardingScenePainter(this.scene);

  final int scene;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final w = size.width;
    final h = size.height;
    final center = Offset(w * .5, h * .52);

    paint.color = const Color(0xFFE8F1FA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w * .62, height: h * .74),
        const Radius.circular(2),
      ),
      paint,
    );

    switch (scene) {
      case 0:
        _drawDeskWorker(canvas, size, paint);
      case 1:
        _drawNetwork(canvas, size, paint);
      default:
        _drawContentDesk(canvas, size, paint);
    }
  }

  void _drawDeskWorker(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    paint.color = Colors.white;
    canvas.drawOval(Rect.fromLTWH(w * .27, h * .12, w * .18, h * .08), paint);
    canvas.drawOval(Rect.fromLTWH(w * .56, h * .17, w * .24, h * .09), paint);

    paint.color = const Color(0xFFD99955);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .22, h * .57, w * .44, h * .025),
        const Radius.circular(8),
      ),
      paint,
    );
    paint
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8E6F55);
    canvas.drawLine(Offset(w * .28, h * .58), Offset(w * .24, h * .8), paint);
    canvas.drawLine(Offset(w * .62, h * .58), Offset(w * .68, h * .8), paint);

    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF6E879A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .43, h * .32, w * .06, h * .23),
        const Radius.circular(9),
      ),
      paint,
    );
    paint.color = const Color(0xFFAFC2CF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .39, h * .52, w * .16, h * .02),
        const Radius.circular(6),
      ),
      paint,
    );

    paint.color = const Color(0xFFF2C49B);
    canvas.drawCircle(Offset(w * .72, h * .32), w * .035, paint);
    paint.color = AppColors.ink;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * .72, h * .31), radius: w * .042),
      3.1,
      2.5,
      true,
      paint,
    );
    paint.color = const Color(0xFF333A3D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .66, h * .39, w * .12, h * .19),
        const Radius.circular(16),
      ),
      paint,
    );
    paint.color = const Color(0xFF9D6441);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .66, h * .55, w * .13, h * .22),
        const Radius.circular(14),
      ),
      paint,
    );
    paint
      ..color = const Color(0xFFF2C49B)
      ..strokeWidth = 7;
    canvas.drawLine(Offset(w * .63, h * .47), Offset(w * .53, h * .55), paint);

    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFF1F6E7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .22, h * .72, w * .14, h * .2),
        const Radius.circular(16),
      ),
      paint,
    );
    paint
      ..color = const Color(0xFF12324A)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .18, h * .76, w * .2, h * .19),
        const Radius.circular(18),
      ),
      paint,
    );
    paint.style = PaintingStyle.fill;
  }

  void _drawNetwork(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    paint.color = const Color(0xFFE7EEDC);
    final hill = Path()
      ..moveTo(w * .18, h * .72)
      ..quadraticBezierTo(w * .52, h * .22, w * .82, h * .54)
      ..lineTo(w * .82, h * .82)
      ..lineTo(w * .18, h * .82)
      ..close();
    canvas.drawPath(hill, paint);

    paint.color = const Color(0xFFF8C46F);
    canvas.drawCircle(Offset(w * .62, h * .27), w * .085, paint);
    paint
      ..color = const Color(0xFFC79539)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(w * .62, h * .25), Offset(w * .62, h * .55), paint);
    canvas.drawLine(Offset(w * .62, h * .38), Offset(w * .56, h * .33), paint);
    canvas.drawLine(Offset(w * .62, h * .44), Offset(w * .69, h * .38), paint);

    paint
      ..style = PaintingStyle.fill
      ..color = AppColors.blue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .28, h * .56, w * .22, h * .075),
        const Radius.circular(22),
      ),
      paint,
    );
    paint.color = AppColors.ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .18, h * .58, w * .08, h * .035),
        const Radius.circular(10),
      ),
      paint,
    );
    paint
      ..color = const Color(0xFFF2C49B)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .52, h * .54), Offset(w * .62, h * .44), paint);
    paint.color = const Color(0xFF174763);
    canvas.drawCircle(Offset(w * .65, h * .43), w * .037, paint);
    paint.color = const Color(0xFFF2C49B);
    canvas.drawCircle(Offset(w * .62, h * .45), w * .04, paint);
  }

  void _drawContentDesk(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    paint.color = const Color(0xFFC8D7DB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .31, h * .44, w * .48, h * .08),
        const Radius.circular(4),
      ),
      paint,
    );
    paint.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .49, h * .25, w * .21, h * .18),
        const Radius.circular(3),
      ),
      paint,
    );
    paint.color = AppColors.blue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .51, h * .28, w * .17, h * .025),
        const Radius.circular(3),
      ),
      paint,
    );
    paint.color = const Color(0xFFF8C46F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .52, h * .32, w * .13, h * .045),
        const Radius.circular(3),
      ),
      paint,
    );
    paint.color = const Color(0xFFB65A3A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .28, h * .4, w * .14, h * .18),
        const Radius.circular(18),
      ),
      paint,
    );
    paint.color = const Color(0xFFF2C49B);
    canvas.drawCircle(Offset(w * .35, h * .32), w * .04, paint);
    paint.color = const Color(0xFF3B2630);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * .35, h * .31), radius: w * .052),
      2.3,
      4.0,
      true,
      paint,
    );
    paint.color = const Color(0xFFD89A42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .31, h * .57, w * .17, h * .16),
        const Radius.circular(16),
      ),
      paint,
    );
    paint
      ..color = const Color(0xFF6D7D87)
      ..strokeWidth = 5;
    canvas.drawLine(Offset(w * .48, h * .7), Offset(w * .58, h * .78), paint);
    paint.color = const Color(0xFF6DA064);
    canvas.drawOval(Rect.fromLTWH(w * .67, h * .62, w * .18, h * .07), paint);
    paint.color = const Color(0xFF804A2E);
    canvas.drawOval(Rect.fromLTWH(w * .76, h * .58, w * .08, h * .05), paint);
  }

  @override
  bool shouldRepaint(covariant OnboardingScenePainter oldDelegate) {
    return oldDelegate.scene != scene;
  }
}
