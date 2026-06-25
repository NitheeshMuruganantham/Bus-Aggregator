import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SelectionModeToggle extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onModeChanged;

  const SelectionModeToggle({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  static const List<String> modes = ['Position', 'Count'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: modes.map((mode) {
        final bool isActive = mode == selectedMode;
        return Expanded(
          child: GestureDetector(
            onTap: () => onModeChanged(mode),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                mode,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
