import '../components/playlist_artwork.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/playlist.dart';
import '../../state/music_controller.dart';
import '../components/song_tile.dart';

class PlaylistsScreen extends StatelessWidget {
  final MusicController controller;

  const PlaylistsScreen({super.key, required this.controller});

  void _showCreateDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Give your playlist a name',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'My Playlist #1',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryRed)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryRed, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(ctx).pop();
                final success = await controller.createPlaylist(name);
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Created "$name" successfully!'),
                      backgroundColor: AppColors.primaryRed,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Create',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openPlaylistDetail(BuildContext context, Playlist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) =>
            PlaylistDetailScreen(controller: controller, playlist: playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only real user playlists (no untitled or blank placeholders)
    final validUserPlaylists = controller.userPlaylists
        .where((p) =>
            p.name.trim().isNotEmpty &&
            p.name.trim().toLowerCase() != 'untitled playlist')
        .toList();

    final charts = controller.chartPlaylists;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'Your Library',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            onPressed: () => _showCreateDialog(context),
            tooltip: 'Create Playlist',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await controller.loadUserPlaylists();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // "Create playlist" Action Banner
            GestureDetector(
              onTap: () => _showCreateDialog(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppColors.primaryRed, width: 1.2),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_rounded,
                            color: AppColors.primaryRed, size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create playlist',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Build your custom track collection',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white38),
                  ],
                ),
              ),
            ),

            // Real User Playlists Section (Only if created by user!)
            if (validUserPlaylists.isNotEmpty) ...[
              const Text(
                'Your Playlists',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...validUserPlaylists
                  .map((pl) => _buildUserPlaylistTile(context, pl)),
              const SizedBox(height: 24),
            ],

            // Real Curated Playlists / Charts (from Spotify screenshots)
            const Text(
              'Featured Charts & Playlists',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),

            ...charts.map((pl) => _buildCuratedPlaylistTile(context, pl)),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPlaylistTile(BuildContext context, Playlist pl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: PlaylistArtwork(playlist: pl, size: 52),
        ),
        title: Text(
          pl.name,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          'Playlist · ${pl.tracks.length} ${pl.tracks.length == 1 ? "track" : "tracks"}',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: () => _openPlaylistDetail(context, pl),
      ),
    );
  }

  Widget _buildCuratedPlaylistTile(BuildContext context, Playlist pl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: PlaylistArtwork(playlist: pl, size: 52),
        ),
        title: Text(
          pl.name,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(
          pl.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
        ),
        trailing: const Icon(Icons.play_circle_fill,
            color: AppColors.primaryRed, size: 26),
        onTap: () => _openPlaylistDetail(context, pl),
      ),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final MusicController controller;
  final Playlist playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.controller,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    // Find live instance if user playlist, else fallback to curated
    final livePlaylist = controller.userPlaylists.firstWhere(
      (p) => p.id == playlist.id,
      orElse: () => playlist,
    );
    final tracks = livePlaylist.tracks;
    final isUserPlaylist =
        controller.userPlaylists.any((p) => p.id == livePlaylist.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (isUserPlaylist)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white70),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Delete Playlist',
                        style: TextStyle(color: Colors.white)),
                    content: Text('Delete "${livePlaylist.name}"?',
                        style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await controller.deletePlaylist(livePlaylist.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: PlaylistArtwork(playlist: livePlaylist, size: 170),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              livePlaylist.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
          if (livePlaylist.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                livePlaylist.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Center(
            child: Text(
              '${tracks.length} tracks',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 12),
            ),
          ),
          const SizedBox(height: 18),
          if (tracks.isNotEmpty)
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  controller.playSong(tracks.first, queueContext: tracks);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 22),
                label: const Text('PLAY ALL',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          const SizedBox(height: 24),
          if (tracks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.music_note_rounded,
                      size: 48, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 12),
                  Text('No songs added yet',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    'Search for tracks or tap "+ Add to Playlist" while listening.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ...tracks.map((song) => SongTile(
                  song: song,
                  isPlaying: controller.player.currentSong?.id == song.id &&
                      controller.player.isPlaying,
                  isCurrentTrack: controller.player.currentSong?.id == song.id,
                  onTap: () => controller.playSong(song, queueContext: tracks),
                  trailing: isUserPlaylist
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.white38, size: 20),
                          onPressed: () => controller.removeSongFromPlaylist(
                              livePlaylist.id, song.id),
                        )
                      : null,
                )),
          const SizedBox(height: 110),
        ],
      ),
    );
  }
}
