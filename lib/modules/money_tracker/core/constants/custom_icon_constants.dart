// Custom icon constants for image-based icons
class CustomIconConstants {
  // Map icon names to image asset paths
  static const Map<String, String> customIcons = {
    'cat': 'assets/images/cat_icon.png',
    // Add more custom PNG icons here
    // 'dog': 'assets/images/dog_icon.png',
    // 'home': 'assets/images/home_icon.png',
  };

  // Check if an icon name is a custom icon
  static bool isCustomIcon(String iconName) {
    return customIcons.containsKey(iconName);
  }

  // Get the asset path for a custom icon
  static String? getAssetPath(String iconName) {
    return customIcons[iconName];
  }

  // Get all available custom icon names
  static List<String> getAllCustomIconNames() {
    return customIcons.keys.toList();
  }
}
