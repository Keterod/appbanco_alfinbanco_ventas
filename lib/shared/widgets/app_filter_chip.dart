import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Chip de filtro con contraste legible (seleccionado / no seleccionado).
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.accentColor,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.secondary;
    final selectedBg = _selectedBackground(accent);
    final selectedFg = _foregroundOn(selectedBg);

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
      backgroundColor: AppColors.white,
      selectedColor: selectedBg,
      checkmarkColor: selected ? selectedFg : accent,
      side: BorderSide(
        color: selected ? selectedBg : AppColors.divider,
        width: selected ? 1.5 : 1,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: selected ? selectedFg : AppColors.textPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static Color _selectedBackground(Color accent) {
    if (accent.computeLuminance() > 0.72) {
      return AppColors.purpleSupport;
    }
    return accent;
  }

  static Color _foregroundOn(Color background) {
    return background.computeLuminance() > 0.55
        ? AppColors.purpleSupport
        : AppColors.white;
  }
}
