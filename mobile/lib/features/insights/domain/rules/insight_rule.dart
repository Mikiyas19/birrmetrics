import 'package:birrmetrics/features/insights/domain/entities/insight.dart';
import 'package:birrmetrics/features/insights/domain/rules/insight_context.dart';

abstract class InsightRule {
  String get key;

  /// 'once_per_day' | 'once_per_week' | 'once_per_month' | 'always'
  String get dedupeWindow => 'once_per_day';

  /// How long before this insight expires. null = never expires.
  Duration? get expiresIn => const Duration(days: 7);

  /// A "signature" that identifies the input data.
  /// If this changes (e.g., total spend grows from 550 to 800),
  /// the dedupe check is bypassed and the rule can fire again.
  String getDataSignature(InsightContext context) => '';

  List<Insight> evaluate(InsightContext context);
}
