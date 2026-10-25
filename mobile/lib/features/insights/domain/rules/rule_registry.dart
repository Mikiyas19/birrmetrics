import 'package:birrmetrics/features/insights/domain/rules/insight_rule.dart';
import 'package:birrmetrics/features/insights/domain/rules/budget_rules.dart';
import 'package:birrmetrics/features/insights/domain/rules/category_rules.dart';
import 'package:birrmetrics/features/insights/domain/rules/debt_rules.dart';
import 'package:birrmetrics/features/insights/domain/rules/positive_rules.dart';
import 'package:birrmetrics/features/insights/domain/rules/spending_rules.dart';

final List<InsightRule> allInsightRules = [
  // Budget rules
  BudgetNotSetRule(),
  Budget50PctRule(),
  Budget80PctRule(),
  BudgetExceededRule(),
  BudgetProjectionRule(),
  BudgetOnTrackRule(),

  // Category rules
  TopCategoryRule(),
  CategorySpikeRule(),
  NewCategoryRule(),
  HeavyUncategorizedRule(),

  // Spending pattern rules
  DailySpikeRule(),
  LargestTransactionRule(),
  MonthStartRule(),
  NoSpendRule(),
  WeekendSpikeRule(),

  // Debt rules
  DebtOverdueRule(),
  DebtDueSoonRule(),
  NetDebtHighRule(),
  ManyPendingDebtsRule(),
  DebtNoDueDateRule(),

  // Positive rules
  FirstExpenseRule(),
  SpendStreakRule(),
  SavingsOpportunityRule(),
];
