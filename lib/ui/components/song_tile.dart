import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/song.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final bool isCurrentTrack;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const SongTile({
    super.key,
    required this.song,
    this.isPlaying = false,
    this.isCurrentTrack = false,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primaryRed.withOpacity(0.12),
        highlightColor: AppColors.surfaceHighlight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Artwork Thumbnail
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.surfaceHighlight,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: song.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            song.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.music_note_rounded,
                              color: AppColors.textMuted,
                            ),
                          )
                        : const Icon(Icons.music_note_rounded, color: AppColors.textMuted),
                  ),

                  // Active Playback Overlay
                  if (isCurrentTrack)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isPlaying ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                        color: AppColors.primaryRed,
                        size: 26,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Title & Artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrentTrack ? AppColors.primaryRed : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: isCurrentTrack ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist.isNotEmpty ? song.artist : 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Duration (if available)
              if (song.duration.isNotEmpty) ...[
                Text(
                  song.duration,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Download Status Button
              IconButton(
                icon: isDownloading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: downloadProgress > 0 ? downloadProgress : null,
                          strokeWidth: 2.2,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                        ),
                      )
                    : Icon(
                        isDownloaded ? Icons.check_circle_rounded : Icons.arrow_downward_rounded,
                        color: isDownloaded ? AppColors.primaryRed : AppColors.textMuted,
                        size: 22,
                      ),
                onPressed: onDownload,
                tooltip: isDownloaded ? 'Downloaded' : 'Download for offline playback',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
