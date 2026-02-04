import 'package:flutter/material.dart';
import '../utils/platform_helper.dart';

/// Platform-aware SMS service that only works on Android
class PlatformSmsService {
  static bool _isInitialized = false;

  /// Initialize SMS service (only on Android)
  static Future<void> initService() async {
    if (!PlatformHelper.supportsSMS) {
      print('ℹ️ SMS service not supported on ${PlatformHelper.platformName}');
      _isInitialized = true;
      return;
    }

    try {
      // Dynamic import only on Android
      final smsService = await _loadAndroidSmsService();
      if (smsService != null) {
        await smsService.initService();
        _isInitialized = true;
      }
    } catch (e) {
      print('❌ Failed to initialize SMS service: $e');
    }
  }

  /// Request SMS permissions (only on Android)
  static Future<bool> requestSmsPermission() async {
    if (!PlatformHelper.supportsSMS) {
      return false;
    }

    try {
      final smsService = await _loadAndroidSmsService();
      if (smsService != null) {
        return await smsService.requestSmsPermission();
      }
    } catch (e) {
      print('❌ Failed to request SMS permission: $e');
    }

    return false;
  }

  /// Check SMS permission status (only on Android)
  static Future<bool> checkSmsPermission() async {
    if (!PlatformHelper.supportsSMS) {
      return false;
    }

    try {
      final smsService = await _loadAndroidSmsService();
      if (smsService != null) {
        return await smsService.checkSmsPermission();
      }
    } catch (e) {
      print('❌ Failed to check SMS permission: $e');
    }

    return false;
  }

  /// Parse and save transaction (only on Android)
  static Future<void> parseAndSaveTransaction(
    String messageBody,
    String sender,
  ) async {
    if (!PlatformHelper.supportsSMS) {
      return;
    }

    try {
      final smsService = await _loadAndroidSmsService();
      if (smsService != null) {
        await smsService.parseAndSaveTransaction(messageBody, sender);
      }
    } catch (e) {
      print('❌ Failed to parse SMS transaction: $e');
    }
  }

  /// Check if SMS service is initialized
  static bool get isInitialized => _isInitialized;

  /// Check if SMS features are supported on this platform
  static bool get isSupported => PlatformHelper.supportsSMS;

  /// Load Android SMS service dynamically
  static Future<dynamic> _loadAndroidSmsService() async {
    if (PlatformHelper.isAndroid) {
      try {
        // On Android, import the actual SMS service
        // This is a placeholder - implement actual conditional imports
        final module = await _conditionalImport();
        return module;
      } catch (e) {
        print('Error loading Android SMS service: $e');
      }
    }
    return null;
  }

  /// Conditional import helper
  static Future<dynamic> _conditionalImport() async {
    // This would normally use conditional imports
    // For now, return null on non-Android platforms
    if (PlatformHelper.isAndroid) {
      // Import actual SMS service
      // final SmsService = await import('./sms_service.dart');
      // return SmsService;
    }
    return null;
  }

  /// Show platform-specific SMS status widget
  static Widget buildSmsStatusWidget(BuildContext context) {
    if (!PlatformHelper.supportsSMS) {
      return Card(
        child: ListTile(
          leading: Icon(Icons.info_outline, color: Colors.grey[600]),
          title: const Text('SMS Auto-Detection'),
          subtitle: Text(
            'SMS auto-detection is only available on Android devices. '
            'On ${PlatformHelper.platformName}, you can manually add transactions.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
