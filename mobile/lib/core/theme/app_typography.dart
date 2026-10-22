import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
abstract final class AppTypography {
  static TextTheme buildTextTheme(Brightness brightness) {
    final Color base = brightness == Brightness.light ? const Color(0xFF0B1220) : const Color(0xFFE6EDF3);
    TextTheme t = GoogleFonts.interTextTheme();
    return t.copyWith(
      displayMedium: t.displayMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, color: base),
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 15, color: base),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 14, color: base),
      titleLarge: t.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: base),
      labelLarge: t.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: base),
      labelMedium: t.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: base),
      labelSmall: t.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: base),
    );
  }
  static TextStyle money(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.displayMedium!.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }
}