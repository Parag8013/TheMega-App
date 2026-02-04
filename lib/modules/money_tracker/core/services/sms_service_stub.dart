// SMS Service stub for non-Android platforms
class SmsService {
  static Future<void> initService() async {
    // No-op on non-Android platforms
  }

  static Future<bool> requestSmsPermission() async {
    return false;
  }
}
