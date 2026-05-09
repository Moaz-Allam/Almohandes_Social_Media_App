import 'package:flutter/material.dart';

class LikeBurst extends StatelessWidget {
  const LikeBurst({
    super.key,
    required this.visible,
    this.size = 96,
    this.color = Colors.white,
  });

  final bool visible;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 170),
        child: AnimatedScale(
          scale: visible ? 1 : .35,
          duration: const Duration(milliseconds: 240),
          curve: Curves.elasticOut,
          child: Icon(
            Icons.thumb_up_alt_rounded,
            color: color,
            size: size,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 22)],
          ),
        ),
      ),
    );
  }
}
