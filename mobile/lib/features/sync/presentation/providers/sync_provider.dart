import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/features/sync/data/sync_service.dart';

final syncServiceProvider = Provider((ref) => SyncService());

final syncStateProvider = StateNotifierProvider<SyncNotifier, AsyncValue<String?>>((ref) {
  return SyncNotifier(ref.watch(syncServiceProvider));
});

class SyncNotifier extends StateNotifier<AsyncValue<String?>> {
  final SyncService _service;

  SyncNotifier(this._service) : super(const AsyncData(null));

  Future<void> syncNow() async {
    state = const AsyncLoading();
    try {
      final result = await _service.pushChanges();
      state = AsyncData(result);
    } catch (e) {
      state = AsyncError(e.toString().replaceAll('Exception: ', ''), StackTrace.current);
    }
  }
}