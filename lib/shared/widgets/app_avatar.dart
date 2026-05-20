import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'cached_image.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    required this.radius,
    required this.color,
    this.badge,
    this.imageUrl,
  });

  final String name;
  final double radius;
  final Color color;
  final String? badge;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    // Use grapheme clusters, not raw UTF-16 substring. Emoji names ("😀")
    // and names starting with a multi-codepoint grapheme would crash or
    // truncate mid-character with `substring(0, 1)`.
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : (trimmed.characters.firstOrNull ?? '?');
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: color,
          child: _hasImage
              ? null
              : Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: radius * .72,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        if (_hasImage)
          Positioned.fill(
            child: ClipOval(
              child: CachedImage(
                url: imageUrl,
                cacheWidth: (radius * 2 * MediaQuery.devicePixelRatioOf(context))
                    .round()
                    .clamp(48, 512),
                cacheHeight:
                    (radius * 2 * MediaQuery.devicePixelRatioOf(context))
                        .round()
                        .clamp(48, 512),
                fallback: ColoredBox(
                  color: color,
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: radius * .72,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (badge != null)
          PositionedDirectional(
            bottom: -3,
            end: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: badge == 'متاح' ? AppColors.blue : AppColors.darkBlue,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool get _hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
}
