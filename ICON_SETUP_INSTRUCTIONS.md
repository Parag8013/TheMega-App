# Icon Setup Instructions

## 1. Money Tracker Module Icon (cat_icon.png) ✅ DONE
The cat_icon.png is now used for the Money Tracker module in the app store.

**What was done:**
- Updated `main.dart` to use `assets/images/cat_icon.png` as the Money Tracker module icon
- Modified `installed_module_card.dart` to display local asset images
- The cat icon will now appear when you view Money Tracker in the installed apps list

## 2. Flutter Application Icon (general.png)

**Steps to set up the app icon:**

### Step 1: Add your general.png icon
Place your `general.png` file in the `assets/images/` folder. The image should be:
- At least 1024x1024 pixels (recommended)
- Square aspect ratio
- PNG format with transparency if needed

### Step 2: Install dependencies
```bash
flutter pub get
```

### Step 3: Generate app icons
Run this command to generate platform-specific icons:
```bash
flutter pub run flutter_launcher_icons
```

This will automatically create icons for:
- Android (all required sizes)
- iOS (all required sizes)
- Windows (app icon)

### Step 4: Rebuild the app
```bash
flutter clean
flutter build windows --release
```

## Current Status
- ✅ cat_icon.png configured for Money Tracker module
- ⏳ general.png needs to be added to `assets/images/`
- ⏳ Run icon generation command after adding general.png

## Notes
- The Money Tracker module icon is loaded from local assets (cat_icon.png)
- The Flutter app icon (general.png) will be used as the desktop/mobile app icon
- After running the icon generation, you'll see your icon in the taskbar, app list, etc.
