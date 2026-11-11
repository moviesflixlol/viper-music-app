import 'playlist_artwork.dart';
import 'music_artwork.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/song.dart';
import '../../state/music_controller.dart';

class AddToPlaylistSheet extends StatelessWidget {
  final MusicController controller;
  final Song song;

  const AddToPlaylistSheet({
    super.key,
    required this.controller,
    required this.song,
  });

  static Future<void> show(BuildContext context, MusicController controller, Song song) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AddToPlaylistSheet(controller: controller, song: song),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Give your playlist a name', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'My Playlist #1',
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
                final created = await controller.createPlaylist(name);
                if (created && controller.userPlaylists.isNotEmpty) {
                  final newPl = controller.userPlaylists.first;
                  await controller.addSongToPlaylist(newPl.id, song);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Created "$name" and added track!'),
                        backgroundColor: AppColors.primaryRed,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validPlaylists = controller.userPlaylists
        .where((p) => p.name.trim().isNotEmpty && p.name.toLowerCase() != 'untitled playlist')
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: MusicArtwork(
                  song.thumbnailUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.white12,
                    child: const Icon(Icons.music_note, color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Action: New Playlist
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryRed, width: 0.8),
              ),
              child: const Icon(Icons.add, color: AppColors.primaryRed, size: 26),
            ),
            title: const Text('New playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: const Text('Create and add this song', style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => _showCreateDialog(context),
          ),
          const Divider(color: AppColors.border, height: 20),

          // Existing Playlists
          if (validPlaylists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No playlists yet. Tap "New playlist" above to create one!',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: validPlaylists.length,
                itemBuilder: (ctx, i) {
                  final pl = validPlaylists[i];
                  final hasTrack = pl.tracks.any((t) => t.id == song.id);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: PlaylistArtwork(playlist: pl, size: 44),
                    ),
                    title: Text(pl.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text('${pl.tracks.length} tracks', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: hasTrack
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryRed, size: 24)
                        : const Icon(Icons.add_circle_outline_rounded, color: Colors.white54, size: 24),
                    onTap: () async {
                      if (!hasTrack) {
                        await controller.addSongToPlaylist(pl.id, song);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to "${pl.name}"'),
                              backgroundColor: AppColors.primaryRed,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
