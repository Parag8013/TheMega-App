import 'package:flutter/material.dart';
import '../models/app_module.dart';
import '../services/module_storage_service.dart';

/// Abstract base class that all sub-app modules must implement
abstract class ModuleEntry {
  /// Unique module ID
  String get moduleId;

  /// Module name
  String get moduleName;

  /// Module version
  String get moduleVersion;

  /// Get the main widget for this module
  Widget buildModule(BuildContext context, ModuleContext moduleContext);

  /// Called when module is initialized
  Future<void> onModuleInit() async {}

  /// Called when module is disposed
  Future<void> onModuleDispose() async {}
}

/// Context provided to each module with isolated resources
class ModuleContext {
  final String moduleId;
  final String moduleName;
  final String dataDirectory;
  final String assetsDirectory;
  final Map<String, dynamic> configuration;

  ModuleContext({
    required this.moduleId,
    required this.moduleName,
    required this.dataDirectory,
    required this.assetsDirectory,
    this.configuration = const {},
  });

  /// Get database path for this module
  String getDatabasePath(String databaseName) {
    return '$dataDirectory/$databaseName';
  }

  /// Get asset path for this module
  String getAssetPath(String assetName) {
    return '$assetsDirectory/$assetName';
  }
}

/// Service for launching and managing module instances
class ModuleLauncher {
  final ModuleStorageService _storageService = ModuleStorageService();
  final Map<String, ModuleEntry> _registeredModules = {};

  /// Register a module entry point
  void registerModule(ModuleEntry module) {
    _registeredModules[module.moduleId] = module;
  }

  /// Launch a module
  Future<Widget?> launchModule(BuildContext context, AppModule module) async {
    try {
      // Check if module is installed
      final isInstalled = await _storageService.isModuleInstalled(module.id);
      if (!isInstalled) {
        throw Exception('Module ${module.name} is not installed');
      }

      // Get module directories
      final moduleDataDir = await _storageService.getModuleDataDirectory(
        module.id,
      );
      final moduleAssetsDir = await _storageService.getModuleAssetsDirectory(
        module.id,
      );

      // Create module context
      final moduleContext = ModuleContext(
        moduleId: module.id,
        moduleName: module.name,
        dataDirectory: moduleDataDir.path,
        assetsDirectory: moduleAssetsDir.path,
        configuration: module.metadata,
      );

      // Check if module is registered
      final moduleEntry = _registeredModules[module.id];
      if (moduleEntry == null) {
        // If not registered, show placeholder
        return _buildModulePlaceholder(context, module, moduleContext);
      }

      // Initialize module
      await moduleEntry.onModuleInit();

      // Build and return module widget
      return moduleEntry.buildModule(context, moduleContext);
    } catch (e) {
      print('Error launching module: $e');
      return _buildErrorWidget(context, module, e.toString());
    }
  }

  /// Build placeholder for modules that aren't dynamically loaded yet
  Widget _buildModulePlaceholder(
    BuildContext context,
    AppModule module,
    ModuleContext moduleContext,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text(module.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64),
            const SizedBox(height: 16),
            Text(
              '${module.name} is installed',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This module is ready to launch.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Data Directory:\n${moduleContext.dataDirectory}',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget(
    BuildContext context,
    AppModule module,
    String error,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text(module.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to launch module',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(error, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  /// Get registered module IDs
  List<String> get registeredModuleIds => _registeredModules.keys.toList();

  /// Check if a module is registered
  bool isModuleRegistered(String moduleId) {
    return _registeredModules.containsKey(moduleId);
  }
}

/// Global module launcher instance
final moduleLauncher = ModuleLauncher();
