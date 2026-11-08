import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/song.dart';
import 'api_service.dart';
import 'file_helper.dart';

enum PlaybackState { idle, loading, playing, paused, completed, error }
enum RepeatMode { off, all, one }

class AudioPlayerService extends ChangeNotifier {
  final ApiService apiService;
  final AudioPlayer _player = AudioPlayer();

  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = -1;
  PlaybackState _state = PlaybackState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;

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
  RepeatMode get repeatMode => _repeatMode;
  bool get isPlaying => _state == PlaybackState.playing;

  Future<void> _initAudio() async {
    if (!kIsWeb) {
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
      } catch (_) {}
    }

    _player.playerStateStream.listen((playerState) {
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
      _position = pos;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
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
    notifyListeners();

    try {
      // 1. If song is downloaded and on native, play directly from local file
      if (!kIsWeb && song.isDownloaded && song.localFilePath != null && checkFileExists(song.localFilePath!)) {
        final source = getAudioSourceForFile(song.localFilePath!);
        if (source != null) {
          await _player.setAudioSource(source);
          await _player.play();
          return;
        }
      }

      // 2. Otherwise resolve stream URL from NextViper backend
      String? streamUrl = song.streamUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = await apiService.resolveStreamUrl(song.id);
      }

      if (streamUrl == null) {
        throw Exception("Unable to extract playable audio stream");
      }

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );
      await _player.play();
    } catch (e) {
      _state = PlaybackState.error;
      notifyListeners();
    }
  }

  Future<void> resume() async => await _player.play();
  Future<void> pause() async => await _player.pause();
  Future<void> togglePlayPause() async => isPlaying ? await pause() : await resume();

  Future<void> seek(Duration position) async => await _player.seek(position);

  Future<void> skipNext() async {
    if (_queue.isEmpty) return;
    if (_repeatMode == RepeatMode.one) {
      await seek(Duration.zero);
      await resume();
      return;
    }

    if (_currentIndex + 1 < _queue.length) {
      _currentIndex++;
      await _loadAndPlay(_queue[_currentIndex]);
    } else if (_repeatMode == RepeatMode.all) {
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
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  void _onTrackCompleted() {
    if (_repeatMode == RepeatMode.one) {
      seek(Duration.zero).then((_) => resume());
    } else {
      skipNext();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
