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
  bool _isLoadingMoreFeed = false;
  bool _isBackendConnected = false;
  int _feedPage = 0;

  // Search state
  List<Song> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingMoreSearch = false;
  String _currentQuery = '';
  int _searchPage = 0;

  static const List<String> _feedQueries = [
    'global top hits',
    'viral pop 2026',
    'hip hop essentials',
    'electronic dance workout',
    'acoustic chill vibes',
    'rock legends',
    'rnb slow jams',
  ];

  MusicController({required this.apiService}) {
    player = AudioPlayerService(apiService: apiService);
    downloads = DownloadService(apiService: apiService);

    player.addListener(notifyListeners);
    downloads.addListener(notifyListeners);

    // Seed instant curated tracks so UI is never blank
    _trendingTracks = _defaultTrendingTracks;
    _feedRecommendations = _defaultPicks;

    loadInitialFeed();
  }

  int get selectedTabIndex => _selectedTabIndex;
  List<Song> get feedRecommendations => _feedRecommendations;
  List<Song> get trendingTracks => _trendingTracks;
  bool get isFeedLoading => _isFeedLoading;
  bool get isLoadingMoreFeed => _isLoadingMoreFeed;
  bool get isBackendConnected => _isBackendConnected;

  List<Song> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  bool get isLoadingMoreSearch => _isLoadingMoreSearch;
  String get currentQuery => _currentQuery;

  void setTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  Future<void> loadInitialFeed() async {
    _isFeedLoading = true;
    _feedPage = 0;
    notifyListeners();

    try {
      // Parallel queries to NextViper AWS backend with fast response
      final results = await Future.wait([
        apiService.search('trending music').catchError((_) => <Song>[]),
        apiService.search('top hits billboard').catchError((_) => <Song>[]),
        apiService.checkHealth().catchError((_) => false),
      ]);

      final trending = results[0] as List<Song>;
      final topPicks = results[1] as List<Song>;
      _isBackendConnected = results[2] as bool;

      if (trending.isNotEmpty) {
        _trendingTracks = trending.take(12).toList();
      }
      if (topPicks.isNotEmpty) {
        _feedRecommendations = topPicks.take(20).toList();
      }
    } catch (_) {}

    _isFeedLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreFeed() async {
    if (_isLoadingMoreFeed) return;
    _isLoadingMoreFeed = true;
    notifyListeners();

    try {
      final query = _feedQueries[_feedPage % _feedQueries.length];
      _feedPage++;

      final moreSongs = await apiService.search(query);
      if (moreSongs.isNotEmpty) {
        final existingIds = _feedRecommendations.map((s) => s.id).toSet();
        final newUnique = moreSongs.where((s) => !existingIds.contains(s.id)).toList();

        if (newUnique.isNotEmpty) {
          _feedRecommendations = [..._feedRecommendations, ...newUnique];
        }
      }
    } catch (_) {}

    _isLoadingMoreFeed = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    _currentQuery = query;
    _searchPage = 0;
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

  Future<void> loadMoreSearch() async {
    if (_isLoadingMoreSearch || _currentQuery.trim().isEmpty) return;
    _isLoadingMoreSearch = true;
    notifyListeners();

    try {
      _searchPage++;
      final suffixes = ['official audio', 'remix', 'live', 'album'];
      final suffix = suffixes[_searchPage % suffixes.length];
      final moreQuery = '$_currentQuery $suffix';

      final moreResults = await apiService.search(moreQuery);
      if (moreResults.isNotEmpty) {
        final existingIds = _searchResults.map((s) => s.id).toSet();
        final newUnique = moreResults.where((s) => !existingIds.contains(s.id)).toList();

        if (newUnique.isNotEmpty) {
          _searchResults = [..._searchResults, ...newUnique];
        }
      }
    } catch (_) {}

    _isLoadingMoreSearch = false;
    notifyListeners();
  }

  void updateBaseUrl(String newUrl) {
    apiService.baseUrl = newUrl;
    loadInitialFeed();
  }

  @override
  void dispose() {
    player.removeListener(notifyListeners);
    downloads.removeListener(notifyListeners);
    player.dispose();
    downloads.dispose();
    super.dispose();
  }

  // --- Instant Fallback Tracks (eliminates loading timeouts & blank screens) ---
  static const List<Song> _defaultTrendingTracks = [
    Song(
      id: 'rqCP4Invnrs',
      title: 'Fun (feat. Tove Lo)',
      artist: 'Coldplay',
      thumbnailUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400',
      duration: '4:27',
    ),
    Song(
      id: 'DG8o24dFq7w',
      title: 'BIRDS OF A FEATHER',
      artist: 'Billie Eilish',
      thumbnailUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400',
      duration: '3:30',
    ),
    Song(
      id: '4NRXx6U8ABQ',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      thumbnailUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
      duration: '3:20',
    ),
    Song(
      id: 'kJQP7kiw5Fk',
      title: 'Despacito',
      artist: 'Luis Fonsi ft. Daddy Yankee',
      thumbnailUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
      duration: '4:42',
    ),
    Song(
      id: 'JGwWNGJdvx8',
      title: 'Shape of You',
      artist: 'Ed Sheeran',
      thumbnailUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=400',
      duration: '3:53',
    ),
  ];

  static const List<Song> _defaultPicks = [
    Song(
      id: '0VwhorQ51gE',
      title: 'Starboy',
      artist: 'The Weeknd ft. Daft Punk',
      thumbnailUrl: 'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=400',
      duration: '3:50',
    ),
    Song(
      id: '3tmd-ClpJxA',
      title: 'Look What You Made Me Do',
      artist: 'Taylor Swift',
      thumbnailUrl: 'https://images.unsplash.com/photo-1487180144351-b8472da7d491?w=400',
      duration: '4:15',
    ),
    Song(
      id: 'fJ9rUzIMcZQ',
      title: 'Bohemian Rhapsody',
      artist: 'Queen',
      thumbnailUrl: 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400',
      duration: '5:55',
    ),
    Song(
      id: 'hT_nvWreIhg',
      title: 'Counting Stars',
      artist: 'OneRepublic',
      thumbnailUrl: 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=400',
      duration: '4:17',
    ),
  ];
}
