import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A drop-in image that:
/// - Caches HTTP(S) URLs to disk and decodes at the requested pixel size.
/// - Decodes legacy `data:image/...;base64,...` URLs once.
/// - Renders [fallback] for any other input or load error.
///
/// Use this instead of `Image.network` everywhere — uncached network images
/// are one of the biggest sources of jank in the app.
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    this.fallback,
    this.placeholder,
    this.fadeIn = true,
  });

  final String? url;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;
  final Widget? fallback;
  final Widget? placeholder;
  final bool fadeIn;

  @override
  Widget build(BuildContext context) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) {
      return fallback ?? const SizedBox.shrink();
    }
    if (raw.startsWith('data:')) {
      final bytes = _bytesFromDataUrl(raw);
      if (bytes == null) {
        return fallback ?? const SizedBox.shrink();
      }
      return Image.memory(
        bytes,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
      );
    }
    if (!raw.startsWith('http')) {
      return fallback ?? const SizedBox.shrink();
    }
    return CachedNetworkImage(
      imageUrl: raw,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      fadeInDuration: fadeIn
          ? const Duration(milliseconds: 180)
          : Duration.zero,
      placeholder: (_, _) =>
          placeholder ?? const ColoredBox(color: Color(0x11000000)),
      errorWidget: (_, _, _) => fallback ?? const SizedBox.shrink(),
    );
  }

  static Uint8List? _bytesFromDataUrl(String value) {
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
