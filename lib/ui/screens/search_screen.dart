import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../state/music_controller.dart';
import '../components/song_tile.dart';

class SearchScreen extends StatefulWidget {
  final MusicController controller;

  const SearchScreen({super.key, required this.controller});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchFieldController = TextEditingController();

  final List<String> _quickTags = [
    'Coldplay',
    'Ed Sheeran',
    'The Weeknd',
    'Billie Eilish',
    'Lofi Hip Hop',
    'Synthwave',
    'Rock Classics',
    'Deep House',
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
            // Search Input Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: TextField(
                  controller: _searchFieldController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (query) => controller.search(query),
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists, albums...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                    suffixIcon: _searchFieldController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                            onPressed: () {
                              _searchFieldController.clear();
                              controller.search('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Quick Tags / Chips Carousel
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickTags.length,
                itemBuilder: (context, index) {
                  final tag = _quickTags[index];
                  final isSelected = controller.currentQuery.toLowerCase() == tag.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryRed,
                      backgroundColor: AppColors.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryRed : AppColors.border,
                        ),
                      ),
                      onSelected: (_) => _executeSearch(tag),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Search Results or Empty State
            Expanded(
              child: controller.isSearching
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : controller.searchResults.isNotEmpty
                      ? ListView.builder(
                          itemCount: controller.searchResults.length + 1,
                          itemBuilder: (context, index) {
                            // Bottom "Load More Results" item
                            if (index == controller.searchResults.length) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
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
                              isPlaying: controller.player.isPlaying,
                              isCurrentTrack: isCurrent,
                              isDownloaded: controller.downloads.isDownloaded(song.id),
                              isDownloading: controller.downloads.isDownloading(song.id),
                              downloadProgress: controller.downloads.getDownloadProgress(song.id),
                              onTap: () {
                                controller.player.playSong(song, queueContext: controller.searchResults);
                              },
                              onDownload: () {
                                controller.downloads.downloadSong(song);
                              },
                            );
                          },
                        )
                      : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.headphones_rounded,
            size: 64,
            color: AppColors.surfaceHighlight,
          ),
          const SizedBox(height: 16),
          const Text(
            'Explore Over 100 Million Songs',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Powered by NextViper backend streaming engine',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
