import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/song.dart';
import 'api_service.dart';
import 'file_helper.dart';
import 'web_audio_bridge.dart';

enum PlaybackState { idle, loading, playing, paused, completed, error }
enum PlayerRepeatMode { off, all, one }

class AudioPlayerService extends ChangeNotifier {
  final ApiService apiService;
  final AudioPlayer _player = AudioPlayer();
  Timer? _webPositionTimer;

  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = -1;
  PlaybackState _state = PlaybackState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffle = false;
  PlayerRepeatMode _repeatMode = PlayerRepeatMode.off;

  AudioPlayerService({required this.apiService}) {
    _initAudio();
  }

  Song? get currentSong => _currentSong;
  List<Song> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  PlaybackState get state => _state;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffle => _isShuffle;
  PlayerRepeatMode get repeatMode => _repeatMode;
  bool get isPlaying => _state == PlaybackState.playing;

  Future<void> _initAudio() async {
    if (!kIsWeb) {
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
      } catch (_) {}
    }

    _player.playerStateStream.listen((playerState) {
      if (kIsWeb) return; // Managed via WebAudioBridge on web
      if (playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering) {
        _state = PlaybackState.loading;
      } else if (playerState.processingState == ProcessingState.completed) {
        _state = PlaybackState.completed;
        _onTrackCompleted();
      } else if (playerState.playing) {
        _state = PlaybackState.playing;
      } else {
        _state = PlaybackState.paused;
      }
      notifyListeners();
    });

    _player.positionStream.listen((pos) {
      if (kIsWeb) return;
      _position = pos;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      if (kIsWeb) return;
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
  }

  /// Play a song, setting up queue
  Future<void> playSong(Song song, {List<Song>? queueContext}) async {
    if (queueContext != null && queueContext.isNotEmpty) {
      _queue = List.from(queueContext);
      _currentIndex = _queue.indexOf(song);
      if (_currentIndex == -1) {
        _queue.insert(0, song);
        _currentIndex = 0;
      }
    } else {
      _queue = [song];
      _currentIndex = 0;
    }

    await _loadAndPlay(song);
  }

  Future<void> _loadAndPlay(Song song) async {
    _currentSong = song;
    _state = PlaybackState.loading;
    _position = Duration.zero;
    notifyListeners();

    try {
      // 1. Web Player Engine (uses YouTube Iframe audio bridge with 0 CORS & 0 bot blocks)
      if (kIsWeb && WebAudioBridge.isSupported) {
        WebAudioBridge.playSong(
          song.id,
          title: song.title,
          artist: song.artist,
          thumbnailUrl: song.thumbnailUrl,
        );
        _state = PlaybackState.playing;
        _startWebPositionTimer();
        notifyListeners();
        return;
      }

      // 2. Native Offline File Playback
      if (!kIsWeb && song.isDownloaded && song.localFilePath != null && checkFileExists(song.localFilePath!)) {
        final source = getAudioSourceForFile(song.localFilePath!);
        if (source != null) {
          await _player.setAudioSource(source);
          await _player.play();
          return;
        }
      }

      // 3. Native Stream Playback
      String? streamUrl = song.streamUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = await apiService.resolveStreamUrl(song.id);
      }

      if (streamUrl != null && streamUrl.isNotEmpty) {
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(streamUrl),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          ),
        );
        await _player.play();
      } else {
        // Fallback to WebAudioBridge if available
        if (WebAudioBridge.isSupported) {
          WebAudioBridge.playSong(
            song.id,
            title: song.title,
            artist: song.artist,
            thumbnailUrl: song.thumbnailUrl,
          );
          _state = PlaybackState.playing;
          _startWebPositionTimer();
          notifyListeners();
          return;
        }
        throw Exception("Unable to extract playable audio stream");
      }
    } catch (e) {
      _state = PlaybackState.error;
      notifyListeners();
    }
  }

  void _startWebPositionTimer() {
    _webPositionTimer?.cancel();
    _webPositionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_state != PlaybackState.playing && _state != PlaybackState.paused) return;

      final currentSec = WebAudioBridge.getCurrentTime();
      final totalSec = WebAudioBridge.getDuration();
      final ytState = WebAudioBridge.getPlayerState();

      // State 0 = ended
      if (ytState == 0) {
        _onTrackCompleted();
        return;
      }

      // State 1 = playing, 2 = paused
      if (ytState == 1 && _state != PlaybackState.playing) {
        _state = PlaybackState.playing;
      } else if (ytState == 2 && _state != PlaybackState.paused) {
        _state = PlaybackState.paused;
      }

      _position = Duration(milliseconds: (currentSec * 1000).toInt());
      if (totalSec > 0) {
        _duration = Duration(milliseconds: (totalSec * 1000).toInt());
      }
      notifyListeners();
    });
  }

  Future<void> resume() async {
    if (kIsWeb && WebAudioBridge.isSupported) {
      WebAudioBridge.resume();
      _state = PlaybackState.playing;
      notifyListeners();
      return;
    }
    await _player.play();
  }

  Future<void> pause() async {
    if (kIsWeb && WebAudioBridge.isSupported) {
      WebAudioBridge.pause();
      _state = PlaybackState.paused;
      notifyListeners();
      return;
    }
    await _player.pause();
  }

  Future<void> togglePlayPause() async => isPlaying ? await pause() : await resume();

  Future<void> seek(Duration position) async {
    if (kIsWeb && WebAudioBridge.isSupported) {
      WebAudioBridge.seek(position.inMilliseconds / 1000.0);
      _position = position;
      notifyListeners();
      return;
    }
    await _player.seek(position);
  }

  Future<void> skipNext() async {
    if (_queue.isEmpty) return;
    if (_repeatMode == PlayerRepeatMode.one) {
      await seek(Duration.zero);
      await resume();
      return;
    }

    if (_currentIndex + 1 < _queue.length) {
      _currentIndex++;
      await _loadAndPlay(_queue[_currentIndex]);
    } else if (_repeatMode == PlayerRepeatMode.all) {
      _currentIndex = 0;
      await _loadAndPlay(_queue[0]);
    }
  }

  Future<void> skipPrevious() async {
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
      await _loadAndPlay(_queue[_currentIndex]);
    } else {
      await seek(Duration.zero);
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case PlayerRepeatMode.off:
        _repeatMode = PlayerRepeatMode.all;
        break;
      case PlayerRepeatMode.all:
        _repeatMode = PlayerRepeatMode.one;
        break;
      case PlayerRepeatMode.one:
        _repeatMode = PlayerRepeatMode.off;
        break;
    }
    notifyListeners();
  }

  void _onTrackCompleted() {
    if (_repeatMode == PlayerRepeatMode.one) {
      seek(Duration.zero).then((_) => resume());
    } else {
      skipNext();
    }
  }

  @override
  void dispose() {
    _webPositionTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
