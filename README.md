# Mega App - Modular Flutter Application Platform

A Flutter-based mega application that hosts up to 32 independent sub-applications with Over-The-Air (OTA) update support and on-demand module downloading.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Android Studio (for Android development)
- Visual Studio 2022 (for Windows desktop development)

### Initial Setup

```powershell
cd c:\TheMegaApp\the_mega_app
flutter pub get
```

### Run the App

**Windows Desktop:**
```powershell
flutter run -d windows
```

**Android:**
```powershell
flutter run -d android
```

## 📁 Project Structure

```
the_mega_app/
├── lib/
│   ├── core/              # Core services and utilities
│   ├── features/          # UI features (home, widgets)
│   ├── modules/           # Sub-app modules
│   └── main.dart
├── assets/                # Images and module packages
├── ARCHITECTURE.md        # Detailed architecture docs
└── README.md             # This file
```

## ✨ Features

- **32 Sub-App Support**: Host up to 32 independent applications
- **OTA Updates**: Download and update modules over-the-air
- **On-Demand Download**: Install only the modules you need
- **Data Isolation**: Each module has isolated storage
- **Cross-Platform**: Support for Android, Windows, and more
- **Modern UI**: Material Design 3 with dark theme

## 📚 Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Detailed architecture and integration guide
- **Module Development** - See ARCHITECTURE.md for how to create modules

## 🎯 Current Status

### ✅ Completed
- Core module management system
- OTA update mechanism
- UI for browsing and installing modules
- Module isolation and storage
- Money Tracker placeholder integration

### 🚧 Next Steps
- Full Money Tracker integration
- Platform-specific optimizations
- OTA server implementation
- Additional 31 modules

## 🔧 Development

### Adding a New Module

1. Create module file in `lib/modules/your_app/`
2. Implement `ModuleEntry` interface
3. Register in `main.dart`
4. Test on target platforms

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed instructions.

## 📱 Supported Platforms

- ✅ Windows Desktop
- ✅ Android
- 🚧 iOS (planned)
- 🚧 macOS (planned)
- 🚧 Linux (planned)
- 🚧 Web (planned)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple platforms
5. Submit a pull request

## 📄 License

This project is private and not licensed for public use.

---

**Version**: 1.0.0  
**Last Updated**: December 30, 2025
