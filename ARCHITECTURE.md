# Mega App Architecture Documentation

## Overview

The Mega App is a modular Flutter application designed to host up to 32 independent sub-applications with Over-The-Air (OTA) update support and on-demand module downloading.

## Architecture Components

### 1. Core Services

#### ModuleStorageService (`lib/core/services/module_storage_service.dart`)
- Manages local file system storage for modules
- Provides isolated directories for each module:
  - Module base directory: `<app_docs>/mega_app_modules/<module_id>/`
  - Data directory: For databases, preferences, etc.
  - Assets directory: For module-specific resources
- Handles module metadata persistence using SharedPreferences
- Tracks installed modules and their versions

#### OTAService (`lib/core/services/ota_service.dart`)
- Fetches available modules from a server (currently using mock data)
- Downloads module packages (.zip files)
- Extracts and installs modules
- Checks for updates by comparing version numbers
- Handles module uninstallation

#### ModuleLauncher (`lib/core/services/module_launcher.dart`)
- Launches installed modules with isolated contexts
- Provides ModuleContext to each module with:
  - Isolated data directory
  - Isolated assets directory
  - Module-specific configuration
- Manages module lifecycle (init/dispose)

### 2. Data Models

#### AppModule (`lib/core/models/app_module.dart`)
Represents a sub-application module with properties:
- `id`: Unique identifier
- `name`: Display name
- `description`: Module description
- `version`: Current version
- `downloadUrl`: URL to download the module
- `sizeInBytes`: Package size
- `isInstalled`: Installation status
- `isUpdateAvailable`: Update availability flag
- `platforms`: Supported platforms (android, windows, etc.)

#### ModuleDownloadProgress (`lib/core/models/download_progress.dart`)
Tracks download and installation progress with status:
- `idle`, `downloading`, `installing`, `completed`, `failed`, `cancelled`

### 3. State Management

#### ModuleProvider (`lib/core/providers/module_provider.dart`)
- Manages global module state using Provider pattern
- Handles module operations:
  - Loading available modules
  - Downloading and installing modules
  - Uninstalling modules
  - Checking for updates
- Notifies UI of state changes

### 4. User Interface

#### HomeScreen (`lib/features/home/home_screen.dart`)
- Main interface with two tabs:
  - **All Apps**: Browse and install available modules
  - **Installed**: View and launch installed modules
- Supports pull-to-refresh and update checking

#### ModuleDetailsScreen (`lib/features/home/module_details_screen.dart`)
- Detailed view of a module with:
  - Description and metadata
  - Platform support information
  - Install/Update/Open/Uninstall actions

## How to Integrate a Sub-App

### Option 1: Module Registration (For Built-in Modules)

For modules that are compiled into the mega app (like Money Tracker):

1. **Create a Module Entry Class**:

```dart
// lib/modules/money_tracker/money_tracker_module.dart
import 'package:flutter/material.dart';
import 'package:the_mega_app/core/services/module_launcher.dart';

class MoneyTrackerModule extends ModuleEntry {
  @override
  String get moduleId => 'money_tracker';

  @override
  String get moduleName => 'Money Tracker';

  @override
  String get moduleVersion => '1.0.0';

  @override
  Widget buildModule(BuildContext context, ModuleContext moduleContext) {
    // Return the main widget of your money tracker app
    // Make sure to use moduleContext.dataDirectory for database paths
    return MoneyTrackerApp(moduleContext: moduleContext);
  }

  @override
  Future<void> onModuleInit() async {
    // Initialize module-specific services
    print('Money Tracker module initialized');
  }

  @override
  Future<void> onModuleDispose() async {
    // Clean up resources
    print('Money Tracker module disposed');
  }
}
```

2. **Register the Module in main.dart**:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register modules
  moduleLauncher.registerModule(MoneyTrackerModule());
  
  runApp(const MegaApp());
}
```

3. **Adapt Your Sub-App to Use ModuleContext**:

Instead of using `getApplicationDocumentsDirectory()` directly, use the module context:

```dart
class MoneyTrackerApp extends StatelessWidget {
  final ModuleContext moduleContext;

  const MoneyTrackerApp({Key? key, required this.moduleContext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Tracker',
      theme: AppTheme.darkTheme,
      home: DashboardScreen(moduleContext: moduleContext),
    );
  }
}
```

Update DatabaseHelper to use module context:

```dart
class DatabaseHelper {
  final ModuleContext moduleContext;
  
  DatabaseHelper(this.moduleContext);

