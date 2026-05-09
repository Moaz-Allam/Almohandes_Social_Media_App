import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class ComposerTopBar extends StatelessWidget {
  const ComposerTopBar({
    super.key,
    required this.title,
    required this.onClose,
    this.actionLabel = 'نشر',
    this.onAction,
    this.actionEnabled = true,
  });

  final String title;
  final VoidCallback onClose;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool actionEnabled;

  @override
  Widget build(BuildContext context) {
    final canAct = actionEnabled && onAction != null;

    return SafeArea(
      bottom: false,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: context.appSurface,
          border: Border(bottom: BorderSide(color: context.appBorder)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              tooltip: 'إغلاق',
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: canAct ? onAction : null,
              child: Text(
                actionLabel,
                style: TextStyle(
                  color: canAct ? AppColors.blue : AppColors.muted,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
