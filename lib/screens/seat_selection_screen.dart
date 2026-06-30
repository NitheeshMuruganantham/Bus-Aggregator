import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/mock_data.dart';
import '../models/bus_model.dart';
import '../utils/seat_filter_logic.dart';
import 'bus_list_screen.dart';
import 'smart_suggestion_screen.dart';
import 'platform_screen.dart';

const _kBg = Color(0xFFF0F4F8);
const _kCardBg = Color(0xFFFFFFFF);
const _kBrandBlue = Color(0xFF1A56DB);
const _kBrandBlueDark = Color(0xFF1E3A8A);
const _kTextPrimary = Color(0xFF1E293B);
const _kTextSecondary = Color(0xFF64748B);
const _kTextMuted = Color(0xFF94A3B8);
const _kBorder = Color(0xFFE2E8F0);
const _kFieldBg = Color(0xFFF8FAFC);
const _kBlueLightBg = Color(0xFFEFF6FF);
const _kBlueLightBorder = Color(0xFFBFDBFE);
const _kGreenBg = Color(0xFFF0FDF4);
const _kGreenText = Color(0xFF16A34A);
const _kRed = Color(0xFFEF4444);
const _kYellow = Color(0xFFF59E0B);

const _layouts = ['2+1', '2+2', 'Sleeper', 'Mixed'];

class SeatSelectionScreen extends StatefulWidget {
  final String from;
  final String to;
  final String date;
  final String timeSlot;

  const SeatSelectionScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
    required this.timeSlot,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  // Active template
  String activeTemplate = 'Seater';

  // Position vs Count mode
  bool isPositionMode = true;

  // Current date (can be changed via date selection)
  String _currentDate;

  // Cross-template seat selection
  // Persists when switching tabs
  Map<String, List<String>> allSelectedSeats = {
    'Seater': [],
    'Lower':  [],
    'Upper':  [],
  };

  // Tracks user's type choice per seat
  // seatId -> 'women' or 'general'
  Map<String, String> seatTypePreference = {};

  // Count mode seat counts
  Map<String, int> templateCounts = {
    'Seater': 0,
    'Lower': 0,
    'Upper': 0,
  };

  // Template data (counts + bus maps)
  TemplateData? templateData;

  // All buses for this route
  List<BusModel> routeBuses = [];

  // Loading state
  bool isLoadingTemplate = true;

  double _rotationY3d = 0.0;
  double _rotationX3d = -0.15;
  final double _scale3d = 1.0;

  List<BusModel> get _allBuses => getMockBuses();

  _SeatSelectionScreenState() : _currentDate = '';

  @override
  void initState() {
    super.initState();
    _currentDate = widget.date;
    _loadTemplateData();
  }

  // Get selections across all templates
  List<String> get allSelectedSeatsList => [
    ...allSelectedSeats['Seater']!,
    ...allSelectedSeats['Lower']!,
    ...allSelectedSeats['Upper']!,
  ];

  // Total selected count
  int get totalSelected =>
    allSelectedSeatsList.length;

  // Total count mode seats
  int get totalCountModeSeats =>
    templateCounts.values.fold(0, (sum, val) => sum + val);

  void _loadTemplateData() {
    setState(() => isLoadingTemplate = true);

    // Simulate API delay
    Future.delayed(
      const Duration(milliseconds: 600), () {
      // Get buses for this route
      final buses = getMockBuses().where((b) =>
        b.from.toLowerCase() ==
          widget.from.toLowerCase() &&
        b.to.toLowerCase() ==
          widget.to.toLowerCase()
      ).toList();

      final data = UniversalTemplateLogic
        .buildTemplateData(buses);

      if (mounted) {
        setState(() {
          routeBuses = buses;
          templateData = data;
          isLoadingTemplate = false;
        });
      }
    });
  }

  // Clear all selections
  void _clearAllSelections() {
    setState(() {
      allSelectedSeats = {
        'Seater': [],
        'Lower':  [],
        'Upper':  [],
      };
      seatTypePreference = {};
    });
  }

  // Toggle between Position and Count mode
  void _onModeToggle(bool toPosition) {
    HapticFeedback.lightImpact();
    setState(() {
      isPositionMode = toPosition;
      if (toPosition) {
        templateCounts = {
          'Seater': 0, 'Lower': 0, 'Upper': 0,
        };
      } else {
        allSelectedSeats = {
          'Seater': [], 'Lower': [], 'Upper': [],
        };
      }
    });
  }

  // Toggle seat in active template
  void _onSeatTap(String seatId) {
    final isSelected = allSelectedSeats[
      activeTemplate]!.contains(seatId);

    // If deselecting, just remove normally
    if (isSelected) {
      HapticFeedback.lightImpact();
      setState(() {
        allSelectedSeats[activeTemplate]!
          .remove(seatId);
      });
      return;
    }

    // Only check women-only split for Seater
    if (activeTemplate == 'Seater') {
      final hasMixed = UniversalTemplateLogic
        .hasMixedAvailability(seatId, routeBuses);

      if (hasMixed) {
        _showSeatTypeChooser(seatId);
        return;
      }
    }

    // No mixed availability — select normally
    HapticFeedback.lightImpact();
    setState(() {
      allSelectedSeats[activeTemplate]!.add(seatId);
    });
  }

  void _toggleSeat(String seatId) {
    HapticFeedback.lightImpact();
    setState(() {
      final list =
        allSelectedSeats[activeTemplate]!;
      if (list.contains(seatId)) {
        list.remove(seatId);
      } else {
        list.add(seatId);
      }
    });
  }

