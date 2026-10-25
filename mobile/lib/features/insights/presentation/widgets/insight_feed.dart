import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/core/theme/app_colors.dart';
import 'package:birrmetrics/core/theme/app_spacing.dart';
import 'package:birrmetrics/features/insights/domain/entities/insight.dart';
import 'package:birrmetrics/features/insights/presentation/providers/insight_providers.dart';

class InsightFeed extends ConsumerWidget {
  final List<Insight> insights;

  const InsightFeed({super.key, required this.insights});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: insights.isEmpty
          ? const SizedBox.shrink()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Insights for you',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.auto_awesome,
                      size: 18, color: AppColors.accent),
                ],
              ),
              TextButton(
                onPressed: () {
                  ref.read(insightsProvider.notifier).clearAll();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...insights.take(3).map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _InsightCard(insight: insight),
          )),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Insight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    switch (insight.severity) {
      case InsightSeverity.critical:
        bgColor = AppColors.danger.withValues(alpha: 0.1);
        iconColor = AppColors.danger;
        icon = Icons.warning_amber_rounded;
        break;
      case InsightSeverity.warning:
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        iconColor = AppColors.warning;
        icon = Icons.lightbulb_outline;
        break;
      case InsightSeverity.info:
        bgColor = AppColors.info.withValues(alpha: 0.1);
        iconColor = AppColors.info;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkText
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
