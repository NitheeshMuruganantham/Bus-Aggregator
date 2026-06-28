import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bus_model.dart';
import '../data/mock_data.dart';
import 'seat_selection_screen.dart';
import 'platform_screen.dart';

class SmartSuggestionScreen extends StatefulWidget {
  final String from;
  final String to;
  final String date;
  final String timeSlot;
  final List<String> selectedSeats;
  final List<String> seaterSeats;
  final List<String> lowerSeats;
  final List<String> upperSeats;
  final List<BusModel> exactMatches;
  final List<BusModel> allRouteBuses;
  final TemplateData templateData;

  const SmartSuggestionScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
    required this.timeSlot,
    required this.selectedSeats,
    required this.seaterSeats,
    required this.lowerSeats,
    required this.upperSeats,
    required this.exactMatches,
    required this.allRouteBuses,
    required this.templateData,
  });

  @override
  State<SmartSuggestionScreen> createState() =>
    _SmartSuggestionScreenState();
}

class _SmartSuggestionScreenState
  extends State<SmartSuggestionScreen> {

  // Layer results
  List<BusModel> exactMatches = [];
  List<Map<String, dynamic>> nearbyMatches = [];
  List<Map<String, dynamic>> zoneMatches = [];
  List<Map<String, dynamic>> splitOptions = [];
  List<Map<String, dynamic>> dateOptions = [];

  bool isLoading = true;

  // Split option checkbox states
  final Map<int, bool> _splitCardSelected = {};
  final Map<int, Map<String, bool>> _splitGroupSelected = {};

  @override
  void initState() {
    super.initState();
    exactMatches = widget.exactMatches;
    _buildAllLayers();
  }

  void _buildAllLayers() async {
    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    if (!mounted) return;

    setState(() {
      // Layer 2: Nearby seat suggestions
      nearbyMatches = _buildNearbyMatches();

      // Layer 3: Zone matches
      zoneMatches = _buildZoneMatches();

      // Layer 4: Split bus options
      splitOptions = _buildSplitOptions();

      // Layer 5: Date alternatives
      dateOptions = _buildDateOptions();

      isLoading = false;
    });
  }

  // ── LAYER 2: NEARBY SEATS ──────────────────────
  List<Map<String, dynamic>> _buildNearbyMatches() {
    if (exactMatches.isNotEmpty) return [];

    final results = <Map<String, dynamic>>[];

    // For each selected seat try ±2 row variants
    for (final seat in widget.selectedSeats) {
      final variants = _getNearbySeats(seat);

      for (final variant in variants) {
        // Replace this seat with variant
        final newSeats = widget.selectedSeats
          .map((s) => s == seat ? variant : s)
          .toList();

        // Find buses with new seat combo
        final matches = widget.allRouteBuses
          .where((bus) => newSeats.every(
            (s) => bus.availableSeats.contains(s),
          ))
          .toList();

        if (matches.isNotEmpty) {
          results.add({
            'original': seat,
            'suggested': variant,
            'newSeats': newSeats,
            'buses': matches,
            'busCount': matches.length,
          });
        }
      }
    }

    // Sort by most buses available
    results.sort((a, b) =>
      (b['busCount'] as int)
      .compareTo(a['busCount'] as int),
    );

    return results.take(3).toList();
  }

  List<String> _getNearbySeats(String seatId) {
    final nearby = <String>[];
    final isLower = seatId.startsWith('L');
    final isUpper = seatId.startsWith('U');

    // Extract row number and column
    String cleanId = seatId;
    if (isLower || isUpper) {
      cleanId = seatId.substring(1);
    }

    final digits = cleanId.replaceAll(
      RegExp(r'[^0-9]'), '',
    );
    final letters = cleanId.replaceAll(
      RegExp(r'[^A-Za-z]'), '',
    );

    if (digits.isEmpty) return nearby;
    final row = int.tryParse(digits) ?? 0;
    final prefix = isLower
      ? 'L' : isUpper ? 'U' : '';

    // ±2 rows same column
    for (int delta = -2; delta <= 2; delta++) {
      if (delta == 0) continue;
      final newRow = row + delta;
      if (newRow >= 1 && newRow <= 10) {
        final candidate = '$prefix$newRow$letters';
        // Exclude if already selected by user
        if (!widget.selectedSeats.contains(candidate)) {
          nearby.add(candidate);
        }
      }
    }

    // Same row different columns
    for (final col in ['A', 'B', 'C', 'D']) {
      if (col != letters) {
        final candidate = '$prefix$row$col';
        // Exclude if already selected by user
        if (!widget.selectedSeats.contains(candidate)) {
          nearby.add(candidate);
        }
      }
    }

    return nearby;
  }

  // ── LAYER 3: ZONE MATCHES ──────────────────────
  List<Map<String, dynamic>> _buildZoneMatches() {
    if (exactMatches.isNotEmpty) return [];

    String _getZone(String seatId) {
      final digits = seatId.replaceAll(
        RegExp(r'[^0-9]'), '',
      );
      final row = int.tryParse(digits) ?? 0;
      if (row <= 3) return 'Front';
      if (row <= 7) return 'Middle';
      return 'Rear';
    }

    // Get zones of selected seats
    final selectedZones = widget.selectedSeats
      .map(_getZone)
      .toSet();

    final results = <Map<String, dynamic>>[];

    // Find buses with seats in same zones
    for (final bus in widget.allRouteBuses) {
      int zoneMatched = 0;
      final matchedSeats = <String>[];

      for (final seat in bus.availableSeats) {
        final zone = _getZone(seat);
        if (selectedZones.contains(zone)) {
          zoneMatched++;
          matchedSeats.add(seat);
        }
      }

      if (zoneMatched >= widget.selectedSeats.length) {
        results.add({
          'bus': bus,
          'matchedSeats': matchedSeats
            .take(widget.selectedSeats.length)
            .toList(),
          'zones': selectedZones.toList(),
          'type': 'zone',
        });
      }
    }

    return results.take(3).toList();
  }

  // ── LAYER 4: SPLIT BUS OPTIONS ─────────────────
  List<Map<String, dynamic>> _buildSplitOptions() {
    if (exactMatches.isNotEmpty) return [];
    if (widget.selectedSeats.length < 2) return [];

    final results = <Map<String, dynamic>>[];

    // Try splitting seats across 2 buses
    // Group 1: seater seats
    // Group 2: berth seats
    if (widget.seaterSeats.isNotEmpty &&
        (widget.lowerSeats.isNotEmpty ||
         widget.upperSeats.isNotEmpty)) {

      // Find bus for seater group
      final seaterBuses = widget.allRouteBuses
        .where((bus) => widget.seaterSeats.every(
          (s) => bus.availableSeats.contains(s),
        ))
        .toList();

      // Find bus for berth group
      final berthSeats = [
        ...widget.lowerSeats,
        ...widget.upperSeats,
      ];
      final berthBuses = widget.allRouteBuses
        .where((bus) => berthSeats.every(
          (s) => bus.availableSeats.contains(s),
        ))
        .toList();

      if (seaterBuses.isNotEmpty &&
          berthBuses.isNotEmpty) {

        // Find pairs with same departure time
        for (final sb in seaterBuses) {
          for (final bb in berthBuses) {
            if (sb.id != bb.id) {
              final timeDiff = _parseTime(
                sb.departure,
              ).difference(
                _parseTime(bb.departure),
              ).abs();

              // Within 30 mins of each other
              if (timeDiff.inMinutes <= 30) {
                results.add({
                  'bus1': sb,
                  'bus1Seats': widget.seaterSeats,
                  'bus2': bb,
                  'bus2Seats': berthSeats,
                  'timeDiff': timeDiff.inMinutes,
                  'type': 'split',
                });
              }
            }
          }
        }
      }
    }

    return results.take(2).toList();
  }

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

  // ── LAYER 5: DATE OPTIONS ──────────────────────
  List<Map<String, dynamic>> _buildDateOptions() {
    if (exactMatches.isNotEmpty) return [];

    final results = <Map<String, dynamic>>[];
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];

    // Parse current date from string (assume format like "Jan 15, 2026")
    final now = DateTime.now();
    final baseDate = now; // Use current date as base

    // Check next 5 days
    for (int dayOffset = 1; dayOffset <= 5; dayOffset++) {
      final checkDate = baseDate.add(
        Duration(days: dayOffset),
      );

      // Simulate different availability per day
      // (with real API this would be actual data)
      final seed = dayOffset * 7;
      final simulatedAvailable =
        widget.selectedSeats.where((seat) {
        return (seat.hashCode + seed) % 3 != 0;
      }).length;

      final allAvailable =
        simulatedAvailable ==
        widget.selectedSeats.length;

      final dateStr =
        '${months[checkDate.month - 1]} '
        '${checkDate.day}';

      // Simulate price variation
      final basePrice = widget.allRouteBuses
        .isNotEmpty
        ? widget.allRouteBuses.first.price
        : 500;
      final priceVar = (dayOffset - 1) * 35;
      final dayPrice = basePrice + priceVar;

      results.add({
        'date': checkDate,
        'dateStr': dateStr,
        'dayOffset': dayOffset,
        'allAvailable': allAvailable,
        'availableCount': simulatedAvailable,
        'totalNeeded':
          widget.selectedSeats.length,
        'estimatedPrice': dayPrice,
        'busCount': allAvailable
          ? 3 + dayOffset : 0,
      });
    }

    return results;
  }

  // ── BUILD UI ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
        const Color(0xFFF0F4F8),
      body: Column(
        children: [
          _buildAppBar(),
          _buildSelectedSeatsBar(),
          Expanded(
            child: isLoading
              ? _buildLoading()
              : _buildResults(),
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
                  '${widget.from} → ${widget.to}',
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
                  'Smart seat matching results',
                  style: TextStyle(
                    color: const Color(0xFFBFDBFE),
                    fontSize: 11,
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

  Widget _buildSelectedSeatsBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment:
          CrossAxisAlignment.start,
        children: [
          Text(
            'Your selection:',
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF64748B),
              fontFamily: GoogleFonts.poppins()
                .fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ...widget.seaterSeats.map((s) =>
                _seatChip(s,
                  const Color(0xFF1A56DB),
                  Icons.airline_seat_recline_normal,
                ),
              ),
              ...widget.lowerSeats.map((s) =>
                _seatChip(s,
                  const Color(0xFF16A34A),
                  Icons.bed_outlined,
                ),
              ),
              ...widget.upperSeats.map((s) =>
                _seatChip(s,
                  const Color(0xFF7C3AED),
                  Icons.airline_seat_flat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seatChip(
    String label,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: GoogleFonts.poppins()
                .fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment:
          MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF1A56DB),
          ),
          const SizedBox(height: 16),
          Text(
            'Finding best matches...',
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 14,
              fontFamily: GoogleFonts.poppins()
                .fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16,
        MediaQuery.of(context).padding.bottom
        + 16,
      ),
      child: Column(
        crossAxisAlignment:
          CrossAxisAlignment.start,
        children: [

          // ── LAYER 1: EXACT MATCHES ─────────────
          if (exactMatches.isNotEmpty) ...[
            _sectionHeader(
              'Perfect Match',
              '${exactMatches.length} bus(es) '
              'have all your seats free',
              const Color(0xFF16A34A),
            ),
            ...exactMatches.map((bus) =>
              _exactBusCard(bus),
            ),
            const SizedBox(height: 16),
          ],

          // ── LAYER 2: NEARBY SUGGESTIONS ────────
          if (nearbyMatches.isNotEmpty) ...[
            _sectionHeader(
              '🔄 Nearby Seat Suggestions',
              'Change 1 seat to get more options',
              const Color(0xFF1A56DB),
            ),
            ...nearbyMatches.map((m) =>
              _nearbySuggestionCard(m),
            ),
            const SizedBox(height: 16),
          ],

          // ── LAYER 3: AREA MATCHES ──────────────
          if (zoneMatches.isNotEmpty &&
              exactMatches.isEmpty &&
              nearbyMatches.isEmpty) ...[
            _sectionHeader(
              '📍 Same Area Matches',
              'Similar seat positions available based on your seat selection',
              const Color(0xFFF59E0B),
            ),
            ...zoneMatches.map((m) =>
              _zoneMatchCard(m),
            ),
            const SizedBox(height: 16),
          ],

          // ── LAYER 4: SPLIT OPTIONS ─────────────
          if (splitOptions.isNotEmpty) ...[
            _sectionHeader(
              '🚌 Split Bus Option',
              'Travel same time on 2 buses',
              const Color(0xFF7C3AED),
            ),
            ...splitOptions.asMap().entries.map((entry) =>
              _splitOptionCard(entry.value, entry.key),
            ),
            const SizedBox(height: 16),
          ],

          // ── LAYER 5: DATE OPTIONS ──────────────
          if (exactMatches.isEmpty && zoneMatches.isEmpty) ...[
            _sectionHeader(
              '📅 Try Different Date',
              'Prices and availability by day',
              const Color(0xFF0891B2),
            ),
            _buildDateCalendar(),
            const SizedBox(height: 16),
          ],

          // ── NO RESULTS MESSAGE ─────────────────
          if (exactMatches.isEmpty &&
              nearbyMatches.isEmpty &&
              zoneMatches.isEmpty &&
              splitOptions.isEmpty) ...[
            _buildNoResultsCard(),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(
    String title,
    String subtitle,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    fontFamily:
                      GoogleFonts.poppins()
                      .fontFamily,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
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

  // Exact match bus card
  Widget _exactBusCard(BusModel bus) {
    final cheapPrice = bus.platforms.values
      .reduce((a, b) => a < b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF16A34A),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A)
              .withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius:
                    BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF16A34A),
                  ),
                ),
                child: Text(
                  '✅ All seats available',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                    fontFamily:
                      GoogleFonts.poppins()
                      .fontFamily,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                bus.layout,
                style: TextStyle(
                  fontSize: 10,
                  color: const Color(0xFF64748B),
                  fontFamily:
                    GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
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
                        fontWeight: FontWeight.w700,
                        color:
                          const Color(0xFF1E293B),
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                      ),
                    ),
                    Text(
                      '${bus.departure} → '
                      '${bus.arrival}  '
                      '· ${bus.duration}',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                          const Color(0xFF64748B),
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment:
                  CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹$cheapPrice',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color:
                        const Color(0xFF1A56DB),
                      fontFamily:
                        GoogleFonts.poppins()
                        .fontFamily,
                    ),
                  ),
                  Text(
                    'per person',
                    style: TextStyle(
                      fontSize: 9,
                      color:
                        const Color(0xFF94A3B8),
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
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                      PlatformScreen(
                        bus: bus,
                        from: widget.from,
                        to: widget.to,
                        date: widget.date,
                        mode: 'Position',
                        selectedSeats:
                          widget.selectedSeats,
                        seatCount:
                          widget.selectedSeats.length,
                      ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                  const Color(0xFF1A56DB),
                shape: RoundedRectangleBorder(
                  borderRadius:
                    BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Book This Bus →',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily:
                    GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nearby suggestion card
  Widget _nearbySuggestionCard(
    Map<String, dynamic> match,
  ) {
    final buses = match['buses'] as List<BusModel>;
    final original = match['original'] as String;
    final suggested = match['suggested'] as String;
    final busCount = match['busCount'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: Column(
        crossAxisAlignment:
          CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                  const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3,
                  ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius:
                    BorderRadius.circular(20),
                ),
                child: Text(
                  '$busCount buses available',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A56DB),
                    fontFamily:
                      GoogleFonts.poppins()
                      .fontFamily,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                fontFamily: GoogleFonts.poppins()
                  .fontFamily,
                color: const Color(0xFF1E293B),
              ),
              children: [
                const TextSpan(
                  text: 'Change ',
                ),
                TextSpan(
                  text: original,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                    decoration:
                      TextDecoration.lineThrough,
                  ),
                ),
                const TextSpan(text: ' → '),
                TextSpan(
                  text: suggested,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Go back to seat selection with seat replacement data
                Navigator.pop(context, {
                  'replaceSeat': original,
                  'withSeat': suggested,
                });
              },
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
                'Use $suggested instead →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A56DB),
                  fontFamily:
                    GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Zone match card
  Widget _zoneMatchCard(
    Map<String, dynamic> match,
  ) {
    final bus = match['bus'] as BusModel;
    final zones = match['zones'] as List;
    final matchedSeats = match['matchedSeats'] as List<String>;
    final cheapPrice = bus.platforms.values
      .reduce((a, b) => a < b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment:
          CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                    CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus.operator,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                      ),
                    ),
                    Text(
                      '${zones.join(' & ')} area '
                      'seats available',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                      ),
                    ),
                    Text(
                      bus.departure,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment:
                  CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹$cheapPrice',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A56DB),
                      fontFamily:
                        GoogleFonts.poppins()
                        .fontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                      const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3,
                      ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius:
                        BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    child: Text(
                      'Area match',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF59E0B),
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                      PlatformScreen(
                        bus: bus,
                        from: widget.from,
                        to: widget.to,
                        date: widget.date,
                        mode: 'Position',
                        selectedSeats: matchedSeats,
                        seatCount: matchedSeats.length,
                      ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                  const Color(0xFFF59E0B),
                shape: RoundedRectangleBorder(
                  borderRadius:
                    BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Book This Bus →',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily:
                    GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Split option card
  Widget _splitOptionCard(
    Map<String, dynamic> match,
    int index,
  ) {
    final bus1 = match['bus1'] as BusModel;
    final bus2 = match['bus2'] as BusModel;
    final bus1Seats =
      match['bus1Seats'] as List<String>;
    final bus2Seats =
      match['bus2Seats'] as List<String>;
    final timeDiff = match['timeDiff'] as int;

    // Initialize checkbox states if not present
    if (!_splitCardSelected.containsKey(index)) {
      _splitCardSelected[index] = false;
      _splitGroupSelected[index] = {'Group 1': false, 'Group 2': false};
    }

    final cardSelected = _splitCardSelected[index] ?? false;
    final group1Selected = _splitGroupSelected[index]?['Group 1'] ?? false;
    final group2Selected = _splitGroupSelected[index]?['Group 2'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cardSelected
            ? const Color(0xFF7C3AED)
            : const Color(0xFFE9D5FF),
        ),
      ),
      child: Column(
        crossAxisAlignment:
          CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: cardSelected,
                onChanged: (value) {
                  setState(() {
                    _splitCardSelected[index] = value ?? false;
                    // When card is selected, select all groups
                    if (value ?? false) {
                      _splitGroupSelected[index] = {'Group 1': true, 'Group 2': true};
                    } else {
                      _splitGroupSelected[index] = {'Group 1': false, 'Group 2': false};
                    }
                  });
                },
                activeColor: const Color(0xFF7C3AED),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius:
                      BorderRadius.circular(20),
                  ),
                  child: Text(
                    timeDiff == 0
                      ? 'Same departure time'
                      : '$timeDiff min apart · '
                        'meet at destination',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7C3AED),
                      fontFamily:
                        GoogleFonts.poppins()
                        .fontFamily,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Bus 1
          _splitBusRow(
            bus1,
            bus1Seats,
            'Group 1',
            const Color(0xFF1A56DB),
            index,
            group1Selected,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 6,
            ),
            child: Divider(height: 1),
          ),
          // Bus 2
          _splitBusRow(
            bus2,
            bus2Seats,
            'Group 2',
            const Color(0xFF7C3AED),
            index,
            group2Selected,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: (group1Selected && group2Selected)
                ? () {
                    HapticFeedback.mediumImpact();
                    // Navigate to platform screen for first bus
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                          PlatformScreen(
                            bus: bus1,
                            from: widget.from,
                            to: widget.to,
                            date: widget.date,
                            mode: 'Position',
                            selectedSeats: bus1Seats,
                            seatCount: bus1Seats.length,
                          ),
                      ),
                    );
                  }
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                  const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(
                  borderRadius:
                    BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Book Both Groups →',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily:
                    GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _splitBusRow(
    BusModel bus,
    List<String> seats,
    String groupLabel,
    Color color,
    int cardIndex,
    bool groupSelected,
  ) {
    final cheapPrice = bus.platforms.values
      .reduce((a, b) => a < b ? a : b);

    return Row(
      children: [
        Checkbox(
          value: groupSelected,
          onChanged: (value) {
            setState(() {
              _splitGroupSelected[cardIndex]![groupLabel] = value ?? false;
              // Update card selection based on group selections
              final g1 = _splitGroupSelected[cardIndex]?['Group 1'] ?? false;
              final g2 = _splitGroupSelected[cardIndex]?['Group 2'] ?? false;
              _splitCardSelected[cardIndex] = g1 && g2;
            });
          },
          activeColor: color,
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 2,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius:
              BorderRadius.circular(6),
          ),
          child: Text(
            groupLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: GoogleFonts.poppins()
                .fontFamily,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment:
              CrossAxisAlignment.start,
            children: [
              Text(
                bus.operator,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                  fontFamily:
                    GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
              Text(
                '${bus.departure} · '
                'Seats: ${seats.join(', ')}',
                style: TextStyle(
                  fontSize: 10,
                  color: const Color(0xFF64748B),
                  fontFamily:
                    GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
            ],
          ),
        ),
        Text(
          '₹$cheapPrice',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A56DB),
            fontFamily: GoogleFonts.poppins()
              .fontFamily,
          ),
        ),
      ],
    );
  }

  // Date calendar widget
  Widget _buildDateCalendar() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dateOptions.length,
        itemBuilder: (_, i) {
          final d = dateOptions[i];
          final available =
            d['allAvailable'] as bool;
          final busCount = d['busCount'] as int;
          final price =
            d['estimatedPrice'] as int;
          final dateStr = d['dateStr'] as String;

          return GestureDetector(
            onTap: available
              ? () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context)
                    .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Switched to $dateStr',
                      ),
                      backgroundColor:
                        const Color(0xFF1A56DB),
                      duration: const Duration(
                        seconds: 2,
                      ),
                    ),
                  );
                }
              : null,
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(
                right: 8,
              ),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: available
                  ? Colors.white
                  : const Color(0xFFF8FAFC),
                borderRadius:
                  BorderRadius.circular(12),
                border: Border.all(
                  color: available
                    ? const Color(0xFF1A56DB)
                    : const Color(0xFFE2E8F0),
                  width: available ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment:
                  MainAxisAlignment.center,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: available
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF94A3B8),
                      fontFamily:
                        GoogleFonts.poppins()
                        .fontFamily,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  if (available) ...[
                    Text(
                      '₹$price',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(
                          0xFF1A56DB,
                        ),
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                      ),
                    ),
                    Text(
                      '$busCount buses',
                      style: TextStyle(
                        fontSize: 9,
                        color: const Color(
                          0xFF16A34A,
                        ),
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                      ),
                    ),
                  ] else
                    Text(
                      'No match',
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoResultsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            'No matches found',
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
            'This route may have limited buses.\n'
            'Try a different date or modify '
            'your seat selection.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontFamily: GoogleFonts.poppins()
                .fontFamily,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
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
                'Modify Seat Selection',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A56DB),
                  fontFamily:
                    GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
