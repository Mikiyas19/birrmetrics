import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:birrmetrics/routing/app_routes.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    
    int currentIndex = 0;
    if (location.startsWith(AppRoutes.expenses)) currentIndex = 1;
    if (location.startsWith(AppRoutes.debts)) currentIndex = 2;
    if (location.startsWith(AppRoutes.insights)) currentIndex = 3;
    if (location.startsWith(AppRoutes.settings)) currentIndex = 4;

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go(AppRoutes.dashboard);
            case 1: context.go(AppRoutes.expenses);
            case 2: context.go(AppRoutes.debts);
            case 3: context.go(AppRoutes.insights);
            case 4: context.go(AppRoutes.settings);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.swap_horiz_outlined), selectedIcon: Icon(Icons.swap_horiz), label: 'Debts'),
          NavigationDestination(icon: Icon(Icons.lightbulb_outline), selectedIcon: Icon(Icons.lightbulb), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}