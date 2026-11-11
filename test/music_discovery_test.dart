import 'package:flutter_test/flutter_test.dart';
import 'package:viper_music/services/api_service.dart';
import 'package:viper_music/services/listening_tracker.dart';

void main() {
  test('artist and album browse identities survive catalog parsing', () {
    final data = CatalogResult.fromJson({
      'artists': [
        {
          'id': 'UC_artist',
          'name': 'Artist',
          'imageUrl': 'https://example.test/a.jpg'
        }
      ],
      'albums': [
        {'id': 'MPRE_album', 'title': 'Album', 'section': 'Singles & EPs'}
      ],
      'results': [
        {
          'id': 'abcdefghijk',
          'title': 'Song',
          'artist': 'Artist',
          'thumbnail': ''
        }
      ],
    });
    expect(data.artists.single.id, 'UC_artist');
    expect(data.albums.single.section, 'Singles & EPs');
    expect(data.songs.single.id, 'abcdefghijk');
    expect(CatalogResult.fromJson({}).songs, isEmpty);
  });
  test('only thirty seconds of playback counts, once per play', () {
    final tracker = ListeningTracker();
    for (var i = 0; i < 30; i++) {
      expect(
          tracker.update(
              session: 1, position: Duration(seconds: i), playing: true),
          isFalse);
    }
    expect(
        tracker.update(
            session: 1, position: const Duration(seconds: 30), playing: true),
        isTrue);
    expect(
        tracker.update(
            session: 1, position: const Duration(seconds: 31), playing: true),
        isFalse);
    expect(tracker.update(session: 2, position: Duration.zero, playing: true),
        isFalse);
    expect(tracker.playedSeconds, 0);
  });
  test('seeking and paused time do not inflate a listen', () {
    final tracker = ListeningTracker();
    tracker.update(session: 1, position: Duration.zero, playing: true);
    tracker.update(
        session: 1, position: const Duration(seconds: 120), playing: true);
    expect(tracker.playedSeconds, 0);
    tracker.update(
        session: 1, position: const Duration(seconds: 121), playing: false);
    expect(tracker.playedSeconds, 0);
    tracker.update(
        session: 1, position: const Duration(seconds: 122), playing: true);
    expect(tracker.playedSeconds, 1);
  });
}
