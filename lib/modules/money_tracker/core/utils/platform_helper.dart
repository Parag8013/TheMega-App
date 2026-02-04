import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform detection utility
class PlatformHelper {
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  static bool get isWeb => kIsWeb;
  static bool get isDesktop => isWindows || isMacOS || isLinux;
  static bool get isMobile => isAndroid || isIOS;

  /// Check if SMS features should be enabled
  static bool get supportsSMS => isAndroid;

  /// Check if telephony features should be enabled
  static bool get supportsTelephony => isAndroid;

  /// Get platform name
  static String get platformName {
    if (isAndroid) return 'Android';
    if (isWindows) return 'Windows';
    if (isIOS) return 'iOS';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    if (isWeb) return 'Web';
    return 'Unknown';
  }
}
