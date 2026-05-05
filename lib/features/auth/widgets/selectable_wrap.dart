import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class SelectableWrap extends StatelessWidget {
  const SelectableWrap({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  final List<String> values;
  final Set<String> selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          FilterChip(
            label: Text(value),
            selected: selected.contains(value),
            showCheckmark: false,
            selectedColor: AppColors.paleBlue,
            side: BorderSide(
              color: selected.contains(value)
                  ? AppColors.blue
                  : AppColors.border,
            ),
            labelStyle: TextStyle(
              color: selected.contains(value)
                  ? AppColors.darkBlue
                  : AppColors.ink,
              fontWeight: selected.contains(value)
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
            onSelected: (_) => onChanged(value),
          ),
      ],
    );
  }
}
