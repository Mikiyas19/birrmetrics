import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/features/insights/data/repositories/insight_repository.dart';
import 'package:birrmetrics/features/insights/domain/entities/insight.dart';

final insightRepositoryProvider = Provider((ref) => InsightRepository());

class InsightsNotifier extends StateNotifier<AsyncValue<List<Insight>>> {
  final InsightRepository _repo;

  InsightsNotifier(this._repo) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    // Keep existing data if we have it to prevent UI flashes
    final current = state.valueOrNull;
    if (current == null) {
      state = const AsyncLoading();
    }

    try {
      final insights = await _repo.getRecentInsights();
      state = AsyncData(insights);
    } catch (e, st) {
      if (current != null) {
        state = AsyncData(current);
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  Future<void> addInsights(List<Insight> insights) async {
    for (final insight in insights) {
      await _repo.insertInsight(insight);
    }
    await _repo.pruneExpired();
    await load();
  }

  Future<void> markAsRead(int insightId) async {
    await _repo.markAsRead(insightId);
    await load();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    await load();
  }
}

final insightsProvider =
StateNotifierProvider<InsightsNotifier, AsyncValue<List<Insight>>>((ref) {
  return InsightsNotifier(ref.watch(insightRepositoryProvider));
});