  Future<Database> get database async {
    // Use module context for database path
    final dbPath = moduleContext.getDatabasePath('money_tracker.db');
    return await openDatabase(dbPath, ...);
  }
}
```

### Option 2: Dynamic Loading (For Downloaded Modules)

For modules downloaded at runtime:

1. **Package your module as a .zip file** containing:
   ```
   module.zip
   ├── assets/
   ├── lib/
   └── metadata.json
   ```

2. **Host the module on a server** and update OTAService:

```dart
// In OTAService, replace mock data with real API:
Future<List<AppModule>> fetchAvailableModules() async {
  final response = await _dio.get('https://your-server.com/api/modules/available');
  final List<dynamic> data = response.data['modules'];
  return data.map((json) => AppModule.fromJson(json)).toList();
}
```

3. **Server response format**:

```json
{
  "modules": [
    {
      "id": "money_tracker",
      "name": "Money Tracker",
      "description": "Track your income and expenses",
      "version": "1.0.0",
      "iconUrl": "https://your-cdn.com/icons/money_tracker.png",
      "downloadUrl": "https://your-cdn.com/modules/money_tracker_v1.0.0.zip",
      "sizeInBytes": 5242880,
      "platforms": ["android", "windows"],
      "metadata": {
        "category": "Finance",
        "author": "Your Name",
        "rating": 4.5
      }
    }
  ]
}
```

## Data Retention Strategy

Each module has its own isolated directories:

### Database Isolation
```dart
// Each module gets its own database
final dbPath = moduleContext.getDatabasePath('app_database.db');
// Actual path: <documents>/mega_app_modules/<module_id>/data/app_database.db
```

### SharedPreferences Isolation
```dart
// Use prefixed keys for each module
final prefs = await SharedPreferences.getInstance();
await prefs.setString('${moduleContext.moduleId}_user_setting', value);
```

### File Storage Isolation
```dart
// Store files in module's data directory
final filePath = '${moduleContext.dataDirectory}/user_data.json';
await File(filePath).writeAsString(jsonData);
```

## Platform Optimization

### Windows Desktop Support

To optimize for Windows:

1. **Responsive Layout**: Use `MediaQuery` to adapt UI:
```dart
int _getCrossAxisCount(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width > 1200) return 6;
  if (width > 800) return 4;
  return 2;
}
```

2. **Mouse Input**: Enable hover states and context menus
3. **Window Sizing**: Set appropriate window constraints in `windows/runner/main.cpp`
4. **Desktop-specific widgets**: Use desktop scrollbars, keyboard shortcuts

### Android Support

- Use platform channels for Android-specific features
- Handle permissions properly
- Optimize for touch input

## OTA Update Flow

1. **Check for updates**: `ModuleProvider.checkForUpdates()`
2. **Download**: `ModuleProvider.downloadModule(module)`
3. **Extract**: OTAService extracts .zip to module directory
4. **Install**: Module metadata saved, marked as installed
5. **Launch**: Module loaded with isolated context

## Testing

### Test Module Installation
```dart
// In your tests
final provider = ModuleProvider();
await provider.initialize();
await provider.downloadModule(testModule);

expect(await storageService.isModuleInstalled(testModule.id), true);
```

## Next Steps

1. **Adapt Money Tracker**: Modify to use ModuleContext
2. **Create OTA Server**: Build backend to serve modules
3. **Add Remaining Apps**: Develop the other 31 sub-apps
4. **Implement Auto-Update**: Background update checking
5. **Add Analytics**: Track module usage and crashes
6. **Implement Permissions**: Module permission system
7. **Add Module Communication**: Allow modules to interact (if needed)

## Security Considerations

- **Code Signing**: Sign module packages
- **Verification**: Verify package integrity before installation
- **Sandboxing**: Keep module data isolated
- **Permission System**: Control what modules can access
- **Encrypted Storage**: For sensitive module data

## Current Limitations

1. **No Hot Reload for Modules**: Downloaded modules can't use Flutter's hot reload
2. **Shared Dependencies**: All modules share the mega app's dependencies
3. **Update Requires Restart**: Module updates need app restart to take effect
4. **No Dart Code Loading**: Can't dynamically load Dart code at runtime (Flutter limitation)

## Recommended Approach

For your 32 sub-apps, I recommend:

1. **Built-in Core Apps**: Include 4-5 most important apps (like Money Tracker) as registered modules
2. **Feature Flags**: Enable/disable built-in modules based on server configuration
3. **Asset Bundles**: Download UI assets, images, and data - keep code compiled in
4. **Phased Rollout**: Start with a few apps, gradually add more

This approach provides:
- ✅ OTA content updates
- ✅ On-demand feature activation
- ✅ Data isolation
- ✅ Independent versioning
- ✅ User choice of which apps to "install"
- ⚠️ All code is compiled (Flutter limitation)
