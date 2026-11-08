import 'dart:js_interop';

@JS('viperPlaySong')
external void _viperPlaySong(JSString videoId, JSString title, JSString artist, JSString thumbnailUrl);

@JS('viperSetMediaMetadata')
external void _viperSetMediaMetadata(JSString title, JSString artist, JSString thumbnailUrl);

@JS('viperPause')
external void _viperPause();

@JS('viperResume')
external void _viperResume();

@JS('viperSeek')
external void _viperSeek(JSNumber seconds);

@JS('viperGetTime')
external JSNumber _viperGetTime();

@JS('viperGetDuration')
external JSNumber _viperGetDuration();

@JS('viperGetState')
external JSNumber _viperGetState();

class WebAudioBridge {
  static bool get isSupported => true;

  static void playSong(
    String videoId, {
    String title = '',
    String artist = '',
    String thumbnailUrl = '',
  }) {
    try {
      _viperPlaySong(videoId.toJS, title.toJS, artist.toJS, thumbnailUrl.toJS);
    } catch (_) {}
  }

  static void setMetadata({
    String title = '',
    String artist = '',
    String thumbnailUrl = '',
  }) {
    try {
      _viperSetMediaMetadata(title.toJS, artist.toJS, thumbnailUrl.toJS);
    } catch (_) {}
  }

  static void pause() {
    try {
      _viperPause();
    } catch (_) {}
  }

  static void resume() {
    try {
      _viperResume();
    } catch (_) {}
  }

  static void seek(double seconds) {
    try {
      _viperSeek(seconds.toJS);
    } catch (_) {}
  }

  static double getCurrentTime() {
    try {
      return _viperGetTime().toDartDouble;
    } catch (_) {
      return 0.0;
    }
  }

  static double getDuration() {
    try {
      return _viperGetDuration().toDartDouble;
    } catch (_) {
      return 0.0;
    }
  }

  static int getPlayerState() {
    try {
      return _viperGetState().toDartInt;
    } catch (_) {
      return -1;
    }
  }
}
