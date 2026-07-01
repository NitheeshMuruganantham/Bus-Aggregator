import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bus_model.dart';
import 'platform_screen.dart';

class BusListScreen extends StatefulWidget {
  final List<BusModel> filteredBuses;
  final String from;
  final String to;
  final String date;
  final String timeSlot;
  final bool isPositionMode;
  final int seatCount;
  final List<String> selectedSeats;

  const BusListScreen({
    super.key,
    required this.filteredBuses,
    required this.from,
    required this.to,
    required this.date,
    required this.timeSlot,
    this.isPositionMode = false,
    this.seatCount = 0,
    this.selectedSeats = const [],
  });

  @override
  State<BusListScreen> createState() =>
    _BusListScreenState();
}

class _BusListScreenState
  extends State<BusListScreen> {

  String _sortBy = 'Price ↑';
  late List<BusModel> _sortedBuses;

  @override
  void initState() {
    super.initState();
    _sortedBuses =
      List.from(widget.filteredBuses);
    _applySorting();
  }

  void _applySorting() {
    setState(() {
      switch (_sortBy) {
        case 'Price ↑':
          _sortedBuses.sort((a, b) =>
            _cheapest(a).compareTo(_cheapest(b)));
          break;
        case 'Price ↓':
          _sortedBuses.sort((a, b) =>
            _cheapest(b).compareTo(_cheapest(a)));
          break;
        case 'Rating':
          _sortedBuses.sort((a, b) =>
            b.rating.compareTo(a.rating));
          break;
        case 'Departure':
          _sortedBuses.sort((a, b) =>
            _parseTime(a.departure)
            .compareTo(_parseTime(b.departure)));
          break;
      }
    });
  }

  int _cheapest(BusModel bus) =>
    bus.platforms.values
      .reduce((a, b) => a < b ? a : b);

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final cleaned = timeStr.trim().toUpperCase();
    final parts = cleaned.split(' ');
    if (parts.length < 2) return now;
    final timeParts = parts[0].split(':');
    if (timeParts.length < 2) return now;
    int hour = int.tryParse(timeParts[0]) ?? 0;
    int minute = int.tryParse(timeParts[1]) ?? 0;
    final isPM = parts[1] == 'PM';
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return DateTime(
      now.year, now.month, now.day, hour, minute,
    );
  }

  String _formatDate(String d) => d;

  IconData _amenityIconData(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'ac': return Icons.ac_unit;
      case 'wifi': return Icons.wifi;
      case 'charging': return Icons.bolt;
      case 'water': return Icons.water_drop;
      case 'blanket': return Icons.bed;
      case 'pillow':
        return Icons.airline_seat_legroom_extra;
      case 'snacks': return Icons.fastfood;
      default: return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          _buildAppBar(),
          _buildSortBar(),
          Expanded(
            child: _sortedBuses.isEmpty
              ? _buildEmptyState()
              : _buildBusList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A56DB),
            Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                  Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white
                      .withOpacity(0.2),
                    borderRadius:
                      BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                    CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.from} → '
                      '${widget.to}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                      ),
                    ),
                    Text(
                      '${_formatDate(widget.date)}'
                      ' · ${widget.timeSlot}',
                      style: TextStyle(
                        color: const Color(
                          0xFFBFDBFE,
                        ),
                        fontSize: 11,
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white
                    .withOpacity(0.2),
                  borderRadius:
                    BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_sortedBuses.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Mode indicator bar
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius:
                BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white
                  .withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isPositionMode
                    ? Icons.event_seat
                    : Icons.people,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isPositionMode
                    ? 'Seats: ${widget
                        .selectedSeats.join(', ')}'
                    : '${widget.seatCount} '
                      'seat(s) needed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontFamily:
                      GoogleFonts.poppins()
                      .fontFamily,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  '${_sortedBuses.length} buses',
                  style: TextStyle(
                    color: const Color(0xFFBFDBFE),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily:
                      GoogleFonts.poppins()
                      .fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16, 10, 16, 10,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            'Price ↑',
            'Price ↓',
            'Rating',
            'Departure',
          ].map((label) {
            final isActive = _sortBy == label;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _sortBy = label);
                _applySorting();
              },
              child: Container(
                margin: const EdgeInsets.only(
                  right: 8,
                ),
                padding:
                  const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7,
                  ),
                decoration: BoxDecoration(
                  color: isActive
                    ? const Color(0xFF1A56DB)
                    : Colors.white,
                  borderRadius:
                    BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                      ? const Color(0xFF1A56DB)
                      : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive
                      ? Colors.white
                      : const Color(0xFF64748B),
                    fontFamily:
                      GoogleFonts.poppins()
                      .fontFamily,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBusList() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).padding.bottom
        + 16,
      ),
      itemCount: _sortedBuses.length,
      itemBuilder: (_, i) =>
        _buildBusCard(_sortedBuses[i]),
    );
  }

  Widget _buildBusCard(BusModel bus) {
    final cheapPrice = _cheapest(bus);
    final allPrices = bus.platforms.values
      .toList()..sort();
    final cheapestPlatform = bus.platforms.entries
      .firstWhere((e) =>
        e.value == allPrices.first).key;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [

          // Top accent bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment:
                CrossAxisAlignment.start,
              children: [

                // Row 1: Operator + rating + layout
                Row(
                  crossAxisAlignment:
                    CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                          CrossAxisAlignment.start,
                        children: [
                          Text(
                            bus.operator,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                FontWeight.w700,
                              color: const Color(
                                0xFF1E293B,
                              ),
                              fontFamily:
                                GoogleFonts
                                .poppins()
                                .fontFamily,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bus.busType,
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(
                                0xFF64748B,
                              ),
                              fontFamily:
                                GoogleFonts
                                .poppins()
                                .fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding:
                            const EdgeInsets
                            .symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFFBEB,
                            ),
                            borderRadius:
                              BorderRadius
                              .circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 11,
                                color: Color(
                                  0xFFF59E0B,
                                ),
                              ),
                              const SizedBox(
                                width: 2,
                              ),
                              Text(
                                bus.rating
                                  .toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                    FontWeight.w700,
                                  color:
                                    const Color(
                                    0xFF92400E,
                                  ),
                                  fontFamily:
                                    GoogleFonts
                                    .poppins()
                                    .fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding:
                            const EdgeInsets
                            .symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFEF2F2,
                            ),
                            borderRadius:
                              BorderRadius
                              .circular(6),
                          ),
                          child: Text(
                            bus.layout,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                FontWeight.w700,
                              color: const Color(
                                0xFFB91C1C,
                              ),
                              fontFamily:
                                GoogleFonts
                                .poppins()
                                .fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Row 2: Departure → duration → arrival
                Row(
                  children: [
                    Column(
                      crossAxisAlignment:
                        CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.departure,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                              FontWeight.w700,
                            color: const Color(
                              0xFF1E293B,
                            ),
                            fontFamily:
                              GoogleFonts.poppins()
                              .fontFamily,
                          ),
                        ),
                        Text(
                          'Departure',
                          style: TextStyle(
                            fontSize: 9,
                            color: const Color(
                              0xFF94A3B8,
                            ),
                            fontFamily:
                              GoogleFonts.poppins()
                              .fontFamily,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            bus.duration,
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(
                                0xFF94A3B8,
                              ),
                              fontFamily:
                                GoogleFonts
                                .poppins()
                                .fontFamily,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: const Color(
                                    0xFFE2E8F0,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.directions_bus,
                                size: 14,
                                color: Color(
                                  0xFF94A3B8,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: const Color(
                                    0xFFE2E8F0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment:
                        CrossAxisAlignment.end,
                      children: [
                        Text(
                          bus.arrival,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                              FontWeight.w700,
                            color: const Color(
                              0xFF1E293B,
                            ),
                            fontFamily:
                              GoogleFonts.poppins()
                              .fontFamily,
                          ),
                        ),
                        Text(
                          'Arrival',
                          style: TextStyle(
                            fontSize: 9,
                            color: const Color(
                              0xFF94A3B8,
                            ),
                            fontFamily:
                              GoogleFonts.poppins()
                              .fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Row 3: Amenities
                if (bus.amenities.isNotEmpty)
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: bus.amenities
                      .map((a) => Row(
                        mainAxisSize:
                          MainAxisSize.min,
                        children: [
                          Icon(
                            _amenityIconData(a),
                            size: 13,
                            color: const Color(
                              0xFF1A56DB,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            a,
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(
                                0xFF64748B,
                              ),
                              fontFamily:
                                GoogleFonts
                                .poppins()
                                .fontFamily,
                            ),
                          ),
                        ],
                      ))
                      .toList(),
                  ),

                const SizedBox(height: 10),

                // Row 4: Price + seats + View Platforms
                Row(
                  children: [
                    Column(
                      crossAxisAlignment:
                        CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹$cheapPrice',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                              FontWeight.w800,
                            color: const Color(
                              0xFF1A56DB,
                            ),
                            fontFamily:
                              GoogleFonts.poppins()
                              .fontFamily,
                          ),
                        ),
                        Text(
                          'via $cheapestPlatform',
                          style: TextStyle(
                            fontSize: 9,
                            color: const Color(
                              0xFF94A3B8,
                            ),
                            fontFamily:
                              GoogleFonts.poppins()
                              .fontFamily,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                        const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFF0FDF4,
                        ),
                        borderRadius:
                          BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${bus.availableSeats.length}'
                        ' seats left',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(
                            0xFF16A34A,
                          ),
                          fontFamily:
                            GoogleFonts.poppins()
                            .fontFamily,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback
                          .mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                              PlatformScreen(
                                bus: bus,
                                from: widget.from,
                                to: widget.to,
                                date: widget.date,
                                timeSlot:
                                  widget.timeSlot,
                                selectedSeats: widget
                                  .isPositionMode
                                  ? widget
                                    .selectedSeats
                                  : [],
                              ),
                          ),
                        );
                      },
                      style:
                        ElevatedButton.styleFrom(
                        backgroundColor:
                          const Color(0xFFEFF6FF),
                        foregroundColor:
                          const Color(0xFF1A56DB),
                        elevation: 0,
                        padding:
                          const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                            BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'View Platforms',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily:
                            GoogleFonts.poppins()
                            .fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
          MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_bus_outlined,
            size: 56,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            'No buses found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
              fontFamily: GoogleFonts.poppins()
                .fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your seat\n'
            'selection or count',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontFamily: GoogleFonts.poppins()
                .fontFamily,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () =>
              Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFF1A56DB),
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                  BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Go Back',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A56DB),
                fontFamily: GoogleFonts.poppins()
                  .fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
