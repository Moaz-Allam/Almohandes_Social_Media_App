import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

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
    final initial = name.trim().isEmpty ? '?' : name.trim().substring(0, 1);
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
              child: _AvatarImage(
                imageUrl: imageUrl!,
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

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.imageUrl, required this.fallback});

  final String imageUrl;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final bytes = _bytesFromDataUrl(imageUrl);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  Uint8List? _bytesFromDataUrl(String value) {
    if (!value.startsWith('data:')) {
      return null;
    }
    final comma = value.indexOf(',');
    if (comma == -1) {
      return null;
    }
    try {
      return base64Decode(value.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }
}
