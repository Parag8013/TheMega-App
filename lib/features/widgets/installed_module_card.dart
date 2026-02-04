import 'package:flutter/material.dart';
import '../../core/models/app_module.dart';

class InstalledModuleCard extends StatelessWidget {
  final AppModule module;
  final VoidCallback onTap;
  final VoidCallback onUninstall;
  final VoidCallback? onUpdate;

  const InstalledModuleCard({
    Key? key,
    required this.module,
    required this.onTap,
    required this.onUninstall,
    this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building InstalledModuleCard for: ${module.name}');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // App Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildModuleIcon(),
              ),
              const SizedBox(width: 16),

              // App Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'v${module.installedVersion}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (module.isUpdateAvailable) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Update Available',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Column(
                children: [
                  if (onUpdate != null)
                    IconButton(
                      icon: const Icon(Icons.system_update),
                      onPressed: onUpdate,
                      tooltip: 'Update',
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: onTap,
                      tooltip: 'Open',
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onUninstall,
                    tooltip: 'Uninstall',
                  ),
                ],
              ),
            ],
          ),
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
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error loading asset: $error');
            return const Icon(Icons.apps, size: 32);
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
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.apps, size: 32);
          },
        ),
      );
    }

    // Default icon
    return const Icon(Icons.apps, size: 32);
  }
}
