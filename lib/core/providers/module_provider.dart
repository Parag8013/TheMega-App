import 'package:flutter/material.dart';
import '../models/app_module.dart';
import '../models/download_progress.dart';
import '../services/ota_service.dart';
import '../services/module_storage_service.dart';

/// Provider for managing module state
class ModuleProvider extends ChangeNotifier {
  final OTAService _otaService = OTAService();
  final ModuleStorageService _storageService = ModuleStorageService();

  List<AppModule> _availableModules = [];
  List<AppModule> _installedModules = [];
  Map<String, ModuleDownloadProgress> _downloadProgress = {};
  bool _isLoading = false;
  String? _error;

  List<AppModule> get availableModules => _availableModules;
  List<AppModule> get installedModules => _installedModules;
  Map<String, ModuleDownloadProgress> get downloadProgress => _downloadProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize and load modules
  Future<void> initialize() async {
    await loadInstalledModules();
    await loadAvailableModules();
  }

  /// Load available modules from server
  Future<void> loadAvailableModules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availableModules = await _otaService.fetchAvailableModules();

      // Merge with installed modules to update installation status
      final installedIds = _installedModules.map((m) => m.id).toSet();
      _availableModules = _availableModules.map((module) {
        if (installedIds.contains(module.id)) {
          final installed = _installedModules.firstWhere(
            (m) => m.id == module.id,
          );
          return module.copyWith(
            isInstalled: true,
            installedVersion: installed.installedVersion,
            iconUrl: installed.iconUrl, // Use installed module's icon
            isUpdateAvailable: _isNewerVersion(
              module.version,
              installed.installedVersion,
            ),
          );
        }
        return module;
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load modules: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load installed modules from storage
  Future<void> loadInstalledModules() async {
    try {
      _installedModules = await _storageService.getInstalledModules();
      notifyListeners();
    } catch (e) {
      print('Error loading installed modules: $e');
    }
  }

  /// Download and install a module
  Future<void> downloadModule(AppModule module) async {
    try {
      await _otaService.downloadAndInstallModule(module, (progress) {
        _downloadProgress[module.id] = progress;
        notifyListeners();

        // If completed, reload modules
        if (progress.status == DownloadStatus.completed) {
          loadInstalledModules();
          loadAvailableModules();
        }
      });
    } catch (e) {
      _error = 'Failed to download module: $e';
      notifyListeners();
    }
  }

  /// Uninstall a module
  Future<void> uninstallModule(String moduleId) async {
    try {
      await _otaService.uninstallModule(moduleId);
      await loadInstalledModules();
      await loadAvailableModules();
      _downloadProgress.remove(moduleId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to uninstall module: $e';
      notifyListeners();
    }
  }

  /// Check for updates
  Future<void> checkForUpdates() async {
    _isLoading = true;
    notifyListeners();

    try {
      final updates = await _otaService.checkForUpdates();
      if (updates.isNotEmpty) {
        // Update available modules list with update information
        for (final update in updates) {
          final index = _availableModules.indexWhere((m) => m.id == update.id);
          if (index != -1) {
            _availableModules[index] = update;
          }
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to check for updates: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get module by ID
  AppModule? getModuleById(String id) {
    try {
      return _availableModules.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if a module is currently downloading
  bool isDownloading(String moduleId) {
    final progress = _downloadProgress[moduleId];
    return progress?.status == DownloadStatus.downloading ||
        progress?.status == DownloadStatus.installing;
  }

  /// Get download progress for a module
  ModuleDownloadProgress? getDownloadProgress(String moduleId) {
    return _downloadProgress[moduleId];
  }

  bool _isNewerVersion(String newVersion, String currentVersion) {
    final newParts = newVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < newParts.length && i < currentParts.length; i++) {
      if (newParts[i] > currentParts[i]) return true;
      if (newParts[i] < currentParts[i]) return false;
    }

    return newParts.length > currentParts.length;
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
