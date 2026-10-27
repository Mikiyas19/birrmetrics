import 'package:flutter/foundation.dart';
import 'package:birrmetrics/features/insights/domain/entities/insight.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_context.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_rule.dart';
import 'package:birrmetrics/features/insights/domain/rules/rule_registry.dart';

class InsightEngine {
  final List<InsightRule> _rules;
  final List<Insight> _existingInsights;

  InsightEngine({
    List<InsightRule>? rules,
    required List<Insight> existingInsights,
  })  : _rules = rules ?? allInsightRules,
        _existingInsights = existingInsights;

  List<Insight> evaluate(InsightContext context) {
    final newInsights = <Insight>[];

    for (final rule in _rules) {
      try {
        final candidates = rule.evaluate(context);
        for (final insight in candidates) {
          if (_shouldFire(insight, rule, context)) {
            final withExpiry = Insight(
              id: insight.id,
              ruleKey: insight.ruleKey,
              severity: insight.severity,
              title: insight.title,
              message: insight.message,
              payload: insight.payload,
              isRead: false,
              triggeredAt: insight.triggeredAt,
              expiresAt: rule.expiresIn != null
                  ? DateTime.now().add(rule.expiresIn!)
                  : null,
            );
            newInsights.add(withExpiry);
          }
        }
      } catch (e, st) {
        debugPrint('Rule ${rule.key} failed: $e\n$st');
      }
    }

    return newInsights;
  }

  bool _shouldFire(Insight insight, InsightRule rule, InsightContext context) {
    final now = DateTime.now();
    final currentSignature = rule.getDataSignature(context);

    for (final existing in _existingInsights) {
      if (existing.ruleKey != insight.ruleKey) continue;

      // If the data signature changed (e.g., user spent more money),
      // allow the rule to fire again with fresh numbers.
      final existingSig = existing.payload?['_sig'] as String? ?? '';
      if (currentSignature.isNotEmpty && currentSignature != existingSig) {
        return true;
      }

      // Otherwise apply deduplication window
      final elapsed = now.difference(existing.triggeredAt);
      switch (rule.dedupeWindow) {
        case 'once_per_day':
          if (elapsed.inHours < 6) return false;
          break;
        case 'once_per_week':
          if (elapsed.inDays < 3) return false;
          break;
        case 'once_per_month':
          if (elapsed.inDays < 7) return false;
          break;
        case 'always':
          break;
      }
    }
    return true;
  }
}
