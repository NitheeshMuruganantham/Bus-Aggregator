import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bus_model.dart';
import '../models/platform_model.dart';
import '../services/makemytrip_service.dart';
import '../utils/constants.dart';
import '../widgets/platform_card.dart';

class PlatformScreen extends StatefulWidget {
  final BusModel bus;
  final String from;
  final String to;
  final String date;
  final String mode;
  final List<String> selectedSeats;
  final int seatCount;

  const PlatformScreen({
    super.key,
    required this.bus,
    required this.from,
    required this.to,
    required this.date,
    required this.mode,
    required this.selectedSeats,
    required this.seatCount,
  });

  @override
  State<PlatformScreen> createState() => _PlatformScreenState();
}

class _PlatformScreenState extends State<PlatformScreen> {
  late List<PlatformModel> _platforms;
  int _minPrice = 0;
  int _maxPrice = 0;

  @override
  void initState() {
    super.initState();
    _buildPlatforms();
  }

  String _formatDateForUrl(String date) {
    final parts = date.split(' ');
    if (parts.length >= 3) {
      const months = {
        'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
        'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
        'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
      };
      final day = parts[0].padLeft(2, '0');
      final month = months[parts[1]] ?? '01';
      final year = parts[2];
      return '$year-$month-$day';
    }
    return date.replaceAll(' ', '-');
  }

  void _buildPlatforms() {
    final fromLower = widget.from.toLowerCase().replaceAll(' ', '-');
    final toLower = widget.to.toLowerCase().replaceAll(' ', '-');
    final fromSlug = widget.from.replaceAll(' ', '-');
    final toSlug = widget.to.replaceAll(' ', '-');
    final urlDate = _formatDateForUrl(widget.date);

    _platforms = [
      PlatformModel(
        name: 'RedBus',
        color: AppColors.redbus,
        price: widget.bus.platforms['RedBus'] ?? widget.bus.price,
        deepLink:
            'https://www.redbus.in/bus-tickets/$fromLower-to-$toLower',
        tag: 'Most Popular',
      ),
      PlatformModel(
        name: 'AbhiBus',
        color: AppColors.abhibus,
        price: widget.bus.platforms['AbhiBus'] ?? widget.bus.price,
        deepLink:
            'https://www.abhibus.com/bus/$fromSlug/$toSlug/$urlDate',
        tag: 'Govt Buses',
      ),
      PlatformModel(
        name: 'MakeMyTrip',
        color: AppColors.mmt,
        price: widget.bus.platforms['MakeMyTrip'] ?? widget.bus.price,
        deepLink: MakeMyTripService.getBusDeepLink(
          from: fromSlug,
          to: toSlug,
          date: urlDate,
        ),
        tag: 'Best Offers',
      ),
      PlatformModel(
        name: 'Ixigo',
        color: AppColors.ixigo,
        price: widget.bus.platforms['Ixigo'] ?? widget.bus.price,
        deepLink:
            'https://www.ixigo.com/bus/search/$fromSlug/$toSlug/$urlDate/1',
        tag: 'Price Alerts',
      ),
    ];

    final prices = _platforms.map((p) => p.price).toList();
    _minPrice = prices.reduce((a, b) => a < b ? a : b);
    _maxPrice = prices.reduce((a, b) => a > b ? a : b);
  }

  void _onBookNow(PlatformModel platform) {
    HapticFeedback.heavyImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platform.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: platform.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You'll be redirected to ${platform.name}",
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Complete your booking there',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _openUrl(platform);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: platform.color,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Continue →'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openUrl(PlatformModel platform) async {
    final uri = Uri.parse(platform.deepLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${platform.name}...'),
            backgroundColor: AppColors.cardBg,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final savings = _maxPrice - _minPrice;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.bus.operator,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${widget.bus.layout} · ${widget.bus.departure}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                _buildBusInfoCard(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Choose where to book',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Prices may vary on each platform',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ..._platforms.map((platform) {
                  return PlatformCard(
                    platform: platform,
                    isCheapest: platform.price == _minPrice,
                    onBookNow: () => _onBookNow(platform),
                  );
                }),
                if (savings > 0)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Save ₹$savings vs most expensive',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'SeatFirst finds · Partners book · You save',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusInfoCard() {
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
          Text(
            widget.bus.operator,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.bus.departure,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.bus.duration,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                widget.bus.arrival,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _badge(widget.bus.layout),
              const SizedBox(width: 8),
              _badge(widget.bus.busType),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.mode == 'Position' && widget.selectedSeats.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.selectedSeats.map((seat) {
                return Chip(
                  label: Text(seat),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            )
          else if (widget.mode == 'Count')
            Text(
              '${widget.seatCount} seats available',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
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
