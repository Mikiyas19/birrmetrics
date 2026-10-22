import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:birrmetrics/app.dart';
import 'package:birrmetrics/core/storage/app_database.dart'; // <-- IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize SQLite database
  await AppDatabase.instance;
  debugPrint('SQLite Database is ready!');

  runApp(const ProviderScope(child: BirrMetricsApp()));
}
