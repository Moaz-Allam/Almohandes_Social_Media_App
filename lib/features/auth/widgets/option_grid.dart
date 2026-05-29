import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Dark-theme grid of single-select option tiles used by the account-type,
/// specialization and governorate screens.
class OptionGrid extends StatelessWidget {
  const OptionGrid({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    this.icon,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // AuthScaffold wraps content in IntrinsicHeight, which forbids descendant
    // LayoutBuilders. Use MediaQuery to derive the available width instead —
    // AuthScaffold's body padding is 24px on each side.
    final available = MediaQuery.sizeOf(context).width - 48;
    final twoColumns = available > 380;
    final tileWidth = twoColumns ? (available - 10) / 2 : available;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final value in values)
          SizedBox(
            width: tileWidth,
            child: _OptionTile(
              label: value,
              icon: icon ?? _iconFor(value),
              selected: selected == value,
              onTap: () => onChanged(value),
            ),
          ),
      ],
    );
  }

  IconData _iconFor(String value) {
    if (value.contains('كهرب') || value.contains('طاقة')) {
      return Icons.bolt_outlined;
    }
    if (value.contains('شركة') || value.contains('مقاول')) {
      return Icons.business_outlined;
    }
    if (value.contains('شفل') ||
        value.contains('كرين') ||
        value.contains('شاحنة') ||
        value.contains('بلدوزر') ||
        value.contains('دحالة') ||
        value.contains('شوكية')) {
      return Icons.local_shipping_outlined;
    }
    if (value.contains('حاسوب') || value.contains('كاميرات')) {
      return Icons.computer_outlined;
    }
    if (value.contains('نجار') ||
        value.contains('حداد') ||
        value.contains('سباك')) {
      return Icons.handyman_outlined;
    }
    return Icons.engineering_outlined;
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceAltDark : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryGlow : AppColors.borderDark,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primaryGlow : AppColors.mutedDark,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      selected ? AppColors.primaryGlow : AppColors.inkDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryGlow,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
