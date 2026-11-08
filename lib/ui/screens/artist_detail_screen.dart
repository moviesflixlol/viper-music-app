import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/song.dart';
import '../../state/music_controller.dart';
import '../components/song_tile.dart';
import '../components/add_to_playlist_sheet.dart';

class ArtistDetailScreen extends StatefulWidget {
  final ArtistInfo artist;
  final MusicController controller;

  const ArtistDetailScreen({
    super.key,
    required this.artist,
    required this.controller,
  });

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  List<Song> _tracks = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArtistTracks();
  }

  Future<void> _loadArtistTracks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = '${widget.artist.name} top songs';
      final results = await widget.controller.apiService.search(query);
      if (mounted) {
        setState(() {
          _tracks = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load tracks: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // 1. SliverAppBar with Artist Hero Banner
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.artist.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.artist.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.person, color: Colors.white30, size: 72),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          AppColors.background.withOpacity(0.9),
                          AppColors.background,
                        ],
                        stops: const [0.0, 0.4, 0.85, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 46,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified, color: Colors.blueAccent, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Verified Artist',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.artist.genre} • Monthly Listeners',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Action Buttons (Play All, Follow, Shuffle)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _tracks.isEmpty
                        ? null
                        : () {
                            controller.playSong(_tracks.first, queueContext: _tracks);
                          },
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text('Play All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _isFollowing = !_isFollowing);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isFollowing
                                ? 'Following ${widget.artist.name}'
                                : 'Unfollowed ${widget.artist.name}',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: _isFollowing ? AppColors.primaryRed : Colors.white54,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    child: Text(_isFollowing ? 'Following' : 'Follow'),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.shuffle, color: Colors.white70),
                    onPressed: _tracks.isEmpty
                        ? null
                        : () {
                            final shuffled = List<Song>.from(_tracks)..shuffle();
                            controller.playSong(shuffled.first, queueContext: shuffled);
                          },
                  ),
                ],
              ),
            ),
          ),

          // 3. Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: const Text(
                'Popular Releases',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          // 4. Track List
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!, style: const TextStyle(color: Colors.white60)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadArtistTracks,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_tracks.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('No tracks found for this artist', style: TextStyle(color: Colors.white60)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _tracks[index];
                  final isCurrent = controller.player.currentSong?.id == song.id;

                  return SongTile(
                    song: song,
                    isPlaying: isCurrent && controller.player.isPlaying,
                    isCurrentTrack: isCurrent,
                    onTap: () => controller.playSong(song, queueContext: _tracks),
                    trailing: IconButton(
                      icon: const Icon(Icons.playlist_add, color: Colors.white60, size: 22),
                      onPressed: () => AddToPlaylistSheet.show(context, controller, song),
                    ),
                  );
                },
                childCount: _tracks.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
