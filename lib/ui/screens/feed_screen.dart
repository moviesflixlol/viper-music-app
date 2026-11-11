import '../components/playlist_artwork.dart';
import '../components/music_artwork.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../state/music_controller.dart';
import '../components/song_tile.dart';
import '../components/add_to_playlist_sheet.dart';
import 'playlists_screen.dart';

class FeedScreen extends StatefulWidget {
  final MusicController controller;
  const FeedScreen({super.key, required this.controller});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  MusicController get c => widget.controller;

  void _openPlaylistDetail(Playlist playlist) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlaylistDetailScreen(controller: c, playlist: playlist),
    ));
  }

  Future<void> _onLoadMore() async {
    await c.loadMoreFeed();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (c.isFeedLoading && c.trendingTracks.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
    }

    final recommended = c.feedRecommendations;
    final mixes = c.recommendedMixes;
    final trending = c.trendingTracks;

    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        return RefreshIndicator(
          color: AppColors.primaryRed,
          backgroundColor: AppColors.surface,
          onRefresh: c.loadInitialFeed,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // ── Header bar with logo + category chips ──
              SliverAppBar(
                backgroundColor: AppColors.background.withOpacity(0.95),
                floating: true,
                pinned: true,
                elevation: 0,
                titleSpacing: 16,
                title: Row(
                  children: [
                    GestureDetector(
                      onTap: () => c.setTab(3),
                      child: Image.asset(
                        'assets/images/header_logo.png',
                        height: 34,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Text(
                          'MUSIC',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: MusicController.categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final cat = MusicController.categories[i];
                            final isSelected = c.selectedCategory == cat;
                            return GestureDetector(
                              onTap: () {
                                if (cat == 'Charts') {
                                  c.setTab(2);
                                } else {
                                  c.setCategory(cat);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryRed : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 13,
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

              // ── Section: Recommended For You (horizontal cards) ──
              if (recommended.isNotEmpty) ...[
                _sectionHeader('Recommended For You'),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: recommended.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => _songCard(recommended[i], recommended),
                    ),
                  ),
                ),
              ],

              // ── Section: Your Playlists / Mixes (horizontal cards) ──
              if (mixes.isNotEmpty) ...[
                _sectionHeaderWithAction(
                  mixes.first.isAutoGenerated ? 'Your Mixes' : 'Playlists',
                  'See all',
                  () => c.setTab(2),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 210,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: mixes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => _playlistCard(mixes[i]),
                    ),
                  ),
                ),
              ],

              // ── Section: Trending Hits (vertical list) ──
              if (trending.isNotEmpty) ...[
                _sectionHeader('Trending Hits'),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final song = trending[i];
                      final isCurrent = c.player.currentSong?.id == song.id;
                      return SongTile(
                        song: song,
                        isPlaying: isCurrent && c.player.isPlaying,
                        isCurrentTrack: isCurrent,
                        onTap: () => c.playSong(song, queueContext: trending),
                        trailing: IconButton(
                          icon: const Icon(Icons.playlist_add, color: Colors.white54, size: 22),
                          onPressed: () => AddToPlaylistSheet.show(context, c, song),
                        ),
                      );
                    },
                    childCount: trending.length,
                  ),
                ),
              ],

              // ── Load More button ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: _LoadMoreButton(
                    isLoading: c.isLoadingMoreFeed,
                    onPressed: _onLoadMore,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _sectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionHeaderWithAction(String title, String actionLabel, VoidCallback onAction) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel,
                  style: const TextStyle(color: AppColors.primaryRed, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _songCard(Song song, List<Song> queue) {
    final isCurrent = c.player.currentSong?.id == song.id;
    return GestureDetector(
      onTap: () => c.playSong(song, queueContext: queue),
      child: SizedBox(
        width: 138,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MusicArtwork(
                    song.thumbnailUrl,
                    width: 138,
                    height: 138,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 138,
                      height: 138,
                      color: AppColors.surface,
                      child: const Icon(Icons.album, color: Colors.white24, size: 40),
                    ),
                  ),
                ),
                // Playing indicator overlay
                if (isCurrent)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withOpacity(0.45),
                      ),
                      child: const Center(
                        child: Icon(Icons.equalizer_rounded, color: AppColors.primaryRed, size: 32),
                      ),
                    ),
                  ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _playlistCard(Playlist pl) {
    return GestureDetector(
      onTap: () => _openPlaylistDetail(pl),
      child: SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: PlaylistArtwork(playlist: pl, size: 148),
            ),
            const SizedBox(height: 7),
            Text(pl.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 2),
            Text(pl.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, height: 1.25)),
          ],
        ),
      ),
    );
  }
}

/// Stateful button so it can show its own loading state immediately on press
class _LoadMoreButton extends StatefulWidget {
  final bool isLoading;
  final Future<void> Function() onPressed;

  const _LoadMoreButton({required this.isLoading, required this.onPressed});

  @override
  State<_LoadMoreButton> createState() => _LoadMoreButtonState();
}

class _LoadMoreButtonState extends State<_LoadMoreButton> {
  bool _localLoading = false;

  Future<void> _handle() async {
    if (_localLoading || widget.isLoading) return;
    setState(() => _localLoading = true);
    await widget.onPressed();
    if (mounted) setState(() => _localLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final loading = _localLoading || widget.isLoading;
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: loading ? null : _handle,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primaryRed, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
          backgroundColor: Colors.transparent,
        ),
        child: loading
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
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                  ),
                ],
              ),
      ),
    );
  }
}
