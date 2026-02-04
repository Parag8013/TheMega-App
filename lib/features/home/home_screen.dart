import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/module_provider.dart';
import '../../core/models/app_module.dart';
import '../../core/models/download_progress.dart';
import '../../core/services/module_launcher.dart';
import '../../core/services/platform_update_service.dart';
import '../widgets/module_card.dart';
import '../widgets/installed_module_card.dart';
import 'module_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTab = _tabController.index;
      });
    });

    // Initialize module provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ModuleProvider>().initialize();
      // Check for platform updates
      PlatformUpdateService().checkForUpdates(context);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.purple[700]!],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.apps, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Mega App Store',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<ModuleProvider>().loadAvailableModules();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.system_update, color: Colors.white),
            onPressed: () {
              context.read<ModuleProvider>().checkForUpdates();
            },
            tooltip: 'Check for updates',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to settings
            },
            tooltip: 'Settings',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.grey[850],
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue[400],
              unselectedLabelColor: Colors.grey[400],
              indicatorColor: Colors.blue[400],
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Installed'),
                Tab(text: 'Store'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<ModuleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.availableModules.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.loadAvailableModules();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInstalledAppsTab(provider),
              _buildStoreTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInstalledAppsTab(ModuleProvider provider) {
    final installedModules = provider.availableModules
        .where((m) => m.isInstalled)
        .toList();

    if (installedModules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No apps installed yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Browse the Store tab to discover and install apps',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: installedModules.length,
      itemBuilder: (context, index) {
        final module = installedModules[index];
        return _buildInstalledAppCard(module, provider);
      },
    );
  }

  Widget _buildInstalledAppCard(AppModule module, ModuleProvider provider) {
    return InkWell(
      onTap: () => _launchModule(module),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getModuleColors(module.id),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getModuleColors(module.id)[0].withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _buildModuleIconWidget(module),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                module.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (module.isUpdateAvailable) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Update Available',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStoreTab(ModuleProvider provider) {
    final modules = provider.availableModules;

    if (modules.isEmpty) {
      return const Center(child: Text('No apps available'));
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAvailableModules(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
          final downloadProgress = provider.getDownloadProgress(module.id);
          return _buildStoreAppCard(module, provider, downloadProgress);
        },
      ),
    );
  }

  Widget _buildStoreAppCard(
    AppModule module,
    ModuleProvider provider,
    ModuleDownloadProgress? downloadProgress,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetails(module),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // App Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getModuleColors(module.id),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildModuleIconWidget(module),
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
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'v${module.version}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.storage, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${(module.sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Button
              if (downloadProgress != null)
                SizedBox(
                  width: 90,
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        value: downloadProgress.progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[700]!,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(downloadProgress.progress * 100).toInt()}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              else if (module.isInstalled)
                ElevatedButton(
                  onPressed: () => _launchModule(module),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('OPEN'),
                )
              else
                OutlinedButton(
                  onPressed: () => provider.downloadModule(module),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                    side: BorderSide(color: Colors.blue[700]!),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('INSTALL'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getModuleColors(String moduleId) {
    switch (moduleId) {
      case 'money_tracker':
        return [Colors.green[600]!, Colors.green[800]!];
      case 'todo_app':
        return [Colors.blue[600]!, Colors.blue[800]!];
      case 'weather':
        return [Colors.cyan[600]!, Colors.cyan[800]!];
      case 'calculator':
        return [Colors.orange[600]!, Colors.orange[800]!];
      default:
        return [Colors.purple[600]!, Colors.purple[800]!];
    }
  }

  Widget _buildModuleIconWidget(AppModule module) {
    if (module.iconUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          module.iconUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _getFallbackIcon(module.id),
              size: 40,
              color: Colors.white,
            );
          },
        ),
      );
    } else if (module.iconUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          module.iconUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _getFallbackIcon(module.id),
              size: 40,
              color: Colors.white,
            );
          },
        ),
      );
    } else {
      return Icon(_getFallbackIcon(module.id), size: 40, color: Colors.white);
    }
  }

  IconData _getFallbackIcon(String moduleId) {
    switch (moduleId) {
      case 'money_tracker':
        return Icons.account_balance_wallet;
      case 'todo_app':
        return Icons.check_circle;
      case 'weather':
        return Icons.wb_sunny;
      case 'calculator':
        return Icons.calculate;
      default:
        return Icons.apps;
    }
  }

  void _navigateToDetails(AppModule module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModuleDetailsScreen(module: module),
      ),
    );
  }

  void _launchModule(AppModule module) async {
    try {
      print('🚀 Attempting to launch module: ${module.name}');
      final moduleWidget = await moduleLauncher.launchModule(context, module);
      print('✅ Module widget obtained: ${moduleWidget != null}');

      if (moduleWidget != null && mounted) {
        print('📱 Pushing module widget to navigator');
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => moduleWidget),
        );
        print('✅ Navigation completed');
      } else {
        print('❌ Module widget is null or widget not mounted');
      }
    } catch (e, stackTrace) {
      print('❌ ERROR launching module: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch ${module.name}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showUninstallDialog(AppModule module) {
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
              context.read<ModuleProvider>().uninstallModule(module.id);
            },
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }
}
