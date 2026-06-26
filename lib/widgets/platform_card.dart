import 'package:flutter/material.dart';
import '../models/platform_model.dart';
import '../utils/app_theme.dart';

class PlatformCard extends StatelessWidget {
  final PlatformModel platform;
  final bool isCheapest;
  final VoidCallback onBookNow;

  const PlatformCard({
    super.key,
    required this.platform,
    required this.isCheapest,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: p.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: platform.color.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: p.shadow,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 88,
                decoration: BoxDecoration(
                  color: platform.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              platform.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: p.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              platform.tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${platform.price}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: platform.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FilledButton(
                            onPressed: onBookNow,
                            style: FilledButton.styleFrom(
                              backgroundColor: platform.color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Book Now',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isCheapest)
          Positioned(
            top: 4,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💰 Cheapest',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
