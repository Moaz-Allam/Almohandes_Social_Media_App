import 'package:flutter/widgets.dart';

/// Single source of truth for "is this a desktop/web layout?" checks.
///
/// Anything wider than [desktop] gets the LinkedIn-style chrome:
/// fixed top bar, 3-column body, no bottom nav. Narrower viewports
/// (phones, narrow web windows) keep the existing mobile shell.
final class LayoutBreakpoints {
  const LayoutBreakpoints._();

  /// Below this width we render the mobile shell.
  static const double desktop = 960;

  /// Below this width the right rail is hidden so the centre column has
  /// room to breathe.
  static const double withRightRail = 1180;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  static bool showRightRail(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= withRightRail;
}
