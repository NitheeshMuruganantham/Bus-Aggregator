import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/mock_data.dart';
import '../models/bus_model.dart';
import '../utils/seat_filter_logic.dart';
import 'bus_list_screen.dart';

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

const _layouts = ['2+1', '2+2', 'Sleeper', 'Semi-Sleeper'];

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
  String selectedLayout = '2+1';
  bool isPositionMode = true;
  List<String> selectedSeats = [];
  int seatCount = 1;
  double _rotationY3d = 0.0;
  double _rotationX3d = -0.15;
  final double _scale3d = 1.0;

  List<BusModel> get _allBuses => getMockBuses();

  bool get isCountMode => !isPositionMode;

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

  String _layoutLabel(String layout) {
    if (layout == 'Semi-Sleeper') return 'Semi';
    return layout;
  }

  IconData _layoutIcon(String layout) {
    switch (layout) {
      case '2+1':
        return Icons.airline_seat_recline_extra;
      case '2+2':
        return Icons.airline_seat_recline_normal;
      case 'Sleeper':
        return Icons.bed_outlined;
      case 'Semi-Sleeper':
        return Icons.weekend_outlined;
      default:
        return Icons.event_seat;
    }
  }

  void _onLayoutChanged(String layout) {
    setState(() {
      selectedLayout = layout;
      selectedSeats.clear();
    });
  }

  void _onModeChanged(bool positionMode) {
    if (isPositionMode == positionMode) return;
    setState(() {
      isPositionMode = positionMode;
      selectedSeats.clear();
      seatCount = 1;
    });
  }

  void _open3DView() {
    setState(() {
      _rotationY3d = -0.3;
      _rotationX3d = -0.15;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _build3DSheet(),
    );
  }

  void _onFindBuses() {
    HapticFeedback.mediumImpact();
    final filtered = isPositionMode
        ? SeatFilterLogic.filterBySelectedSeats(
            selectedSeats: selectedSeats,
            layout: selectedLayout,
            allBuses: _allBuses,
          )
        : SeatFilterLogic.filterByCount(
            count: seatCount,
            layout: selectedLayout,
            allBuses: _allBuses,
          );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusListScreen(
          from: widget.from,
          to: widget.to,
          date: widget.date,
          timeSlot: widget.timeSlot,
          layout: selectedLayout,
          mode: isPositionMode ? 'Position' : 'Count',
          selectedSeats: List<String>.from(selectedSeats),
          seatCount: seatCount,
          buses: filtered,
        ),
      ),
    );
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
          if (isPositionMode) _buildPositionBottomAction() else _buildCountBottomAction(),
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
                  '${widget.date} · ${widget.timeSlot}',
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
                  _layoutLabel(selectedLayout),
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
              _buildModeToggle(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap seats to select · Count shown = buses available',
            style: _poppins(fontSize: 11, color: _kTextSecondary),
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
                  iconColor: _kRed,
                  bg: const Color(0xFFFEF2F2),
                  border: const Color(0xFFFCA5A5),
                  label: 'Full',
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

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeTab('Position', isPositionMode),
          _modeTab('Count', !isPositionMode),
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

  Widget _modeTab(String label, bool active) {
    return GestureDetector(
      onTap: () => _onModeChanged(label == 'Position'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _kBrandBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: _poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : _kTextSecondary,
          ),
        ),
      ),
    );
  }

  // ─── Section 3: Layout Tabs ───────────────────────────────────────────────

  Widget _buildLayoutTabs() {
    return Container(
      color: _kCardBg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _layouts.map((layout) {
                  final active = selectedLayout == layout;
                  return GestureDetector(
                    onTap: () => _onLayoutChanged(layout),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active ? _kBrandBlue : _kFieldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active ? _kBrandBlue : _kBorder,
                          width: active ? 0 : 1,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: _kBrandBlue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _layoutIcon(layout),
                            size: 14,
                            color: active ? Colors.white : _kTextSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _layoutLabel(layout),
                            style: _poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active ? Colors.white : _kTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: ElevatedButton.icon(
              onPressed: _open3DView,
              icon: const Icon(Icons.view_in_ar, size: 16),
              label: Text(
                '3D',
                style: _poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kTextPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 4: Seat Area ─────────────────────────────────────────────────

  Widget _buildSeatArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildBusFront(),
            _buildSeatGrid(),
            _buildBusRear(),
          ],
        ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
          const Icon(Icons.radio_button_unchecked, color: _kTextMuted, size: 28),
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
        ],
      ),
    );
  }

  Widget _buildSeatGrid() {
    switch (selectedLayout) {
      case '2+1':
        return _buildGrid2Plus1();
      case '2+2':
        return _buildGrid2Plus2();
      case 'Sleeper':
        return _buildGridSleeper();
      case 'Semi-Sleeper':
        return _buildGridSemiSleeper();
      default:
        return _buildGrid2Plus1();
    }
  }

  Widget _buildGrid2Plus1() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 32),
              Expanded(
                child: Center(
                  child: Text(
                    'A',
                    style: _poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kTextMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Center(
                  child: Text(
                    'B',
                    style: _poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kTextMuted,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'C',
                    style: _poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kTextMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int row = 1; row <= 10; row++) ...[
            Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      '$row',
                      style: _poppins(fontSize: 10, color: _kTextMuted),
                    ),
                  ),
                ),
                Expanded(child: _buildSeatCell('${row}A', selectedLayout)),
                const SizedBox(
                  width: 16,
                  child: Center(
                    child: SizedBox(
                      width: 1,
                      height: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: _kBorder),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildSeatCell('${row}B', selectedLayout)),
                Expanded(child: _buildSeatCell('${row}C', selectedLayout)),
              ],
            ),
            if (row < 10) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid2Plus2() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 32),
              for (final col in ['A', 'B'])
                Expanded(
                  child: Center(
                    child: Text(
                      col,
                      style: _poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _kTextMuted,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 16),
              for (final col in ['C', 'D'])
                Expanded(
                  child: Center(
                    child: Text(
                      col,
                      style: _poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _kTextMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (int row = 1; row <= 10; row++) ...[
            Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      '$row',
                      style: _poppins(fontSize: 10, color: _kTextMuted),
                    ),
                  ),
                ),
                Expanded(child: _buildSeatCell('${row}A', selectedLayout)),
                Expanded(child: _buildSeatCell('${row}B', selectedLayout)),
                const SizedBox(
                  width: 16,
                  child: Center(
                    child: SizedBox(
                      width: 1,
                      height: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: _kBorder),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildSeatCell('${row}C', selectedLayout)),
                Expanded(child: _buildSeatCell('${row}D', selectedLayout)),
              ],
            ),
            if (row < 10) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildGridSemiSleeper() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 32),
              for (final col in ['A', 'B'])
                Expanded(
                  child: Center(
                    child: Text(
                      col,
                      style: _poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _kTextMuted,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 16),
              for (final col in ['C', 'D'])
                Expanded(
                  child: Center(
                    child: Text(
                      col,
                      style: _poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _kTextMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (int row = 1; row <= 10; row++) ...[
            Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      '$row',
                      style: _poppins(fontSize: 10, color: _kTextMuted),
                    ),
                  ),
                ),
                Expanded(child: _buildSeatCell('${row}A', selectedLayout)),
                Expanded(child: _buildSeatCell('${row}B', selectedLayout)),
                const SizedBox(
                  width: 16,
                  child: Center(
                    child: SizedBox(
                      width: 1,
                      height: 40,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: _kBorder),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildSeatCell('${row}C', selectedLayout)),
                Expanded(child: _buildSeatCell('${row}D', selectedLayout)),
              ],
            ),
            if (row < 10) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildGridSleeper() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildSleeperDeck(prefix: 'L', isLower: true)),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: _kBorder,
          ),
          Expanded(child: _buildSleeperDeck(prefix: 'U', isLower: false)),
        ],
      ),
    );
  }

  Widget _buildSleeperDeck({required String prefix, required bool isLower}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isLower ? _kGreenBg : _kBlueLightBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isLower ? const Color(0xFFBBF7D0) : _kBlueLightBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLower ? Icons.arrow_downward : Icons.arrow_upward,
                size: 10,
                color: isLower ? _kGreenText : _kBrandBlue,
              ),
              const SizedBox(width: 4),
              Text(
                isLower ? 'Lower Berth' : 'Upper Berth',
                style: _poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isLower ? _kGreenText : _kBrandBlue,
                ),
              ),
            ],
          ),
        ),
        for (int row = 1; row <= 7; row++) ...[
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$prefix$row',
                  style: _poppins(fontSize: 9, color: _kTextMuted),
                ),
              ),
              Expanded(
                child: _buildBerthCell(
                  '$prefix${row}A',
                  selectedLayout,
                  isLower,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildBerthCell(
                  '$prefix${row}B',
                  selectedLayout,
                  isLower,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildBerthCell(
                  '$prefix${row}C',
                  selectedLayout,
                  isLower,
                ),
              ),
            ],
          ),
          if (row < 7) const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildSeatCell(String seatId, String layout) {
    final count = SeatFilterLogic.getSeatAvailabilityCount(
      seatId: seatId,
      layout: layout,
      allBuses: getMockBuses(),
    );
    final isSelected = selectedSeats.contains(seatId);
    final isAvailable = count > 0;

    final bgColor = isSelected
        ? _kBrandBlue
        : count >= 3
            ? _kGreenBg
            : count > 0
                ? const Color(0xFFFFFBEB)
                : const Color(0xFFFEF2F2);

    final borderColor = isSelected
        ? _kBrandBlue
        : count >= 3
            ? _kGreenText
            : count > 0
                ? _kYellow
                : const Color(0xFFFCA5A5);

    final contentColor = isSelected
        ? Colors.white
        : count >= 3
            ? _kGreenText
            : count > 0
                ? _kYellow
                : _kRed;

    return GestureDetector(
      onTap: isAvailable && isPositionMode
          ? () {
              HapticFeedback.lightImpact();
              setState(() {
                if (isSelected) {
                  selectedSeats.remove(seatId);
                } else {
                  selectedSeats.add(seatId);
                }
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 14,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1565C0)
                    : count >= 3
                        ? _kGreenText.withValues(alpha: 0.3)
                        : count > 0
                            ? _kYellow.withValues(alpha: 0.3)
                            : _kRed.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Center(
                child: Text(
                  seatId,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : contentColor,
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                border: Border(
                  left: BorderSide(color: borderColor, width: 1),
                  right: BorderSide(color: borderColor, width: 1),
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _kBrandBlue.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.airline_seat_recline_normal,
                    size: 14,
                    color: contentColor,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : count >= 3
                              ? _kGreenText
                              : count > 0
                                  ? _kYellow
                                  : _kRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBerthCell(
    String seatId,
    String layout,
    bool isLower,
  ) {
    final count = SeatFilterLogic.getSeatAvailabilityCount(
      seatId: seatId,
      layout: layout,
      allBuses: getMockBuses(),
    );
    final isSelected = selectedSeats.contains(seatId);
    final isAvailable = count > 0;

    final bgColor = isSelected
        ? _kBrandBlue
        : count >= 3
            ? _kGreenBg
            : count > 0
                ? const Color(0xFFFFFBEB)
                : const Color(0xFFFEF2F2);

    final borderColor = isSelected
        ? _kBrandBlue
        : count >= 3
            ? _kGreenText
            : count > 0
                ? _kYellow
                : const Color(0xFFFCA5A5);

    final contentColor = isSelected
        ? Colors.white
        : count >= 3
            ? _kGreenText
            : count > 0
                ? _kYellow
                : _kRed;

    return GestureDetector(
      onTap: isAvailable && isPositionMode
          ? () {
              HapticFeedback.lightImpact();
              setState(() {
                if (isSelected) {
                  selectedSeats.remove(seatId);
                } else {
                  selectedSeats.add(seatId);
                }
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(3),
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _kBrandBlue.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bed_outlined,
              size: 14,
              color: contentColor,
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seatId,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: contentColor,
                  ),
                ),
                Text(
                  isLower ? 'Lower' : 'Upper',
                  style: TextStyle(
                    fontSize: 7,
                    color: contentColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : count >= 3
                        ? _kGreenText
                        : count > 0
                            ? _kYellow
                            : _kRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusRear() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: _kFieldBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.more_horiz, color: _kTextMuted, size: 20),
          const SizedBox(width: 8),
          Text('Rear of bus', style: _poppins(fontSize: 10, color: _kTextMuted)),
          const SizedBox(width: 8),
          const Icon(Icons.more_horiz, color: _kTextMuted, size: 20),
        ],
      ),
    );
  }

  // ─── Section 6: Bottom Actions ────────────────────────────────────────────

  Widget _buildPositionBottomAction() {
    if (selectedSeats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: const Border(top: BorderSide(color: _kBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kBlueLightBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBlueLightBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_seat, color: _kBrandBlue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${selectedSeats.length} seat(s) selected: ${selectedSeats.join(', ')}',
                      style: _poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kBrandBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => selectedSeats.clear()),
                    child: Text(
                      'Clear',
                      style: _poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _onFindBuses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBrandBlue,
                  disabledBackgroundColor: _kBorder,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Find Buses (${selectedSeats.length} seat(s))',
                      style: _poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: seatCount > 1
                      ? () => setState(() => seatCount--)
                      : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: seatCount > 1 ? _kBlueLightBg : _kFieldBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: seatCount > 1 ? _kBrandBlue : _kBorder,
                      ),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: seatCount > 1 ? _kBrandBlue : _kTextMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Text(
                      '$seatCount',
                      style: _poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'seats needed',
                      style: _poppins(fontSize: 11, color: _kTextSecondary),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: seatCount < 10
                      ? () => setState(() => seatCount++)
                      : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: seatCount < 10 ? _kBrandBlue : _kFieldBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: seatCount < 10 ? _kBrandBlue : _kBorder,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: seatCount < 10 ? Colors.white : _kTextMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _onFindBuses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBrandBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Find Buses with $seatCount Seats →',
                  style: _poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
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
                        _layoutLabel(selectedLayout),
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
                      selectedSeats.isEmpty
                          ? 'Close'
                          : 'Apply ${selectedSeats.length} seat(s) selected →',
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
    final hasSleeper = selectedLayout == 'Sleeper';

    if (selectedLayout == '2+1') {
      columns = ['A', 'B', 'C'];
    } else if (selectedLayout == 'Sleeper') {
      columns = ['LA', 'LB', 'UA', 'UB'];
    } else {
      columns = ['A', 'B', 'C', 'D'];
    }

    final rowCount = hasSleeper ? 7 : 10;

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

                    if (selectedLayout == '2+1') {
                      seatId = '$row$col';
                    } else if (selectedLayout == 'Sleeper') {
                      final prefix = col.startsWith('L') ? 'L' : 'U';
                      final letter = col.substring(1);
                      seatId = '$prefix$row$letter';
                    } else {
                      seatId = '$row$col';
                    }

                    var addAisleAfter = false;
                    if (selectedLayout == '2+1' && colIdx == 0) {
                      addAisleAfter = true;
                    }
                    if ((selectedLayout == '2+2' ||
                            selectedLayout == 'Semi-Sleeper') &&
                        colIdx == 1) {
                      addAisleAfter = true;
                    }
                    if (selectedLayout == 'Sleeper' && colIdx == 1) {
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
    final count = SeatFilterLogic.getSeatAvailabilityCount(
      seatId: seatId,
      layout: selectedLayout,
      allBuses: getMockBuses(),
    );
    final isSelected = selectedSeats.contains(seatId);
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
                  if (isSelected) {
                    selectedSeats.remove(seatId);
                  } else {
                    selectedSeats.add(seatId);
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
