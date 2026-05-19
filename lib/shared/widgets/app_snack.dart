import 'package:flutter/material.dart';

import '../errors/user_error_message.dart';

/// Consistent snackbar helpers. Every error feedback in the app should go
/// through [AppSnack.error] so users see the same icon + colour + tone
/// across screens.
final class AppSnack {
  const AppSnack._();

  /// Show a red error toast. `errorOrMessage` can be:
  /// - an `Object` thrown from a repo / SDK — it will be passed through
  ///   [userErrorMessage] so the user sees a specific Arabic message.
  /// - a plain `String` — it will be shown as-is.
  ///
  /// [fallback] is used if [userErrorMessage] can't classify the error.
  static void error(
    BuildContext context,
    Object errorOrMessage, {
    String fallback = 'تعذر تنفيذ العملية. حاول مرة أخرى',
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 5),
  }) {
    final text = errorOrMessage is String
        ? errorOrMessage
        : userErrorMessage(errorOrMessage, fallback: fallback);
    _show(
      context,
      text: text,
      icon: Icons.error_outline,
      backgroundColor: Colors.red.shade700,
      action: action,
      duration: duration,
    );
  }

  /// Show a green success toast.
  static void success(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      text: message,
      icon: Icons.check_circle_outline,
      backgroundColor: const Color(0xFF188038),
      action: action,
      duration: duration,
    );
  }

  /// Show a neutral info toast.
  static void info(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      text: message,
      icon: Icons.info_outline,
      backgroundColor: const Color(0xFF1F2A37),
      action: action,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String text,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          // Fixed (full-width, anchored to the bottom edge) instead of
          // floating: floating snackbars overlap whatever sits at the
          // bottom of the screen (primary buttons, bottom nav). Fixed
          // pushes UI up briefly which is a much clearer affordance.
          behavior: SnackBarBehavior.fixed,
          duration: duration,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          action: action,
        ),
      );
  }
}
