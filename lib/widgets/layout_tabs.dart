import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class LayoutTabs extends StatelessWidget {
  final String selectedLayout;
  final ValueChanged<String> onLayoutChanged;

  const LayoutTabs({
    super.key,
    required this.selectedLayout,
    required this.onLayoutChanged,
  });

  static const List<String> layouts = [
    '2+1',
    '2+2',
    'Sleeper',
    'Semi-Sleeper',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: layouts.map((layout) {
          final bool isActive = layout == selectedLayout;
          return Expanded(
            child: GestureDetector(
              onTap: () => onLayoutChanged(layout),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  layout,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? p.onPrimary : p.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
