class Budget {
  final int? id;
  final int userId;
  final String period;        // 'YYYY-MM', e.g., '2026-10'
  final int amountSantim;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Budget({
    this.id,
    required this.userId,
    required this.period,
    required this.amountSantim,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Helper: current month in 'YYYY-MM' format
  static String currentPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