  void _showSeatTypeChooser(String seatId) {
    final womenBuses = UniversalTemplateLogic
      .getWomenOnlyBuses(seatId, routeBuses);
    final generalBuses = UniversalTemplateLogic
      .getGeneralBuses(seatId, routeBuses)
      .where((b) =>
        b.availableSeats.contains(seatId))
      .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20,
          MediaQuery.of(ctx).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
            CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(
                bottom: 16,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius:
                  BorderRadius.circular(2),
              ),
            ),
            Text(
              'Seat $seatId — Choose type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
                fontFamily: GoogleFonts.poppins()
                  .fontFamily,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This seat position has both '
              'women-only and general options',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontFamily: GoogleFonts.poppins()
                  .fontFamily,
              ),
            ),
            const SizedBox(height: 16),

            // Women only option
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
                setState(() {
                  allSelectedSeats['Seater']!
                    .add(seatId);
                  seatTypePreference[seatId] =
                    'women';
                });
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius:
                    BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEC4899),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFEC4899,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.female,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                          CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Women Only',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                FontWeight.w700,
                              color: const Color(
                                0xFFBE185D,
                              ),
                              fontFamily:
                                GoogleFonts.poppins()
                                .fontFamily,
                            ),
                          ),
                          Text(
                            '${womenBuses.length} '
                            'bus(es) available',
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
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFEC4899),
                    ),
                  ],
                ),
              ),
            ),

            // General option
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
                setState(() {
                  allSelectedSeats['Seater']!
                    .add(seatId);
                  seatTypePreference[seatId] =
                    'general';
                });
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius:
                    BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1A56DB),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF1A56DB,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                          CrossAxisAlignment.start,
                        children: [
                          Text(
                            'General',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                FontWeight.w700,
                              color: const Color(
                                0xFF1A56DB,
                              ),
                              fontFamily:
                                GoogleFonts.poppins()
                                .fontFamily,
                            ),
                          ),
                          Text(
                            '${generalBuses.length} '
                            'bus(es) available',
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
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF1A56DB),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _poppins({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = _kTextPrimary,
    double? height,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  void _onFindBuses() {
  HapticFeedback.mediumImpact();

  if (isPositionMode) {
    // Existing position mode logic
    final allSeats = allSelectedSeatsList;
    if (allSeats.isEmpty) return;

    List<BusModel> _getEligibleBusesForSeats(
      List<String> seats,
    ) {
      List<BusModel> eligible = routeBuses;

      for (final seat in seats) {
        final pref = seatTypePreference[seat];
        if (pref == 'women') {
          eligible = eligible.where((bus) =>
            bus.womenOnlySeats.contains(seat)
          ).toList();
        } else if (pref == 'general') {
          eligible = eligible.where((bus) =>
            !bus.womenOnlySeats.contains(seat)
          ).toList();
        }
      }
      return eligible;
    }

    final eligibleBuses = _getEligibleBusesForSeats(allSeats);

    final exactMatches = eligibleBuses.where((bus) =>
      allSeats.every((seat) =>
        bus.availableSeats.contains(seat)
      )
    ).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartSuggestionScreen(
          from: widget.from,
          to: widget.to,
          date: _currentDate,
          timeSlot: widget.timeSlot,
          selectedSeats: allSeats,
          seaterSeats: allSelectedSeats['Seater']!,
          lowerSeats: allSelectedSeats['Lower']!,
          upperSeats: allSelectedSeats['Upper']!,
          exactMatches: exactMatches,
          allRouteBuses: routeBuses,
          templateData: templateData!,
        ),
      ),
    ).then((result) {
      // Handle result from smart suggestion screen
      if (result != null && result is Map) {
        // Handle date change
        final changeDate = result['changeDate'] as bool?;
        final newDate = result['newDate'] as String?;

        if (changeDate == true && newDate != null) {
          // Update the date and refresh the screen
          setState(() {
            _currentDate = newDate;
          });
          // Reload template data for new date
          _loadTemplateData();
          return;
        }

        // Handle seat replacement from suggestion
        final replaceSeat = result['replaceSeat'] as String?;
        final withSeat = result['withSeat'] as String?;

        if (replaceSeat != null && withSeat != null) {
          // Determine which template the seat belongs to
          String template = 'Seater';
          if (replaceSeat.startsWith('L')) {
            template = 'Lower';
          } else if (replaceSeat.startsWith('U')) {
            template = 'Upper';
          }

          setState(() {
            // Remove the old seat and add the new one
            allSelectedSeats[template]!.remove(replaceSeat);
            allSelectedSeats[template]!.add(withSeat);
          });
        }
      }
    });
  } else {
    // Count mode logic
    if (totalCountModeSeats == 0) return;

    final matchingBuses = routeBuses.where((bus) {
      bool matches = true;

      if ((templateCounts['Seater'] ?? 0) > 0) {
        final avail = bus.availableSeats
          .where((s) => UniversalTemplateLogic
            .isSeaterSeat(s))
          .length;
        if (avail < templateCounts['Seater']!) {
          matches = false;
        }
      }
      if ((templateCounts['Lower'] ?? 0) > 0) {
        final avail = bus.availableSeats
          .where((s) => UniversalTemplateLogic
            .isLowerBerth(s))
          .length;
        if (avail < templateCounts['Lower']!) {
          matches = false;
        }
      }
      if ((templateCounts['Upper'] ?? 0) > 0) {
        final avail = bus.availableSeats
          .where((s) => UniversalTemplateLogic
            .isUpperBerth(s))
          .length;
        if (avail < templateCounts['Upper']!) {
          matches = false;
        }
      }

      return matches;
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusListScreen(
          from: widget.from,
          to: widget.to,
          date: _currentDate,
          timeSlot: widget.timeSlot,
          layout: 'Mixed',
          mode: 'Count',
          selectedSeats: [],
          seatCount: totalCountModeSeats,
          buses: matchingBuses,
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildAppBar(),
          _buildRouteInfo(),
          _buildLayoutTabs(),
          Expanded(child: _buildSeatArea()),
          _buildBottomAction(),
        ],
      ),
    );
  }

  // ─── Section 1: App Bar ───────────────────────────────────────────────────

  Widget _buildAppBar() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kBrandBlue, _kBrandBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(8, topPadding + 12, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${widget.from} → ${widget.to}',
                  style: _poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$_currentDate · ${widget.timeSlot}',
                  style: _poppins(
                    fontSize: 11,
                    color: _kBlueLightBorder,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_bus, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  activeTemplate,
                  style: _poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 2: Route Info + Mode Toggle ──────────────────────────────────

  Widget _buildRouteInfo() {
    return Container(
      color: _kCardBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select your preferred seat',
                style: _poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // Mode toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _onModeToggle(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isPositionMode
                            ? _kBrandBlue
                            : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Position',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isPositionMode
                              ? Colors.white
                              : const Color(0xFF64748B),
                            fontFamily: GoogleFonts.poppins()
                              .fontFamily,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _onModeToggle(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: !isPositionMode
                            ? _kBrandBlue
                            : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: !isPositionMode
                              ? Colors.white
                              : const Color(0xFF64748B),
                            fontFamily: GoogleFonts.poppins()
                              .fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _legendItem(
                  icon: Icons.airline_seat_recline_normal,
                  iconColor: _kGreenText,
                  bg: _kGreenBg,
                  border: _kGreenText,
                  label: '3+ buses',
                ),
                _legendItem(
                  icon: Icons.airline_seat_recline_normal,
                  iconColor: _kYellow,
                  bg: const Color(0xFFFFFBEB),
                  border: _kYellow,
                  label: '1-2 buses',
                ),
                _legendItem(
                  icon: Icons.airline_seat_recline_normal,
                  iconColor: _kTextMuted,
                  bg: const Color(0xFFF1F5F9),
                  border: const Color(0xFFCBD5E1),
                  label: 'Unavailable',
                ),
                _legendItem(
                  icon: Icons.airline_seat_recline_normal,
                  iconColor: Colors.white,
                  bg: _kBrandBlue,
                  border: _kBrandBlue,
                  label: 'Selected',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required IconData icon,
    required Color iconColor,
    required Color bg,
    required Color border,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border, width: 1),
          ),
          child: Icon(icon, size: 13, color: iconColor),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: _poppins(
            fontSize: 10,
            color: _kTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Section 3: Layout Tabs ───────────────────────────────────────────────

  Widget _buildLayoutTabs() {
    return Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(
      16, 8, 16, 8,
    ),
    child: Row(
      children: [
        _templateTab(
          'Seater',
          Icons.airline_seat_recline_normal,
          allSelectedSeats['Seater']!.length,
        ),
        const SizedBox(width: 8),
        _templateTab(
          'Lower',
          Icons.bed_outlined,
          allSelectedSeats['Lower']!.length,
        ),
        const SizedBox(width: 8),
        _templateTab(
          'Upper',
          Icons.airline_seat_flat,
          allSelectedSeats['Upper']!.length,
        ),
      ],
    ),
  );
}

Widget _templateTab(
  String template,
  IconData icon,
  int selectedCount,
) {
  final isActive = activeTemplate == template;
  final screenW =
    MediaQuery.of(context).size.width;
  final tabW = (screenW - 56) / 3;

  return GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      setState(() => activeTemplate = template);
    },
    child: AnimatedContainer(
      duration: const Duration(
        milliseconds: 200,
      ),
      width: tabW,
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isActive
          ? const Color(0xFF1A56DB)
          : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
            ? const Color(0xFF1A56DB)
            : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: isActive
          ? [
              BoxShadow(
                color: const Color(0xFF1A56DB)
                  .withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : [],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
              MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive
                  ? Colors.white
                  : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                template,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive
                    ? Colors.white
                    : const Color(0xFF1E293B),
                  fontFamily:
                    GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
            ],
          ),
          // Show selected count badge
          if (selectedCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding:
                const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
              decoration: BoxDecoration(
                color: isActive
                  ? Colors.white
                    .withOpacity(0.25)
                  : const Color(0xFF1A56DB),
                borderRadius:
                  BorderRadius.circular(10),
              ),
              child: Text(
                '$selectedCount selected',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isActive
                    ? Colors.white
                    : Colors.white,
                  fontFamily:
                    GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  // ─── Section 4: Seat Area ─────────────────────────────────────────────────

  Widget _buildSeatArea() {
    if (isPositionMode) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: _buildSeatGrid(),
      );
    } else {
      return _buildCountModeBody();
    }
  }

  Widget _buildCountModeBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16, 16, 16, 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            'How many seats do you need?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
              fontFamily: GoogleFonts.poppins()
                .fontFamily,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set count for each seat type you need',
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF64748B),
              fontFamily: GoogleFonts.poppins()
                .fontFamily,
            ),
          ),
          const SizedBox(height: 16),

          _countCard(
            label: 'Seater',
            subtitle: 'Regular seat (2+2)',
            icon: Icons.airline_seat_recline_normal,
            color: const Color(0xFF1A56DB),
            template: 'Seater',
          ),
          const SizedBox(height: 12),

          _countCard(
            label: 'Lower Berth',
            subtitle: 'Sleeper - bottom deck',
            icon: Icons.bed_outlined,
            color: const Color(0xFF16A34A),
            template: 'Lower',
          ),
          const SizedBox(height: 12),

          _countCard(
            label: 'Upper Berth',
            subtitle: 'Sleeper - top deck',
            icon: Icons.airline_seat_flat,
            color: const Color(0xFF7C3AED),
            template: 'Upper',
          ),

          const SizedBox(height: 20),

          // Live availability preview
          if (totalCountModeSeats > 0)
            _buildAvailabilityPreview(),
        ],
      ),
    );
  }

  Widget _countCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String template,
  }) {
    final count = templateCounts[template] ?? 0;
    final isActive = count > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
            ? color
            : const Color(0xFFE2E8F0),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
          ? [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : [],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    fontFamily: GoogleFonts.poppins()
                      .fontFamily,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                    fontFamily: GoogleFonts.poppins()
                      .fontFamily,
                  ),
                ),
              ],
            ),
          ),

          // Minus button
          GestureDetector(
            onTap: count > 0
              ? () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    templateCounts[template] =
                      count - 1;
                  });
                }
              : null,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: count > 0
                  ? color.withOpacity(0.1)
                  : const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: count > 0
                    ? color
                    : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                Icons.remove,
                size: 14,
                color: count > 0
                  ? color
                  : const Color(0xFF94A3B8),
              ),
            ),
          ),

          SizedBox(
            width: 36,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isActive
                  ? color
                  : const Color(0xFF94A3B8),
                fontFamily: GoogleFonts.poppins()
                  .fontFamily,
              ),
            ),
          ),

          // Plus button
          GestureDetector(
            onTap: count < 10
              ? () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    templateCounts[template] =
                      count + 1;
                  });
                }
              : null,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: count < 10
                  ? color
                  : const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: count < 10
                    ? color
                    : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                Icons.add,
                size: 14,
                color: count < 10
                  ? Colors.white
                  : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityPreview() {
    if (templateData == null) return const SizedBox();

    // Count buses matching ALL requested counts
    final matchingBuses = routeBuses.where((bus) {
      bool matches = true;

      if ((templateCounts['Seater'] ?? 0) > 0) {
        final seaterAvail = bus.availableSeats
          .where((s) =>
            UniversalTemplateLogic.isSeaterSeat(s))
          .length;
        if (seaterAvail < templateCounts['Seater']!) {
          matches = false;
        }
      }
      if ((templateCounts['Lower'] ?? 0) > 0) {
        final lowerAvail = bus.availableSeats
          .where((s) =>
            UniversalTemplateLogic.isLowerBerth(s))
          .length;
        if (lowerAvail < templateCounts['Lower']!) {
          matches = false;
        }
      }
      if ((templateCounts['Upper'] ?? 0) > 0) {
        final upperAvail = bus.availableSeats
          .where((s) =>
            UniversalTemplateLogic.isUpperBerth(s))
          .length;
        if (upperAvail < templateCounts['Upper']!) {
          matches = false;
        }
      }

      return matches;
    }).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: matchingBuses > 0
          ? const Color(0xFFF0FDF4)
          : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: matchingBuses > 0
            ? const Color(0xFFBBF7D0)
            : const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            matchingBuses > 0
              ? Icons.check_circle
              : Icons.info_outline,
            color: matchingBuses > 0
              ? const Color(0xFF16A34A)
              : const Color(0xFFEF4444),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              matchingBuses > 0
                ? '$matchingBuses bus(es) match '
                  'your requirement'
                : 'No buses match this combination '
                  'yet — try adjusting counts',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: matchingBuses > 0
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFEF4444),
                fontFamily: GoogleFonts.poppins()
                  .fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusFront() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kBrandBlue.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: const Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_forward, color: _kBrandBlue, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Direction of travel',
                    style: _poppins(fontSize: 9, color: _kTextMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.radio_button_unchecked, color: _kTextMuted, size: 28),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kBrandBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _kBlueLightBorder),
                ),
                child: const Icon(Icons.person, color: _kBrandBlue, size: 20),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Driver', style: _poppins(fontSize: 10, color: _kTextMuted)),
                  Text(
                    'Front',
                    style: _poppins(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatGrid() {
    if (isLoadingTemplate) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            color: Color(0xFF1A56DB),
          ),
        ),
      );
    }

    if (templateData == null) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildTopViewBus(
          constraints.maxWidth,
        );
      },
    );
  }

  Widget _buildTopViewBus(double availW) {
    // Always 2+2 shell for Seater
    // Always 2+2 berth shell for Lower/Upper
    final isBerth = activeTemplate == 'Lower'
      || activeTemplate == 'Upper';
    final rowCount = isBerth ? 7 : 10;
    final shellW = availW - 32;

    // Adaptive seat size
    final seatW = ((shellW - 72) / 4)
      .clamp(36.0, 60.0);
    final seatH = isBerth
      ? seatW * 0.6   // berths are wider flatter
      : seatW * 1.15; // seats are taller
    final rowH = seatH + 20;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [

        // Front header
        _buildBusFrontHeader(),

        // Scrollable seat area
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Column headers
              _buildColumnHeaders(
                seatW, isBerth,
              ),

              // Seat rows
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4,
                ),
                child: Column(
                  children: List.generate(
                    rowCount, (idx) {
                    final row = idx + 1;
                    return _buildTopViewRow(
                      row: row,
                      seatW: seatW,
                      seatH: seatH,
                      rowH: rowH,
                      isBerth: isBerth,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),

        // Rear footer
        _buildBusRearFooter(),
      ],
    ),
  );
}

  Widget _buildColumnHeaders(
  double seatW, bool isBerth,
) {
  final cols = isBerth
    ? (activeTemplate == 'Lower'
        ? ['LA', 'LB', 'LC', 'LD']
        : ['UA', 'UB', 'UC', 'UD'])
    : ['A', 'B', 'C', 'D'];

  return Padding(
    padding: const EdgeInsets.fromLTRB(
      28, 8, 28, 4,
    ),
    child: Row(
      children: [
        const SizedBox(width: 20),
        // Left 2 columns
        SizedBox(
          width: seatW * 2 + 8,
          child: Row(
            mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
            children: [
              _colHeader(cols[0], seatW),
              const SizedBox(width: 8),
              _colHeader(cols[1], seatW),
            ],
          ),
        ),
        // Aisle
        const SizedBox(width: 20),
        // Right 2 columns
        SizedBox(
          width: seatW * 2 + 8,
          child: Row(
            mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
            children: [
              _colHeader(cols[2], seatW),
              const SizedBox(width: 8),
              _colHeader(cols[3], seatW),
            ],
          ),
        ),
        const SizedBox(width: 20),
      ],
    ),
  );
}

