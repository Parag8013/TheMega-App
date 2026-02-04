import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/app_module.dart';

/// Manages local storage for modules
class ModuleStorageService {
  static const String _installedModulesKey = 'installed_modules';
  static const String _moduleMetadataPrefix = 'module_meta_';

  /// Get the base directory for storing modules
  Future<Directory> getModulesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modulesDir = Directory(path.join(appDir.path, 'mega_app_modules'));
    if (!await modulesDir.exists()) {
      await modulesDir.create(recursive: true);
    }
    return modulesDir;
  }

  /// Get directory for a specific module
  Future<Directory> getModuleDirectory(String moduleId) async {
    final modulesDir = await getModulesDirectory();
    final moduleDir = Directory(path.join(modulesDir.path, moduleId));
    if (!await moduleDir.exists()) {
      await moduleDir.create(recursive: true);
    }
    return moduleDir;
  }

  /// Get data directory for a specific module (for database, prefs, etc.)
  Future<Directory> getModuleDataDirectory(String moduleId) async {
    final moduleDir = await getModuleDirectory(moduleId);
    final dataDir = Directory(path.join(moduleDir.path, 'data'));
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return dataDir;
  }

  /// Get assets directory for a specific module
  Future<Directory> getModuleAssetsDirectory(String moduleId) async {
    final moduleDir = await getModuleDirectory(moduleId);
    final assetsDir = Directory(path.join(moduleDir.path, 'assets'));
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    return assetsDir;
  }

  /// Save module metadata
  Future<void> saveModuleMetadata(AppModule module) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_moduleMetadataPrefix${module.id}',
      jsonEncode(module.toJson()),
    );

    // Update installed modules list
    final installedModules = await getInstalledModuleIds();
    if (!installedModules.contains(module.id)) {
      installedModules.add(module.id);
      await prefs.setStringList(_installedModulesKey, installedModules);
    }
  }

  /// Get module metadata
  Future<AppModule?> getModuleMetadata(String moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final metadataJson = prefs.getString('$_moduleMetadataPrefix$moduleId');
    if (metadataJson == null) return null;

    try {
      return AppModule.fromJson(jsonDecode(metadataJson));
    } catch (e) {
      print('Error parsing module metadata: $e');
      return null;
    }
  }

  /// Get all installed module IDs
  Future<List<String>> getInstalledModuleIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_installedModulesKey) ?? [];
  }

  /// Get all installed modules
  Future<List<AppModule>> getInstalledModules() async {
    final moduleIds = await getInstalledModuleIds();
    final modules = <AppModule>[];

    print('📦 Loading ${moduleIds.length} installed modules: $moduleIds');

    for (final id in moduleIds) {
      final module = await getModuleMetadata(id);
      if (module != null) {
        print('✅ Loaded module: ${module.name}, iconUrl: ${module.iconUrl}');
        modules.add(module);
      }
    }

    return modules;
  }

  /// Delete module and its data
  Future<void> deleteModule(String moduleId) async {
    final prefs = await SharedPreferences.getInstance();

    // Delete module directory
    final moduleDir = await getModuleDirectory(moduleId);
    if (await moduleDir.exists()) {
      await moduleDir.delete(recursive: true);
    }

    // Remove metadata
    await prefs.remove('$_moduleMetadataPrefix$moduleId');

    // Update installed modules list
    final installedModules = await getInstalledModuleIds();
    installedModules.remove(moduleId);
    await prefs.setStringList(_installedModulesKey, installedModules);
  }

  /// Check if module is installed
  Future<bool> isModuleInstalled(String moduleId) async {
    final installedModules = await getInstalledModuleIds();
    return installedModules.contains(moduleId);
  }

  /// Get module file path
  Future<String> getModuleFilePath(String moduleId, String filename) async {
    final moduleDir = await getModuleDirectory(moduleId);
    return path.join(moduleDir.path, filename);
  }

  /// Calculate total storage used by modules
  Future<int> getTotalStorageUsed() async {
    final modulesDir = await getModulesDirectory();
    return await _getDirectorySize(modulesDir);
  }

  /// Calculate storage used by a specific module
  Future<int> getModuleStorageUsed(String moduleId) async {
    final moduleDir = await getModuleDirectory(moduleId);
    return await _getDirectorySize(moduleDir);
  }

  Future<int> _getDirectorySize(Directory directory) async {
    int totalSize = 0;
    if (!await directory.exists()) return 0;

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        try {
          totalSize += await entity.length();
        } catch (e) {
          print('Error getting file size: $e');
        }
      }
    }

    return totalSize;
  }

  /// Clear all module cache/temp files
  Future<void> clearModuleCache() async {
    final modulesDir = await getModulesDirectory();
    final cacheDir = Directory(path.join(modulesDir.path, '.cache'));
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }
}
