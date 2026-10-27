class ExpenseCategory {
  final int? id;
  final String name;
  final String icon;
  final int isSystem;
  final int isDeletable;

  const ExpenseCategory({
    this.id,
    required this.name,
    required this.icon,
    this.isSystem = 0,
    this.isDeletable = 1,
  });
}
