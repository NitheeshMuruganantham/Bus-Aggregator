import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bus_model.dart';
import '../data/mock_data.dart';
import 'seat_selection_screen.dart';

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

  final List<String> _timeSlots = [
    '6AM - 9AM',
    '9AM - 12PM',
    '12PM - 3PM',
    '3PM - 6PM',
    '6PM - 9PM',
    '9PM - 12AM',
  ];

  final List<Map<String, dynamic>> _priceData = [
    {'date': 'Jun 23', 'price': 720, 'height': 55.0},
    {'date': 'Jun 24', 'price': 680, 'height': 46.0},
    {'date': 'Today', 'price': 620, 'height': 34.0, 'best': true},
    {'date': 'Jun 27', 'price': 650, 'height': 40.0},
    {'date': 'Jun 28', 'price': 670, 'height': 44.0},
    {'date': 'Jun 29', 'price': 700, 'height': 49.0},
    {'date': 'Jun 30', 'price': 730, 'height': 55.0},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _loadAndSortBuses();
  }

  void _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fromCtrl.text = prefs.getString('last_from') ?? 'Bangalore';
      _toCtrl.text = prefs.getString('last_to') ?? 'Chennai';
    });
  }

  void _loadAndSortBuses() {
    List<BusModel> buses = getMockBuses();
    buses.sort(
      (a, b) => _parseTime(a.departure).compareTo(_parseTime(b.departure)),
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

  void _swapCities() {
    HapticFeedback.lightImpact();
    setState(() {
      final temp = _fromCtrl.text;
      _fromCtrl.text = _toCtrl.text;
      _toCtrl.text = temp;
    });
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
            const Text(
              'Select time slot',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            ..._timeSlots.map(
              (slot) => ListTile(
                contentPadding: EdgeInsets.zero,
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

  void _onSearch() {
    HapticFeedback.mediumImpact();
    if (_fromCtrl.text.trim().isEmpty || _toCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter From and To cities'),
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
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A56DB), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 16,
        16,
        24,
      ),
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
              const Text(
                '🇮🇳 INR',
                style: TextStyle(
                  color: Color(0xFFBFDBFE),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Find your seat. Then your bus.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Compare seats across all buses instantly',
            style: TextStyle(
              color: Color(0xFFBFDBFE),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildCityField(
                        label: 'From',
                        controller: _fromCtrl,
                        dotColor: const Color(0xFF1A56DB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _swapCities,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.swap_vert,
                          color: Color(0xFF1A56DB),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCityField(
                        label: 'To',
                        controller: _toCtrl,
                        dotColor: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _onSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56DB),
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
          ),
          const SizedBox(height: 16),
          const Text(
            'Popular routes',
            style: TextStyle(
              color: Color(0xFFBFDBFE),
              fontSize: 11,
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
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          route,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityField({
    required String label,
    required TextEditingController controller,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadonlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
      color: const Color(0xFFF0F4F8),
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
                      color: isActive
                          ? const Color(0xFF1A56DB)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF1A56DB)
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
          ..._buses.map(_buildBusCard),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBusCard(BusModel bus) {
    final isCheapest = bus.id == _cheapestBus?.id;
    final cheapestPlatformPrice =
        bus.platforms.values.reduce((a, b) => a < b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
              Row(
                children: [
                  if (isCheapest)
                    _badge(
                      'Cheapest',
                      const Color(0xFFF0FDF4),
                      const Color(0xFF16A34A),
                    ),
                  if (isCheapest) const SizedBox(width: 4),
                  _badge(
                    bus.layout,
                    const Color(0xFFEFF6FF),
                    const Color(0xFF1A56DB),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                bus.departure,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Expanded(
                child: Text(
                  '——— ${bus.duration} ———',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              Text(
                bus.arrival,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹$cheapestPlatformPrice',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A56DB),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${bus.availableSeats.length} seats free',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
              GestureDetector(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'View seats',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A56DB),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find cheapest prices',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Price for one passenger · '
            '${_fromCtrl.text} → ${_toCtrl.text}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _priceData.map((d) {
                final isActive = d['best'] == true;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '₹${d['price']}',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? const Color(0xFF1A56DB)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: d['height'] as double,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF1A56DB)
                              : const Color(0xFFBFDBFE),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d['date'] as String,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Color(0xFF94A3B8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFBFDBFE),
              ),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cheapest today · '
                      '${_fromCtrl.text} → ${_toCtrl.text}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: '₹620 ',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A56DB),
                            ),
                          ),
                          TextSpan(
                            text: 'via AbhiBus',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
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

  Widget _buildPromoBanner() {
    return Container(
      color: const Color(0xFFF0F4F8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
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

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }
}
