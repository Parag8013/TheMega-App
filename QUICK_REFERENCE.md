# 🚀 Mega App - Quick Reference Card

## Essential Commands

### Setup & Run
```powershell
# Get dependencies
flutter pub get

# Run on Windows
flutter run -d windows

# Run on Android  
flutter run -d android

# List devices
flutter devices

# Check for issues
flutter analyze
```

### Build for Release
```powershell
# Windows
flutter build windows --release

# Android
flutter build apk --release
flutter build appbundle --release
```

## Project Structure

```
the_mega_app/
├── lib/
│   ├── core/              # Core services
│   │   ├── models/        # Data models
│   │   ├── providers/     # State management
│   │   ├── services/      # Business logic
│   │   └── theme/         # App theme
│   ├── features/          # UI features
│   │   ├── home/          # Home screen
│   │   └── widgets/       # Shared widgets
│   ├── modules/           # Sub-apps go here
│   │   └── money_tracker/ # Example module
│   └── main.dart          # Entry point
├── assets/                # Images, modules
├── ARCHITECTURE.md        # Architecture details
├── GETTING_STARTED.md     # Development guide
└── PROJECT_SUMMARY.md     # This project summary
```

## Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry, module registration |
| `lib/core/providers/module_provider.dart` | Module state management |
| `lib/core/services/ota_service.dart` | OTA updates |
| `lib/core/services/module_launcher.dart` | Launch modules |
| `lib/core/services/module_storage_service.dart` | File management |
| `lib/features/home/home_screen.dart` | Main UI |

## Adding a New Module

### 1. Create Module File
```dart
// lib/modules/your_app/your_app_module.dart
import 'package:flutter/material.dart';
import '../../core/services/module_launcher.dart';

class YourAppModule extends ModuleEntry {
  @override
  String get moduleId => 'your_app';
  
  @override
  String get moduleName => 'Your App';
  
  @override
  String get moduleVersion => '1.0.0';
  
  @override
  Widget buildModule(BuildContext context, ModuleContext ctx) {
    return YourAppScreen(moduleContext: ctx);
  }
}
```

### 2. Register Module
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  moduleLauncher.registerModule(YourAppModule()); // Add here
  
  runApp(const MegaApp());
}
```

### 3. Add to Mock Data
```dart
// lib/core/services/ota_service.dart - in _getMockModules()
AppModule(
  id: 'your_app',
  name: 'Your App',
  description: 'Description',
  version: '1.0.0',
  iconUrl: 'https://via.placeholder.com/150',
  downloadUrl: 'https://example.com/your_app.zip',
  sizeInBytes: 3 * 1024 * 1024, // 3 MB
  platforms: ['android', 'windows'],
),
```

## Module Context Usage

```dart
class YourAppScreen extends StatelessWidget {
  final ModuleContext moduleContext;

  @override
  Widget build(BuildContext context) {
    // Get isolated database path
    final dbPath = moduleContext.getDatabasePath('app.db');
    
    // Get isolated file path
    final filePath = '${moduleContext.dataDirectory}/data.json';
    
    // Get module config
    final config = moduleContext.configuration;
    
    // Get module info
    print('Module ID: ${moduleContext.moduleId}');
    print('Module Name: ${moduleContext.moduleName}');
    
    return Scaffold(...);
  }
}
```

## Platform-Specific Code

```dart
import 'dart:io';

if (Platform.isAndroid) {
  // Android-specific code
} else if (Platform.isWindows) {
  // Windows-specific code
} else {
  // Other platforms
}

// Check before using platform-specific packages
if (Platform.isAndroid) {
  await initSmsService();
}
```

## Responsive UI

```dart
Widget build(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  
  // Adjust columns based on width
  final columns = width > 1200 ? 6 :
                  width > 800 ? 4 :
                  width > 600 ? 3 : 2;
  
  return GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
    ),
    itemBuilder: (context, index) => YourWidget(),
  );
}
```

## Module Database Pattern

```dart
class ModuleDatabase {
  final ModuleContext context;
  Database? _db;

  ModuleDatabase(this.context);

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = context.getDatabasePath('app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
```

## Common Tasks

### Update Mock Modules List
Edit `lib/core/services/ota_service.dart` → `_getMockModules()`

### Change Theme Colors
Edit `lib/core/theme/app_theme.dart` → Colors constants

### Modify Home Screen Layout
Edit `lib/features/home/home_screen.dart`

### Change Module Card Design
Edit `lib/features/widgets/module_card.dart`

### Add New Service
Create file in `lib/core/services/your_service.dart`

## Debugging

### View Logs
- VS Code: Debug Console
- Terminal: Command output
- Android: `adb logcat`

### Common Issues

**Module not showing:**
- Check registration in main.dart
- Verify module ID matches

**Database errors:**
- Use `moduleContext.getDatabasePath()`
- Check file permissions

**Platform errors:**
- Add platform checks
- Verify package support

## State Management

### Using Provider
```dart
// Read value
final provider = context.read<ModuleProvider>();

// Watch for changes
final provider = context.watch<ModuleProvider>();

// Listen without rebuild
context.read<ModuleProvider>().downloadModule(module);
```

### Provider Methods
```dart
provider.initialize();              // Load modules
provider.loadAvailableModules();    // Refresh list
provider.downloadModule(module);    // Install module
provider.uninstallModule(moduleId); // Remove module
provider.checkForUpdates();         // Check updates
```

## OTA Server Setup

### Mock Data (Current)
Located in `lib/core/services/ota_service.dart`

### Real Server (TODO)
```dart
// Update _baseUrl
static const String _baseUrl = 'https://your-server.com/api/modules';

// Uncomment real API call in fetchAvailableModules()
final response = await _dio.get('$_baseUrl/available');
```

### Server Endpoints Needed
- `GET /api/modules/available` - List modules
- `GET /modules/:filename.zip` - Download module

## Testing Checklist

- [ ] Module appears in "All Apps"
- [ ] Install button works
- [ ] Download progress shows
- [ ] Module launches successfully
- [ ] Data persists after restart
- [ ] Uninstall removes data
- [ ] Works on Windows
- [ ] Works on Android
- [ ] UI is responsive
- [ ] No console errors

## Quick Tips

1. **Test often** on both platforms
2. **Use isolated paths** via ModuleContext
3. **Platform checks** for specific features
4. **Responsive layout** for all screen sizes
5. **Mock data** for rapid development
6. **Git commits** frequently
7. **Read docs** when stuck

## Resources

- 📖 ARCHITECTURE.md - Technical details
- 🚀 GETTING_STARTED.md - Full guide
- 📊 PROJECT_SUMMARY.md - Project overview
- 🌐 [Flutter Docs](https://docs.flutter.dev/)

## Version Info

**Mega App Version:** 1.0.0  
**Flutter SDK:** 3.8.1+  
**Dart SDK:** 3.7.2+  
**Status:** Ready for Development

---

**Quick Start:**
```powershell
cd c:\TheMegaApp\the_mega_app
flutter run -d windows
```

Happy coding! 🎉
