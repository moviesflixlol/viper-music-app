import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/song.dart';
import '../../state/music_controller.dart';
import '../components/hero_header.dart';
import '../components/song_tile.dart';
import '../components/add_to_playlist_sheet.dart';

class FeedScreen extends StatelessWidget {
  final MusicController controller;

  const FeedScreen({super.key, required this.controller});

  void _showInfoDialog(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artist: ${song.artist}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text('Genre: ${song.genre}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text('Duration: ${song.duration}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text('Match Score: ${(song.popularity * 100).toInt()}%', style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close', style: TextStyle(color: Colors.white70))),
        ],
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

    final featured = controller.featuredSong ??
        (controller.trendingTracks.isNotEmpty
            ? controller.trendingTracks.first
            : const Song(
                id: '4NRXx6U8ABQ',
                title: 'Blinding Lights',
                artist: 'The Weeknd',
                thumbnailUrl: 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg',
              ));

    // Filter recommended tracks by category if not 'All Titles'
    List<Song> displayRecommended = controller.feedRecommendations;
    if (controller.selectedCategory == 'Songs') {
      displayRecommended = controller.feedRecommendations;
    } else if (controller.selectedCategory == 'Trending') {
      displayRecommended = controller.trendingTracks;
    } else if (controller.selectedCategory == 'Chill') {
      displayRecommended = controller.feedRecommendations.where((s) => s.genre == 'Acoustic' || s.genre == 'Chill').toList();
      if (displayRecommended.isEmpty) displayRecommended = controller.feedRecommendations;
    } else if (controller.selectedCategory == 'Workout') {
      displayRecommended = controller.feedRecommendations.where((s) => s.genre == 'Hip-Hop' || s.genre == 'Electronic' || s.genre == 'Rock').toList();
      if (displayRecommended.isEmpty) displayRecommended = controller.feedRecommendations;
    }

    return RefreshIndicator(
      color: AppColors.primaryRed,
      backgroundColor: AppColors.surface,
      onRefresh: controller.loadInitialFeed,
      child: CustomScrollView(
        slivers: [
          // 1. Sleek Header matching Screenshot (M Logo + Inline Search + Grid Icon)
          SliverAppBar(
            backgroundColor: AppColors.background.withOpacity(0.92),
            floating: true,
            pinned: false,
            elevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                // Red 'M' Logo
                Image.asset(
                  'assets/images/header_logo.png',
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Inline Search Bar Button matching screenshot
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.setTab(1), // Switch to Search tab
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: Colors.white12, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.6), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Search titles...',
                            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Category / Grid Icon matching screenshot
                GestureDetector(
                  onTap: () => controller.setTab(2), // Switch to Playlists tab
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12, width: 0.8),
                    ),
                    child: const Center(
                      child: Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Category Chips Row matching screenshot (All Titles, Movies/Songs, TV Series/Playlists, etc.)
          SliverToBoxAdapter(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: MusicController.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = MusicController.categories[index];
                  final isSelected = controller.selectedCategory == cat;

                  return GestureDetector(
                    onTap: () {
                      if (cat == 'Playlists') {
                        controller.setTab(2);
                      } else {
                        controller.setCategory(cat);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryRed : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryRed : Colors.white12,
                          width: 0.8,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
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

          // 3. Spotlight Hero Banner matching Screenshot
          SliverToBoxAdapter(
            child: HeroHeader(
              song: featured,
              onPlay: () => controller.playSongWithAuth(context, featured, queueContext: controller.trendingTracks),
              onAddToList: () => AddToPlaylistSheet.show(context, controller, featured),
              onInfo: () => _showInfoDialog(context, featured),
            ),
          ),

          // 4. "Recommended For You" Header matching Screenshot
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recommended For You',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.setTab(1),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See More',
                          style: TextStyle(
                            color: AppColors.primaryRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, color: AppColors.primaryRed, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Vertical Aspect-Ratio Cards (Movieflix/Netflix Poster Carousel) matching Screenshot
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayRecommended.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final song = displayRecommended[index];
                  return _buildPosterCard(context, song, displayRecommended);
                },
              ),
            ),
          ),

          // 6. Intelligent Auto-Mixes Section
          if (controller.recommendedMixes.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 28, bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primaryRed, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Personalized Mixes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.recommendedMixes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final mix = controller.recommendedMixes[index];
                    return _buildMixPoster(context, mix);
                  },
                ),
              ),
            ),
          ],

          // 7. Trending Tracks Feed Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 28, bottom: 8),
              child: const Text(
                'Trending Hits',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = controller.trendingTracks[index];
                return SongTile(
                  song: song,
                  isPlaying: controller.player.currentSong?.id == song.id && controller.player.isPlaying,
                  onTap: () => controller.playSongWithAuth(context, song, queueContext: controller.trendingTracks),
                  trailing: IconButton(
                    icon: const Icon(Icons.playlist_add, color: Colors.white54, size: 22),
                    onPressed: () => AddToPlaylistSheet.show(context, controller, song),
                  ),
                );
              },
              childCount: controller.trendingTracks.length,
            ),
          ),

          // 8. "Load More Music" Pagination Button
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

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildPosterCard(BuildContext context, Song song, List<Song> queue) {
    return GestureDetector(
      onTap: () => controller.playSongWithAuth(context, song, queueContext: queue),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vertical Poster Card matching screenshot
            Container(
              height: 165,
              width: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    song.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.music_note, color: Colors.white30, size: 36),
                    ),
                  ),
                  // Subtle top and bottom gradients
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Play Overlay Button
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                      ),
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
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
  }

  Widget _buildMixPoster(BuildContext context, dynamic mix) {
    return GestureDetector(
      onTap: () {
        if (mix.tracks.isNotEmpty) {
          controller.playSongWithAuth(context, mix.tracks.first, queueContext: mix.tracks);
        }
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    mix.coverUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.white12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mix.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '${mix.tracks.length} tracks',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              mix.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AUTO MIX', style: TextStyle(color: AppColors.primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
                const Icon(Icons.play_circle_fill, color: AppColors.primaryRed, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
