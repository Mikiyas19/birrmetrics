import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/features/auth/data/auth_service.dart';
import 'package:birrmetrics/core/storage/app_database.dart';
import 'package:birrmetrics/features/expenses/presentation/providers/expense_providers.dart';
import 'package:birrmetrics/features/debts/presentation/providers/debt_providers.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider), ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final AuthService _service;
  final Ref _ref;

  AuthNotifier(this._service, this._ref) : super(const AsyncLoading()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final hasToken = await _service.hasToken();
    state = AsyncData(hasToken);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _service.login(email: email, password: password);
      // Refresh providers to load new user's data
      _ref.read(expensesProvider.notifier).loadAll();
      _ref.read(debtsProvider.notifier).loadDebts();
      state = const AsyncData(true);
    } catch (e, st) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      state = AsyncError(cleanMessage, st);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    try {
      await _service.register(email: email, password: password, fullName: name);
      // Refresh providers to load new user's data
      _ref.read(expensesProvider.notifier).loadAll();
      _ref.read(debtsProvider.notifier).loadDebts();
      state = const AsyncData(true);
    } catch (e, st) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      state = AsyncError(cleanMessage, st);
    }
  }

  Future<void> logout() async {
    // 1. Wipe local DB to protect the next user
    await AppDatabase.wipeAllData();

    // 2. Force providers to reload (now empty) data
    _ref.read(expensesProvider.notifier).loadAll();
    _ref.read(debtsProvider.notifier).loadDebts();

    // 3. Delete the auth token
    await _service.logout();

    // 4. Update state
    state = const AsyncData(false);
  }
}
