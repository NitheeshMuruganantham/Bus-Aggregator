import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_data.dart';
import '../models/bus_model.dart';
import '../models/seat_model.dart';
import '../utils/app_theme.dart';
import '../utils/navigation.dart';
import '../utils/seat_filter_logic.dart';
import '../widgets/bus_layout_view.dart';
import '../widgets/custom_button.dart';
import '../widgets/layout_tabs.dart';
import '../widgets/selection_mode_toggle.dart';
import 'bus_list_screen.dart';

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
  String _mode = 'Position';
  String _layout = '2+1';
  List<String> _selectedSeats = [];
  int _seatCount = 1;
  final Set<String> _preferences = {'Any Layout'};
  List<SeatModel> _seatGrid = [];
  final List<BusModel> _allBuses = getMockBuses();

  static const List<String> _preferenceOptions = [
    'Any Layout',
    'Window',
    'Aisle',
    'Lower Berth',
    'Upper Berth',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferredLayout();
    _regenerateGrid();
  }

  Future<void> _loadPreferredLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('preferred_layout');
    if (saved != null && LayoutTabs.layouts.contains(saved)) {
      setState(() {
        _layout = saved;
        _regenerateGrid();
      });
    }
  }

  Future<void> _savePreferredLayout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_layout', _layout);
  }

  void _regenerateGrid() {
    _seatGrid = SeatFilterLogic.generateSeatGrid(
      layout: _layout,
      allBuses: _allBuses,
    );
    for (final seat in _seatGrid) {
      seat.isSelected = _selectedSeats.contains(seat.id);
    }
  }

  void _onLayoutChanged(String layout) {
    setState(() {
      _layout = layout;
      _selectedSeats = [];
      _regenerateGrid();
    });
    _savePreferredLayout();
  }

  void _onModeChanged(String mode) {
    setState(() => _mode = mode);
  }

  void _toggleSeat(SeatModel seat) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedSeats.contains(seat.id)) {
        _selectedSeats.remove(seat.id);
        seat.isSelected = false;
      } else {
        _selectedSeats.add(seat.id);
        seat.isSelected = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedSeats = [];
      for (final seat in _seatGrid) {
        seat.isSelected = false;
      }
    });
  }

  void _togglePreference(String pref) {
    setState(() {
      if (pref == 'Any Layout') {
        _preferences
          ..clear()
          ..add('Any Layout');
      } else {
        _preferences.remove('Any Layout');
        if (_preferences.contains(pref)) {
          _preferences.remove(pref);
          if (_preferences.isEmpty) _preferences.add('Any Layout');
        } else {
          _preferences.add(pref);
        }
      }
    });
  }

  bool get _canFindBuses {
    if (_mode == 'Position') return _selectedSeats.isNotEmpty;
    return _seatCount >= 1;
  }

  void _findBuses() {
    if (!_canFindBuses) return;
    HapticFeedback.mediumImpact();

    final results = _mode == 'Position'
        ? SeatFilterLogic.filterBySelectedSeats(
            selectedSeats: _selectedSeats,
            layout: _layout,
            allBuses: _allBuses,
          )
        : SeatFilterLogic.filterByCount(
            count: _seatCount,
            layout: _layout,
            allBuses: _allBuses,
          );

    Navigator.push(
      context,
      slideUpRoute(
        BusListScreen(
          from: widget.from,
          to: widget.to,
          date: widget.date,
          timeSlot: widget.timeSlot,
          layout: _layout,
          mode: _mode,
          selectedSeats: List.from(_selectedSeats),
          seatCount: _seatCount,
          buses: results,
        ),
      ),
    );
  }

  String get _buttonText {
    if (_mode == 'Position') {
      return 'Find Buses (${_selectedSeats.length} selected)';
    }
    return 'Find $_seatCount Buses';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: p.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              '${widget.from} → ${widget.to}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: p.textPrimary,
              ),
            ),
            Text(
              '${widget.date} | ${widget.timeSlot}',
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SelectionModeToggle(
              selectedMode: _mode,
              onModeChanged: _onModeChanged,
            ),
            const SizedBox(height: 12),
            const SeatLegend(),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _mode == 'Position'
                    ? _buildPositionGrid()
                    : _buildCountMode(),
              ),
            ),
            if (_mode == 'Position' && _selectedSeats.isNotEmpty)
              _buildSelectedSummary(primary, p),
            const SizedBox(height: 8),
            LayoutTabs(
              selectedLayout: _layout,
              onLayoutChanged: _onLayoutChanged,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: _buttonText,
              onPressed: _canFindBuses ? _findBuses : null,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSummary(Color primary, AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedSeats.length} seats: ${_selectedSeats.join(', ')}',
              style: TextStyle(color: primary, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _clearSelection,
            child: Text('Clear', style: TextStyle(color: p.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildCountMode() {
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      key: const ValueKey('count'),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 48, color: primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'How many seats?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleButton(Icons.remove, _seatCount > 1
                    ? () => setState(() => _seatCount--)
                    : null),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '$_seatCount',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                _circleButton(Icons.add, _seatCount < 10
                    ? () => setState(() => _seatCount++)
                    : null),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Finding $_seatCount seats in any position',
              style: TextStyle(fontSize: 14, color: p.textSecondary),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _preferenceOptions.map((pref) {
                final selected = _preferences.contains(pref);
                return FilterChip(
                  label: Text(pref),
                  selected: selected,
                  onSelected: (_) => _togglePreference(pref),
                  selectedColor: primary.withValues(alpha: 0.15),
                  checkmarkColor: primary,
                  labelStyle: TextStyle(
                    color: selected ? primary : p.textSecondary,
                    fontSize: 12,
                  ),
                  backgroundColor: p.chipBg,
                  side: BorderSide(color: p.border),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback? onTap) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap != null ? p.cardBg : p.chipBg,
          border: Border.all(
            color: onTap != null
                ? Theme.of(context).colorScheme.primary
                : p.border,
            width: 1.5,
          ),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: p.shadow,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: onTap != null ? p.textPrimary : p.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPositionGrid() {
    return SingleChildScrollView(
      key: ValueKey(_layout),
      child: BusLayoutView(
        layout: _layout,
        seats: _seatGrid,
        onSeatTap: _toggleSeat,
      ),
    );
  }
}
