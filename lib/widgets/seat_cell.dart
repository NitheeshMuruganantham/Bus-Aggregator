import 'package:flutter/material.dart';
import '../models/seat_model.dart';
import '../utils/constants.dart';

class SeatCell extends StatelessWidget {
  final SeatModel seatModel;
  final bool isSelected;
  final VoidCallback onTap;
  final double height;
  final bool showReclineIcon;

  const SeatCell({
    super.key,
    required this.seatModel,
    required this.isSelected,
    required this.onTap,
    this.height = 60,
    this.showReclineIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final count = seatModel.availableCount;
    final bool isUnavailable = count == 0;

    Color borderColor;
    Color bgColor;
    Color countColor;

    if (isSelected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary;
      countColor = Colors.black;
    } else if (isUnavailable) {
      borderColor = Colors.transparent;
      bgColor = const Color(0x20FF4444);
      countColor = AppColors.textSecondary;
    } else if (count >= 3) {
      borderColor = AppColors.primary;
      bgColor = const Color(0x1500C896);
      countColor = AppColors.textPrimary;
    } else {
      borderColor = AppColors.warning;
      bgColor = const Color(0x15FFB800);
      countColor = AppColors.textPrimary;
    }

    final String typeIcon = _typeIcon(seatModel.type);

    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTap: isUnavailable ? null : onTap,
        child: Container(
          width: 52,
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                seatModel.id,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: countColor,
                ),
              ),
              if (showReclineIcon)
                const Icon(
                  Icons.airline_seat_recline_normal,
                  size: 8,
                  color: AppColors.textSecondary,
                )
              else
                Text(
                  typeIcon,
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeIcon(String type) {
    switch (type) {
      case 'window-left':
      case 'window-right':
      case 'window':
        return 'W';
      case 'aisle':
        return 'A';
      case 'lower':
        return 'L';
      case 'upper':
        return 'U';
      default:
        return '';
    }
  }
}
