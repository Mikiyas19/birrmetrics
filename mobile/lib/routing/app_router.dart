import 'package:flutter/material.dart';
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
        GoRoute(
          path: AppRoutes.dashboard,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const DashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: AppRoutes.expenses,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ExpensesScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: AppRoutes.debts,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const DebtsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: AppRoutes.insights,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const InsightsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
      ],
    ),
  ],
);
