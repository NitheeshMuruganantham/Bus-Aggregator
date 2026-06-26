import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color busShell;
  final Color aisle;
  final Color seatAvailable;
  final Color seatAvailableBorder;
  final Color seatSelected;
  final Color seatSoldOut;
  final Color seatLowStock;
  final Color heroStart;
  final Color heroEnd;
  final Color chipBg;
  final Color shadow;
  final Color onPrimary;

  const AppPalette({
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.busShell,
    required this.aisle,
    required this.seatAvailable,
    required this.seatAvailableBorder,
    required this.seatSelected,
    required this.seatSoldOut,
    required this.seatLowStock,
    required this.heroStart,
    required this.heroEnd,
    required this.chipBg,
    required this.shadow,
    required this.onPrimary,
  });

  @override
  AppPalette copyWith({
    Color? cardBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? busShell,
    Color? aisle,
    Color? seatAvailable,
    Color? seatAvailableBorder,
    Color? seatSelected,
    Color? seatSoldOut,
    Color? seatLowStock,
    Color? heroStart,
    Color? heroEnd,
    Color? chipBg,
    Color? shadow,
    Color? onPrimary,
  }) {
    return AppPalette(
      cardBg: cardBg ?? this.cardBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      busShell: busShell ?? this.busShell,
      aisle: aisle ?? this.aisle,
      seatAvailable: seatAvailable ?? this.seatAvailable,
      seatAvailableBorder: seatAvailableBorder ?? this.seatAvailableBorder,
      seatSelected: seatSelected ?? this.seatSelected,
      seatSoldOut: seatSoldOut ?? this.seatSoldOut,
      seatLowStock: seatLowStock ?? this.seatLowStock,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      chipBg: chipBg ?? this.chipBg,
      shadow: shadow ?? this.shadow,
      onPrimary: onPrimary ?? this.onPrimary,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      busShell: Color.lerp(busShell, other.busShell, t)!,
      aisle: Color.lerp(aisle, other.aisle, t)!,
      seatAvailable: Color.lerp(seatAvailable, other.seatAvailable, t)!,
      seatAvailableBorder:
          Color.lerp(seatAvailableBorder, other.seatAvailableBorder, t)!,
      seatSelected: Color.lerp(seatSelected, other.seatSelected, t)!,
      seatSoldOut: Color.lerp(seatSoldOut, other.seatSoldOut, t)!,
      seatLowStock: Color.lerp(seatLowStock, other.seatLowStock, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
    );
  }

  static const light = AppPalette(
    cardBg: Colors.white,
    textPrimary: Color(0xFF132968),
    textSecondary: Color(0xFF6B7280),
    border: Color(0xFFE8ECF1),
    busShell: Colors.white,
    aisle: Color(0xFFF0F2F5),
    seatAvailable: Colors.white,
    seatAvailableBorder: Color(0xFFCBD5E1),
    seatSelected: Color(0xFFFA5353),
    seatSoldOut: Color(0xFFE2E8F0),
    seatLowStock: Color(0xFFF59E0B),
    heroStart: Color(0xFFE8EEF8),
    heroEnd: Color(0xFFF5F0EB),
    chipBg: Color(0xFFF8F9FB),
    shadow: Color(0x14000000),
    onPrimary: Colors.white,
  );

  static const dark = AppPalette(
    cardBg: Color(0xFF1C1C1E),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFF8E8E93),
    border: Color(0xFF2C2C2E),
    busShell: Color(0xFF1C1C1E),
    aisle: Color(0xFF2C2C2E),
    seatAvailable: Color(0xFF2C2C2E),
    seatAvailableBorder: Color(0xFF48484A),
    seatSelected: Color(0xFFFA5353),
    seatSoldOut: Color(0xFF3A3A3C),
    seatLowStock: Color(0xFFF59E0B),
    heroStart: Color(0xFF1A1A2E),
    heroEnd: Color(0xFF16213E),
    chipBg: Color(0xFF2C2C2E),
    shadow: Color(0x40000000),
    onPrimary: Colors.white,
  );
}

extension AppThemeX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class AppTheme {
  static const Color _coral = Color(0xFFFA5353);
  static const Color _navy = Color(0xFF132968);

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F9FB),
      primaryColor: _coral,
      colorScheme: const ColorScheme.light(
        primary: _coral,
        secondary: _navy,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSurface: _navy,
      ),
      extensions: const [AppPalette.light],
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: _navy,
        iconTheme: IconThemeData(color: _navy),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: AppPalette.light.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE8ECF1)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _coral,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0F0F10),
      primaryColor: _coral,
      colorScheme: const ColorScheme.dark(
        primary: _coral,
        secondary: Color(0xFF5B8DEF),
        surface: Color(0xFF1C1C1E),
        onPrimary: Colors.white,
        onSurface: Color(0xFFF5F5F7),
      ),
      extensions: const [AppPalette.dark],
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F0F10),
        elevation: 0,
        centerTitle: true,
        foregroundColor: Color(0xFFF5F5F7),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C1C1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C2C2E)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _coral,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
