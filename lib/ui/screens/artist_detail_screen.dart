import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../services/api_service.dart';
import '../../state/music_controller.dart';
import '../components/music_artwork.dart';
import '../components/song_tile.dart';
import 'playlists_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  final ArtistInfo artist;
  final MusicController controller;
  const ArtistDetailScreen(
      {super.key, required this.artist, required this.controller});
  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  CatalogResult? _catalog;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
    });
    try {
      final result =
          await widget.controller.apiService.browse(widget.artist.id);
      if (mounted) setState(() => _catalog = result);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load this artist.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final tracks = _catalog?.songs ?? <Song>[];
    final albums = _catalog?.albums ?? <ReleaseItem>[];
    final singles = albums
        .where((a) => a.section.toLowerCase().contains('single'))
        .toList();
    final fullAlbums = albums.where((a) => !singles.contains(a)).toList();
    return Scaffold(
        backgroundColor: Colors.black,
        body: CustomScrollView(slivers: [
          SliverAppBar(
              backgroundColor: Colors.black,
              expandedHeight: 320,
              pinned: true,
              title: Text(widget.artist.name),
              flexibleSpace: FlexibleSpaceBar(
                  background: Stack(fit: StackFit.expand, children: [
                MusicArtwork(widget.artist.imageUrl, fit: BoxFit.cover),
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black]))),
                Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Text(widget.artist.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w800))),
              ]))),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Expanded(
                        child: Text('Music',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold))),
                    FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black),
                        onPressed: tracks.isEmpty
                            ? null
                            : () =>
                                c.playSong(tracks.first, queueContext: tracks),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play all')),
                  ]))),
          if (_catalog == null && _error == null)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child:
                            CircularProgressIndicator(color: Colors.white)))),
          if (_error != null)
            SliverToBoxAdapter(
                child: Column(children: [
              Text(_error!, style: const TextStyle(color: Colors.white70)),
              TextButton(onPressed: _load, child: const Text('Retry'))
            ])),
          if (tracks.isNotEmpty)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Top songs',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)))),
          SliverList.builder(
              itemCount: tracks.length,
              itemBuilder: (_, i) => SongTile(
                  song: tracks[i],
                  onTap: () => c.playSong(tracks[i], queueContext: tracks))),
          if (fullAlbums.isNotEmpty)
            ReleaseShelf(title: 'Albums', releases: fullAlbums, controller: c),
          if (singles.isNotEmpty)
            ReleaseShelf(
                title: 'Singles and EPs', releases: singles, controller: c),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ]));
  }
}

class ReleaseShelf extends StatelessWidget {
  final String title;
  final List<ReleaseItem> releases;
  final MusicController controller;
  const ReleaseShelf(
      {super.key,
      required this.title,
      required this.releases,
      required this.controller});
  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22))),
        SizedBox(
            height: 224,
            child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: releases.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) {
                  final release = releases[i];
                  return InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ReleaseScreen(
                              release: release, controller: controller))),
                      child: SizedBox(
                          width: 160,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: MusicArtwork(release.thumbnail,
                                        width: 160, height: 160)),
                                const SizedBox(height: 8),
                                Text(release.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    release.subtitle.isEmpty
                                        ? release.artist
                                        : release.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 13)),
                              ])));
                })),
      ]));
}

class ReleaseScreen extends StatefulWidget {
  final ReleaseItem release;
  final MusicController controller;
  const ReleaseScreen(
      {super.key, required this.release, required this.controller});
  @override
  State<ReleaseScreen> createState() => _ReleaseScreenState();
}

class _ReleaseScreenState extends State<ReleaseScreen> {
  late final Future<CatalogResult> _result =
      widget.controller.apiService.browse(widget.release.id);
  @override
  Widget build(BuildContext context) => FutureBuilder<CatalogResult>(
      future: _result,
      builder: (context, snapshot) {
        if (snapshot.hasData)
          return PlaylistDetailScreen(
              controller: widget.controller,
              playlist: Playlist(
                  id: widget.release.id,
                  name: widget.release.title,
                  coverUrl: widget.release.thumbnail,
                  description: widget.release.subtitle,
                  tracks: snapshot.data!.songs,
                  isAutoGenerated: true));
        return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(title: Text(widget.release.title)),
            body: Center(
                child: snapshot.hasError
                    ? const Text(
                        'Could not load this release. Please try again.',
                        style: TextStyle(color: Colors.white70))
                    : const CircularProgressIndicator(color: Colors.white)));
      });
}
