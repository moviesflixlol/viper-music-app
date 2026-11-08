import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_item.dart';
import '../models/song.dart';
import 'api_service.dart';

class DownloadService extends ChangeNotifier {
  static const String _prefsKey = 'viper_downloaded_songs';
  final ApiService apiService;
  final Dio _dio = Dio();

  final Map<String, DownloadItem> _activeDownloads = {};
  List<Song> _downloadedSongs = [];

  DownloadService({required this.apiService}) {
    _loadDownloadedSongs();
  }

  List<Song> get downloadedSongs => List.unmodifiable(_downloadedSongs);
  Map<String, DownloadItem> get activeDownloads => Map.unmodifiable(_activeDownloads);

  bool isDownloaded(String songId) {
    return _downloadedSongs.any((s) => s.id == songId);
  }

  bool isDownloading(String songId) {
    return _activeDownloads.containsKey(songId) &&
        _activeDownloads[songId]?.status == DownloadStatus.downloading;
  }

  double getDownloadProgress(String songId) {
    return _activeDownloads[songId]?.progress ?? 0.0;
  }

  Future<void> _loadDownloadedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_prefsKey) ?? [];
      _downloadedSongs = jsonList
          .map((item) => Song.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .where((s) => s.localFilePath != null && File(s.localFilePath!).existsSync())
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveDownloadedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _downloadedSongs.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_prefsKey, jsonList);
    } catch (_) {}
  }

  /// Download a song for offline playback
  Future<void> downloadSong(Song song) async {
    if (isDownloaded(song.id) || isDownloading(song.id)) return;

    _activeDownloads[song.id] = DownloadItem(
      song: song,
      status: DownloadStatus.downloading,
      progress: 0.05,
    );
    notifyListeners();

    try {
      // 1. Resolve audio stream URL if not already present
      String? streamUrl = song.streamUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = await apiService.resolveStreamUrl(song.id);
      }

      if (streamUrl == null) {
        throw Exception("Could not resolve stream URL for offline download");
      }

      // 2. Prepare local storage destination
      final appDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${appDir.path}/offline_music');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final sanitizedId = song.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final targetPath = '${downloadsDir.path}/$sanitizedId.m4a';

      // 3. Download with progress callbacks
      await _dio.download(
        streamUrl,
        targetPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total).clamp(0.0, 1.0);
            _activeDownloads[song.id] = _activeDownloads[song.id]!.copyWith(
              progress: progress,
              downloadedBytes: received,
              totalBytes: total,
            );
            notifyListeners();
          }
        },
      );

      // 4. Record as successfully downloaded
      final downloadedSong = song.copyWith(
        isDownloaded: true,
        localFilePath: targetPath,
      );

      _downloadedSongs.removeWhere((s) => s.id == song.id);
      _downloadedSongs.insert(0, downloadedSong);
      await _saveDownloadedSongs();

      _activeDownloads[song.id] = _activeDownloads[song.id]!.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        savedPath: targetPath,
      );
      notifyListeners();

      // Clear from active after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        _activeDownloads.remove(song.id);
        notifyListeners();
      });
    } catch (e) {
      _activeDownloads[song.id] = _activeDownloads[song.id]!.copyWith(
        status: DownloadStatus.failed,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  /// Remove offline song
  Future<void> removeDownload(String songId) async {
    final index = _downloadedSongs.indexWhere((s) => s.id == songId);
    if (index != -1) {
      final song = _downloadedSongs[index];
      if (song.localFilePath != null) {
        final file = File(song.localFilePath!);
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {}
        }
      }
      _downloadedSongs.removeAt(index);
      await _saveDownloadedSongs();
      notifyListeners();
    }
  }
}
