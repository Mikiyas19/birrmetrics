import 'package:flutter/widgets.dart';
abstract final class AppRadius {
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 24;
  static const double pill = 999;
  static const BorderRadius allMd   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg   = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl   = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));
}