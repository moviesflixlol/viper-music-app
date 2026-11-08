import 'song.dart';

enum DownloadStatus { pending, downloading, completed, failed }

class DownloadItem {
  final Song song;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? savedPath;
  final String? error;

  const DownloadItem({
    required this.song,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.savedPath,
    this.error,
  });

  DownloadItem copyWith({
    Song? song,
    DownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? savedPath,
    String? error,
  }) {
    return DownloadItem(
      song: song ?? this.song,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      savedPath: savedPath ?? this.savedPath,
      error: error ?? this.error,
    );
  }
}
