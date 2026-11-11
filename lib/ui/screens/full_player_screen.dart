import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';
import '../../state/music_controller.dart';
import '../components/add_to_playlist_sheet.dart';
import '../components/more_songs_sheet.dart';
import '../components/music_artwork.dart';

class FullPlayerScreen extends StatefulWidget {
  final MusicController controller;
  const FullPlayerScreen({super.key, required this.controller});
  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  MusicController get c => widget.controller;
  final _related = ValueNotifier<List<Song>>([]);
  String? _relatedId;
  bool _sheetOpen = false;
  @override
  void dispose() {
    _related.dispose();
    super.dispose();
  }

  String _fmt(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  Future<void> _showSongs() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    final id = c.player.currentSong?.id;
    if (id != null && id != _relatedId) {
      _relatedId = id;
      _related.value = [];
      unawaited(c.apiService.related(id).then((songs) {
        if (mounted && _relatedId == id) _related.value = songs;
      }).catchError((_) {}));
    }
    try {
      await showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (sheetContext) => ListenableBuilder(
              listenable: Listenable.merge([c, _related]),
              builder: (_, __) {
                final choices = moreSongs(
                    queue: c.player.queue,
                    currentId: c.player.currentSong?.id,
                    recommended: _related.value,
                    trending: c.feedRecommendations);
                return MoreSongsSheet(
                    songs: choices,
                    onSelected: (song) {
                      c.playSong(song, queueContext: choices);
                      Navigator.of(sheetContext).pop();
                    });
              }));
    } finally {
      _sheetOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: c.player,
      builder: (context, _) {
        final player = c.player;
        final song = player.currentSong;
        if (song == null)
          return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                  child: Text('Choose a song to play',
                      style: TextStyle(color: Colors.white70))));
        final maxMs = math.max(1.0, player.duration.inMilliseconds.toDouble());
        final position =
            player.position.inMilliseconds.toDouble().clamp(0.0, maxMs);
        return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: LayoutBuilder(builder: (context, bounds) {
                          final compact = bounds.maxHeight < 650;
                          final artSize = math.max(
                              120.0,
                              math.min(bounds.maxWidth - 40,
                                  bounds.maxHeight - (compact ? 390 : 410)));
                          return SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      minHeight: bounds.maxHeight),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(children: [
                                          IconButton(
                                              tooltip: 'Close player',
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              icon: const Icon(
                                                  Icons.keyboard_arrow_down,
                                                  color: Colors.white,
                                                  size: 32)),
                                          const Spacer(),
                                          const DecoratedBox(
                                              decoration: BoxDecoration(
                                                  color: Color(0xff242424),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(24))),
                                              child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 8),
                                                  child: Row(children: [
                                                    Icon(Icons.headphones,
                                                        color: Colors.white,
                                                        size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Music',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                  ]))),
                                          const Spacer(),
                                          IconButton(
                                              tooltip: 'Song options',
                                              onPressed: () =>
                                                  AddToPlaylistSheet.show(
                                                      context, c, song),
                                              icon: const Icon(Icons.more_vert,
                                                  color: Colors.white)),
                                        ]),
                                        SwipeUpSongs(
                                            onOpen: _showSongs,
                                            onSwipeDown: () =>
                                                Navigator.of(context).pop(),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                child: SizedBox(
                                                    width: artSize,
                                                    height: artSize,
                                                    child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                8),
                                                        child: ColoredBox(
                                                            color: const Color(
                                                                0xff090909),
                                                            child: MusicArtwork(
                                                                song
                                                                    .thumbnailUrl,
                                                                fit: BoxFit
                                                                    .contain)))))),
                                        Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                20, 10, 20, 0),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(song.title,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize:
                                                              compact ? 21 : 25,
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                  const SizedBox(height: 4),
                                                  Text(song.artist,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          color: Colors.white60,
                                                          fontSize: 16)),
                                                  if (!compact)
                                                    Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 16),
                                                        child: Row(children: [
                                                          OutlinedButton.icon(
                                                              style: OutlinedButton.styleFrom(
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                  backgroundColor:
                                                                      const Color(
                                                                          0xff202020),
                                                                  side:
                                                                      BorderSide
                                                                          .none),
                                                              onPressed: () =>
                                                                  AddToPlaylistSheet
                                                                      .show(
                                                                          context,
                                                                          c,
                                                                          song),
                                                              icon: const Icon(Icons
                                                                  .playlist_add),
                                                              label: const Text(
                                                                  'Save')),
                                                          const SizedBox(
                                                              width: 12),
                                                          IconButton(
                                                              tooltip:
                                                                  'Download song',
                                                              onPressed: () => c
                                                                  .downloads
                                                                  .downloadSong(
                                                                      song),
                                                              icon: Icon(
                                                                  c.downloads.isDownloaded(
                                                                          song
                                                                              .id)
                                                                      ? Icons
                                                                          .download_done
                                                                      : Icons
                                                                          .download_outlined,
                                                                  color: Colors
                                                                      .white70)),
                                                        ])),
                                                ])),
                                        Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: Column(children: [
                                              SliderTheme(
                                                  data: SliderTheme.of(context).copyWith(
                                                      trackHeight: 3,
                                                      activeTrackColor:
                                                          Colors.white,
                                                      inactiveTrackColor:
                                                          Colors.white24,
                                                      thumbColor: Colors.white,
                                                      thumbShape:
                                                          const RoundSliderThumbShape(
                                                              enabledThumbRadius:
                                                                  3)),
                                                  child: Slider(
                                                      value: position,
                                                      max: maxMs,
                                                      onChanged: player.duration
                                                                  .inMilliseconds >
                                                              0
                                                          ? (value) => player
                                                              .seek(Duration(
                                                                  milliseconds:
                                                                      value
                                                                          .round()))
                                                          : null)),
                                              Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8),
                                                  child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                            _fmt(player
                                                                .position),
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white54,
                                                                    fontSize:
                                                                        12)),
                                                        Text(
                                                            _fmt(player
                                                                .duration),
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white54,
                                                                    fontSize:
                                                                        12)),
                                                      ])),
                                              Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 12),
                                                  child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        IconButton(
                                                            tooltip: 'Shuffle',
                                                            onPressed: player
                                                                .toggleShuffle,
                                                            icon: Icon(
                                                                Icons.shuffle,
                                                                color: player
                                                                        .isShuffle
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .white38)),
                                                        IconButton(
                                                            tooltip:
                                                                'Previous song',
                                                            onPressed: player
                                                                .skipPrevious,
                                                            icon: const Icon(
                                                                Icons
                                                                    .skip_previous_rounded,
                                                                color: Colors
                                                                    .white,
                                                                size: 40)),
                                                        SizedBox(
                                                            width: compact
                                                                ? 68
                                                                : 80,
                                                            height: compact
                                                                ? 68
                                                                : 80,
                                                            child: FilledButton(
                                                                style: FilledButton.styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .white,
                                                                    foregroundColor:
                                                                        Colors
                                                                            .black,
                                                                    shape:
                                                                        const CircleBorder(),
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero),
                                                                onPressed: player
                                                                    .togglePlayPause,
                                                                child: player.state ==
                                                                        PlaybackState
                                                                            .loading
                                                                    ? const SizedBox(
                                                                        width:
                                                                            26,
                                                                        height:
                                                                            26,
                                                                        child: CircularProgressIndicator(
                                                                            color:
                                                                                Colors.black,
                                                                            strokeWidth: 2))
                                                                    : Icon(player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 48))),
                                                        IconButton(
                                                            tooltip:
                                                                'Next song',
                                                            onPressed: c
                                                                .skipNextWithTelemetry,
                                                            icon: const Icon(
                                                                Icons
                                                                    .skip_next_rounded,
                                                                color: Colors
                                                                    .white,
                                                                size: 40)),
                                                        IconButton(
                                                            tooltip: 'Repeat',
                                                            onPressed: player
                                                                .toggleRepeat,
                                                            icon: Icon(
                                                                player.repeatMode ==
                                                                        PlayerRepeatMode
                                                                            .one
                                                                    ? Icons
                                                                        .repeat_one
                                                                    : Icons
                                                                        .repeat,
                                                                color: player
                                                                            .repeatMode ==
                                                                        PlayerRepeatMode
                                                                            .off
                                                                    ? Colors
                                                                        .white38
                                                                    : Colors
                                                                        .white)),
                                                      ])),
                                            ])),
                                        SwipeUpSongs(
                                            onOpen: _showSongs,
                                            tapToOpen: true,
                                            child: SizedBox(
                                                width: double.infinity,
                                                child: Padding(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        20, 8, 20, 20),
                                                    child: Column(children: [
                                                      Container(
                                                          width: 40,
                                                          height: 4,
                                                          decoration: BoxDecoration(
                                                              color: Colors
                                                                  .white38,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4))),
                                                      const SizedBox(
                                                          height: 14),
                                                      const Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text('Up next',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        17,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600)),
                                                            Icon(
                                                                Icons
                                                                    .queue_music,
                                                                color: Colors
                                                                    .white70),
                                                          ]),
                                                    ])))),
                                      ])));
                        })))));
      });
}
