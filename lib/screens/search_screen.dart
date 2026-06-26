import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bus_model.dart';
import '../data/mock_data.dart';
import 'seat_selection_screen.dart';

const _kBrandBlue = Color(0xFF1A56DB);
const _kBrandBlueDark = Color(0xFF1E3A8A);

class SearchScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const SearchScreen({super.key, this.onToggleTheme});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _fromCtrl =
      TextEditingController(text: 'Bangalore');
  final TextEditingController _toCtrl =
      TextEditingController(text: 'Chennai');

  DateTime _selectedDate = DateTime.now();
  String _selectedTimeSlot = '9PM - 12AM';
  int _selectedDateIndex = 0;
  List<BusModel> _buses = [];

  int _chartRouteIndex = 0;
  Timer? _chartTimer;
  List<Map<String, dynamic>> _chartData = [];

  final List<String> _timeSlots = [
    '6AM - 9AM',
    '9AM - 12PM',
    '12PM - 3PM',
    '3PM - 6PM',
    '6PM - 9PM',
    '9PM - 12AM',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _loadAndSortBuses();
    _buildChartData();
    _startChartRotation();
  }

  @override
  void dispose() {
    _chartTimer?.cancel();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  void _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fromCtrl.text = prefs.getString('last_from') ?? 'Bangalore';
      _toCtrl.text = prefs.getString('last_to') ?? 'Chennai';
    });
    _loadAndSortBuses();
  }

  void _loadAndSortBuses() {
    final from = _fromCtrl.text.toLowerCase().trim();
    final to = _toCtrl.text.toLowerCase().trim();
    final buses = getMockBuses()
        .where(
          (b) =>
              b.from.toLowerCase().trim() == from &&
              b.to.toLowerCase().trim() == to,
        )
        .toList()
      ..sort(
        (a, b) =>
            _parseTime(a.departure).compareTo(_parseTime(b.departure)),
      );
    setState(() => _buses = buses);
  }

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final cleaned = timeStr.trim().toUpperCase();
    final parts = cleaned.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    final isPM = parts[1] == 'PM';
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  void _startChartRotation() {
    _chartTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _chartRouteIndex = (_chartRouteIndex + 1) % kFeaturedRoutes.length;
        _buildChartData();
      });
    });
  }

  void _buildChartData() {
    final route = kFeaturedRoutes[_chartRouteIndex];
    final from = route['from']!;
    final to = route['to']!;
    final today = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final raw = List.generate(7, (i) {
      final day = today.add(Duration(days: i - 2));
      final price = getCheapestPriceForRoute(from, to, i);
      return {
        'date': i == 2 ? 'Today' : '${months[day.month - 1]} ${day.day}',
        'price': price,
        'isToday': i == 2,
        'isBest': false,
      };
    });

    final prices = raw
        .where((d) => (d['price'] as int) > 0)
        .map((d) => d['price'] as int)
        .toList();
    if (prices.isNotEmpty) {
      final minP = prices.reduce((a, b) => a < b ? a : b);
      for (final d in raw) {
        if (d['price'] == minP && d['isBest'] == false) {
          d['isBest'] = true;
          break;
        }
      }
    }
    _chartData = raw;
  }

  double _barHeight(int price, List<Map<String, dynamic>> data) {
    final prices = data
        .where((d) => (d['price'] as int) > 0)
        .map((d) => d['price'] as int)
        .toList();
    if (prices.isEmpty) return 20;
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    final minP = prices.reduce((a, b) => a < b ? a : b);
    if (maxP == minP) return 50;
    return 25 + ((price - minP) / (maxP - minP)) * 45;
  }

  void _swapCities() {
    HapticFeedback.lightImpact();
    setState(() {
      final temp = _fromCtrl.text;
      _fromCtrl.text = _toCtrl.text;
      _toCtrl.text = temp;
    });
    _loadAndSortBuses();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1A56DB),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showTimeSlotPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Select time slot',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            ..._timeSlots.map(
              (slot) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.access_time,
                  color: slot == _selectedTimeSlot
                      ? const Color(0xFF1A56DB)
                      : const Color(0xFF94A3B8),
                  size: 18,
                ),
                title: Text(
                  slot,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: slot == _selectedTimeSlot
                        ? const Color(0xFF1A56DB)
                        : const Color(0xFF1E293B),
                  ),
                ),
                trailing: slot == _selectedTimeSlot
                    ? const Icon(
                        Icons.check_circle,
                        color: Color(0xFF1A56DB),
                        size: 20,
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedTimeSlot = slot);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCityPicker({required bool isFrom}) {
    HapticFeedback.lightImpact();
    String filter = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final filtered = kAllCities
              .where((c) => c.toLowerCase().contains(filter.toLowerCase()))
              .toList();
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.65,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFrom
                              ? 'Select departure city'
                              : 'Select destination city',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            autofocus: true,
                            onChanged: (v) => setModal(() => filter = v),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search city...',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color(0xFF1A56DB),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No cities found',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final city = filtered[i];
                              final isSelected = isFrom
                                  ? city == _fromCtrl.text
                                  : city == _toCtrl.text;
                              return ListTile(
                                leading: Icon(
                                  isSelected
                                      ? Icons.location_on
                                      : Icons.location_on_outlined,
                                  color: isSelected
                                      ? const Color(0xFF1A56DB)
                                      : const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                title: Text(
                                  city,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF1A56DB)
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF1A56DB),
                                        size: 18,
                                      )
                                    : null,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    if (isFrom) {
                                      _fromCtrl.text = city;
                                    } else {
                                      _toCtrl.text = city;
                                    }
                                  });
                                  Navigator.pop(ctx);
                                  _loadAndSortBuses();
                                },
                              );
                            },
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

  void _onSearch() {
    HapticFeedback.mediumImpact();
    if (_fromCtrl.text.trim().isEmpty || _toCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select From and To cities'),
          backgroundColor: Color(0xFF1A56DB),
        ),
      );
      return;
    }
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('last_from', _fromCtrl.text);
      prefs.setString('last_to', _toCtrl.text);
    });
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => SeatSelectionScreen(
          from: _fromCtrl.text,
          to: _toCtrl.text,
          date: _formatSelectedDate(),
          timeSlot: _selectedTimeSlot,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  List<String> _getDateLabels() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final today = DateTime.now();
    return List.generate(5, (i) {
      final d = today.add(Duration(days: i));
      if (i == 0) return 'Today, ${months[d.month - 1]} ${d.day}';
      return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
    });
  }

  String _formatSelectedDate() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = _selectedDate;
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  BusModel? get _cheapestBus {
    if (_buses.isEmpty) return null;
    return _buses.reduce((a, b) => a.price < b.price ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeroSection()),
          SliverToBoxAdapter(child: _buildDeparturesSection()),
          SliverToBoxAdapter(child: _buildCheapestSection()),
          SliverToBoxAdapter(child: _buildPromoBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final topPadding = MediaQuery.of(context).padding.top;
    const heroImageHeight = 235.0;
    final section3Start = heroImageHeight + topPadding;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kBrandBlue, _kBrandBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: section3Start,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                Image.asset(
                  'assests/images/hero_bus.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.0, 0.45),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _kBrandBlue.withValues(alpha: 0.52),
                        _kBrandBlueDark.withValues(alpha: 0.58),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Seat',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                TextSpan(
                                  text: 'First',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF93C5FD),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Row(
                            children: [
                              Text(
                                '🇮🇳 INR',
                                style: TextStyle(
                                  color: Color(0xFFBFDBFE),
                                  fontSize: 12,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Color(0xFFBFDBFE),
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Find your seat. Then your bus.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Compare seats across all buses instantly',
                        style: TextStyle(
                          color: Color(0xFFBFDBFE),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHeroSearchCard(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Popular routes',
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'Chennai → Madurai',
                      'Bangalore → Chennai',
                      'Hyderabad → Bangalore',
                      'Coimbatore → Chennai',
                      'Mumbai → Pune',
                      'Bangalore → Mysore',
                    ]
                        .map(
                          (route) => GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              final parts = route.split(' → ');
                              setState(() {
                                _fromCtrl.text = parts[0];
                                _toCtrl.text = parts[1];
                              });
                              _loadAndSortBuses();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.directions_bus_outlined,
                                    size: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    route,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSearchCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _cityDropdownField(
                  label: 'From',
                  value: _fromCtrl.text,
                  dotColor: _kBrandBlue,
                  isFrom: true,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _swapCities,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swap_vert,
                    color: _kBrandBlue,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _cityDropdownField(
                  label: 'To',
                  value: _toCtrl.text,
                  dotColor: const Color(0xFFEF4444),
                  isFrom: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: _buildReadonlyField(
                    label: 'Departure',
                    value: _formatSelectedDate(),
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: _showTimeSlotPicker,
                  child: _buildReadonlyField(
                    label: 'Time slot',
                    value: _selectedTimeSlot,
                    icon: Icons.access_time_outlined,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBrandBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Search buses →',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _operatorLogo(String operator) {
    final style = _operatorLogoStyle(operator);
    final words = operator.split(' ').where((w) => w.isNotEmpty).toList();
    final initials = words
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: style.$1,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: style.$2,
        ),
      ),
    );
  }

  (Color, Color) _operatorLogoStyle(String operator) {
    final key = operator.toLowerCase();
    if (key.contains('vrl')) {
      return (const Color(0xFFFFC107), const Color(0xFF1E293B));
    }
    if (key.contains('srs')) {
      return (const Color(0xFFEF4444), Colors.white);
    }
    if (key.contains('kpn')) {
      return (const Color(0xFF16A34A), Colors.white);
    }
    if (key.contains('orange')) {
      return (const Color(0xFFF97316), Colors.white);
    }
    if (key.contains('ksrtc') || key.contains('tsrtc') || key.contains('setc')) {
      return (const Color(0xFF0EA5E9), Colors.white);
    }
    if (key.contains('parveen')) {
      return (const Color(0xFF7C3AED), Colors.white);
    }
    return (_kBrandBlue, Colors.white);
  }

  Widget _cityDropdownField({
    required String label,
    required String value,
    required Color dotColor,
    required bool isFrom,
  }) {
    return GestureDetector(
      onTap: () => _openCityPicker(isFrom: isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Select city' : value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: value.isEmpty
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadonlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: const Color(0xFF1A56DB),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeparturesSection() {
    final dateLabels = _getDateLabels();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Next bus departures',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(dateLabels.length, (i) {
                final isActive = i == _selectedDateIndex;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedDateIndex = i);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? _kBrandBlue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? _kBrandBlue
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      dateLabels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          _buses.isEmpty
              ? _emptyState()
              : Column(children: _buses.map(_buildBusCard).toList()),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.directions_bus_outlined,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            'No buses found for\n'
            '${_fromCtrl.text} → ${_toCtrl.text}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a popular route below',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(BusModel bus) {
    final isCheapest = bus.id == _cheapestBus?.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeatSelectionScreen(
              from: _fromCtrl.text,
              to: _toCtrl.text,
              date: _formatSelectedDate(),
              timeSlot: _selectedTimeSlot,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            _operatorLogo(bus.operator),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          bus.operator,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCheapest) ...[
                        const SizedBox(width: 6),
                        _badge(
                          'Cheapest',
                          const Color(0xFFF0FDF4),
                          const Color(0xFF16A34A),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_bus_outlined,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        bus.busType,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Live Tracking',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bus.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.star,
                        size: 10,
                        color: Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _badge(
                  bus.layout,
                  const Color(0xFFF8FAFC),
                  const Color(0xFF64748B),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCheapestSection() {
    final route = kFeaturedRoutes[_chartRouteIndex];
    final bestBars =
        _chartData.where((d) => d['isBest'] == true).toList();
    final Map<String, dynamic> cheapestBar = bestBars.isNotEmpty
        ? bestBars.first
        : <String, dynamic>{'price': 0, 'date': 'Today'};

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Find cheapest prices',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  key: ValueKey(_chartRouteIndex),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    "${route['from']} → ${route['to']}",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A56DB),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Cheapest one-way price per day',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: SizedBox(
              key: ValueKey(_chartRouteIndex),
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _chartData.map((d) {
                  final price = d['price'] as int;
                  final isBest = d['isBest'] as bool;
                  final isToday = d['isToday'] as bool;
                  final h =
                      price > 0 ? _barHeight(price, _chartData) : 10.0;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          price > 0 ? '₹$price' : '-',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: isBest
                                ? const Color(0xFF1A56DB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: h,
                          decoration: BoxDecoration(
                            color: isBest
                                ? const Color(0xFF1A56DB)
                                : isToday
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFFBFDBFE),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d['date'] as String,
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isToday
                                ? const Color(0xFF1A56DB)
                                : const Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              kFeaturedRoutes.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _chartRouteIndex ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _chartRouteIndex
                      ? const Color(0xFF1A56DB)
                      : const Color(0xFFBFDBFE),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Container(
              key: ValueKey(_chartRouteIndex),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A56DB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('💰', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cheapest · ${route['from']} → ${route['to']}",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cheapestBar['price'] != null &&
                                  (cheapestBar['price'] as int) > 0
                              ? '₹${cheapestBar['price']} starting price'
                              : 'No buses on this route',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A56DB),
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

  Widget _buildPromoBanner() {
    return Container(
      color: const Color(0xFFF0F4F8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: _onSearch,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A56DB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('🪑', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick your seat first',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'See availability across all buses',
                      style: TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Try it →',
                  style: TextStyle(
                    color: Color(0xFF1A56DB),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
