import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import '../widgets/bus_card.dart';
import '../widgets/shimmer_loader.dart';
import 'platform_screen.dart';

class BusListScreen extends StatefulWidget {
  final String from;
  final String to;
  final String date;
  final String timeSlot;
  final String layout;
  final String mode;
  final List<String> selectedSeats;
  final int seatCount;
  final List<BusModel> buses;

  const BusListScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
    required this.timeSlot,
    required this.layout,
    required this.mode,
    required this.selectedSeats,
    required this.seatCount,
    required this.buses,
  });

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  bool _isLoading = true;
  late List<BusModel> _filteredBuses;
  String _activeSort = 'Price ↑';

  static const List<String> _sortOptions = [
    'Price ↑',
    'Price ↓',
    'Rating',
    'Departure',
  ];

  @override
  void initState() {
    super.initState();
    _filteredBuses = List.from(widget.buses);
    _applySort(_activeSort);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _applySort(String sort) {
    setState(() {
      _activeSort = sort;
      _filteredBuses = List.from(widget.buses);
      switch (sort) {
        case 'Price ↑':
          _filteredBuses.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'Price ↓':
          _filteredBuses.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'Rating':
          _filteredBuses.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'Departure':
          _filteredBuses.sort((a, b) => a.departure.compareTo(b.departure));
          break;
      }
    });
  }

  void _openPlatform(BusModel bus) {
    Navigator.push(
      context,
      slideUpRoute(
        PlatformScreen(
          bus: bus,
          from: widget.from,
          to: widget.to,
          date: widget.date,
          mode: widget.mode,
          selectedSeats: widget.selectedSeats,
          seatCount: widget.seatCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Available Buses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${widget.buses.length} buses found',
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
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _sortOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final sort = _sortOptions[index];
                final isActive = sort == _activeSort;
                return GestureDetector(
                  onTap: () => _applySort(sort),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      sort,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.black
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const ShimmerLoaderList()
                : _filteredBuses.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredBuses.length,
                        itemBuilder: (context, index) {
                          final bus = _filteredBuses[index];
                          return BusCard(
                            bus: bus,
                            onViewPlatforms: () => _openPlatform(bus),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_seat,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No buses match your seat preference',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try selecting different seats or use Count Mode',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Change Selection'),
            ),
          ],
        ),
      ),
    );
  }
}
