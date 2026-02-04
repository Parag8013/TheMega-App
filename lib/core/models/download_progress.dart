// Module Download Status
enum DownloadStatus {
  idle,
  downloading,
  installing,
  completed,
  failed,
  cancelled,
}

class ModuleDownloadProgress {
  final String moduleId;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final String? error;
  final int downloadedBytes;
  final int totalBytes;

  ModuleDownloadProgress({
    required this.moduleId,
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.error,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
  });

  ModuleDownloadProgress copyWith({
    String? moduleId,
    DownloadStatus? status,
    double? progress,
    String? error,
    int? downloadedBytes,
    int? totalBytes,
  }) {
    return ModuleDownloadProgress(
      moduleId: moduleId ?? this.moduleId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }

  String get progressPercentage => '${(progress * 100).toStringAsFixed(0)}%';

  String get statusText {
    switch (status) {
      case DownloadStatus.idle:
        return 'Ready';
      case DownloadStatus.downloading:
        return 'Downloading $progressPercentage';
      case DownloadStatus.installing:
        return 'Installing...';
      case DownloadStatus.completed:
        return 'Installed';
      case DownloadStatus.failed:
        return 'Failed: ${error ?? "Unknown error"}';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }
}
