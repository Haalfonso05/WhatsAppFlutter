import 'package:flutter/material.dart';

const kPrimary = Color(0xFF4F46E5);
const kEmerald = Color(0xFF10B981);
const kAmber = Color(0xFFF59E0B);
const kRed = Color(0xFFEF4444);
const kSlate50 = Color(0xFFF8FAFC);
const kSlate100 = Color(0xFFF1F5F9);
const kSlate200 = Color(0xFFE2E8F0);
const kSlate300 = Color(0xFFCBD5E1);
const kSlate400 = Color(0xFF94A3B8);
const kSlate500 = Color(0xFF64748B);
const kSlate600 = Color(0xFF475569);
const kSlate700 = Color(0xFF334155);
const kSlate800 = Color(0xFF1E293B);
const kSlate900 = Color(0xFF0F172A);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: Brightness.light,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: kSlate50,
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: kSlate200),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kSlate200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kSlate200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kPrimary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kRed),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    labelStyle: const TextStyle(color: kSlate500, fontSize: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kSlate700,
      side: const BorderSide(color: kSlate200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: kPrimary),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 1,
    shadowColor: kSlate200,
    titleTextStyle: TextStyle(
      color: kSlate900,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: kSlate700),
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: Colors.white,
    selectedIconTheme: IconThemeData(color: kPrimary),
    selectedLabelTextStyle: TextStyle(color: kPrimary, fontWeight: FontWeight.w600),
    unselectedIconTheme: IconThemeData(color: kSlate400),
    unselectedLabelTextStyle: TextStyle(color: kSlate500),
  ),
);
