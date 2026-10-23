class Repayment {
  final int? id;
  final int debtId;
  final int amountSantim;
  final DateTime repaymentDate;
  final DateTime createdAt;

  const Repayment({
    this.id,
    required this.debtId,
    required this.amountSantim,
    required this.repaymentDate,
    required this.createdAt,
  });
}
