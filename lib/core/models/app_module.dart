// Core Module Model - Represents a sub-app module
class AppModule {
  final String id;
  final String name;
  final String description;
  final String version;
  final String iconUrl;
  final String downloadUrl;
  final int sizeInBytes;
  final bool isInstalled;
  final bool isUpdateAvailable;
  final String installedVersion;
  final List<String> platforms; // android, windows, ios, macos, linux, web
  final DateTime? lastUpdated;
  final Map<String, dynamic> metadata;

  AppModule({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.iconUrl,
    required this.downloadUrl,
    required this.sizeInBytes,
    this.isInstalled = false,
    this.isUpdateAvailable = false,
    this.installedVersion = '0.0.0',
    this.platforms = const ['android', 'windows'],
    this.lastUpdated,
    this.metadata = const {},
  });

  factory AppModule.fromJson(Map<String, dynamic> json) {
    return AppModule(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      iconUrl: json['iconUrl'] as String,
      downloadUrl: json['downloadUrl'] as String,
      sizeInBytes: json['sizeInBytes'] as int,
      isInstalled: json['isInstalled'] as bool? ?? false,
      isUpdateAvailable: json['isUpdateAvailable'] as bool? ?? false,
      installedVersion: json['installedVersion'] as String? ?? '0.0.0',
      platforms:
          (json['platforms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['android', 'windows'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'version': version,
      'iconUrl': iconUrl,
      'downloadUrl': downloadUrl,
      'sizeInBytes': sizeInBytes,
      'isInstalled': isInstalled,
      'isUpdateAvailable': isUpdateAvailable,
      'installedVersion': installedVersion,
      'platforms': platforms,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'metadata': metadata,
    };
  }

  AppModule copyWith({
    String? id,
    String? name,
    String? description,
    String? version,
    String? iconUrl,
    String? downloadUrl,
    int? sizeInBytes,
    bool? isInstalled,
    bool? isUpdateAvailable,
    String? installedVersion,
    List<String>? platforms,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return AppModule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      iconUrl: iconUrl ?? this.iconUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      isInstalled: isInstalled ?? this.isInstalled,
      isUpdateAvailable: isUpdateAvailable ?? this.isUpdateAvailable,
      installedVersion: installedVersion ?? this.installedVersion,
      platforms: platforms ?? this.platforms,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }

  String get formattedSize {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get needsUpdate => isInstalled && isUpdateAvailable;
}
