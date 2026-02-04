import 'dart:io';
import 'package:dio/dio.dart';
import 'package:archive/archive_io.dart';
import '../models/app_module.dart';
import '../models/download_progress.dart';
import 'module_storage_service.dart';

/// Handles OTA (Over-The-Air) updates and module downloads
class OTAService {
  final Dio _dio = Dio();
  final ModuleStorageService _storageService = ModuleStorageService();

  // TODO: In production, this should point to your server
  // static const String _baseUrl = 'https://your-server.com/api/modules';

  /// Fetch available modules from server
  Future<List<AppModule>> fetchAvailableModules() async {
    try {
      // For now, return mock data. Replace with actual API call
      return _getMockModules();

      // Uncomment when you have a real server:
      // final response = await _dio.get('$_baseUrl/available');
      // final List<dynamic> data = response.data['modules'];
      // return data.map((json) => AppModule.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching modules: $e');
      return [];
    }
  }

  /// Check for updates for installed modules
  Future<List<AppModule>> checkForUpdates() async {
    try {
      final installedModules = await _storageService.getInstalledModules();
      final availableModules = await fetchAvailableModules();

      final updates = <AppModule>[];

      for (final installed in installedModules) {
        final available = availableModules.firstWhere(
          (m) => m.id == installed.id,
          orElse: () => installed,
        );

        if (_isNewerVersion(available.version, installed.installedVersion)) {
          updates.add(
            available.copyWith(
              isInstalled: true,
              installedVersion: installed.installedVersion,
              isUpdateAvailable: true,
            ),
          );
        }
      }

      return updates;
    } catch (e) {
      print('Error checking for updates: $e');
      return [];
    }
  }

  /// Download and install a module
  Future<void> downloadAndInstallModule(
    AppModule module,
    void Function(ModuleDownloadProgress) onProgress,
  ) async {
    try {
      // Check if module is built-in
      if (module.metadata['built_in'] == true) {
        // Built-in modules don't need downloading
        onProgress(
          ModuleDownloadProgress(
            moduleId: module.id,
            status: DownloadStatus.completed,
            progress: 1.0,
          ),
        );
        return;
      }

      // Update status to downloading
      onProgress(
        ModuleDownloadProgress(
          moduleId: module.id,
          status: DownloadStatus.downloading,
          progress: 0.0,
        ),
      );

      // Get download path
      final moduleDir = await _storageService.getModuleDirectory(module.id);
      final downloadPath = '${moduleDir.path}/module.zip';

      // Download the module
      await _dio.download(
        module.downloadUrl,
        downloadPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(
              ModuleDownloadProgress(
                moduleId: module.id,
                status: DownloadStatus.downloading,
                progress: progress,
                downloadedBytes: received,
                totalBytes: total,
              ),
            );
          }
        },
      );

      // Update status to installing
      onProgress(
        ModuleDownloadProgress(
          moduleId: module.id,
          status: DownloadStatus.installing,
          progress: 1.0,
        ),
      );

      // Extract the module
      await _extractModule(downloadPath, moduleDir.path);

      // Delete the zip file
      final zipFile = File(downloadPath);
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      // Save module metadata
      await _storageService.saveModuleMetadata(
        module.copyWith(
          isInstalled: true,
          installedVersion: module.version,
          isUpdateAvailable: false,
          lastUpdated: DateTime.now(),
        ),
      );

      // Update status to completed
      onProgress(
        ModuleDownloadProgress(
          moduleId: module.id,
          status: DownloadStatus.completed,
          progress: 1.0,
        ),
      );
    } catch (e) {
      print('Error downloading module: $e');
      onProgress(
        ModuleDownloadProgress(
          moduleId: module.id,
          status: DownloadStatus.failed,
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// Extract module archive
  Future<void> _extractModule(
    String archivePath,
    String destinationPath,
  ) async {
    try {
      final bytes = File(archivePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = '$destinationPath/${file.name}';
        if (file.isFile) {
          final outFile = File(filename);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filename).create(recursive: true);
        }
      }
    } catch (e) {
      print('Error extracting module: $e');
      rethrow;
    }
  }

  /// Uninstall a module
  Future<void> uninstallModule(String moduleId) async {
    try {
      await _storageService.deleteModule(moduleId);
    } catch (e) {
      print('Error uninstalling module: $e');
      rethrow;
    }
  }

  /// Compare version strings (e.g., "1.2.3" vs "1.2.2")
  bool _isNewerVersion(String newVersion, String currentVersion) {
    final newParts = newVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < newParts.length && i < currentParts.length; i++) {
      if (newParts[i] > currentParts[i]) return true;
      if (newParts[i] < currentParts[i]) return false;
    }

    return newParts.length > currentParts.length;
  }

  /// Mock modules for testing (replace with real API)
  List<AppModule> _getMockModules() {
    return [
      AppModule(
        id: 'money_tracker',
        name: 'Money Tracker',
        description: 'Track your income and expenses with SMS auto-detection',
        version: '1.0.0',
        iconUrl: 'assets/images/cat_icon.png', // Use local cat icon
        downloadUrl: 'https://example.com/modules/money_tracker.zip',
        sizeInBytes: 5 * 1024 * 1024, // 5 MB
        platforms: ['android', 'windows'],
        metadata: {
          'category': 'Finance',
          'author': 'Mega App Team',
          'rating': 4.5,
        },
      ),
      AppModule(
        id: 'task_manager',
        name: 'Task Manager',
        description: 'Organize your tasks and boost productivity',
        version: '1.0.0',
        iconUrl: 'https://via.placeholder.com/150',
        downloadUrl: 'https://example.com/modules/task_manager.zip',
        sizeInBytes: 3 * 1024 * 1024, // 3 MB
        platforms: ['android', 'windows', 'web'],
        metadata: {
          'category': 'Productivity',
          'author': 'Mega App Team',
          'rating': 4.7,
        },
      ),
      // Add more mock modules as placeholders for the remaining 30 apps
      ...List.generate(
        30,
        (index) => AppModule(
          id: 'app_${index + 3}',
          name: 'App ${index + 3}',
          description: 'Coming soon - App ${index + 3}',
          version: '0.0.1',
          iconUrl: 'https://via.placeholder.com/150',
          downloadUrl: 'https://example.com/modules/app_${index + 3}.zip',
          sizeInBytes: 2 * 1024 * 1024, // 2 MB
          platforms: ['android', 'windows'],
          metadata: {'category': 'Misc', 'status': 'coming_soon'},
        ),
      ),
    ];
  }
}
