import 'package:flutter/material.dart';
import '../models/seat_model.dart';
import '../utils/app_theme.dart';

enum SeatVisualState { available, lowStock, soldOut, selected }

class BusSeatWidget extends StatelessWidget {
  static const double seatWidth = 48;
  static const double seatHeight = 52;
  static const double sleeperHeight = 58;

  final SeatModel seat;
  final bool isSelected;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool isSleeper;

  const BusSeatWidget({
    super.key,
    required this.seat,
    required this.isSelected,
    this.onTap,
    this.width = seatWidth,
    this.height = seatHeight,
    this.isSleeper = false,
  });

  SeatVisualState get _state {
    if (isSelected) return SeatVisualState.selected;
    if (seat.availableCount == 0) return SeatVisualState.soldOut;
    if (seat.availableCount <= 2) return SeatVisualState.lowStock;
    return SeatVisualState.available;
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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = _state;
    final count = seat.availableCount;
    final bool tappable = state != SeatVisualState.soldOut;

    late final Color fill;
    late final Color border;
    late final Color labelColor;
    late final Color countColor;

    switch (state) {
      case SeatVisualState.selected:
        fill = p.seatSelected;
        border = p.seatSelected;
        labelColor = p.onPrimary.withValues(alpha: 0.85);
        countColor = p.onPrimary;
      case SeatVisualState.soldOut:
        fill = p.seatSoldOut;
        border = p.seatSoldOut;
        labelColor = p.textSecondary;
        countColor = p.textSecondary;
      case SeatVisualState.lowStock:
        fill = p.seatLowStock.withValues(alpha: 0.12);
        border = p.seatLowStock;
        labelColor = p.textSecondary;
        countColor = p.textPrimary;
      case SeatVisualState.available:
        fill = p.seatAvailable;
        border = p.seatAvailableBorder;
        labelColor = p.textSecondary;
        countColor = p.textPrimary;
    }

    return Semantics(
      label: 'Seat ${seat.id}, available on $count buses',
      button: tappable,
      child: AnimatedScale(
        scale: isSelected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: tappable ? onTap : null,
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      seat.id,
                      style: TextStyle(
                        fontSize: isSleeper ? 8 : 9,
                        fontWeight: FontWeight.w500,
                        color: labelColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: isSleeper ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        color: countColor,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _typeIcon(seat.type),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
