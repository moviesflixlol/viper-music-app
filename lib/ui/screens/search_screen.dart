import '../components/music_artwork.dart';
import 'artist_detail_screen.dart';
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
      imageUrl: 'assets/search_cards/music.png',
    ),
    SearchCategory(
      title: 'Podcasts',
      color: Color(0xFF00796B),
      query: 'trending podcasts english hindi',
      imageUrl: 'assets/search_cards/podcasts.png',
    ),
    SearchCategory(
      title: 'Bollywood',
      color: Color(0xFFC2185B),
      query: 'bollywood hits',
      imageUrl: 'assets/search_cards/bollywood.png',
    ),
    SearchCategory(
      title: 'Home of I-Pop',
      color: Color(0xFF1E3A8A),
      query: 'indian pop',
      imageUrl: 'assets/search_cards/home-of-i-pop.png',
    ),
    SearchCategory(
      title: 'Punjabi Hits',
      color: Color(0xFFE65100),
      query: 'punjabi hits',
      imageUrl: 'assets/search_cards/punjabi-hits.png',
    ),
    SearchCategory(
      title: 'Made For You',
      color: Color(0xFF7E57C2),
      query: 'viral hits',
      imageUrl: 'assets/search_cards/made-for-you.png',
    ),
    SearchCategory(
      title: 'Hip-Hop',
      color: Color(0xFF5D4037),
      query: 'hip hop essentials',
      imageUrl: 'assets/search_cards/hip-hop.png',
    ),
    SearchCategory(
      title: 'Acoustic Chill',
      color: Color(0xFF455A64),
      query: 'acoustic chill',
      imageUrl: 'assets/search_cards/acoustic-chill.png',
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
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22),
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
                  const Icon(Icons.camera_alt_outlined,
                      color: Colors.white70, size: 24),
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
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (query) => controller.search(query),
                  decoration: InputDecoration(
                    hintText: 'Search songs and artists',
                    hintStyle: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Colors.black87, size: 24),
                    suffixIcon: _searchFieldController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: Colors.black54, size: 20),
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
                      child: CircularProgressIndicator(
                          color: AppColors.primaryRed),
                    )
                  : controller.currentQuery.isNotEmpty
                      ? ListView(
                          padding: const EdgeInsets.only(bottom: 120),
                          children: [
                            if (controller.searchError != null)
                              Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(children: [
                                    Text(controller.searchError!,
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                    TextButton(
                                        onPressed: () => controller
                                            .search(controller.currentQuery),
                                        child: const Text('Retry'))
                                  ])),
                            if (controller.searchArtists.isNotEmpty) ...[
                              const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Artists',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold))),
                              ...controller.searchArtists.map((artist) =>
                                  ListTile(
                                    leading: ClipOval(
                                        child: MusicArtwork(artist.imageUrl,
                                            width: 56, height: 56)),
                                    title: Text(artist.name,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    subtitle: const Text('Artist',
                                        style:
                                            TextStyle(color: Colors.white54)),
                                    trailing: const Icon(Icons.chevron_right,
                                        color: Colors.white54),
                                    onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => ArtistDetailScreen(
                                                controller: controller,
                                                artist: ArtistInfo(
                                                    id: artist.id,
                                                    name: artist.name,
                                                    imageUrl: artist.imageUrl,
                                                    genre: artist.genre)))),
                                  )),
                            ],
                            if (controller.searchResults.isNotEmpty)
                              const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Songs',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold))),
                            ...controller.searchResults.map((song) => SongTile(
                                song: song,
                                isPlaying: controller.player.currentSong?.id ==
                                        song.id &&
                                    controller.player.isPlaying,
                                isCurrentTrack:
                                    controller.player.currentSong?.id ==
                                        song.id,
                                onTap: () => controller.playSong(song,
                                    queueContext: controller.searchResults),
                                trailing: IconButton(
                                    icon: const Icon(Icons.playlist_add,
                                        color: Colors.white54),
                                    onPressed: () => AddToPlaylistSheet.show(
                                        context, controller, song)))),
                            if (controller.searchError == null &&
                                controller.searchResults.isEmpty &&
                                controller.searchArtists.isEmpty)
                              const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('No songs or artists found.',
                                      style: TextStyle(color: Colors.white70))),
                          ],
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
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
            childAspectRatio: 1.0,
          ),
          itemCount: _browseCategories.length,
          itemBuilder: (context, index) {
            final cat = _browseCategories[index];
            return Semantics(button: true, label: cat.title, child: InkWell(
              onTap: () => _executeSearch(cat.query),
              borderRadius: BorderRadius.circular(12),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Stack(fit: StackFit.expand, children: [
                Image.asset(cat.imageUrl, fit: BoxFit.cover),
                const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.center, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87]))),
                Positioned(left: 12, right: 10, bottom: 12, child: Text(cat.title,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800))),
              ])),
            ));
          },
        ),
      ],
    );
  }
}
