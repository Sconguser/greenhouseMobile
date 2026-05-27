import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: Colors.white,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.black),
  ),
  dividerColor: Colors.transparent,
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
    elevation: 2,
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white),
  ),
  dividerColor: Colors.transparent,
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: const Color(0xFF1E1E1E),
    selectedItemColor: Colors.green[300],
    unselectedItemColor: Colors.grey[500],
    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    elevation: 2,
  ),
);

double modalBottomSheetElevation = 5;