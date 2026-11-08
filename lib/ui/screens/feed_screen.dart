import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../state/music_controller.dart';
import '../components/song_tile.dart';
import '../components/add_to_playlist_sheet.dart';
import 'playlists_screen.dart';

class FeedScreen extends StatelessWidget {
  final MusicController controller;

  const FeedScreen({super.key, required this.controller});

  void _openPlaylistDetail(BuildContext context, Playlist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PlaylistDetailScreen(controller: controller, playlist: playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.isFeedLoading && controller.trendingTracks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    final startListening = controller.trendingTracks.take(4).toList();
    final recommended = controller.feedRecommendations;
    final charts = MusicController.curatedPlaylists;
    final artists = MusicController.popularArtists;

    return RefreshIndicator(
      color: AppColors.primaryRed,
      backgroundColor: AppColors.surface,
      onRefresh: controller.loadInitialFeed,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // 1. Spotify-Style Header (Avatar + Filter Pills [ All ] [ Music ] [ Podcasts ])
          SliverAppBar(
            backgroundColor: AppColors.background.withOpacity(0.95),
            floating: true,
            pinned: true,
            elevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                // Circular 'M' Avatar
                GestureDetector(
                  onTap: () => controller.setTab(3), // Open profile
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primaryRed, Color(0xFFB80710)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Category Filter Pills matching Screenshot 2, 3, 5
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: MusicController.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = MusicController.categories[index];
                        final isSelected = controller.selectedCategory == cat;

                        return GestureDetector(
                          onTap: () {
                            if (cat == 'Charts') {
                              controller.setTab(2); // Jump to Playlists
                            } else {
                              controller.setCategory(cat);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryRed : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. "Start listening" Section matching Screenshot 5
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jump into a session based on your tastes',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Start listening',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),

          // Start listening items
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = startListening[index];
                final isCurrent = controller.player.currentSong?.id == song.id;
                return SongTile(
                  song: song,
                  isPlaying: isCurrent && controller.player.isPlaying,
                  isCurrentTrack: isCurrent,
                  onTap: () => controller.playSong(song, queueContext: startListening),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.playlist_add, color: Colors.white60, size: 22),
                        onPressed: () => AddToPlaylistSheet.show(context, controller, song),
                      ),
                    ],
                  ),
                );
              },
              childCount: startListening.length,
            ),
          ),

          // 3. "Charts & Hot Hits" Section matching Screenshot 2 & 3
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Charts',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  GestureDetector(
                    onTap: () => controller.setTab(2),
                    child: const Text(
                      'See all',
                      style: TextStyle(color: AppColors.primaryRed, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 215,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: charts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final pl = charts[index];
                  return GestureDetector(
                    onTap: () => _openPlaylistDetail(context, pl),
                    child: SizedBox(
                      width: 145,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              pl.coverUrl,
                              width: 145,
                              height: 145,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 145,
                                height: 145,
                                color: AppColors.surface,
                                child: const Icon(Icons.queue_music, color: Colors.white30, size: 40),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pl.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pl.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11, height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 4. "Popular artists" Section with Circular Avatars matching Screenshot 4
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: const Text(
                'Popular artists',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: artists.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final artist = artists[index];
                  return GestureDetector(
                    onTap: () {
                      controller.setTab(1); // Switch to search
                      controller.search(artist.name);
                    },
                    child: SizedBox(
                      width: 105,
                      child: Column(
                        children: [
                          // Circular Artist Photo
                          Container(
                            width: 105,
                            height: 105,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              artist.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.surface,
                                child: const Icon(Icons.person, color: Colors.white30, size: 36),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            artist.genre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 5. "Recommended For You" Section matching Screenshot 2
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: const Text(
                'Recommended For You',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recommended.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final song = recommended[index];
                  return GestureDetector(
                    onTap: () => controller.playSong(song, queueContext: recommended),
                    child: SizedBox(
                      width: 135,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                Image.network(
                                  song.thumbnailUrl,
                                  width: 135,
                                  height: 135,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 135,
                                    height: 135,
                                    color: AppColors.surface,
                                    child: const Icon(Icons.album, color: Colors.white30, size: 36),
                                  ),
                                ),
                                Positioned(
                                  right: 6,
                                  bottom: 6,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryRed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 6. "Trending Hits" Vertical List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: const Text(
                'Trending Hits',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = controller.trendingTracks[index];
                final isCurrent = controller.player.currentSong?.id == song.id;
                return SongTile(
                  song: song,
                  isPlaying: isCurrent && controller.player.isPlaying,
                  isCurrentTrack: isCurrent,
                  onTap: () => controller.playSong(song, queueContext: controller.trendingTracks),
                  trailing: IconButton(
                    icon: const Icon(Icons.playlist_add, color: Colors.white54, size: 22),
                    onPressed: () => AddToPlaylistSheet.show(context, controller, song),
                  ),
                );
              },
              childCount: controller.trendingTracks.length,
            ),
          ),

          // 7. "Load More Music" Pagination Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: controller.isLoadingMoreFeed ? null : controller.loadMoreFeed,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryRed, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      backgroundColor: Colors.transparent,
                    ),
                    child: controller.isLoadingMoreFeed
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: AppColors.primaryRed, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.expand_more_rounded, color: AppColors.primaryRed, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'LOAD MORE MUSIC',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}
