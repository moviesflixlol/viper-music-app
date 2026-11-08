import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';
import '../../state/music_controller.dart';
import '../components/add_to_playlist_sheet.dart';

class FullPlayerScreen extends StatelessWidget {
  final MusicController controller;

  const FullPlayerScreen({super.key, required this.controller});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = controller.player;
    final song = player.currentSong;

    if (song == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('No song playing', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final isDownloaded = controller.downloads.isDownloaded(song.id);
    final isDownloading = controller.downloads.isDownloading(song.id);
    final pos = player.position;
    final dur = player.duration;
    final maxDur = dur.inMilliseconds.toDouble();
    final currentPos = pos.inMilliseconds.toDouble().clamp(0.0, maxDur > 0 ? maxDur : 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Column(
                    children: [
                      const Text(
                        'PLAYING FROM VIPER STREAM',
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.queue_music_rounded, color: Colors.white, size: 24),
                    onPressed: () => _showQueueBottomSheet(context),
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // Album Art with Red Ambient Glow
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient Red Glow
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withOpacity(0.35),
                            blurRadius: 80,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                    ),

                    // Main Cover Art
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: song.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              song.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _fallbackCover(),
                            )
                          : _fallbackCover(),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Title, Artist & Download Action
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.playlist_add_rounded, color: Colors.white, size: 26),
                    onPressed: () => AddToPlaylistSheet.show(context, controller, song),
                  ),
                  IconButton(
                    icon: isDownloading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                            ),
                          )
                        : Icon(
                            isDownloaded ? Icons.check_circle_rounded : Icons.file_download_outlined,
                            color: isDownloaded ? AppColors.primaryRed : Colors.white,
                            size: 26,
                          ),
                    onPressed: () => controller.downloads.downloadSong(song),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Scrubber Bar
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.5,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                      activeTrackColor: AppColors.primaryRed,
                      inactiveTrackColor: AppColors.surfaceHighlight,
                      thumbColor: AppColors.primaryRed,
                      overlayColor: AppColors.primaryRed.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: currentPos,
                      min: 0.0,
                      max: maxDur > 0 ? maxDur : 1.0,
                      onChanged: (val) {
                        player.seek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(pos), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        Text(_formatDuration(dur), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Controls: Shuffle, Previous, Play/Pause, Next, Repeat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Shuffle
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: player.isShuffle ? AppColors.primaryRed : AppColors.textMuted,
                      size: 24,
                    ),
                    onPressed: player.toggleShuffle,
                  ),

                  // Previous
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                    onPressed: player.skipPrevious,
                  ),

                  // Play/Pause Big Red Button
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryRed,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryRed.withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: player.state == PlaybackState.loading
                          ? const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                              onPressed: player.togglePlayPause,
                            ),
                    ),
                  ),

                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                    onPressed: controller.skipNextWithTelemetry,
                  ),

                  // Repeat
                  IconButton(
                    icon: Icon(
                      player.repeatMode == PlayerRepeatMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      color: player.repeatMode != PlayerRepeatMode.off ? AppColors.primaryRed : AppColors.textMuted,
                      size: 24,
                    ),
                    onPressed: player.toggleRepeat,
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showQueueBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final queue = controller.player.queue;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Up Next Queue',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final item = queue[index];
                    final isCurrent = index == controller.player.currentIndex;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: item.thumbnailUrl.isNotEmpty
                            ? Image.network(item.thumbnailUrl, width: 44, height: 44, fit: BoxFit.cover)
                            : Container(width: 44, height: 44, color: AppColors.surfaceHighlight),
                      ),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        style: TextStyle(
                          color: isCurrent ? AppColors.primaryRed : AppColors.textPrimary,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(item.artist, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: isCurrent
                          ? const Icon(Icons.equalizer_rounded, color: AppColors.primaryRed)
                          : null,
                      onTap: () {
                        controller.player.playSong(item, queueContext: queue);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fallbackCover() {
    return Container(
      color: AppColors.surfaceHighlight,
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: AppColors.primaryRed, size: 72),
      ),
    );
  }
}
