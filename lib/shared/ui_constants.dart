import 'package:flutter/material.dart';

/// Shared seed colour for both themes so the brand green stays consistent.
const Color _seedGreen = Color(0xFF2E7D32); // green 800

// ---------------------------------------------------------------------------
// LIGHT THEME
// ---------------------------------------------------------------------------

final ColorScheme _lightScheme = ColorScheme.fromSeed(
  seedColor: _seedGreen,
  brightness: Brightness.light,
).copyWith(
  surface: Colors.white,
);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: _lightScheme,
  scaffoldBackgroundColor: const Color(0xFFF4F6F4),
  cardColor: Colors.white,
  cardTheme: const CardThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 1,
    margin: EdgeInsets.all(8),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Colors.green[700],
    unselectedItemColor: Colors.grey[600],
    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.green[700],
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 2,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF0F2F0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  ),
);

// ---------------------------------------------------------------------------
// DARK THEME
//
// A soft, consistent dark palette. We deliberately avoid pure black (#000)
// and pure white text to keep contrast comfortable rather than eye-burning.
// Surfaces use a layered hierarchy: scaffold (darkest) < card < elevated.
// ---------------------------------------------------------------------------

const Color _darkScaffold = Color(0xFF121212);
const Color _darkSurface = Color(0xFF1E1E1E); // cards / sheets / app bar
const Color _darkSurfaceHigh = Color(0xFF262626); // dialogs / elevated
const Color _darkGreen = Color(0xFF81C784); // green 300 — readable accent
const Color _darkOnSurface = Color(0xFFE6E6E6); // off-white, not pure white

final ColorScheme _darkScheme = ColorScheme.fromSeed(
  seedColor: _seedGreen,
  brightness: Brightness.dark,
).copyWith(
  primary: _darkGreen,
  surface: _darkSurface,
  onSurface: _darkOnSurface,
  surfaceContainerHighest: _darkSurfaceHigh,
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: _darkScheme,
  scaffoldBackgroundColor: _darkScaffold,
  canvasColor: _darkScaffold,
  cardColor: _darkSurface,
  dividerColor: const Color(0xFF2C2C2C),
  cardTheme: const CardThemeData(
    color: _darkSurface,
    surfaceTintColor: Colors.transparent,
    elevation: 1,
    margin: EdgeInsets.all(8),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: _darkSurfaceHigh,
    surfaceTintColor: Colors.transparent,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: _darkSurface,
    surfaceTintColor: Colors.transparent,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: _darkSurface,
    selectedItemColor: _darkGreen,
    unselectedItemColor: Color(0xFF9E9E9E),
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _darkSurface,
    foregroundColor: _darkOnSurface,
    surfaceTintColor: Colors.transparent,
    elevation: 2,
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: _darkGreen,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _darkSurfaceHigh,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  ),
);

double modalBottomSheetElevation = 5;

/// Soft shadow colour that works in both light and dark themes.
/// Use instead of a hardcoded grey so cards don't glare in dark mode.
Color cardShadowColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.grey.withValues(alpha: 0.4);
}