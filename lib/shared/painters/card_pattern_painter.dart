import 'package:flutter/material.dart';

class CardPatternPainter extends CustomPainter {
  const CardPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    paint.color = Colors.white.withValues(alpha: .25);
    canvas.drawCircle(
      Offset(size.width * .2, size.height * .85),
      size.width * .32,
      paint,
    );
    paint.color = color.withValues(alpha: .25);
    canvas.drawCircle(
      Offset(size.width * .8, size.height * .2),
      size.width * .26,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CardPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
