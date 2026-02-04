import 'dart:io';
import 'package:flutter/material.dart';
import 'sms_service.dart' if (dart.library.html) 'sms_service_stub.dart';

/// Platform-aware SMS Service wrapper
/// Only enables SMS features on Android
class PlatformAwareSmsService {
  static bool get isSupported => Platform.isAndroid;

  /// Initialize SMS service (Android only)
  static Future<void> initService() async {
    if (!isSupported) {
      print('ℹ️ SMS service not supported on ${Platform.operatingSystem}');
      return;
    }

    try {
      // On Android, initialize the actual SMS service
      await SmsService.initService();
    } catch (e) {
      print('❌ Failed to initialize SMS service: $e');
    }
  }

  /// Request SMS permission (Android only)
  static Future<bool> requestSmsPermission() async {
    if (!isSupported) return false;

    try {
      return await SmsService.requestSmsPermission();
    } catch (e) {
      print('❌ Failed to request SMS permission: $e');
      return false;
    }
  }

  /// Check SMS permission (Android only)
  static Future<bool> checkSmsPermission() async {
    if (!isSupported) return false;

    try {
      return await SmsService.requestSmsPermission();
    } catch (e) {
      print('❌ Failed to check SMS permission: $e');
      return false;
    }
  }

  /// Show platform status widget
  static Widget buildPlatformStatusWidget(BuildContext context) {
    if (!isSupported) {
      return Card(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SMS Auto-Detection',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SMS auto-detection is only available on Android devices. '
                      'On ${Platform.operatingSystem}, you can manually add transactions.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
