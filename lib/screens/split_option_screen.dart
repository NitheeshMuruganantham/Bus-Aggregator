import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bus_model.dart';
import 'platform_screen.dart';

class SplitOptionScreen extends StatelessWidget {
  final List<Map<String, dynamic>> splitOptions;
  final String from;
  final String to;
  final String date;
  final String timeSlot;
  final List<String> selectedSeats;

  const SplitOptionScreen({
    super.key,
    required this.splitOptions,
    required this.from,
    required this.to,
    required this.date,
    required this.timeSlot,
    required this.selectedSeats,
  });

  IconData _amenityIconData(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'ac': return Icons.ac_unit;
      case 'wifi': return Icons.wifi;
      case 'charging': return Icons.bolt;
      case 'water': return Icons.water_drop;
      case 'blanket': return Icons.bed;
      case 'pillow':
        return Icons
          .airline_seat_legroom_extra;
      case 'snacks': return Icons.fastfood;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          // Blue gradient app bar
          Container(
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
              MediaQuery.of(context).padding.top
                + 12,
              16,
              16,
            ),
            child: Row(
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
                        '$from → $to',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                            FontWeight.w700,
                          fontFamily:
                            GoogleFonts.poppins()
                            .fontFamily,
                        ),
                      ),
                      Text(
                        '$date'
                        ' · $timeSlot',
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
              ],
            ),
          ),

          // Info banner
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
              16, 12, 16, 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_split,
                    color: Color(0xFF7C3AED),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                      CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Split Bus Option',
                        style: TextStyle(
                          fontSize: 13,
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
                        'No single bus has all '
                        'your seats. Travel on '
                        '2 buses at the same time.',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(
                            0xFF64748B,
                          ),
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
          ),

          // Split option cards
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                16, 12, 16,
                MediaQuery.of(context)
                  .padding.bottom + 16,
              ),
              itemCount: splitOptions.length,
              itemBuilder: (_, i) =>
                _buildSplitCard(
                  context,
                  splitOptions[i],
                  i,
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitCard(
    BuildContext context,
    Map<String, dynamic> option,
    int index,
  ) {
    final bus1 = option['bus1'] as BusModel;
    final bus2 = option['bus2'] as BusModel;
    final bus1Seats =
      option['bus1Seats'] as List<String>;
    final bus2Seats =
      option['bus2Seats'] as List<String>;
    final timeDiff =
      option['timeDiff'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE9D5FF),
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F3FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.call_split,
                  color: Color(0xFF7C3AED),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Option ${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7C3AED),
                    fontFamily:
                      GoogleFonts.poppins()
                      .fontFamily,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                    const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3,
                    ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED)
                      .withOpacity(0.1),
                    borderRadius:
                      BorderRadius.circular(20),
                  ),
                  child: Text(
                    timeDiff == 0
                      ? 'Same time'
                      : '${timeDiff}min apart',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(
                        0xFF7C3AED,
                      ),
                      fontFamily:
                        GoogleFonts.poppins()
                        .fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Bus 1 block
                _buildSplitBusBlock(
                  context,
                  bus: bus1,
                  seats: bus1Seats,
                  groupLabel: 'Group 1',
                  groupColor:
                    const Color(0xFF1A56DB),
                ),

                // Divider with + icon
                Padding(
                  padding: const EdgeInsets
                    .symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(
                            0xFFE2E8F0,
                          ),
                        ),
                      ),
                      Container(
                        margin:
                          const EdgeInsets
                          .symmetric(
                            horizontal: 8,
                          ),
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF0F4F8,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFE2E8F0,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 14,
                          color: Color(0xFF64748B),
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
                ),

                // Bus 2 block
                _buildSplitBusBlock(
                  context,
                  bus: bus2,
                  seats: bus2Seats,
                  groupLabel: 'Group 2',
                  groupColor:
                    const Color(0xFF7C3AED),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitBusBlock(
    BuildContext context, {
    required BusModel bus,
    required List<String> seats,
    required String groupLabel,
    required Color groupColor,
  }) {
    final cheapPrice = bus.platforms.values
      .reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: groupColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: groupColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
          CrossAxisAlignment.start,
        children: [
          // Group label + seats
          Row(
            children: [
              Container(
                padding:
                  const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3,
                  ),
                decoration: BoxDecoration(
                  color: groupColor
                    .withOpacity(0.1),
                  borderRadius:
                    BorderRadius.circular(20),
                ),
                child: Text(
                  groupLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: groupColor,
                    fontFamily:
                      GoogleFonts.poppins()
                      .fontFamily,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  children: seats.map((s) =>
                    Container(
                      padding:
                        const EdgeInsets
                        .symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                      decoration: BoxDecoration(
                        color: groupColor
                          .withOpacity(0.08),
                        borderRadius:
                          BorderRadius
                          .circular(20),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                            FontWeight.w600,
                          color: groupColor,
                          fontFamily:
                            GoogleFonts.poppins()
                            .fontFamily,
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Operator + rating
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
                        color: const Color(
                          0xFF1E293B,
                        ),
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                    ),
                    ),
                    Text(
                      bus.busType,
                      style: TextStyle(
                        fontSize: 10,
                        color: const Color(
                          0xFF64748B,
                        ),
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                    ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    size: 11,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    bus.rating.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(
                        0xFF92400E,
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

          const SizedBox(height: 6),

          // Time row
          Row(
            children: [
              Text(
                bus.departure,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                  fontFamily: GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    bus.duration,
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
                ),
              ),
              Text(
                bus.arrival,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                  fontFamily: GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
            ],
          ),

          // Amenities
          if (bus.amenities.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: bus.amenities
                .take(3)
                .map((a) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _amenityIconData(a),
                      size: 11,
                      color: const Color(
                        0xFF1A56DB,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      a,
                      style: TextStyle(
                        fontSize: 9,
                        color: const Color(
                          0xFF64748B,
                        ),
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                      ),
                    ),
                  ],
                ))
                .toList(),
            ),
          ],

          const SizedBox(height: 8),

          // Price + individual View Platforms
          Row(
            children: [
              Text(
                '₹$cheapPrice',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A56DB),
                  fontFamily: GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                        PlatformScreen(
                          bus: bus,
                          from: from,
                          to: to,
                          date: date,
                          timeSlot: timeSlot,
                          selectedSeats: seats,
                        ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: groupColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                      BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'View Platforms',
                  style: TextStyle(
                    fontSize: 11,
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
    );
  }
}
