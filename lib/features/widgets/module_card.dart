import 'package:flutter/material.dart';
import '../../core/models/app_module.dart';
import '../../core/models/download_progress.dart';

class ModuleCard extends StatelessWidget {
  final AppModule module;
  final ModuleDownloadProgress? downloadProgress;
  final VoidCallback onTap;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;

  const ModuleCard({
    Key? key,
    required this.module,
    this.downloadProgress,
    required this.onTap,
    required this.onInstall,
    required this.onUninstall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building ModuleCard for: ${module.name}');
    final isDownloading =
        downloadProgress?.status == DownloadStatus.downloading ||
        downloadProgress?.status == DownloadStatus.installing;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Icon
            Expanded(
              child: Container(
                color: Colors.grey[800],
                child: Center(child: _buildModuleIcon()),
              ),
            ),

            // App Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Status/Action Section
                  if (isDownloading)
                    Column(
                      children: [
                        LinearProgressIndicator(
                          value: downloadProgress?.progress,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          downloadProgress?.progressPercentage ?? '',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    )
                  else if (module.isInstalled)
                    Row(
                      children: [
                        if (module.isUpdateAvailable)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onInstall,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                              ),
                              child: const Text(
                                'Update',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                        else
                          const Expanded(
                            child: Chip(
                              label: Text(
                                'Installed',
                                style: TextStyle(fontSize: 10),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onInstall,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        child: const Text(
                          'Install',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),

                  // Size and Version
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        module.formattedSize,
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                      Text(
                        'v${module.version}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleIcon() {
    print('🎨 Building icon for ${module.name}, iconUrl: ${module.iconUrl}');

    // Check if iconUrl is a local asset
    if (module.iconUrl.startsWith('assets/')) {
      print('✅ Loading local asset: ${module.iconUrl}');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          module.iconUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error loading asset: $error');
            return Icon(Icons.apps, size: 64, color: Colors.grey[600]);
          },
        ),
      );
    }

    // Otherwise, try to load from network
    if (module.iconUrl.isNotEmpty && module.iconUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          module.iconUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.apps, size: 64, color: Colors.grey[600]);
          },
        ),
      );
    }

    // Default icon
    return Icon(Icons.apps, size: 64, color: Colors.grey[600]);
  }
}
