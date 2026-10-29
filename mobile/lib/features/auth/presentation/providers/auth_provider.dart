import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birrmetrics/features/auth/data/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

// This provider tells the app if the user is logged in or not
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AsyncLoading()) {
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
      state = const AsyncData(true);
    } catch (e, st) {
      // Clean up the error message (remove "Exception: ")
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      state = AsyncError(cleanMessage, st);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    try {
      await _service.register(email: email, password: password, fullName: name);
      state = const AsyncData(true);
    } catch (e, st) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      state = AsyncError(cleanMessage, st);
    }
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AsyncData(false);
  }
}