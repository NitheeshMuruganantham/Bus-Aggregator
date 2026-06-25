import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/search_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const SeatFirstApp());
}

class SeatFirstApp extends StatelessWidget {
  const SeatFirstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeatFirst',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.cardBg,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const SearchScreen(),
    );
  }
}
