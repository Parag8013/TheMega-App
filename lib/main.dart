import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/module_provider.dart';
import 'core/services/module_launcher.dart';
import 'core/services/module_storage_service.dart';
import 'core/models/app_module.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'modules/money_tracker/money_tracker_module.dart';
import 'modules/money_tracker/features/settings/providers/category_provider.dart';
import 'modules/money_tracker/features/settings/providers/recurring_payment_provider.dart';
import 'modules/money_tracker/features/settings/providers/budget_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite_ffi for desktop platforms BEFORE any database operations
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Register built-in modules
  moduleLauncher.registerModule(MoneyTrackerModule());

  // Mark Money Tracker as installed (since it's built-in)
  await _markBuiltInModulesAsInstalled();

  runApp(const MegaApp());
}

/// Mark built-in modules as installed
Future<void> _markBuiltInModulesAsInstalled() async {
  final storageService = ModuleStorageService();

  // Clear old cached metadata for money_tracker to force refresh
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('module_metadata_money_tracker');
  print('🗑️ Cleared old Money Tracker metadata cache');

  // Create Money Tracker module metadata
  final moneyTrackerModule = AppModule(
    id: 'money_tracker',
    name: 'Money Tracker',
    description: 'Track your income and expenses with SMS auto-detection',
    version: '1.0.1', // Increment version to force update
    iconUrl: 'assets/images/cat_icon.png', // Use local cat icon
    downloadUrl: '', // Built-in, no download needed
    sizeInBytes: 0,
    platforms: ['android', 'windows'],
    isInstalled: true,
    installedVersion: '1.0.1',
    metadata: {
      'category': 'Finance',
      'author': 'Mega App Team',
      'rating': 4.5,
      'built_in': true, // Mark as built-in
    },
  );

  try {
    // Force save to overwrite old metadata
    await storageService.saveModuleMetadata(moneyTrackerModule);
    print('✅ Money Tracker metadata updated with cat icon');
    print('📍 Icon path: ${moneyTrackerModule.iconUrl}');
  } catch (e) {
    print('Error marking built-in modules: $e');
  }
}

class MegaApp extends StatelessWidget {
  const MegaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModuleProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => RecurringPaymentProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Initialize providers after they're available
          _initializeProviders(context);
          return MaterialApp(
            title: 'Mega App',
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  void _initializeProviders(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final categoryProvider = context.read<CategoryProvider>();
      final budgetProvider = context.read<BudgetProvider>();
      final recurringPaymentProvider = context.read<RecurringPaymentProvider>();

      await categoryProvider.loadCategories();
      await budgetProvider.loadBudgets();
      await recurringPaymentProvider.loadPayments();
    });
  }
}
