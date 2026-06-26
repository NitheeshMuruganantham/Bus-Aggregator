import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../utils/app_theme.dart';
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
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    bus.operator,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                _ratingBadge(bus.rating),
                const SizedBox(width: 8),
                _Badge(text: bus.layout, color: primary),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              bus.busType,
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.departure,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        'Departure',
                        style: TextStyle(fontSize: 10, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      bus.duration,
                      style: TextStyle(fontSize: 11, color: p.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 24, height: 1, color: p.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.directions_bus,
                            size: 16,
                            color: primary,
                          ),
                        ),
                        Container(width: 24, height: 1, color: p.border),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        bus.arrival,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        'Arrival',
                        style: TextStyle(fontSize: 10, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: p.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '₹${bus.price}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${bus.availableSeats.length} seats left',
                    style: TextStyle(fontSize: 11, color: primary),
                  ),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: onViewPlatforms,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary.withValues(alpha: 0.12),
                    foregroundColor: primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'View Platforms',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Wrap(
              spacing: 10,
              children: bus.amenities.map(_amenityChip).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: AppColors.warning),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amenityChip(String amenity) {
    IconData icon;
    Color color;

    switch (amenity) {
      case 'AC':
        icon = Icons.ac_unit;
        color = Colors.blue;
      case 'WiFi':
        icon = Icons.wifi;
        color = Colors.blue;
      case 'Charging':
        icon = Icons.bolt;
        color = AppColors.warning;
      case 'Water':
        icon = Icons.water_drop;
        color = Colors.cyan;
      case 'Blanket':
        icon = Icons.bed;
        color = Colors.purple;
      case 'Snacks':
        icon = Icons.fastfood;
        color = Colors.orange;
      case 'Pillow':
        icon = Icons.hotel;
        color = Colors.purple;
      default:
        icon = Icons.check_circle;
        color = Colors.grey;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 3),
        Text(amenity, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
