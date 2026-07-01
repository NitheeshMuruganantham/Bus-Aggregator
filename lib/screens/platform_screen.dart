import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bus_model.dart';

class PlatformScreen extends StatelessWidget {
  final BusModel bus;
  final String from;
  final String to;
  final String date;
  final String timeSlot;
  final List<String> selectedSeats;

  const PlatformScreen({
    super.key,
    required this.bus,
    required this.from,
    required this.to,
    required this.date,
    required this.timeSlot,
    required this.selectedSeats,
  });

  DateTime _parseDate(String dateStr) {
    // Parse format like "Wed, Jul 1" or "Wed, Jul 1, 2024"
    final parts = dateStr.split(', ');
    if (parts.length < 2) {
      return DateTime.now();
    }
    
    final monthDay = parts[1].split(' ');
    if (monthDay.length < 2) {
      return DateTime.now();
    }
    
    final monthStr = monthDay[0];
    final dayStr = monthDay[1];
    
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
      'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
      'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    
    final month = months[monthStr] ?? 1;
    final day = int.tryParse(dayStr) ?? 1;
    final year = parts.length >= 3 
      ? int.tryParse(parts[2]) ?? DateTime.now().year
      : DateTime.now().year;
    
    return DateTime(year, month, day);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    const days = [
      'Mon','Tue','Wed','Thu',
      'Fri','Sat','Sun',
    ];
    return '${days[d.weekday-1]}, '
      '${months[d.month-1]} ${d.day}';
  }

  Color _platformColor(String name) {
    switch (name.toLowerCase()) {
      case 'redbus':
        return const Color(0xFFD84040);
      case 'abhibus':
        return const Color(0xFF0077B6);
      case 'makemytrip':
        return const Color(0xFFE8A838);
      case 'ixigo':
        return const Color(0xFF7B2FBE);
      default:
        return const Color(0xFF1A56DB);
    }
  }

  String _platformTag(String name) {
    switch (name.toLowerCase()) {
      case 'redbus':   return 'Most Popular';
      case 'abhibus':  return 'Govt Buses';
      case 'makemytrip': return 'Best Offers';
      case 'ixigo':    return 'Price Alerts';
      default:         return '';
    }
  }

