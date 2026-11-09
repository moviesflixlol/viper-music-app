import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';
import '../../state/music_controller.dart';
import '../components/add_to_playlist_sheet.dart';

class FullPlayerScreen extends StatefulWidget {
  final MusicController controller;
  const FullPlayerScreen({super.key, required this.controller});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen>
    with SingleTickerProviderStateMixin {
  // 0.0 = hero art fully visible, 1.0 = scrolled to queue
  late final DraggableScrollableController _draggableCtrl;
  late final PageController _artPageCtrl;

  MusicController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _draggableCtrl = DraggableScrollableController();
    _artPageCtrl = PageController();
    c.player.addListener(_onPlayerChange);
  }

  void _onPlayerChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    c.player.removeListener(_onPlayerChange);
    _draggableCtrl.dispose();
    _artPageCtrl.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = c.player;
    final song = player.currentSong;
    if (song == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('No song playing', style: TextStyle(color: Colors.white54))),
      );
    }

    final pos = player.position;
    final dur = player.duration;
    final maxMs = dur.inMilliseconds.toDouble();
    final curMs = pos.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 1.0);
    final queue = player.queue;
    final curIdx = player.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Background blurred album art tint ──
          Positioned.fill(
            child: _BlurredBg(thumbnailUrl: song.thumbnailUrl),
          ),

          // ── Main column: header + hero art + controls ──
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('NOW PLAYING',
                                style: TextStyle(
                                    color: AppColors.primaryRed,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5)),
                            const SizedBox(height: 2),
                            Text(song.artist,
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
                        onPressed: () => AddToPlaylistSheet.show(context, c, song),
                      ),
                    ],
                  ),
                ),

                // ── Hero art — swipeable between queue songs ──
                Expanded(
                  child: GestureDetector(
                    // Swipe down closes player
                    onVerticalDragEnd: (d) {
                      if (d.primaryVelocity != null && d.primaryVelocity! > 400) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: queue.isNotEmpty
                          ? PageView.builder(
                              controller: _artPageCtrl,
                              itemCount: queue.length,
                              onPageChanged: (i) {
                                if (i != curIdx) {
                                  c.player.playSong(queue[i], queueContext: queue);
                                }
                              },
                              itemBuilder: (_, i) {
                                final q = queue[i];
                                return _ArtCard(thumbnailUrl: q.thumbnailUrl);
                              },
                            )
                          : _ArtCard(thumbnailUrl: song.thumbnailUrl),
                    ),
                  ),
                ),

                // ── Song title + actions ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white60, fontSize: 15)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.playlist_add_rounded, color: Colors.white70, size: 26),
                        onPressed: () => AddToPlaylistSheet.show(context, c, song),
                      ),
                      _DownloadButton(controller: c, song: song),
                    ],
                  ),
                ),

                // ── Scrubber ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: AppColors.primaryRed,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: AppColors.primaryRed,
                          overlayColor: AppColors.primaryRed.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: curMs,
                          min: 0,
                          max: maxMs > 0 ? maxMs : 1,
                          onChanged: (v) => player.seek(Duration(milliseconds: v.toInt())),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(pos),
                                style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            Text(_fmt(dur),
                                style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Playback controls ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.shuffle_rounded,
                            color: player.isShuffle ? AppColors.primaryRed : Colors.white38, size: 24),
                        onPressed: player.toggleShuffle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                        onPressed: player.skipPrevious,
                      ),
                      _PlayPauseButton(player: player),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                        onPressed: c.skipNextWithTelemetry,
                      ),
                      IconButton(
                        icon: Icon(
                          player.repeatMode == PlayerRepeatMode.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: player.repeatMode != PlayerRepeatMode.off
                              ? AppColors.primaryRed
                              : Colors.white38,
                          size: 24,
                        ),
                        onPressed: player.toggleRepeat,
                      ),
                    ],
                  ),
                ),

                // ── Up Next hint — tap to expand queue ──
                GestureDetector(
                  onTap: () => _showQueueSheet(context, queue, curIdx),
                  onVerticalDragEnd: (d) {
                    if (d.primaryVelocity != null && d.primaryVelocity! < -200) {
                      _showQueueSheet(context, queue, curIdx);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('UP NEXT',
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2)),
                        Row(
                          children: [
                            if (queue.length > curIdx + 1) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  queue[curIdx + 1].thumbnailUrl,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 32,
                                    height: 32,
                                    color: AppColors.surface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 120,
                                child: Text(
                                  queue[curIdx + 1].title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white38, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQueueSheet(BuildContext context, List<Song> queue, int curIdx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Up Next',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: queue.length,
                itemBuilder: (context, i) {
                  final item = queue[i];
                  final isCur = i == curIdx;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: item.thumbnailUrl.isNotEmpty
                              ? Image.network(item.thumbnailUrl, width: 46, height: 46, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(width: 46, height: 46, color: AppColors.surface))
                              : Container(width: 46, height: 46, color: AppColors.surface),
                        ),
                        if (isCur)
                          const Icon(Icons.equalizer_rounded, color: AppColors.primaryRed, size: 20),
                      ],
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      style: TextStyle(
                        color: isCur ? AppColors.primaryRed : Colors.white,
                        fontWeight: isCur ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(item.artist,
                        style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    trailing: isCur
                        ? const Icon(Icons.volume_up_rounded, color: AppColors.primaryRed, size: 18)
                        : null,
                    onTap: () {
                      c.player.playSong(item, queueContext: queue);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────

class _ArtCard extends StatelessWidget {
  final String thumbnailUrl;
  const _ArtCard({required this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Red ambient glow
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.30),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          // Album art
          Container(
            width: 285,
            height: 285,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.75), blurRadius: 30, offset: const Offset(0, 16)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: thumbnailUrl.isNotEmpty
                ? Image.network(thumbnailUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback())
                : _fallback(),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.surfaceHighlight,
        child: const Center(child: Icon(Icons.music_note_rounded, color: AppColors.primaryRed, size: 72)),
      );
}

class _BlurredBg extends StatelessWidget {
  final String thumbnailUrl;
  const _BlurredBg({required this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbnailUrl.isNotEmpty)
          Image.network(thumbnailUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox()),
        Container(color: Colors.black.withOpacity(0.82)),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final AudioPlayerService player;
  const _PlayPauseButton({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryRed,
        boxShadow: [
          BoxShadow(color: AppColors.primaryRed.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 4))
        ],
      ),
      child: Center(
        child: player.state == PlaybackState.loading
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : IconButton(
                icon: Icon(
                  player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
                onPressed: player.togglePlayPause,
              ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final MusicController controller;
  final Song song;
  const _DownloadButton({required this.controller, required this.song});

  @override
  Widget build(BuildContext context) {
    final isDownloaded = controller.downloads.isDownloaded(song.id);
    final isDownloading = controller.downloads.isDownloading(song.id);
    return IconButton(
      icon: isDownloading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryRed))
          : Icon(
              isDownloaded ? Icons.check_circle_rounded : Icons.file_download_outlined,
              color: isDownloaded ? AppColors.primaryRed : Colors.white70,
              size: 26,
            ),
      onPressed: () => controller.downloads.downloadSong(song),
    );
  }
}
