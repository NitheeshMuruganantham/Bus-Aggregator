import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_data.dart';
import '../models/bus_model.dart';
import '../models/seat_model.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import '../utils/seat_filter_logic.dart';
import '../widgets/custom_button.dart';
import '../widgets/layout_tabs.dart';
import '../widgets/seat_cell.dart';
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
          if (_preferences.isEmpty) {
            _preferences.add('Any Layout');
          }
        } else {
          _preferences.add(pref);
        }
      }
    });
  }

  bool get _canFindBuses {
    if (_mode == 'Position') {
      return _selectedSeats.isNotEmpty;
    }
    return _seatCount >= 1;
  }

  void _findBuses() {
    if (!_canFindBuses) return;

    HapticFeedback.mediumImpact();

    List<BusModel> results;
    if (_mode == 'Position') {
      results = SeatFilterLogic.filterBySelectedSeats(
        selectedSeats: _selectedSeats,
        layout: _layout,
        allBuses: _allBuses,
      );
    } else {
      results = SeatFilterLogic.filterByCount(
        count: _seatCount,
        layout: _layout,
        allBuses: _allBuses,
      );
    }

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              '${widget.from} → ${widget.to}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${widget.date} | ${widget.timeSlot}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            SelectionModeToggle(
              selectedMode: _mode,
              onModeChanged: _onModeChanged,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _mode == 'Position'
                    ? _buildPositionGrid()
                    : _buildCountMode(),
              ),
            ),
            if (_mode == 'Position' && _selectedSeats.isNotEmpty)
              _buildSelectedSummary(),
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

  Widget _buildSelectedSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedSeats.length} seats selected: ${_selectedSeats.join(', ')}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: _clearSelection,
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountMode() {
    return Center(
      key: const ValueKey('count'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'How many seats?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleButton(
                icon: Icons.remove,
                onTap: _seatCount > 1
                    ? () => setState(() => _seatCount--)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '$_seatCount',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _circleButton(
                icon: Icons.add,
                onTap: _seatCount < 10
                    ? () => setState(() => _seatCount++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Finding $_seatCount seats in any position',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
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
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
                backgroundColor: AppColors.cardBg,
                side: const BorderSide(color: AppColors.border),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap != null ? AppColors.cardBg : AppColors.border,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          color: onTap != null
              ? AppColors.textPrimary
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPositionGrid() {
    return SingleChildScrollView(
      key: ValueKey(_layout),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _buildLayoutGrid(),
      ),
    );
  }

  Widget _buildLayoutGrid() {
    switch (_layout) {
      case '2+1':
        return _buildTwoPlusOneGrid();
      case '2+2':
        return _buildTwoPlusTwoGrid();
      case 'Sleeper':
        return _buildSleeperGrid();
      case 'Semi-Sleeper':
        return _buildSemiSleeperGrid();
      default:
        return const SizedBox.shrink();
    }
  }

  SeatModel? _findSeat(String id) {
    try {
      return _seatGrid.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Widget _buildTwoPlusOneGrid() {
    return Column(
      children: [
        const Icon(Icons.directions_bus, color: AppColors.textSecondary),
        const Text('Driver', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _headerLabel('A'),
            const SizedBox(width: 68),
            _headerLabel('B'),
            const SizedBox(width: 8),
            _headerLabel('C'),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(10, (rowIndex) {
          final row = rowIndex + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _seatWidget('${row}A'),
                const SizedBox(width: 16),
                _seatWidget('${row}B'),
                const SizedBox(width: 8),
                _seatWidget('${row}C'),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTwoPlusTwoGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _headerLabel('A'),
            const SizedBox(width: 8),
            _headerLabel('B'),
            const SizedBox(width: 24),
            _headerLabel('C'),
            const SizedBox(width: 8),
            _headerLabel('D'),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(10, (rowIndex) {
          final row = rowIndex + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _seatWidget('${row}A'),
                const SizedBox(width: 8),
                _seatWidget('${row}B'),
                const SizedBox(width: 24),
                _seatWidget('${row}C'),
                const SizedBox(width: 8),
                _seatWidget('${row}D'),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSleeperGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LOWER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(7, (rowIndex) {
          final row = rowIndex + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _seatWidget('L${row}A', height: 80),
                const SizedBox(width: 8),
                _seatWidget('L${row}B', height: 80),
                const SizedBox(width: 8),
                _seatWidget('L${row}C', height: 80),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        const Text(
          'UPPER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(7, (rowIndex) {
          final row = rowIndex + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _seatWidget('U${row}A', height: 80),
                const SizedBox(width: 8),
                _seatWidget('U${row}B', height: 80),
                const SizedBox(width: 8),
                _seatWidget('U${row}C', height: 80),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSemiSleeperGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _headerLabel('A'),
            const SizedBox(width: 8),
            _headerLabel('B'),
            const SizedBox(width: 24),
            _headerLabel('C'),
            const SizedBox(width: 8),
            _headerLabel('D'),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(10, (rowIndex) {
          final row = rowIndex + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _seatWidget('${row}A', height: 72, showRecline: true),
                const SizedBox(width: 8),
                _seatWidget('${row}B', height: 72, showRecline: true),
                const SizedBox(width: 24),
                _seatWidget('${row}C', height: 72, showRecline: true),
                const SizedBox(width: 8),
                _seatWidget('${row}D', height: 72, showRecline: true),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _headerLabel(String label) {
    return SizedBox(
      width: 52,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _seatWidget(String id, {double height = 60, bool showRecline = false}) {
    final seat = _findSeat(id);
    if (seat == null) {
      return SizedBox(width: 52, height: height);
    }
    return SeatCell(
      seatModel: seat,
      isSelected: seat.isSelected,
      height: height,
      showReclineIcon: showRecline,
      onTap: () => _toggleSeat(seat),
    );
  }
}
