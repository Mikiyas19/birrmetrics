import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:birrmetrics/core/theme/app_colors.dart';
import 'package:birrmetrics/core/utils/money_formatter.dart';
import 'package:birrmetrics/features/expenses/domain/entities/expense.dart';

class SpendingPieChart extends StatefulWidget {
  final List<Expense> expenses;

  const SpendingPieChart({super.key, required this.expenses});

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // 1. Group expenses by category
    final Map<String, int> categoryTotals = {};
    for (final e in widget.expenses) {
      final name = e.categoryName ?? 'Other';
      categoryTotals[name] = (categoryTotals[name] ?? 0) + e.amountSantim;
    }

    if (categoryTotals.isEmpty) {
      return const Center(child: Text('No expenses to visualize this month.'));
    }

    // 2. Sort by amount (largest first)
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = sortedEntries.fold<int>(0, (sum, e) => sum + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending by Category',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse
                        .touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: List.generate(sortedEntries.length, (i) {
                final entry = sortedEntries[i];
                final isTouched = i == touchedIndex;
                final percent = (entry.value / total) * 100;
                final color =
                AppColors.categoryPalette[i % AppColors.categoryPalette.length];

                return PieChartSectionData(
                  color: color,
                  value: entry.value.toDouble(),
                  title: percent > 5 ? '${percent.toStringAsFixed(0)}%' : '',
                  radius: isTouched ? 60 : 50,
                  titleStyle: TextStyle(
                    fontSize: isTouched ? 16 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List.generate(sortedEntries.length, (i) {
            final entry = sortedEntries[i];
            final color =
            AppColors.categoryPalette[i % AppColors.categoryPalette.length];

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.key} (${MoneyFormatter.formatSantim(entry.value)})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
