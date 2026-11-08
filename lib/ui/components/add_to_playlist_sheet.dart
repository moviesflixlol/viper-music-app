import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/song.dart';
import '../../state/music_controller.dart';
import '../screens/auth_screen.dart';

class AddToPlaylistSheet extends StatelessWidget {
  final MusicController controller;
  final Song song;

  const AddToPlaylistSheet({
    super.key,
    required this.controller,
    required this.song,
  });

  static Future<void> show(BuildContext context, MusicController controller, Song song) async {
    if (!controller.authService.isLoggedIn) {
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (ctx) => AuthScreen(authService: controller.authService),
          fullscreenDialog: true,
        ),
      );
      if (loggedIn != true && !controller.authService.isLoggedIn) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to add songs to playlists.'),
              backgroundColor: Color(0xFFE50914),
            ),
          );
        }
        return;
      }
    }

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => AddToPlaylistSheet(controller: controller, song: song),
      );
    }
  }

  void _showCreateDialog(BuildContext context) {
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
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlists = controller.userPlaylists;

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
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  song.thumbnailUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 44,
                    color: Colors.white12,
                    child: const Icon(Icons.music_note, color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 20),

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
              child: const Icon(Icons.add, color: AppColors.primaryRed),
            ),
            title: const Text('New Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            subtitle: const Text('Create a new cloud playlist', style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => _showCreateDialog(context),
          ),
          const Divider(color: AppColors.border, height: 24),

          // Existing Playlists
          if (playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No playlists yet. Create your first one above!',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (ctx, i) {
                  final pl = playlists[i];
                  final hasTrack = pl.tracks.any((t) => t.id == song.id);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        pl.coverUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 44,
                          height: 44,
                          color: Colors.white12,
                          child: const Icon(Icons.queue_music, color: Colors.white54),
                        ),
                      ),
                    ),
                    title: Text(pl.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text('${pl.tracks.length} tracks', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: hasTrack
                        ? const Icon(Icons.check_circle, color: AppColors.primaryRed, size: 22)
                        : const Icon(Icons.add_circle_outline, color: Colors.white54, size: 22),
                    onTap: () async {
                      if (!hasTrack) {
                        await controller.addSongToPlaylist(pl.id, song);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to "${pl.name}"'),
                              backgroundColor: AppColors.primaryRed,
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
