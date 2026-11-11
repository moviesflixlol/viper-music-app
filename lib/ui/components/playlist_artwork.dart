import 'package:flutter/material.dart';
import '../../models/playlist.dart';
import 'music_artwork.dart';

class PlaylistArtwork extends StatelessWidget {
  final Playlist playlist;
  final double size;
  const PlaylistArtwork({super.key, required this.playlist, required this.size});

  @override
  Widget build(BuildContext context) {
    final tracks = playlist.tracks.take(4).toList();
    Widget tile(int index) => Expanded(child: MusicArtwork(
      index < tracks.length ? tracks[index].thumbnailUrl : '',
    ));
    final art = tracks.length < 2
      ? MusicArtwork(tracks.isNotEmpty && tracks.first.thumbnailUrl.isNotEmpty
          ? tracks.first.thumbnailUrl : playlist.coverUrl)
      : Column(children: [
          Expanded(child: Row(children: [tile(0), tile(1)])),
          Expanded(child: Row(children: [tile(2), tile(3)])),
        ]);
    return Semantics(label: '${playlist.name} playlist artwork',
      child: SizedBox.square(dimension: size,
        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: art)));
  }
}
