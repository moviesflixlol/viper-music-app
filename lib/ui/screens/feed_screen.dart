import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/song.dart';
import '../../state/music_controller.dart';
import '../components/hero_header.dart';
import '../components/song_tile.dart';

class FeedScreen extends StatelessWidget {
  final MusicController controller;

  const FeedScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isFeedLoading && controller.trendingTracks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    final featured = controller.trendingTracks.isNotEmpty
        ? controller.trendingTracks.first
        : const Song(
            id: 'dQw4w9WgXcQ',
            title: 'Discover Fresh Hits',
            artist: 'NextViper Music Stream',
            thumbnailUrl: '',
          );

    return RefreshIndicator(
      color: AppColors.primaryRed,
      backgroundColor: AppColors.surface,
      onRefresh: controller.loadInitialFeed,
      child: CustomScrollView(
        slivers: [
          // Netflix App Bar
          SliverAppBar(
            backgroundColor: AppColors.background.withOpacity(0.9),
            floating: true,
            pinned: false,
            elevation: 0,
            title: Row(
              children: [
                // Netflix 'N' style Icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NV',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'MUSIC',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                onPressed: () => _showSettingsDialog(context),
              ),
            ],
          ),

          // Spotlight Hero Header
          SliverToBoxAdapter(
            child: HeroHeader(
              song: featured,
              isDownloaded: controller.downloads.isDownloaded(featured.id),
              onPlay: () {
                controller.player.playSong(featured, queueContext: controller.trendingTracks);
              },
              onDownload: () {
                controller.downloads.downloadSong(featured);
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Shelf 1: Trending Top Tracks Carousel
          SliverToBoxAdapter(
            child: _buildShelfHeader('TRENDING NOW'),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.trendingTracks.length,
                itemBuilder: (context, index) {
                  final song = controller.trendingTracks[index];
                  return _buildTrendingCard(context, song, index + 1);
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // Shelf 2: Quick Picks Vertical List
          SliverToBoxAdapter(
            child: _buildShelfHeader('QUICK PICKS FOR YOU'),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = controller.feedRecommendations[index];
                final isCurrent = controller.player.currentSong?.id == song.id;
                return SongTile(
                  song: song,
                  isPlaying: controller.player.isPlaying,
                  isCurrentTrack: isCurrent,
                  isDownloaded: controller.downloads.isDownloaded(song.id),
                  isDownloading: controller.downloads.isDownloading(song.id),
                  downloadProgress: controller.downloads.getDownloadProgress(song.id),
                  onTap: () {
                    controller.player.playSong(song, queueContext: controller.feedRecommendations);
                  },
                  onDownload: () {
                    controller.downloads.downloadSong(song);
                  },
                );
              },
              childCount: controller.feedRecommendations.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildShelfHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTrendingCard(BuildContext context, Song song, int rank) {
    return GestureDetector(
      onTap: () {
        controller.player.playSong(song, queueContext: controller.trendingTracks);
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          song.thumbnailUrl,
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 130,
                            height: 130,
                            color: AppColors.surfaceHighlight,
                          ),
                        )
                      : Container(
                          width: 130,
                          height: 130,
                          color: AppColors.surfaceHighlight,
                        ),
                ),
                // Netflix-style Rank Number
                Positioned(
                  bottom: -6,
                  left: -2,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withOpacity(0.9),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.9),
                          blurRadius: 10,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final textController = TextEditingController(text: controller.apiService.baseUrl);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Backend Configuration', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NextViper Server URL:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:8080',
                hintStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryRed)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () {
              controller.apiService.baseUrl = textController.text.trim();
              Navigator.pop(context);
              controller.loadInitialFeed();
            },
            child: const Text('Save & Reconnect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
