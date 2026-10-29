import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/core/theme/app_spacing.dart';
import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/auth/presentation/providers/auth_provider.dart';
import 'package:birrmetrics/features/budget/presentation/providers/budget_provider.dart';
import 'package:birrmetrics/features/budget/presentation/widgets/budget_progress_card.dart';
import 'package:birrmetrics/features/dashboard/presentation/widgets/recent_expenses_list.dart';
import 'package:birrmetrics/features/debts/presentation/providers/debt_providers.dart';
import 'package:birrmetrics/features/expenses/presentation/providers/expense_providers.dart';
import 'package:birrmetrics/features/expenses/presentation/screens/add_expense_sheet.dart';
import 'package:birrmetrics/features/insights/domain/engine/insight_engine.dart';
import 'package:birrmetrics/features/insights/domain/entities/insight.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_context.dart';
import 'package:birrmetrics/features/insights/domain/rules/rule_registry.dart';
import 'package:birrmetrics/features/insights/presentation/providers/insight_providers.dart';
import 'package:birrmetrics/features/insights/presentation/widgets/insight_feed.dart';
import 'package:birrmetrics/features/reminders/presentation/screens/reminders_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isEvaluating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluateInsights();
    });
  }

  Future<void> _evaluateInsights() async {
    if (_isEvaluating) return;
    _isEvaluating = true;

    try {
      await ref.read(insightRepositoryProvider).pruneExpired();

      final expenseState = ref.read(expensesProvider);
      final debtState = ref.read(debtsProvider);
      final budget = ref.read(monthlyBudgetProvider);
      final existingInsights = ref.read(insightsProvider).value ?? [];

      if (expenseState.list is! AsyncData) return;
      if (debtState.lentDebts is! AsyncData || debtState.borrowedDebts is! AsyncData) return;

      final expenses = expenseState.list.value!;
      final activeDebts = [
        ...debtState.lentDebts.value!,
        ...debtState.borrowedDebts.value!,
      ];

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final startOf7DaysAgo = now.subtract(const Duration(days: 7));

      final monthExpenses = expenses.where((e) => e.expenseDate.isAfter(startOfMonth)).toList();
      final last7 = expenses.where((e) => e.expenseDate.isAfter(startOf7DaysAgo)).toList();
      final lastMonth = expenses.where((e) => e.expenseDate.isAfter(startOfLastMonth) && e.expenseDate.isBefore(startOfMonth)).toList();

      final spendByCat = <int, int>{};
      for (final e in monthExpenses) {
        spendByCat[e.categoryId] = (spendByCat[e.categoryId] ?? 0) + e.amountSantim;
      }

      final categoryNames = <int, String>{
        1: 'Food', 2: 'Transport', 3: 'Education', 4: 'Fun',
        5: 'Health', 6: 'Bills', 7: 'Other',
      };

      final daysElapsed = now.day;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final totalSpent = monthExpenses.fold<int>(0, (s, e) => s + e.amountSantim);

      final ctx = InsightContext(
        now: now,
        monthExpenses: monthExpenses,
        last7DaysExpenses: last7,
        lastMonthExpenses: lastMonth,
        activeDebts: activeDebts.where((d) => d.status != 'settled').toList(),
        monthlyBudgetSantim: budget,
        spendByCategory: spendByCat,
        categoryNames: categoryNames,
        totalSpentThisMonth: totalSpent,
        daysElapsed: daysElapsed,
        daysInMonth: daysInMonth,
      );

      final engine = InsightEngine(existingInsights: existingInsights);
      final newInsights = engine.evaluate(ctx);

      if (newInsights.isNotEmpty) {
        final signatureMap = <String, String>{};
        for (final rule in allInsightRules) {
          signatureMap[rule.key] = rule.getDataSignature(ctx);
        }

        final enriched = newInsights.map((i) => Insight(
          ruleKey: i.ruleKey,
          severity: i.severity,
          title: i.title,
          message: i.message,
          payload: {...(i.payload ?? {}), '_sig': signatureMap[i.ruleKey] ?? ''},
          isRead: i.isRead,
          triggeredAt: i.triggeredAt,
          expiresAt: i.expiresAt,
        )).toList();

        await ref.read(insightsProvider.notifier).addInsights(enriched);
      }

      final newKeys = newInsights.map((i) => i.ruleKey).toSet();
      for (final old in existingInsights) {
        if (old.ruleKey == 'FIRST_EXPENSE' && !newKeys.contains('FIRST_EXPENSE')) {
          await ref.read(insightRepositoryProvider).deleteInsight(old.id!);
        }
      }
    } finally {
      _isEvaluating = false;
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will be logged out of BirrMetrics. Your local data will remain on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expensesProvider);
    final insightsAsync = ref.watch(insightsProvider);

    ref.listen(expensesProvider, (previous, next) {
      if (next.list is AsyncData && previous?.list != next.list) {
        _evaluateInsights();
      }
    });
    ref.listen(debtsProvider, (previous, next) {
      if (next.lentDebts is AsyncData && next.borrowedDebts is AsyncData && previous?.lentDebts != next.lentDebts) {
        _evaluateInsights();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddExpenseSheet(),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: 120,
          ),
          children: [
            insightsAsync.when(
              data: (insights) => InsightFeed(insights: insights),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const BudgetProgressCard(),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Spent This Month',
                        style: Theme.of(context).textTheme.bodyLarge),
                    expenseState.total.when(
                      data: (santim) => Text(
                        MoneyFormatter.formatSantim(santim),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      loading: () => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, _) => const Text('Error'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Recent Transactions',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            expenseState.list.when(
              data: (expenses) =>
                  RecentExpensesList(expenses: expenses, shrinkWrap: true),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }
}