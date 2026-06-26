import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/search_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const SeatFirstApp());
}

class SeatFirstApp extends StatefulWidget {
  const SeatFirstApp({super.key});

  @override
  State<SeatFirstApp> createState() => _SeatFirstAppState();
}

class _SeatFirstAppState extends State<SeatFirstApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_theme') ?? false;
    if (mounted) {
      setState(() {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      });
    }
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    await prefs.setBool('is_dark_theme', _themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeatFirst',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: SearchScreen(onToggleTheme: toggleTheme),
    );
  }
}
