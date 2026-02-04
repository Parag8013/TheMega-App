// Money Tracker Module Entry Point
// This integrates the money tracker as a sub-module in the mega app

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/module_launcher.dart';
import 'features/transactions/providers/transaction_provider.dart';
import 'features/accounts/providers/account_provider.dart';
import 'features/charts/providers/charts_provider.dart';
import 'features/transactions/providers/debt_receivables_provider.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'core/database/database_helper.dart';
import 'core/services/platform_aware_sms.dart';
import 'app/theme/app_theme.dart';

class MoneyTrackerModule extends ModuleEntry {
  @override
  String get moduleId => 'money_tracker';

  @override
  String get moduleName => 'Money Tracker';

  @override
  String get moduleVersion => '1.0.0';

  @override
  Widget buildModule(BuildContext context, ModuleContext moduleContext) {
    return MoneyTrackerApp(moduleContext: moduleContext);
  }

  @override
  Future<void> onModuleInit() async {
    print('💰 Money Tracker module initialized');

    // Initialize SMS service only on Android
    if (Platform.isAndroid) {
      try {
        await PlatformAwareSmsService.initService();
        print('💰 SMS auto-detection enabled (Android)');
      } catch (e) {
        print('⚠️ SMS service initialization failed: $e');
      }
    } else {
      print('ℹ️ SMS features disabled (${Platform.operatingSystem})');
    }
  }

  @override
  Future<void> onModuleDispose() async {
    print('💰 Money Tracker module disposed');
  }
}

/// Main Money Tracker Application
class MoneyTrackerApp extends StatefulWidget {
  final ModuleContext moduleContext;

  const MoneyTrackerApp({Key? key, required this.moduleContext})
    : super(key: key);

  @override
  State<MoneyTrackerApp> createState() => _MoneyTrackerAppState();
}

class _MoneyTrackerAppState extends State<MoneyTrackerApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      // Initialize database with module context
      DatabaseHelper.instance.initializeWithContext(widget.moduleContext);
      // Trigger database initialization
      await DatabaseHelper.instance.database;
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ Database initialization error: $e');
      setState(() {
        _isInitialized = true; // Continue anyway
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ChartsProvider()),
        ChangeNotifierProvider(create: (_) => DebtReceivablesProvider()),
      ],
      child: Theme(data: AppTheme.darkTheme, child: const DashboardScreen()),
    );
  }
}
