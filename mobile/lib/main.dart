import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:birrmetrics/app.dart';
import 'package:birrmetrics/core/notifications/notification_service.dart';
import 'package:birrmetrics/core/storage/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env
  await dotenv.load(fileName: ".env");

  // Initialize SQLite database
  await AppDatabase.instance;
  debugPrint('SQLite Database is ready!');

  // Initialize Notification Service
  await NotificationService().init();
  debugPrint('Notification Service is ready!');

  runApp(const ProviderScope(child: BirrMetricsApp()));
}
