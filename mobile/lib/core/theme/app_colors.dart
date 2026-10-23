import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary       = Color(0xFF0F3D3E);
  static const Color primaryLight  = Color(0xFF1A5C5E);
  static const Color primaryDark   = Color(0xFF092B2C);
  static const Color accent        = Color(0xFF2ECC9B);
  static const Color accentSoft    = Color(0xFFD6F5EA);

  // Semantic
  static const Color success       = Color(0xFF22C55E);
  static const Color warning       = Color(0xFFF2A65A); // <-- Added this back
  static const Color danger        = Color(0xFFE04F5F);
  static const Color info          = Color(0xFF3B82F6);

  // Light surfaces
  static const Color bg            = Color(0xFFF7F8FA);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceAlt    = Color(0xFFF0F2F5);
  static const Color border        = Color(0xFFE3E7ED);

  // Light text
  static const Color textPrimary   = Color(0xFF0B1220);
  static const Color textSecondary = Color(0xFF5B6472);
  static const Color textMuted     = Color(0xFF8B97A5);

  // Dark surfaces
  static const Color darkBg        = Color(0xFF0A0F14);
  static const Color darkSurface   = Color(0xFF121A22);
  static const Color darkSurface2  = Color(0xFF1A242E);
  static const Color darkBorder    = Color(0xFF243240);

  // Dark text
  static const Color darkText      = Color(0xFFE6EDF3);
  static const Color darkMuted     = Color(0xFF8B97A5);

  static const List<Color> categoryPalette = <Color>[
    Color(0xFF2ECC9B), Color(0xFF3B82F6), Color(0xFFF2A65A),
    Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFF59E0B),
    Color(0xFF14B8A6), Color(0xFFEF4444), Color(0xFF6366F1),
    Color(0xFF84CC16),
  ];
}
