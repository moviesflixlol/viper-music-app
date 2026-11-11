import 'package:flutter/material.dart';
import '../../models/song.dart';
import 'music_artwork.dart';

List<Song> moreSongs({required List<Song> queue, required String? currentId,
  required List<Song> recommended, required List<Song> trending}) {
  final index = queue.indexWhere((song) => song.id == currentId);
  final played = index < 0 ? <Song>[] : queue.take(index + 1);
  final upcoming = index < 0 ? queue : queue.skip(index + 1);
  final seen = <String>{if (currentId != null) currentId, ...played.map((s) => s.id)};
  return [...upcoming, ...recommended, ...trending]
      .where((song) => song.id.isNotEmpty && seen.add(song.id)).toList();
}

class SwipeUpSongs extends StatefulWidget {
  final Widget child;
  final VoidCallback onOpen;
  final VoidCallback? onSwipeDown;
  final bool tapToOpen;
  const SwipeUpSongs({super.key, required this.child, required this.onOpen,
    this.onSwipeDown, this.tapToOpen = false});
  @override
  State<SwipeUpSongs> createState() => _SwipeUpSongsState();
}
class _SwipeUpSongsState extends State<SwipeUpSongs> {
  double distance = 0;
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: widget.tapToOpen ? widget.onOpen : null,
    onVerticalDragStart: (_) => distance = 0,
    onVerticalDragUpdate: (event) => distance += event.delta.dy,
    onVerticalDragEnd: (event) {
      if (distance < -60 || (event.primaryVelocity ?? 0) < -200) {
        widget.onOpen();
      } else if ((event.primaryVelocity ?? 0) > 400) {
        widget.onSwipeDown?.call();
      }
    }, child: widget.child,
  );
}

class MoreSongsSheet extends StatelessWidget {
  final List<Song> songs;
  final ValueChanged<Song> onSelected;
  const MoreSongsSheet({super.key, required this.songs, required this.onSelected});
  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.65, minChildSize: 0.3, maxChildSize: 0.95, expand: false,
    builder: (_, scrollController) => Material(
      color: const Color(0xFF181818),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: CustomScrollView(controller: scrollController, slivers: [
        SliverToBoxAdapter(child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.all(20), child: Align(
            alignment: Alignment.centerLeft,
            child: Text('More songs', style: TextStyle(color: Colors.white,
              fontSize: 20, fontWeight: FontWeight.w700)))),
        ])),
        if (songs.isEmpty) const SliverToBoxAdapter(child: Padding(
          padding: EdgeInsets.all(24), child: Text('Loading more songs from your feed…',
            style: TextStyle(color: Colors.white60)))),
        SliverList.builder(itemCount: songs.length, itemBuilder: (context, index) {
          final song = songs[index];
          return ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(6),
              child: MusicArtwork(song.thumbnailUrl, width: 48, height: 48)),
            title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white)),
            subtitle: Text(song.artist, maxLines: 1,
              style: const TextStyle(color: Colors.white54)),
            trailing: const Icon(Icons.play_arrow, color: Colors.white70),
            onTap: () => onSelected(song),
          );
        }),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ]),
    ),
  );
}
