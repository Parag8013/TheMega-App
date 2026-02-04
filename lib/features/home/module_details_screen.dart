import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/app_module.dart';
import '../../core/providers/module_provider.dart';

class ModuleDetailsScreen extends StatelessWidget {
  final AppModule module;

  const ModuleDetailsScreen({Key? key, required this.module}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(module.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Icon and Basic Info
            Container(
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.apps, size: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    module.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    module.metadata['author'] as String? ?? 'Unknown Author',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildInfoChip(
                        icon: Icons.star,
                        label:
                            (module.metadata['rating'] as num?)?.toString() ??
                            'N/A',
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.storage,
                        label: module.formattedSize,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.code,
                        label: 'v${module.version}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<ModuleProvider>(
                builder: (context, provider, child) {
                  if (module.isInstalled) {
                    if (module.isUpdateAvailable) {
                      return ElevatedButton.icon(
                        onPressed: provider.isDownloading(module.id)
                            ? null
                            : () => provider.downloadModule(module),
                        icon: const Icon(Icons.system_update),
                        label: const Text('Update'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Launch module
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Launching ${module.name}...',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Open'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showUninstallDialog(context, provider),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Uninstall'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      );
                    }
                  } else {
                    final downloadProgress = provider.getDownloadProgress(
                      module.id,
                    );
                    final isDownloading = provider.isDownloading(module.id);

                    if (isDownloading && downloadProgress != null) {
                      return Column(
                        children: [
                          LinearProgressIndicator(
                            value: downloadProgress.progress,
                          ),
                          const SizedBox(height: 8),
                          Text(downloadProgress.statusText),
                        ],
                      );
                    }

                    return ElevatedButton.icon(
                      onPressed: () => provider.downloadModule(module),
                      icon: const Icon(Icons.download),
                      label: const Text('Install'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    );
                  }
                },
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    module.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[300],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Platform Support
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Platform Support',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: module.platforms.map((platform) {
                      return Chip(
                        label: Text(platform),
                        avatar: Icon(_getPlatformIcon(platform), size: 16),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Additional Info
            if (module.metadata['category'] != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Category',
                      module.metadata['category'] as String,
                    ),
                    if (module.isInstalled)
                      _buildInfoRow(
                        'Installed Version',
                        module.installedVersion,
                      ),
                    _buildInfoRow('Latest Version', module.version),
                    if (module.lastUpdated != null)
                      _buildInfoRow(
                        'Last Updated',
                        _formatDate(module.lastUpdated!),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'windows':
        return Icons.desktop_windows;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.web;
      case 'macos':
        return Icons.laptop_mac;
      case 'linux':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showUninstallDialog(BuildContext context, ModuleProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall App'),
        content: Text('Are you sure you want to uninstall ${module.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home
              provider.uninstallModule(module.id);
            },
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }
}
