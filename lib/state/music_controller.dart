import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';

class MusicController extends ChangeNotifier {
  final ApiService apiService;
  late final AudioPlayerService player;
  late final DownloadService downloads;

  int _selectedTabIndex = 0;
  List<Song> _feedRecommendations = [];
  List<Song> _trendingTracks = [];
  bool _isFeedLoading = false;

  // Search state
  List<Song> _searchResults = [];
  bool _isSearching = false;
  String _currentQuery = '';

  MusicController({required this.apiService}) {
    player = AudioPlayerService(apiService: apiService);
    downloads = DownloadService(apiService: apiService);

    player.addListener(notifyListeners);
    downloads.addListener(notifyListeners);

    loadInitialFeed();
  }

  int get selectedTabIndex => _selectedTabIndex;
  List<Song> get feedRecommendations => _feedRecommendations;
  List<Song> get trendingTracks => _trendingTracks;
  bool get isFeedLoading => _isFeedLoading;

  List<Song> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get currentQuery => _currentQuery;

  void setTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  Future<void> loadInitialFeed() async {
    _isFeedLoading = true;
    notifyListeners();

    try {
      // Fetch trending and popular tracks via NextViper backend
      final trending = await apiService.search('trending music 2026');
      final topPicks = await apiService.search('top hits billboard');

      _trendingTracks = trending.take(10).toList();
      _feedRecommendations = topPicks.take(15).toList();
    } catch (_) {}

    _isFeedLoading = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    _currentQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final results = await apiService.search(query);
    _searchResults = results;
    _isSearching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    player.removeListener(notifyListeners);
    downloads.removeListener(notifyListeners);
    player.dispose();
    downloads.dispose();
    super.dispose();
  }
}
