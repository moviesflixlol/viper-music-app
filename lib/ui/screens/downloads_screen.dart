import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../state/music_controller.dart';
import '../components/song_tile.dart';

class DownloadsScreen extends StatelessWidget {
  final MusicController controller;

  const DownloadsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final downloaded = controller.downloads.downloadedSongs;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OFFLINE MUSIC',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${downloaded.length} songs saved on device • Airplane Mode Ready',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Shuffle All Action
                  if (downloaded.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 20),
                        label: const Text(
                          'Shuffle All Downloads',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final shuffled = List.of(downloaded)..shuffle();
                          controller.playSong(shuffled.first, queueContext: shuffled);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),

            // Downloaded Track List
            Expanded(
              child: downloaded.isNotEmpty
                  ? ListView.builder(
                      itemCount: downloaded.length,
                      itemBuilder: (context, index) {
                        final song = downloaded[index];
                        final isCurrent = controller.player.currentSong?.id == song.id;
                        return Dismissible(
                          key: Key('download_${song.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: AppColors.redDark,
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            controller.downloads.removeDownload(song.id);
                          },
                          child: SongTile(
                            song: song,
                            isPlaying: controller.player.isPlaying,
                            isCurrentTrack: isCurrent,
                            isDownloaded: true,
                            onTap: () {
                              controller.playSong(song, queueContext: downloaded);
                            },
                            onDownload: () {
                              _confirmDelete(context, song.id, song.title);
                            },
                          ),
                        );
                      },
                    )
                  : _buildEmptyDownloads(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String songId, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remove Download', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "$title" from your offline storage?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () {
              controller.downloads.removeDownload(songId);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDownloads(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.file_download_outlined,
                color: AppColors.primaryRed,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Offline Downloads Yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the download icon on any song to save it for listening anywhere, even without Wi-Fi or cellular data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                controller.setTab(1); // switch to search tab
              },
              child: const Text(
                'Find Songs to Download',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
