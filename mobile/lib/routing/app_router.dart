import 'package:go_router/go_router.dart';
import 'package:birrmetrics/routing/app_routes.dart';
import 'package:birrmetrics/shared/widgets/app_shell.dart';
import 'package:birrmetrics/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:birrmetrics/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:birrmetrics/features/debts/presentation/screens/debts_screen.dart';
import 'package:birrmetrics/features/insights/presentation/screens/insights_screen.dart';
import 'package:birrmetrics/features/settings/presentation/screens/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: AppRoutes.dashboard, builder: (context, state) => const DashboardScreen()),
        GoRoute(path: AppRoutes.expenses, builder: (context, state) => const ExpensesScreen()),
        GoRoute(path: AppRoutes.debts, builder: (context, state) => const DebtsScreen()),
        GoRoute(path: AppRoutes.insights, builder: (context, state) => const InsightsScreen()),
        GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
      ],
    ),
  ],
);