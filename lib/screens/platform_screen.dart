import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bus_model.dart';
import '../models/platform_model.dart';
import '../services/makemytrip_service.dart';
import '../utils/app_theme.dart';
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

    final p = context.palette;

    showModalBottomSheet(
      context: context,
      backgroundColor: p.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final sheetP = context.palette;
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
                style: TextStyle(
                  fontSize: 14,
                  color: sheetP.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete your booking there',
                style: TextStyle(
                  fontSize: 12,
                  color: sheetP.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: sheetP.textSecondary,
                        side: BorderSide(color: sheetP.border),
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
            backgroundColor: context.palette.cardBg,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final savings = _maxPrice - _minPrice;
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: p.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.bus.operator,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: p.textPrimary,
              ),
            ),
            Text(
              '${widget.bus.layout} · ${widget.bus.departure}',
              style: TextStyle(fontSize: 12, color: p.textSecondary),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Choose where to book',
                    style: TextStyle(fontSize: 14, color: p.textSecondary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Prices may vary on each platform',
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
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
                      'You Saved ₹$savings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'SeatFirst finds · Partners book · You save',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusInfoCard() {
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.bus.operator,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.bus.departure,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: p.textPrimary,
                ),
              ),
              Text(
                widget.bus.duration,
                style: TextStyle(fontSize: 12, color: p.textSecondary),
              ),
              Text(
                widget.bus.arrival,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Amenity icons
          if (widget.bus.amenities.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: widget.bus.amenities.map((amenity) {
                return _amenityIcon(amenity, p.textSecondary);
              }).toList(),
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
                  backgroundColor: primary.withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: primary, fontSize: 12),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            )
          else if (widget.mode == 'Count')
            Text(
              '${widget.seatCount} seats available',
              style: TextStyle(fontSize: 14, color: p.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.chipBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: p.border),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: p.textSecondary),
      ),
    );
  }

  Widget _amenityIcon(String amenity, Color color) {
    IconData icon;
    String label;
    
    switch (amenity.toLowerCase()) {
      case 'ac':
        icon = Icons.ac_unit;
        label = 'AC';
        break;
      case 'wifi':
        icon = Icons.wifi;
        label = 'WiFi';
        break;
      case 'charging':
        icon = Icons.power;
        label = 'Charging';
        break;
      case 'water':
        icon = Icons.water_drop;
        label = 'Water';
        break;
      case 'blanket':
        icon = Icons.bed;
        label = 'Blanket';
        break;
      case 'pillow':
        icon = Icons.airline_seat_flat;
        label = 'Pillow';
        break;
      default:
        icon = Icons.check_circle;
        label = amenity;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }
}
