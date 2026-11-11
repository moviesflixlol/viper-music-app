import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../state/music_controller.dart';
import '../components/music_artwork.dart';
import '../components/song_tile.dart';
import '../components/add_to_playlist_sheet.dart';
import 'artist_detail_screen.dart';

class FeedScreen extends StatelessWidget {
  final MusicController controller;
  const FeedScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        return RefreshIndicator(
            onRefresh: c.refreshFeed,
            color: Colors.white,
            backgroundColor: const Color(0xff242424),
            child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                      backgroundColor: Colors.black,
                      pinned: true,
                      titleSpacing: 16,
                      title: Image.asset('assets/images/movieflix_header.png', height: 36, width: 145, fit: BoxFit.contain, semanticLabel: 'MovieFlix'),
                      actions: [
                        IconButton(
                            tooltip: 'Search songs and artists',
                            onPressed: () => c.setTab(1),
                            icon: const Icon(Icons.search))
                      ]),
                  const SliverToBoxAdapter(
                      child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Text('YOUR ROTATION',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  letterSpacing: 1.8)))),
                  _heading('Your most listened'),
                  if (c.mostListened.isEmpty)
                    const SliverToBoxAdapter(
                        child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                                'Listen to songs for at least 30 seconds to build your rotation.',
                                style: TextStyle(color: Colors.white54))))
                  else
                    SliverList.builder(
                        itemCount: c.mostListened.take(5).length,
                        itemBuilder: (_, i) => SongTile(
                            song: c.mostListened[i],
                            onTap: () => c.playSong(c.mostListened[i],
                                queueContext: c.mostListened),
                            trailing: Text('#${i + 1}',
                                style:
                                    const TextStyle(color: Colors.white54)))),
                  if (c.isFeedLoading && c.feedRecommendations.isEmpty)
                    const SliverToBoxAdapter(
                        child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white)))),
                  if (c.feedRecommendations.isNotEmpty) ...[
                    _heading(c.mostListened.isEmpty
                        ? 'Discover music'
                        : 'Recommended for you'),
                    _songs(c.feedRecommendations.take(30).toList()),
                  ],
                  if (c.newReleases.isNotEmpty) ...[
                    _heading('New music videos'),
                    _songs(c.newReleases)
                  ],
                  if (c.releaseAlbums.isNotEmpty)
                    ReleaseShelf(
                        title: 'New releases',
                        releases: c.releaseAlbums,
                        controller: c),
                  if (c.popularArtists.isNotEmpty) ...[
                    _heading('Explore artists'),
                    SliverToBoxAdapter(
                        child: SizedBox(
                            height: 154,
                            child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: c.popularArtists.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (context, i) {
                                  final a = c.popularArtists[i];
                                  return InkWell(
                                      onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  ArtistDetailScreen(
                                                      artist: a,
                                                      controller: c))),
                                      child: SizedBox(
                                          width: 112,
                                          child: Column(children: [
                                            ClipOval(
                                                child: MusicArtwork(a.imageUrl,
                                                    width: 112, height: 112)),
                                            const SizedBox(height: 8),
                                            Text(a.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                          ])));
                                }))),
                  ],
                  if (c.trendingTracks.isNotEmpty) ...[
                    _heading('From the charts'),
                    SliverList.builder(
                        itemCount: c.trendingTracks.length,
                        itemBuilder: (context, i) {
                          final song = c.trendingTracks[i];
                          return SongTile(
                              song: song,
                              isCurrentTrack:
                                  c.player.currentSong?.id == song.id,
                              isPlaying: c.player.currentSong?.id == song.id &&
                                  c.player.isPlaying,
                              onTap: () => c.playSong(song,
                                  queueContext: c.trendingTracks),
                              trailing: IconButton(
                                  tooltip: 'Save to playlist',
                                  icon: const Icon(Icons.playlist_add,
                                      color: Colors.white54),
                                  onPressed: () => AddToPlaylistSheet.show(
                                      context, c, song)));
                        }),
                  ],
                  if (c.moreFeed.isNotEmpty) ...[
                    _heading('More for you'),
                    SliverList.builder(itemCount: c.moreFeed.length, itemBuilder: (_, i) => SongTile(
                      song: c.moreFeed[i], onTap: () => c.playSong(c.moreFeed[i], queueContext: c.moreFeed))),
                  ],
                  if (c.feedMessage != null) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16),
                    child: Text(c.feedMessage!, style: const TextStyle(color: Colors.white60)))),
                  if (!c.isFeedLoading && !c.isBackendConnected)
                    SliverToBoxAdapter(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(children: [
                              const Text('Music is temporarily unavailable.',
                                  style: TextStyle(color: Colors.white70)),
                              TextButton(
                                  onPressed: c.loadInitialFeed,
                                  child: const Text('Retry'))
                            ]))),
                  if (c.feedRecommendations.isNotEmpty)
                    SliverToBoxAdapter(
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                                child: c.isLoadingMoreFeed
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white),
                                        onPressed: c.feedHasMore ? c.loadMoreFeed : null,
                                        child: Text(c.feedHasMore ? 'Load more songs' : 'You’re up to date'))))),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ]));
      });
  Widget _heading(String text) => SliverToBoxAdapter(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700))));
  Widget _songs(List<Song> songs) => SliverToBoxAdapter(
      child: SizedBox(
          height: 212,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: songs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final song = songs[i];
                return InkWell(
                    onTap: () => controller.playSong(song, queueContext: songs),
                    child: SizedBox(
                        width: 148,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: MusicArtwork(song.thumbnailUrl,
                                      width: 148, height: 148)),
                              const SizedBox(height: 8),
                              Text(song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 13)),
                            ])));
              })));
}
