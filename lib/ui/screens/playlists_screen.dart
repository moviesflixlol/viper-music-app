import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../state/music_controller.dart';
import '../components/song_tile.dart';
import 'auth_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  final MusicController controller;

  const PlaylistsScreen({super.key, required this.controller});

  void _showCreateDialog(BuildContext context) {
    if (!controller.authService.isLoggedIn) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (ctx) => AuthScreen(authService: controller.authService), fullscreenDialog: true),
      );
      return;
    }

    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('New Playlist', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryRed)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryRed, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(ctx).pop();
                await controller.createPlaylist(name);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openPlaylistDetail(BuildContext context, Playlist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PlaylistDetailScreen(controller: controller, playlist: playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userPlaylists = controller.userPlaylists;
    final mixes = controller.recommendedMixes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Playlists',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryRed, size: 26),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await controller.loadUserPlaylists();
          await controller.loadInitialFeed();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // User Playlists Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Cloud Playlists',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add, color: AppColors.primaryRed, size: 16),
                  label: const Text('New', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (userPlaylists.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.6),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.queue_music, color: Colors.white38, size: 40),
                    const SizedBox(height: 12),
                    const Text('No playlists created yet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      'Create a playlist or save a recommended mix below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () => _showCreateDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Create Playlist'),
                    ),
                  ],
                ),
              )
            else
              ...userPlaylists.map((pl) => _buildPlaylistTile(context, pl)),

            const SizedBox(height: 32),

            // Intelligent Recommendation Mixes Header
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primaryRed, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Auto-Generated For You',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Intelligent mixes powered by NextViper algorithmic scoring.',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Recommendation Mixes Cards
            ...mixes.map((mix) => _buildMixCard(context, mix)),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistTile(BuildContext context, Playlist pl) {
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
          child: Image.network(
            pl.coverUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 50,
              height: 50,
              color: Colors.white12,
              child: const Icon(Icons.queue_music, color: Colors.white54),
            ),
          ),
        ),
        title: Text(
          pl.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(
          '${pl.tracks.length} tracks · Cloud Synced',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: () => _openPlaylistDetail(context, pl),
      ),
    );
  }

  Widget _buildMixCard(BuildContext context, Playlist mix) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              mix.coverUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: Colors.white12,
                child: const Icon(Icons.album, color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('AUTO MIX', style: TextStyle(color: AppColors.primaryRed, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    Text('${mix.tracks.length} songs', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mix.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  mix.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (mix.tracks.isNotEmpty) {
                          controller.playSongWithAuth(context, mix.tracks.first, queueContext: mix.tracks);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Play', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final ok = await controller.saveRecommendationMix(mix);
                        if (context.mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Saved "${mix.name}" to cloud!'), backgroundColor: AppColors.primaryRed),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24, width: 0.6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark_border, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text('Save', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    // Find live playlist instance from controller
    final livePlaylist = controller.userPlaylists.firstWhere(
      (p) => p.id == playlist.id,
      orElse: () => playlist,
    );
    final tracks = livePlaylist.tracks;

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
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Delete Playlist', style: TextStyle(color: Colors.white)),
                  content: Text('Delete "${livePlaylist.name}"?', style: const TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
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
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                livePlaylist.coverUrl,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              livePlaylist.name,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '${tracks.length} tracks · Cloud Synced',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          if (tracks.isNotEmpty)
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  controller.playSongWithAuth(context, tracks.first, queueContext: tracks);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('PLAY ALL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          const SizedBox(height: 24),

          if (tracks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No tracks in this playlist yet.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ),
            )
          else
            ...tracks.map((song) => SongTile(
                  song: song,
                  isPlaying: controller.player.currentSong?.id == song.id && controller.player.isPlaying,
                  onTap: () => controller.playSongWithAuth(context, song, queueContext: tracks),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white38, size: 20),
                    onPressed: () => controller.removeSongFromPlaylist(livePlaylist.id, song.id),
                  ),
                )),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
