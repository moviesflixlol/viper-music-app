/// Count time actually advancing during playback, excluding pauses and seeks.
class ListeningTracker {
  int? _session;
  Duration _position = Duration.zero;
  double _seconds = 0;
  bool _recorded = false;

  bool update(
      {required int session,
      required Duration position,
      required bool playing}) {
    if (_session != session) {
      _session = session;
      _position = Duration.zero;
      _seconds = 0;
      _recorded = false;
    }
    final delta = (position - _position).inMilliseconds / 1000;
    if (playing && delta > 0 && delta <= 2) _seconds += delta;
    _position = position;
    if (_recorded || _seconds < 30) return false;
    _recorded = true;
    return true;
  }

  int get playedSeconds => _seconds.floor();
}
