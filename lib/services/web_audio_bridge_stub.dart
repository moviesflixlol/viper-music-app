class WebAudioBridge {
  static bool get isSupported => false;
  static void playSong(
    String videoId, {
    String title = '',
    String artist = '',
    String thumbnailUrl = '',
  }) {}
  static void setMetadata({
    String title = '',
    String artist = '',
    String thumbnailUrl = '',
  }) {}
  static void pause() {}
  static void resume() {}
  static void seek(double seconds) {}
  static double getCurrentTime() => 0.0;
  static double getDuration() => 0.0;
  static int getPlayerState() => -1;
}
