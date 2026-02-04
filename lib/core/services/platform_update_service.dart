import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PlatformUpdateService {
  // TODO: Replace with your actual repository owner and name
  static const String _repoOwner = 'Parag8013';
  static const String _repoName = 'TheMega-App';

  static const String _releasesUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      // 1. Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      // In debug mode, we might want to pretend version is low for testing
      // final currentVersion = '0.0.0';

      print('Checking for updates... Current: $currentVersion');

      // 2. Fetch latest release from GitHub
      final response = await http.get(Uri.parse(_releasesUrl));

      if (response.statusCode != 200) {
        print('Failed to check updates: ${response.statusCode}');
        return;
      }

      final releaseData = jsonDecode(response.body);
      final String tagName = releaseData['tag_name'] ?? '';
      // Remove 'v' prefix if present
      final latestVersion = tagName.replaceAll('v', '');

      print('Latest version: $latestVersion');

      // 3. Compare versions
      if (_isNewer(latestVersion, currentVersion)) {
        if (!context.mounted) return;
        _showUpdateDialog(context, releaseData);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are on the latest version ($currentVersion)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error checking updates: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error checking updates: $e')));
      }
    }
  }

  bool _isNewer(String latest, String current) {
    List<int> lParts =
        latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> cParts =
        current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < lParts.length && i < cParts.length; i++) {
      if (lParts[i] > cParts[i]) return true;
      if (lParts[i] < cParts[i]) return false;
    }
    // If we're here, equal prefix. If latest is longer, it's newer (1.0.1 vs 1.0)
    return lParts.length > cParts.length;
  }

  void _showUpdateDialog(
    BuildContext context,
    Map<String, dynamic> releaseData,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A new version ${releaseData['tag_name']} is available.'),
            const SizedBox(height: 8),
            const Text('Would you like to restart and update now?'),
            const SizedBox(height: 8),
            Text(
              'Notes:\n${releaseData['body'] ?? 'No notes'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstall(context, releaseData);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstall(
    BuildContext context,
    Map<String, dynamic> releaseData,
  ) async {
    // Show downloading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading update...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final assets = releaseData['assets'] as List;
      final asset = assets.firstWhere(
        (a) => a['name'] == 'windows_release.zip',
        orElse: () => null,
      );

      if (asset == null) {
        throw Exception('Release asset windows_release.zip not found');
      }

      final String downloadUrl = asset['browser_download_url'];
      final tempDir = await getTemporaryDirectory();
      final downloadPath = p.join(tempDir.path, 'update.zip');

      print('Downloading to $downloadPath from $downloadUrl');

      // Download
      final response = await http.get(Uri.parse(downloadUrl));
      await File(downloadPath).writeAsBytes(response.bodyBytes);

      // Locate updater.exe
      // Standard path: in the same directory as the executable
      final currentExeDir = File(Platform.resolvedExecutable).parent.path;
      final updaterPath = p.join(
        currentExeDir,
        'updater.exe',
      ); // Bundled updater

      if (!await File(updaterPath).exists()) {
        throw Exception('Updater tool not found at $updaterPath');
      }

      // Launch Updater
      print('Launching updater...');
      await Process.start(
          updaterPath,
          [
            '--pid', '${pid}', // Current process ID
            '--zip-path', downloadPath,
            '--install-dir', currentExeDir,
          ],
          mode: ProcessStartMode.detached);

      // Exit immediately
      exit(0);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
