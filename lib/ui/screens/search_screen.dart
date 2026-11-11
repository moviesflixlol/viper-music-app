import '../components/music_artwork.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../state/music_controller.dart';
import '../components/song_tile.dart';
import '../components/add_to_playlist_sheet.dart';

class SearchCategory {
  final String title;
  final Color color;
  final String query;
  final String imageUrl;

  const SearchCategory({
    required this.title,
    required this.color,
    required this.query,
    required this.imageUrl,
  });
}

class SearchScreen extends StatefulWidget {
  final MusicController controller;

  const SearchScreen({super.key, required this.controller});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchFieldController = TextEditingController();

  static const List<SearchCategory> _browseCategories = [
    SearchCategory(
      title: 'Music',
      color: Color(0xFFE91E63),
      query: 'top songs',
      imageUrl: 'https://i.scdn.co/image/ab67706f00000002b8d00938f38634812a321cfc',
    ),
    SearchCategory(
      title: 'Podcasts',
      color: Color(0xFF00796B),
      query: 'trending podcasts english hindi',
      imageUrl: 'https://i.scdn.co/image/ab6765630000ba8aa2e2fb4209930773d328dd4c',
    ),
    SearchCategory(
      title: 'Bollywood',
      color: Color(0xFFC2185B),
      query: 'bollywood hits',
      imageUrl: 'https://i.scdn.co/image/ab67706f0000000201dc9ebc44122d256cd1b5b2',
    ),
    SearchCategory(
      title: 'Home of I-Pop',
      color: Color(0xFF1E3A8A),
      query: 'indian pop',
      imageUrl: 'https://i.scdn.co/image/ab67706f000000021c5756df6ad4720973a11681',
    ),
    SearchCategory(
      title: 'Punjabi Hits',
      color: Color(0xFFE65100),
      query: 'punjabi hits',
      imageUrl: 'https://i.scdn.co/image/ab67706f0000000234e4026ceb61c56598c114f6',
    ),
    SearchCategory(
      title: 'Made For You',
      color: Color(0xFF7E57C2),
      query: 'viral hits',
      imageUrl: 'https://i.scdn.co/image/ab67706f000000025f17101683935391e4dbfb3b',
    ),
    SearchCategory(
      title: 'Hip-Hop',
      color: Color(0xFF5D4037),
      query: 'hip hop essentials',
      imageUrl: 'https://i.ytimg.com/vi/H58vbez_m4E/hqdefault.jpg',
    ),
    SearchCategory(
      title: 'Acoustic Chill',
      color: Color(0xFF455A64),
      query: 'acoustic chill',
      imageUrl: 'https://i.ytimg.com/vi/2Vv-BfVoq4g/hqdefault.jpg',
    ),
  ];

  @override
  void dispose() {
    _searchFieldController.dispose();
    super.dispose();
  }

  void _executeSearch(String query) {
    _searchFieldController.text = query;
    widget.controller.search(query);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar matching Screenshot 1 (Avatar + Search Title + Camera)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => controller.setTab(3),
                    child: Image.asset(
                      'assets/images/header_logo.png',
                      height: 34,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text(
                        'M',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 24),
                ],
              ),
            ),

            // White Spotify-Style Search Input Bar matching Screenshot 1
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchFieldController,
                  style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (query) => controller.search(query),
                  decoration: InputDecoration(
                    hintText: 'What do you want to listen to?',
                    hintStyle: const TextStyle(color: Color(0xFF757575), fontSize: 14, fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.black87, size: 24),
                    suffixIcon: _searchFieldController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.black54, size: 20),
                            onPressed: () {
                              _searchFieldController.clear();
                              controller.search('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content: Results OR Browse All Colorful Cards matching Screenshot 1
            Expanded(
              child: controller.isSearching
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : controller.searchResults.isNotEmpty
                      ? ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: controller.searchResults.length + 1,
                          itemBuilder: (context, index) {
                            if (index == controller.searchResults.length) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
                                child: Center(
                                  child: controller.isLoadingMoreSearch
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(color: AppColors.primaryRed),
                                        )
                                      : OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(color: AppColors.primaryRed, width: 1.5),
                                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                          ),
                                          icon: const Icon(Icons.add_rounded, color: AppColors.primaryRed),
                                          label: const Text(
                                            'LOAD MORE RESULTS',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.2,
                                              fontSize: 13,
                                            ),
                                          ),
                                          onPressed: controller.loadMoreSearch,
                                        ),
                                ),
                              );
                            }

                            final song = controller.searchResults[index];
                            final isCurrent = controller.player.currentSong?.id == song.id;
                            return SongTile(
                              song: song,
                              isPlaying: isCurrent && controller.player.isPlaying,
                              isCurrentTrack: isCurrent,
                              isDownloaded: controller.downloads.isDownloaded(song.id),
                              isDownloading: controller.downloads.isDownloading(song.id),
                              downloadProgress: controller.downloads.getDownloadProgress(song.id),
                              onTap: () {
                                controller.playSong(song, queueContext: controller.searchResults);
                              },
                              onDownload: () {
                                controller.downloads.downloadSong(song);
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.playlist_add, color: Colors.white54, size: 22),
                                onPressed: () => AddToPlaylistSheet.show(context, controller, song),
                              ),
                            );
                          },
                        )
                      : _buildBrowseGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseGrid() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        const Text(
          'Browse all',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
          ),
          itemCount: _browseCategories.length,
          itemBuilder: (context, index) {
            final cat = _browseCategories[index];
            return GestureDetector(
              onTap: () => _executeSearch(cat.query),
              child: Container(
                decoration: BoxDecoration(
                  color: cat.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Title
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 48,
                      child: Text(
                        cat.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),

                    // Tilted Artwork Image in bottom right corner (exact Spotify style)
                    Positioned(
                      bottom: -8,
                      right: -12,
                      child: Transform.rotate(
                        angle: 0.45,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(-2, 2),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: MusicArtwork(
                            cat.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.black26),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