  String _buildDeepLink(
    String platform, String from,
    String to, DateTime date,
  ) {
    final f = from.toLowerCase()
      .replaceAll(' ', '-');
    final t = to.toLowerCase()
      .replaceAll(' ', '-');
    switch (platform.toLowerCase()) {
      case 'redbus':
        return 'https://www.redbus.in/'
          'bus-tickets/$f-to-$t';
      case 'abhibus':
        return 'https://www.abhibus.com/'
          'bus/$from/$to/'
          '${date.day}-${date.month}'
          '-${date.year}';
      case 'makemytrip':
        return 'https://www.makemytrip.com/'
          'bus-tickets/$f-to-$t.html';
      case 'ixigo':
        return 'https://www.ixigo.com/'
          'bus/search/$from/$to/'
          '${date.day}-${date.month}'
          '-${date.year}/1';
      default:
        return 'https://www.redbus.in';
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsedDate = _parseDate(date);
    final sortedPlatforms =
      bus.platforms.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final cheapestName =
      sortedPlatforms.first.key;
    final mostExpensive =
      sortedPlatforms.last.value;
    final cheapestPrice =
      sortedPlatforms.first.value;
    final savings =
      mostExpensive - cheapestPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [

          // ── BLUE GRADIENT APP BAR ──────────────
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
                            BorderRadius
                            .circular(10),
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
                          CrossAxisAlignment
                          .start,
                        children: [
                          Text(
                            '$from → $to',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                                FontWeight.w700,
                              fontFamily:
                                GoogleFonts
                                .poppins()
                                .fontFamily,
                            ),
                          ),
                          Text(
                            '${_formatDate(parsedDate)}'
                            ' · $timeSlot',
                            style: TextStyle(
                              color: const Color(
                                0xFFBFDBFE,
                              ),
                              fontSize: 11,
                              fontFamily:
                                GoogleFonts
                                .poppins()
                                .fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bus info card inside app bar
                Container(
                  padding: const EdgeInsets.all(
                    12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white
                      .withOpacity(0.15),
                    borderRadius:
                      BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white
                        .withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bus.operator,
                              style: TextStyle(
                                color:
                                  Colors.white,
                                fontSize: 14,
                                fontWeight:
                                  FontWeight.w700,
                                fontFamily:
                                  GoogleFonts
                                  .poppins()
                                  .fontFamily,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: Color(
                                  0xFFFCD34D,
                                ),
                              ),
                              const SizedBox(
                                width: 3,
                              ),
                              Text(
                                bus.rating
                                  .toString(),
                                style: TextStyle(
                                  color:
                                    Colors.white,
                                  fontSize: 11,
                                  fontWeight:
                                    FontWeight.w700,
                                  fontFamily:
                                    GoogleFonts
                                    .poppins()
                                    .fontFamily,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Container(
                                padding:
                                  const EdgeInsets
                                  .symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                decoration:
                                  BoxDecoration(
                                  color: Colors
                                    .white
                                    .withOpacity(
                                      0.2,
                                    ),
                                  borderRadius:
                                    BorderRadius
                                    .circular(6),
                                ),
                                child: Text(
                                  bus.layout,
                                  style: TextStyle(
                                    color:
                                      Colors.white,
                                    fontSize: 10,
                                    fontWeight:
                                      FontWeight
                                      .w600,
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            bus.departure,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight:
                                FontWeight.w700,
                              fontFamily:
                                GoogleFonts
                                .poppins()
                                .fontFamily,
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '── ${bus.duration}'
                                ' ──',
                                style: TextStyle(
                                  color: Colors
                                    .white
                                    .withOpacity(
                                      0.6,
                                    ),
                                  fontSize: 10,
                                  fontFamily:
                                    GoogleFonts
                                    .poppins()
                                    .fontFamily,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            bus.arrival,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight:
                                FontWeight.w700,
                              fontFamily:
                                GoogleFonts
                                .poppins()
                                .fontFamily,
                            ),
                          ),
                        ],
                      ),
                      if (selectedSeats
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: selectedSeats
                            .map((s) => Container(
                              padding:
                                const EdgeInsets
                                .symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                              decoration:
                                BoxDecoration(
                                color: Colors
                                  .white
                                  .withOpacity(
                                    0.2,
                                  ),
                                borderRadius:
                                  BorderRadius
                                  .circular(20),
                              ),
                              child: Text(
                                s,
                                style: TextStyle(
                                  color:
                                    Colors.white,
                                  fontSize: 10,
                                  fontWeight:
                                    FontWeight
                                    .w600,
                                  fontFamily:
                                    GoogleFonts
                                    .poppins()
                                    .fontFamily,
                                ),
                              ),
                            ))
                            .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── BODY ──────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16, 16, 16,
                MediaQuery.of(context)
                  .padding.bottom + 16,
              ),
              child: Column(
                children: [

                  // Savings banner
                  if (savings > 0)
                    Container(
                      width: double.infinity,
                      padding:
                        const EdgeInsets.all(12),
                      margin: const EdgeInsets
                        .only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFF0FDF4,
                        ),
                        borderRadius:
                          BorderRadius
                          .circular(12),
                        border: Border.all(
                          color: const Color(
                            0xFFBBF7D0,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.savings_outlined,
                            color:
                              Color(0xFF16A34A),
                            size: 18,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: Text(
                              'Book on the cheapest '
                              'platform and save '
                              '₹$savings',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                  FontWeight.w600,
                                color: const Color(
                                  0xFF16A34A,
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
                    ),

                  // "Choose where to book" header
                  Padding(
                    padding: const EdgeInsets
                      .only(bottom: 12),
                    child: Row(
                      children: [
                        Text(
                          'Choose where to book',
                          style: TextStyle(
                            fontSize: 15,
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
                        const Spacer(),
                        Text(
                          'Prices may vary',
                          style: TextStyle(
                            fontSize: 10,
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

                  // Platform cards
                  ...sortedPlatforms.map((entry) {
                    final name = entry.key;
                    final price = entry.value;
                    final color =
                      _platformColor(name);
                    final tag = _platformTag(name);
                    final isCheapest =
                      name == cheapestName;
                    final deepLink = _buildDeepLink(
                      name, from, to, parsedDate,
                    );

                    return Container(
                      margin: const EdgeInsets
                        .only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                          BorderRadius
                          .circular(14),
                        border: Border.all(
                          color: isCheapest
                            ? color
                            : const Color(
                                0xFFE2E8F0,
                              ),
                          width:
                            isCheapest ? 1.5 : 1,
                        ),
                        boxShadow: isCheapest
                          ? [
                              BoxShadow(
                                color: color
                                  .withOpacity(
                                    0.12,
                                  ),
                                blurRadius: 8,
                                offset:
                                  const Offset(
                                    0, 2,
                                  ),
                              ),
                            ]
                          : [],
                      ),
                      child: Column(
                        children: [
                          // Color accent bar top
                          Container(
                            height: 4,
                            decoration:
                              BoxDecoration(
                              color: color,
                              borderRadius:
                                const BorderRadius
                                .only(
                                topLeft:
                                  Radius
                                  .circular(13),
                                topRight:
                                  Radius
                                  .circular(13),
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                              const EdgeInsets
                              .all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                      CrossAxisAlignment
                                      .start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            name,
                                            style:
                                              TextStyle(
                                              fontSize:
                                                14,
                                              fontWeight:
                                                FontWeight
                                                .w700,
                                              color:
                                                const Color(
                                                0xFF1E293B,
                                              ),
                                              fontFamily:
                                                GoogleFonts
                                                .poppins()
                                                .fontFamily,
                                            ),
                                          ),
                                          if (isCheapest) ...[
                                            const SizedBox(
                                              width:
                                                6,
                                            ),
                                            Container(
                                              padding:
                                                const EdgeInsets
                                                .symmetric(
                                                horizontal:
                                                  6,
                                                vertical:
                                                  2,
                                              ),
                                              decoration:
                                                BoxDecoration(
                                                color:
                                                  const Color(
                                                  0xFFF0FDF4,
                                                ),
                                                borderRadius:
                                                  BorderRadius
                                                  .circular(
                                                    20,
                                                  ),
                                                border:
                                                  Border.all(
                                                  color:
                                                    const Color(
                                                    0xFF16A34A,
                                                  ),
                                                ),
                                              ),
                                              child:
                                                Text(
                                                '💰 Cheapest',
                                                style:
                                                  TextStyle(
                                                  fontSize:
                                                    9,
                                                  fontWeight:
                                                    FontWeight
                                                    .w700,
                                                  color:
                                                    const Color(
                                                    0xFF16A34A,
                                                  ),
                                                  fontFamily:
                                                    GoogleFonts
                                                    .poppins()
                                                    .fontFamily,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (tag
                                          .isNotEmpty)
                                        Text(
                                          tag,
                                          style:
                                            TextStyle(
                                            fontSize:
                                              10,
                                            color:
                                              const Color(
                                              0xFF94A3B8,
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
                                Column(
                                  crossAxisAlignment:
                                    CrossAxisAlignment
                                    .end,
                                  children: [
                                    Text(
                                      '₹$price',
                                      style:
                                        TextStyle(
                                        fontSize:
                                          20,
                                        fontWeight:
                                          FontWeight
                                          .w800,
                                        color:
                                          color,
                                        fontFamily:
                                          GoogleFonts
                                          .poppins()
                                          .fontFamily,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 6,
                                    ),
                                    SizedBox(
                                      height: 36,
                                      child:
                                        ElevatedButton(
                                        onPressed:
                                          () async {
                                          HapticFeedback
                                            .mediumImpact();
                                          final uri =
                                            Uri.parse(
                                            deepLink,
                                          );
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(
                                              uri,
                                              mode: LaunchMode
                                                .externalApplication,
                                            );
                                          } else {
                                            if (context
                                              .mounted) {
                                              ScaffoldMessenger
                                                .of(
                                                context,
                                              )
                                                .showSnackBar(
                                                SnackBar(
                                                  content:
                                                    Text(
                                                    'Opening $name...',
                                                  ),
                                                  backgroundColor:
                                                    color,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        style:
                                          ElevatedButton
                                          .styleFrom(
                                          backgroundColor:
                                            color,
                                          foregroundColor:
                                            Colors
                                            .white,
                                          elevation:
                                            0,
                                          padding:
                                            const EdgeInsets
                                            .symmetric(
                                            horizontal:
                                              14,
                                          ),
                                          shape:
                                            RoundedRectangleBorder(
                                            borderRadius:
                                              BorderRadius
                                              .circular(
                                                8,
                                              ),
                                          ),
                                        ),
                                        child: Text(
                                          'Book Now',
                                          style:
                                            TextStyle(
                                            fontSize:
                                              12,
                                            fontWeight:
                                              FontWeight
                                              .w700,
                                            fontFamily:
                                              GoogleFonts
                                              .poppins()
                                              .fontFamily,
                                          ),
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
                  }),

                  const SizedBox(height: 16),

                  // Footer note
                  Container(
                    padding:
                      const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFF8FAFC,
                      ),
                      borderRadius:
                        BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(
                          0xFFE2E8F0,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color:
                            Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SeatFirst finds your seat.'
                            ' Partners complete your'
                            ' booking. You pay the'
                            ' same price.',
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
