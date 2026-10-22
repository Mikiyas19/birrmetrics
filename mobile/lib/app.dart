import 'package:flutter/material.dart';
import 'package:birrmetrics/core/theme/app_theme.dart';
import 'package:birrmetrics/routing/app_router.dart';

class BirrMetricsApp extends StatelessWidget {
  const BirrMetricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BirrMetrics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}