Widget _colHeader(String col, double seatW) {
  return SizedBox(
    width: seatW,
    child: Center(
      child: Text(
        col,
        style: TextStyle(
          color: const Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: GoogleFonts.poppins()
            .fontFamily,
        ),
      ),
    ),
  );
}

  Widget _buildTopViewRow({
  required int row,
  required double seatW,
  required double seatH,
  required double rowH,
  required bool isBerth,
}) {
  // Generate seat IDs based on template
  String _id(String col) {
    if (activeTemplate == 'Lower') {
      return 'L$row$col';
    } else if (activeTemplate == 'Upper') {
      return 'U$row$col';
    }
    return '$row$col';
  }

  return Container(
    height: rowH,
    margin: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment:
        CrossAxisAlignment.center,
      children: [

        // Row number left
        SizedBox(
          width: 20,
          child: Text(
            '$row',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: GoogleFonts.poppins()
                .fontFamily,
            ),
          ),
        ),

        const SizedBox(width: 4),

        // Seat content with fixed width
        SizedBox(
          width: seatW * 4 + 48, // 4 seats + spacing + aisle
          child: Row(
            children: [
              // Left 2 seats/berths
              Row(
                children: [
                  isBerth
                    ? _buildTopViewBerth(
                        _id('A'), seatW, seatH)
                    : _buildTopViewSeat(
                        _id('A'), seatW, seatH),
                  const SizedBox(width: 8),
                  isBerth
                    ? _buildTopViewBerth(
                        _id('B'), seatW, seatH)
                    : _buildTopViewSeat(
                        _id('B'), seatW, seatH),
                ],
              ),

              // Center aisle yellow line
              SizedBox(
                width: 20,
                child: Center(
                  child: Container(
                    width: 3,
                    height: rowH * 0.75,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B)
                        .withOpacity(0.7),
                      borderRadius:
                        BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Right 2 seats/berths
              Row(
                children: [
                  isBerth
                    ? _buildTopViewBerth(
                        _id('C'), seatW, seatH)
                    : _buildTopViewSeat(
                        _id('C'), seatW, seatH),
                  const SizedBox(width: 8),
                  isBerth
                    ? _buildTopViewBerth(
                        _id('D'), seatW, seatH)
                    : _buildTopViewSeat(
                        _id('D'), seatW, seatH),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 4),

        // Row number right
        SizedBox(
          width: 20,
          child: Text(
            '$row',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: GoogleFonts.poppins()
                .fontFamily,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTopViewSeat(
  String seatId,
  double seatW,
  double seatH,
) {
  final count = templateData?.getCount(
    seatId, activeTemplate,
  ) ?? 0;
  final isSelected = allSelectedSeats[
    activeTemplate]!.contains(seatId);
  final isAvailable = count > 0;

  final seaterBusesForThisSeat = routeBuses
    .where((b) => b.layout != 'Lower' &&
      b.layout != 'Upper' &&
      b.availableSeats.contains(seatId))
    .toList();

  final hasWomenOnly = UniversalTemplateLogic
    .getWomenOnlyBuses(
      seatId,
      activeTemplate == 'Seater'
        ? routeBuses
        : [], // only Seater template shows this
    ).isNotEmpty;

  final Color seatColor = isSelected
    ? const Color(0xFF1A56DB)
    : count >= 3
      ? const Color(0xFF16A34A)
      : count > 0
        ? const Color(0xFFF59E0B)
        : const Color(0xFFCBD5E1);

  return GestureDetector(
    onTap: isAvailable
      ? () => _onSeatTap(seatId)
      : null,
    child: SizedBox(
      width: seatW,
      height: seatH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            painter: TopViewSeatPainter(
              color: seatColor,
              isSelected: isSelected,
              isAvailable: isAvailable,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment:
                  MainAxisAlignment.center,
                children: [
                  Text(
                    seatId,
                    style: TextStyle(
                      color: isSelected
                        ? Colors.white
                        : isAvailable
                            ? Colors.white
                            : const Color(0xFF64748B),
                      fontSize: seatW * 0.17,
                      fontWeight: FontWeight.w800,
                      fontFamily:
                        GoogleFonts.poppins()
                        .fontFamily,
                    ),
                  ),
                  if (count > 0)
                    Container(
                      margin: const EdgeInsets
                        .only(top: 2),
                      padding:
                        const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                      decoration: BoxDecoration(
                        color: Colors.white
                          .withOpacity(0.25),
                        borderRadius:
                          BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: seatW * 0.13,
                          fontWeight: FontWeight.w700,
                          fontFamily:
                            GoogleFonts.poppins()
                            .fontFamily,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (hasWomenOnly && count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white, width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.female,
                  size: 9,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _buildTopViewBerth(
  String seatId,
  double seatW,
  double seatH,
) {
  final count = templateData?.getCount(
    seatId, activeTemplate,
  ) ?? 0;
  final isSelected = allSelectedSeats[
    activeTemplate]!.contains(seatId);
  final isAvailable = count > 0;

  final Color berthColor = isSelected
    ? const Color(0xFF1A56DB)
    : count >= 3
      ? const Color(0xFF16A34A)
      : count > 0
        ? const Color(0xFFF59E0B)
        : const Color(0xFFCBD5E1);

  return GestureDetector(
    onTap: isAvailable
      ? () => _toggleSeat(seatId)
      : null,
    child: SizedBox(
      width: seatW,
      height: seatH,
      child: CustomPaint(
        painter: TopViewBerthPainter(
          color: berthColor,
          isSelected: isSelected,
          isLower: activeTemplate == 'Lower',
        ),
        child: Center(
          child: Column(
            mainAxisAlignment:
              MainAxisAlignment.center,
            children: [
              Text(
                seatId,
                style: TextStyle(
                  color: isSelected
                    ? Colors.white
                    : isAvailable
                        ? Colors.white
                        : const Color(0xFF64748B),
                  fontSize: seatW * 0.15,
                  fontWeight: FontWeight.w800,
                  fontFamily:
                    GoogleFonts.poppins()
                    .fontFamily,
                ),
              ),
              if (count > 0)
                Text(
                  '$count',
                  style: TextStyle(
                    color: Colors.white
                      .withOpacity(0.8),
                    fontSize: seatW * 0.13,
                    fontFamily:
                      GoogleFonts.poppins()
                      .fontFamily,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildBusFrontHeader() {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 16, vertical: 12,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      border: const Border(
        bottom: BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
    ),
    child: Row(
      mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
      children: [
        const Icon(
          Icons.arrow_forward,
          color: Color(0xFF64748B),
          size: 16,
        ),
        Row(
          children: [
            Column(
              crossAxisAlignment:
                CrossAxisAlignment.end,
              children: [
                Text(
                  'Driver',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: 10,
                    fontFamily:
                      GoogleFonts.poppins()
                      .fontFamily,
                  ),
                ),
                Text(
                  'Front',
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily:
                      GoogleFonts.poppins()
                      .fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1A56DB)
                  .withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1A56DB),
                ),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF1A56DB),
                size: 16,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildBusRearFooter() {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 16, vertical: 8,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      border: const Border(
        top: BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
    ),
    child: Row(
      mainAxisAlignment:
        MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.more_horiz,
          color: Color(0xFF64748B),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          'Rear of bus',
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: 10,
            fontFamily: GoogleFonts.poppins()
              .fontFamily,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.more_horiz,
          color: Color(0xFF64748B),
          size: 16,
        ),
      ],
    ),
  );
}

  // ─── Section 6: Bottom Actions ────────────────────────────────────────────

  Widget _buildBottomAction() {
  final hasSelections = isPositionMode
    ? totalSelected > 0
    : totalCountModeSeats > 0;

  return AnimatedContainer(
    duration: const Duration(
      milliseconds: 300,
    ),
    padding: EdgeInsets.fromLTRB(
      16, 12, 16,
      MediaQuery.of(context).padding.bottom + 12,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      border: const Border(
        top: BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        // Position mode: Cross-template selection summary
        if (isPositionMode && hasSelections) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(
              bottom: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius:
                BorderRadius.circular(10),
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
                    const Icon(
                      Icons.event_seat,
                      color: Color(0xFF1A56DB),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Selected seats:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                          const Color(0xFF1A56DB),
                        fontFamily:
                          GoogleFonts.poppins()
                          .fontFamily,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _clearAllSelections,
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                            FontWeight.w600,
                          color: const Color(
                            0xFFEF4444,
                          ),
                          fontFamily:
                            GoogleFonts.poppins()
                            .fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Seater selections
                    ...allSelectedSeats[
                      'Seater']!.map((s) =>
                      _selectionChip(
                        s,
                        Icons
                          .airline_seat_recline_normal,
                        const Color(0xFF1A56DB),
                        'Seater',
                      ),
                    ),
                    // Lower selections
                    ...allSelectedSeats[
                      'Lower']!.map((s) =>
                      _selectionChip(
                        s,
                        Icons.bed_outlined,
                        const Color(0xFF16A34A),
                        'Lower',
                      ),
                    ),
                    // Upper selections
                    ...allSelectedSeats[
                      'Upper']!.map((s) =>
                      _selectionChip(
                        s,
                        Icons.airline_seat_flat,
                        const Color(0xFF7C3AED),
                        'Upper',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Count mode: Summary row
        if (!isPositionMode && hasSelections)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFBFDBFE),
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if ((templateCounts['Seater'] ?? 0) > 0)
                  _countSummaryChip(
                    '${templateCounts['Seater']} Seater',
                    const Color(0xFF1A56DB),
                  ),
                if ((templateCounts['Lower'] ?? 0) > 0)
                  _countSummaryChip(
                    '${templateCounts['Lower']} Lower',
                    const Color(0xFF16A34A),
                  ),
                if ((templateCounts['Upper'] ?? 0) > 0)
                  _countSummaryChip(
                    '${templateCounts['Upper']} Upper',
                    const Color(0xFF7C3AED),
                  ),
              ],
            ),
          ),

        // Find Buses button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: hasSelections
              ? _onFindBuses
              : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasSelections
                ? const Color(0xFF1A56DB)
                : const Color(0xFFE2E8F0),
              shape: RoundedRectangleBorder(
                borderRadius:
                  BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment:
                MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  color: hasSelections
                    ? Colors.white
                    : const Color(0xFF94A3B8),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  hasSelections
                    ? isPositionMode
                      ? 'Find Buses · $totalSelected seat(s) →'
                      : 'Find Buses · $totalCountModeSeats seat(s) →'
                    : isPositionMode
                      ? 'Select seats above'
                      : 'Set seat counts above',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: hasSelections
                      ? Colors.white
                      : const Color(0xFF94A3B8),
                    fontFamily:
                      GoogleFonts.poppins()
                      .fontFamily,
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

Widget _selectionChip(
  String seatId,
  IconData icon,
  Color color,
  String template,
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
          seatId,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: GoogleFonts.poppins()
              .fontFamily,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              allSelectedSeats[template]!
                .remove(seatId);
            });
          },
          child: Icon(
            Icons.close,
            size: 10,
            color: color,
          ),
        ),
      ],
    ),
  );
}

Widget _countSummaryChip(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 10, vertical: 5,
    ),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: color.withOpacity(0.4),
      ),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        fontFamily: GoogleFonts.poppins()
          .fontFamily,
      ),
    ),
  );
}

  // ─── 3D View ──────────────────────────────────────────────────────────────

  Widget _build3DSheet() {
    return StatefulBuilder(
      builder: (ctx, set3D) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _kBrandBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        activeTemplate,
                        style: _poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '3D Bus View',
                        style: _poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF93C5FD).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'Beta',
                        style: _poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF93C5FD),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _legendItem3d(
                      color: const Color(0xFF22C55E),
                      label: '3+ buses',
                    ),
                    _legendItem3d(
                      color: const Color(0xFFF59E0B),
                      label: '1-2 buses',
                    ),
                    _legendItem3d(
                      color: _kRed,
                      label: 'Full',
                    ),
                    _legendItem3d(
                      color: const Color(0xFF3B82F6),
                      label: 'Selected',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GestureDetector(
                  onPanUpdate: (details) {
                    set3D(() {
                      _rotationY3d += details.delta.dx * 0.008;
                      _rotationX3d += details.delta.dy * 0.005;
                      _rotationX3d = _rotationX3d.clamp(-0.4, 0.1);
                      _rotationY3d = _rotationY3d.clamp(-0.8, 0.8);
                    });
                  },
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0008)
                      ..rotateX(_rotationX3d)
                      ..rotateY(_rotationY3d)
                      ..scaleByDouble(_scale3d, _scale3d, _scale3d, 1.0),
                    alignment: Alignment.center,
                    child: _build3DBusBody(set3D),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swipe,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Drag to rotate  ·  Tap seat to select',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.of(context).padding.bottom + 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBrandBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      allSelectedSeatsList.isEmpty
                          ? 'Close'
                          : 'Apply ${allSelectedSeatsList.length} seat(s) selected →',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _build3DBusBody(StateSetter set3D) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _kTextMuted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _kTextMuted.withValues(alpha: 0.25),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _kTextMuted.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: _kTextMuted.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: _kTextMuted.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _kTextMuted.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _kTextMuted.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Driver',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 60,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBAE6FD).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _kTextMuted.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 16,
                    ),
                  ),
                  Text(
                    '→ Front',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: _build3DSeatLayout(set3D),
              ),
            ),
            Container(
              height: 28,
              decoration: BoxDecoration(
                color: _kTextMuted.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: _kTextMuted.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.more_horiz,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Rear',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DSeatLayout(StateSetter set3D) {
    final List<String> columns;
    final isBerth = activeTemplate == 'Lower' || activeTemplate == 'Upper';

    if (activeTemplate == 'Seater') {
      columns = ['A', 'B', 'C', 'D'];
    } else if (activeTemplate == 'Lower') {
      columns = ['LA', 'LB', 'LC', 'LD'];
    } else {
      columns = ['UA', 'UB', 'UC', 'UD'];
    }

    final rowCount = isBerth ? 7 : 10;

    return Column(
      children: List.generate(rowCount, (rowIdx) {
        final row = rowIdx + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  '$row',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Row(
                  children: List.generate(columns.length, (colIdx) {
                    final col = columns[colIdx];
                    final String seatId;

                    if (activeTemplate == 'Seater') {
                      seatId = '$row$col';
                    } else if (activeTemplate == 'Lower') {
                      seatId = 'L$row${col.substring(1)}';
                    } else {
                      seatId = 'U$row${col.substring(1)}';
                    }

                    var addAisleAfter = false;
                    if (colIdx == 1) {
                      addAisleAfter = true;
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _build3DSeat(seatId, set3D),
                        if (addAisleAfter)
                          SizedBox(
                            width: 12,
                            child: Center(
                              child: Container(
                                width: 1,
                                height: 32,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _build3DSeat(String seatId, StateSetter set3D) {
    final count = templateData?.getCount(
      seatId, activeTemplate,
    ) ?? 0;
    final isSelected = allSelectedSeats[
      activeTemplate]!.contains(seatId);
    final isAvailable = count > 0;

    final seatColor = isSelected
        ? const Color(0xFF3B82F6)
        : count >= 3
            ? const Color(0xFF22C55E)
            : count > 0
                ? _kYellow
                : const Color(0xFF4B5563);

    final glowColor = isSelected
        ? const Color(0xFF3B82F6)
        : count >= 3
            ? const Color(0xFF22C55E)
            : count > 0
                ? _kYellow
                : Colors.transparent;

    return GestureDetector(
      onTap: isAvailable
          ? () {
              HapticFeedback.lightImpact();
              set3D(() {
                setState(() {
                  final list =
                    allSelectedSeats[activeTemplate]!;
                  if (isSelected) {
                    list.remove(seatId);
                  } else {
                    list.add(seatId);
                  }
                });
              });
            }
          : null,
      child: Container(
        width: 38,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: seatColor.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                boxShadow: isSelected || isAvailable
                    ? [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            ),
            Container(
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    seatColor.withValues(alpha: 0.9),
                    seatColor.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: seatColor.withValues(
                      alpha: isAvailable ? 0.3 : 0.1,
                    ),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      seatId,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem3d({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

// SeatShapePainter - draws realistic seat shape
class SeatShapePainter extends CustomPainter {
  final Color primaryColor;
  final Color bgColor;
  final bool isSelected;
  final bool isAvailable;

  SeatShapePainter({
    required this.primaryColor,
    required this.bgColor,
    required this.isSelected,
    required this.isAvailable,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // ── SEAT BACK (tall main body) ──────────────
    paint.color = bgColor;
    final backRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.62),
      const Radius.circular(8),
    );
    canvas.drawRRect(backRect, paint);

    // Seat back border
    paint
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.5;
    canvas.drawRRect(backRect, paint);
    paint.style = PaintingStyle.fill;

    // ── HEADREST BUMP (top center rounded) ──────
    paint.color = bgColor;
    final headrestRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, 0, w * 0.56, h * 0.16),
      const Radius.circular(6),
    );
    canvas.drawRRect(headrestRect, paint);
    // Headrest border
    paint
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.5;
    canvas.drawRRect(headrestRect, paint);
    paint.style = PaintingStyle.fill;

    // ── ARMRESTS (left and right sides) ─────────
    paint.color = primaryColor.withOpacity(0.15);
    // Left armrest
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.42, w * 0.10, h * 0.22),
        const Radius.circular(4),
      ),
      paint,
    );
    // Right armrest
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.90, h * 0.42, w * 0.10, h * 0.22),
        const Radius.circular(4),
      ),
      paint,
    );

    // ── SEAT CUSHION (bottom section) ───────────
    paint.color = primaryColor.withOpacity(
      isSelected ? 0.35 : 0.12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * 0.08, h * 0.70,
          w * 0.84, h * 0.26,
        ),
        const Radius.circular(6),
      ),
      paint,
    );
    // Cushion border
    paint
      ..color = primaryColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * 0.08, h * 0.70,
          w * 0.84, h * 0.26,
        ),
        const Radius.circular(6),
      ),
      paint,
    );
    paint.style = PaintingStyle.fill;

    // ── SELECTED FILL OVERLAY ────────────────────
    if (isSelected) {
      paint.color = const Color(0xFF1A56DB)
        .withOpacity(0.08);
      canvas.drawRRect(backRect, paint);
    }
  }

  @override
  bool shouldRepaint(SeatShapePainter old) =>
    old.isSelected != isSelected ||
    old.primaryColor != primaryColor;
}

// BerthShapePainter - draws realistic berth
class BerthShapePainter extends CustomPainter {
  final Color primaryColor;
  final Color bgColor;
  final bool isSelected;
  final bool isLower;

  BerthShapePainter({
    required this.primaryColor,
    required this.bgColor,
    required this.isSelected,
    required this.isLower,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // ── MATTRESS BASE ────────────────────────────
    paint.color = bgColor;
    final mattressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.12, w, h * 0.76),
      const Radius.circular(8),
    );
    canvas.drawRRect(mattressRect, paint);

    // Mattress border
    paint
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.5;
    canvas.drawRRect(mattressRect, paint);
    paint.style = PaintingStyle.fill;

    // ── PILLOW (left side) ───────────────────────
    paint.color = primaryColor.withOpacity(
      isSelected ? 0.35 : 0.12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * 0.04, h * 0.18,
          w * 0.18, h * 0.62,
        ),
        const Radius.circular(6),
      ),
      paint,
    );
    // Pillow border
    paint
      ..color = primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * 0.04, h * 0.18,
          w * 0.18, h * 0.62,
        ),
        const Radius.circular(6),
      ),
      paint,
    );
    paint.style = PaintingStyle.fill;

    // ── MATTRESS LINES (texture detail) ──────────
    paint
      ..color = primaryColor.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    // Horizontal lines suggesting mattress
    for (int i = 1; i <= 3; i++) {
      final lineY = h * 0.20 + i * (h * 0.55 / 4);
      canvas.drawLine(
        Offset(w * 0.26, lineY),
        Offset(w * 0.96, lineY),
        paint,
      );
    }
    paint.style = PaintingStyle.fill;

    // ── LOWER BERTH: Side guard rail ─────────────
    if (isLower) {
      paint.color = primaryColor.withOpacity(0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h * 0.10),
          const Radius.circular(4),
        ),
        paint,
      );
    }

    // ── UPPER BERTH: Top guard rail ───────────────
    if (!isLower) {
      paint.color = primaryColor.withOpacity(0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.90, w, h * 0.10),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BerthShapePainter old) =>
    old.isSelected != isSelected ||
    old.primaryColor != primaryColor;
}

// TopViewSeatPainter - draws top view seat
class TopViewSeatPainter extends CustomPainter {
  final Color color;
  final bool isSelected;
  final bool isAvailable;

  TopViewSeatPainter({
    required this.color,
    required this.isSelected,
    required this.isAvailable,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // Seat back (taller section)
    paint.color = color;
    final backRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, 0, w * 0.8, h * 0.65),
      const Radius.circular(6),
    );
    canvas.drawRRect(backRect, paint);

    // Seat cushion (bottom section)
    paint.color = color.withOpacity(0.7);
    final cushionRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.65, w * 0.9, h * 0.35),
      const Radius.circular(4),
    );
    canvas.drawRRect(cushionRect, paint);

    // Border
    paint
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.5;
    canvas.drawRRect(backRect, paint);
    canvas.drawRRect(cushionRect, paint);
  }

  @override
  bool shouldRepaint(TopViewSeatPainter old) =>
    old.color != color || old.isSelected != isSelected;
}

// TopViewBerthPainter - draws top view berth
class TopViewBerthPainter extends CustomPainter {
  final Color color;
  final bool isSelected;
  final bool isLower;

  TopViewBerthPainter({
    required this.color,
    required this.isSelected,
    required this.isLower,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // Mattress
    paint.color = color;
    final mattressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.1, w, h * 0.8),
      const Radius.circular(6),
    );
    canvas.drawRRect(mattressRect, paint);

    // Pillow
    paint.color = color.withOpacity(0.6);
    final pillowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.15, w * 0.25, h * 0.7),
      const Radius.circular(4),
    );
    canvas.drawRRect(pillowRect, paint);

    // Guard rail
    paint.color = color.withOpacity(0.8);
    if (isLower) {
      // Bottom guard rail
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.85, w, h * 0.15),
          const Radius.circular(3),
        ),
        paint,
      );
    } else {
      // Top guard rail
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h * 0.15),
          const Radius.circular(3),
        ),
        paint,
      );
    }

    // Border
    paint
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.5;
    canvas.drawRRect(mattressRect, paint);
  }

  @override
  bool shouldRepaint(TopViewBerthPainter old) =>
    old.color != color || old.isSelected != isSelected;
}

// TemplateData - holds seat counts and bus maps for all templates
class TemplateData {
  final Map<String, int> seaterCounts;
  final Map<String, int> lowerCounts;
  final Map<String, int> upperCounts;
  final Map<String, List<BusModel>> seaterBusMap;
  final Map<String, List<BusModel>> lowerBusMap;
  final Map<String, List<BusModel>> upperBusMap;

  TemplateData({
    required this.seaterCounts,
    required this.lowerCounts,
    required this.upperCounts,
    required this.seaterBusMap,
    required this.lowerBusMap,
    required this.upperBusMap,
  });

  int getCount(String seatId, String template) {
    switch (template) {
      case 'Seater':
        return seaterCounts[seatId] ?? 0;
      case 'Lower':
        return lowerCounts[seatId] ?? 0;
      case 'Upper':
        return upperCounts[seatId] ?? 0;
      default:
        return 0;
    }
  }

  List<BusModel> getBuses(
    String seatId, String template,
  ) {
    switch (template) {
      case 'Seater':
        return seaterBusMap[seatId] ?? [];
      case 'Lower':
        return lowerBusMap[seatId] ?? [];
      case 'Upper':
        return upperBusMap[seatId] ?? [];
      default:
        return [];
    }
  }
}

// UniversalTemplateLogic - builds template data from buses
class UniversalTemplateLogic {

  static bool isSeaterSeat(String id) {
    // No L or U prefix
    // Examples: 1A, 3B, 10D
    return RegExp(
      r'^\d+[A-Za-z]$',
    ).hasMatch(id);
  }

  static bool isLowerBerth(String id) {
    return id.toUpperCase().startsWith('L')
      && id.length >= 3;
  }

  static bool isUpperBerth(String id) {
    return id.toUpperCase().startsWith('U')
      && id.length >= 3;
  }

  static TemplateData buildTemplateData(
    List<BusModel> buses,
  ) {
    Map<String, int> seaterCounts  = {};
    Map<String, int> lowerCounts   = {};
    Map<String, int> upperCounts   = {};
    Map<String, List<BusModel>> seaterMap = {};
    Map<String, List<BusModel>> lowerMap  = {};
    Map<String, List<BusModel>> upperMap  = {};

    for (final bus in buses) {
      for (final seat in bus.availableSeats) {

        if (isSeaterSeat(seat)) {
          seaterCounts[seat] =
            (seaterCounts[seat] ?? 0) + 1;
          seaterMap[seat] = [
            ...(seaterMap[seat] ?? []), bus,
          ];
        }
        else if (isLowerBerth(seat)) {
          lowerCounts[seat] =
            (lowerCounts[seat] ?? 0) + 1;
          lowerMap[seat] = [
            ...(lowerMap[seat] ?? []), bus,
          ];
        }
        else if (isUpperBerth(seat)) {
          upperCounts[seat] =
            (upperCounts[seat] ?? 0) + 1;
          upperMap[seat] = [
            ...(upperMap[seat] ?? []), bus,
          ];
        }
      }
    }

    return TemplateData(
      seaterCounts:  seaterCounts,
      lowerCounts:   lowerCounts,
      upperCounts:   upperCounts,
      seaterBusMap:  seaterMap,
      lowerBusMap:   lowerMap,
      upperBusMap:   upperMap,
    );
  }

  // Returns buses from a list that have
  // this seat marked women-only
  static List<BusModel> getWomenOnlyBuses(
    String seatId,
    List<BusModel> buses,
  ) {
    return buses.where((bus) =>
      bus.womenOnlySeats.contains(seatId)
    ).toList();
  }

  // Returns buses from a list that have
  // this seat as general (not women-only)
  static List<BusModel> getGeneralBuses(
    String seatId,
    List<BusModel> buses,
  ) {
    return buses.where((bus) =>
      !bus.womenOnlySeats.contains(seatId)
    ).toList();
  }

  // Check if a seat has mixed availability
  // (some women-only, some general)
  static bool hasMixedAvailability(
    String seatId,
    List<BusModel> buses,
  ) {
    final women = getWomenOnlyBuses(seatId, buses);
    final general = getGeneralBuses(seatId, buses);
    return women.isNotEmpty && general.isNotEmpty;
  }

  // Check if seat is women-only across ALL
  // buses that have it (no general option)
  static bool isFullyWomenOnly(
    String seatId,
    List<BusModel> buses,
  ) {
    final relevant = buses.where((bus) =>
      bus.availableSeats.contains(seatId)
    ).toList();
    if (relevant.isEmpty) return false;
    return relevant.every((bus) =>
      bus.womenOnlySeats.contains(seatId)
    );
  }
}
