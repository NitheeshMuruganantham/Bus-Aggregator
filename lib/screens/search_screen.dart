import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/navigation.dart';
import 'seat_selection_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  DateTime? _selectedDate;
  String _timeSlot = '9PM - 12AM';
  late AnimationController _swapController;

  static const List<String> _timeSlots = [
    '6AM - 9AM',
    '9AM - 12PM',
    '12PM - 3PM',
    '3PM - 6PM',
    '6PM - 9PM',
    '9PM - 12AM',
  ];

  static const List<Map<String, String>> _popularRoutes = [
    {'from': 'Chennai', 'to': 'Madurai'},
    {'from': 'Bangalore', 'to': 'Chennai'},
    {'from': 'Hyderabad', 'to': 'Bangalore'},
    {'from': 'Coimbatore', 'to': 'Chennai'},
    {'from': 'Mumbai', 'to': 'Pune'},
  ];

  @override
  void initState() {
    super.initState();
    _swapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fromController.text = prefs.getString('last_from') ?? '';
      _toController.text = prefs.getString('last_to') ?? '';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    await prefs.setString('last_from', from);
    await prefs.setString('last_to', to);

    final recent = prefs.getStringList('recent_searches') ?? [];
    final entry = '$from|$to';
    recent.remove(entry);
    recent.insert(0, entry);
    if (recent.length > 5) {
      recent.removeRange(5, recent.length);
    }
    await prefs.setStringList('recent_searches', recent);
  }

  void _swapCities() {
    final from = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = from;
    _swapController.forward(from: 0);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _onFindSeats() {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();

    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both From and To cities'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a travel date'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    _savePreferences();

    Navigator.push(
      context,
      fadeRoute(
        SeatSelectionScreen(
          from: from,
          to: to,
          date: _formatDate(_selectedDate!),
          timeSlot: _timeSlot,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _swapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.tagline,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildCityField(
                      icon: Icons.trip_origin,
                      controller: _fromController,
                      hint: 'From city',
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RotationTransition(
                          turns: Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: _swapController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: IconButton(
                            onPressed: _swapCities,
                            icon: const Icon(
                              Icons.swap_vert,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildCityField(
                      icon: Icons.location_on,
                      controller: _toController,
                      hint: 'To city',
                    ),
                    const SizedBox(height: 16),
                    _buildTapRow(
                      icon: Icons.calendar_today,
                      label: _selectedDate == null
                          ? 'Select Date'
                          : _formatDate(_selectedDate!),
                      onTap: _pickDate,
                    ),
                    const Divider(color: AppColors.border),
                    _buildTimeSlotRow(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Popular Routes',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _popularRoutes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final route = _popularRoutes[index];
                    return ActionChip(
                      label: Text(
                        '${route['from']} → ${route['to']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppColors.cardBg,
                      side: const BorderSide(color: AppColors.border),
                      onPressed: () {
                        setState(() {
                          _fromController.text = route['from']!;
                          _toController.text = route['to']!;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onFindSeats,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Find Seats →',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityField({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTapRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: _selectedDate == null && icon == Icons.calendar_today
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _timeSlot,
                isExpanded: true,
                dropdownColor: AppColors.cardBg,
                style: const TextStyle(color: AppColors.textPrimary),
                items: _timeSlots
                    .map((slot) => DropdownMenuItem(
                          value: slot,
                          child: Text(slot),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _timeSlot = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
