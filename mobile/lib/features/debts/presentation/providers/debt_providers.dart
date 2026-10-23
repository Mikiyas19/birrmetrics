import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/features/debts/data/repositories/debt_repository.dart';
import 'package:birrmetrics/features/debts/domain/entities/debt.dart';
import 'package:birrmetrics/features/debts/domain/entities/repayment.dart';

final debtRepositoryProvider = Provider((ref) => DebtRepository());

class DebtsState {
  final AsyncValue<List<Debt>> allDebts;
  final AsyncValue<List<Debt>> lentDebts;
  final AsyncValue<List<Debt>> borrowedDebts;
  final AsyncValue<List<Debt>> settledDebts;

  DebtsState({
    required this.allDebts,
    required this.lentDebts,
    required this.borrowedDebts,
    required this.settledDebts,
  });
}

class DebtsNotifier extends StateNotifier<DebtsState> {
  final DebtRepository _repo;
  final Ref _ref;

  DebtsNotifier(this._repo, this._ref) : super(DebtsState(
    allDebts: const AsyncLoading(),
    lentDebts: const AsyncLoading(),
    borrowedDebts: const AsyncLoading(),
    settledDebts: const AsyncLoading(),
  )) {
    loadDebts();
  }

  Future<void> loadDebts() async {
    state = DebtsState(
      allDebts: const AsyncLoading(),
      lentDebts: state.lentDebts,
      borrowedDebts: state.borrowedDebts,
      settledDebts: state.settledDebts,
    );

    try {
      final debts = await _repo.getAllDebts();

      final lent = debts.where((d) => d.isLent && d.status != 'settled').toList();
      final borrowed = debts.where((d) => !d.isLent && d.status != 'settled').toList();
      final settled = debts.where((d) => d.status == 'settled').toList();

      state = DebtsState(
        allDebts: AsyncData(debts),
        lentDebts: AsyncData(lent),
        borrowedDebts: AsyncData(borrowed),
        settledDebts: AsyncData(settled),
      );
    } catch (e, st) {
      state = DebtsState(
        allDebts: AsyncError(e, st),
        lentDebts: AsyncError(e, st),
        borrowedDebts: AsyncError(e, st),
        settledDebts: AsyncError(e, st),
      );
    }
  }

  Future<void> addDebt(Debt debt) async {
    await _repo.addDebt(debt);
    await loadDebts();
  }

  Future<void> partialRepay(int debtId, int amountSantim, DateTime date) async {
    await _repo.partialRepay(debtId, amountSantim, date);
    _ref.invalidate(repaymentHistoryProvider(debtId));
    await loadDebts();
  }

  Future<void> settleDebt(int debtId) async {
    await _repo.settleDebt(debtId);
    _ref.invalidate(repaymentHistoryProvider(debtId));
    await loadDebts();
  }

  // NEW: Update debt
  Future<void> updateDebt(Debt debt) async {
    await _repo.updateDebt(debt);
    await loadDebts();
  }

  // NEW: Delete debt
  Future<void> deleteDebt(int debtId) async {
    await _repo.deleteDebt(debtId);
    await loadDebts();
  }
}

final debtsProvider = StateNotifierProvider<DebtsNotifier, DebtsState>((ref) {
  return DebtsNotifier(ref.watch(debtRepositoryProvider), ref);
});

final repaymentHistoryProvider = FutureProvider.autoDispose.family<List<Repayment>, int>((ref, debtId) async {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.getRepaymentsForDebt(debtId);
});
