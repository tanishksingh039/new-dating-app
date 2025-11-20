import 'package:flutter/material.dart';

/// CampusBound App Color Palette
class AppColors {
  // Primary Colors
  static const Color magentaPink = Color(0xFFA82953);
  static const Color warmPeach = Color(0xFFDA8568);
  static const Color softWarmPink = Color(0xFFBD585A);
  static const Color deepPurplePink = Color(0xFF7E1555);
  static const Color shadowyPurple = Color(0xFF4F2A51);
  static const Color mutedMauve = Color(0xFF85474D);

  // Derived Colors
  static const String appName = 'ShooLuv';
  static const Color primary = magentaPink;
  static const Color secondary = warmPeach;
  static const Color accent = softWarmPink;
  static const Color dark = deepPurplePink;
  static const Color darker = shadowyPurple;
  static const Color muted = mutedMauve;

  // Gradient combinations
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [magentaPink, softWarmPink, warmPeach],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepPurplePink, shadowyPurple, mutedMauve],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [warmPeach, softWarmPink],
  );

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFFFFFFFF);

  // Background Colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
}
