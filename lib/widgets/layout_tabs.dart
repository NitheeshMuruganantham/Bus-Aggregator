import 'package:flutter/material.dart';
import '../utils/constants.dart';

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
    return SizedBox(
      height: 48,
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
                  color: isActive ? AppColors.primary : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  layout,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Colors.black
                        : AppColors.textSecondary,
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
