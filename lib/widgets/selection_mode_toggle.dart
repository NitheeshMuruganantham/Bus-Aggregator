import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

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
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: p.chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: modes.map((mode) {
          final bool isActive = mode == selectedMode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onModeChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mode == 'Position'
                          ? Icons.event_seat
                          : Icons.numbers,
                      size: 16,
                      color: isActive ? primary : p.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mode,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? p.textPrimary : p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
