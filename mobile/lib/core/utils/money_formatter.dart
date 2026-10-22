import 'package:intl/intl.dart';

abstract final class MoneyFormatter {
  static final NumberFormat _etbFormat = NumberFormat.currency(
    locale: 'en_ET',
    symbol: 'ETB ',
    decimalDigits: 2,
  );

  static String formatSantim(int santim) {
    final double amount = santim / 100.0;
    return _etbFormat.format(amount);
  }

  static int toSantim(double amount) => (amount * 100).round();
}