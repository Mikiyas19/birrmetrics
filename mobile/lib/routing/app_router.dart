import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:birrmetrics/routing/app_routes.dart';
import 'package:birrmetrics/shared/widgets/app_shell.dart';
import 'package:birrmetrics/features/auth/presentation/providers/auth_provider.dart';
import 'package:birrmetrics/features/auth/presentation/screens/login_screen.dart';
import 'package:birrmetrics/features/auth/presentation/screens/register_screen.dart';
import 'package:birrmetrics/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:birrmetrics/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:birrmetrics/features/debts/presentation/screens/debts_screen.dart';
import 'package:birrmetrics/features/insights/presentation/screens/insights_screen.dart';
import 'package:birrmetrics/features/settings/presentation/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      // 1. Wait during loading
      if (authState is AsyncLoading) return null;
      
      // 2. Stay on the current page if there's an error (e.g. wrong password)
      if (authState is AsyncError) return null;

      // 3. Get the current logged-in state
      final isLoggedIn = authState.valueOrNull ?? false;
      final isAuthRoute = state.matchedLocation == AppRoutes.login || 
                          state.matchedLocation == AppRoutes.register;

      // 4. Not logged in → force to login
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;

      // 5. Logged in → force to dashboard
      if (isLoggedIn && isAuthRoute) return AppRoutes.dashboard;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.expenses,
            builder: (context, state) => const ExpensesScreen(),
          ),
          GoRoute(
            path: AppRoutes.debts,
            builder: (context, state) => const DebtsScreen(),
          ),
          GoRoute(
            path: AppRoutes.insights,
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});