import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../utils/constants.dart';

class BusCard extends StatelessWidget {
  final BusModel bus;
  final VoidCallback onViewPlatforms;

  const BusCard({
    super.key,
    required this.bus,
    required this.onViewPlatforms,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  bus.operator,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bus.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Badge(text: bus.layout),
              const SizedBox(width: 8),
              _Badge(text: bus.busType),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bus.departure,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                bus.duration,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                bus.arrival,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '₹${bus.price}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${bus.availableSeats.length} seats',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewPlatforms,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
                child: const Text(
                  'View Platforms',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: bus.amenities.map(_amenityIcon).toList(),
          ),
        ],
      ),
    );
  }

  Widget _amenityIcon(String amenity) {
    IconData icon;
    Color color;

    switch (amenity) {
      case 'AC':
        icon = Icons.ac_unit;
        color = Colors.blue;
        break;
      case 'WiFi':
        icon = Icons.wifi;
        color = Colors.blue;
        break;
      case 'Charging':
        icon = Icons.bolt;
        color = AppColors.warning;
        break;
      case 'Water':
        icon = Icons.water_drop;
        color = Colors.cyan;
        break;
      case 'Blanket':
        icon = Icons.bed;
        color = Colors.purple;
        break;
      case 'Snacks':
        icon = Icons.fastfood;
        color = Colors.orange;
        break;
      case 'Pillow':
        icon = Icons.hotel;
        color = Colors.purple;
        break;
      default:
        icon = Icons.check_circle;
        color = AppColors.textSecondary;
    }

    return Icon(icon, size: 18, color: color);
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
