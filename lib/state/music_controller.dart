import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/auth_service.dart';
import '../services/download_service.dart';
import '../ui/screens/auth_screen.dart';

class MusicController extends ChangeNotifier {
  final ApiService apiService;
  final AuthService authService;
  late final AudioPlayerService player;
  late final DownloadService downloads;

  int _selectedTabIndex = 0;
  String _selectedCategory = 'All Titles';
  Song? _featuredSong;
  List<Song> _feedRecommendations = [];
  List<Song> _trendingTracks = [];
  List<Playlist> _recommendedMixes = [];
  List<Playlist> _userPlaylists = [];

  bool _isFeedLoading = false;
  bool _isLoadingMoreFeed = false;
  bool _isPlaylistsLoading = false;
  bool _isBackendConnected = false;
  int _feedPage = 0;

  // Search state
  List<Song> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingMoreSearch = false;
  String _currentQuery = '';
  int _searchPage = 0;

  static const List<String> categories = [
    'All Titles',
    'Songs',
    'Playlists',
    'Mixes',
    'Trending',
    'Chill',
    'Workout',
  ];

  static const List<String> _feedQueries = [
    'global top hits',
    'viral pop 2026',
    'hip hop essentials',
    'electronic dance workout',
    'acoustic chill vibes',
    'rock legends',
    'rnb slow jams',
  ];

  MusicController({
    required this.apiService,
    required this.authService,
  }) {
    player = AudioPlayerService(apiService: apiService);
    downloads = DownloadService(apiService: apiService);

    player.addListener(notifyListeners);
    downloads.addListener(notifyListeners);
    authService.addListener(_onAuthChanged);

    // Initial default state
    _trendingTracks = _defaultTrendingTracks;
    _feedRecommendations = _defaultPicks;
    _featuredSong = _defaultTrendingTracks[0];

    loadInitialFeed();
    loadUserPlaylists();
  }

  void _onAuthChanged() {
    loadUserPlaylists();
    loadInitialFeed();
    notifyListeners();
  }

  int get selectedTabIndex => _selectedTabIndex;
  String get selectedCategory => _selectedCategory;
  Song? get featuredSong => _featuredSong;
  List<Song> get feedRecommendations => _feedRecommendations;
  List<Song> get trendingTracks => _trendingTracks;
  List<Playlist> get recommendedMixes => _recommendedMixes;
  List<Playlist> get userPlaylists => _userPlaylists;

  bool get isFeedLoading => _isFeedLoading;
  bool get isLoadingMoreFeed => _isLoadingMoreFeed;
  bool get isPlaylistsLoading => _isPlaylistsLoading;
  bool get isBackendConnected => _isBackendConnected;

  List<Song> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  bool get isLoadingMoreSearch => _isLoadingMoreSearch;
  String get currentQuery => _currentQuery;

  void setTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void setCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  /// Playback Guard: Requires user authentication before playing music
  Future<bool> playSongWithAuth(
    BuildContext context,
    Song song, {
    List<Song>? queueContext,
  }) async {
    if (!authService.isLoggedIn) {
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (ctx) => AuthScreen(authService: authService),
          fullscreenDialog: true,
        ),
      );

      if (loggedIn != true && !authService.isLoggedIn) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to stream high-fidelity music.'),
              backgroundColor: Color(0xFFE50914),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    }

    // User is authenticated, proceed to play
    await player.playSong(song, queueContext: queueContext);

    // Send recommendation telemetry signal to NextViper engine
    apiService.sendRecommendationEvent(
      trackId: song.id,
      eventType: 'play',
      artist: song.artist,
      genre: song.genre,
      token: authService.token,
    );

    return true;
  }

  /// Skip track with telemetry
  Future<void> skipNextWithTelemetry() async {
    final curSong = player.currentSong;
    final pos = player.position.inSeconds;
    final dur = player.duration.inSeconds;

    if (curSong != null) {
      apiService.sendRecommendationEvent(
        trackId: curSong.id,
        eventType: 'skip',
        duration: dur > 0 ? dur : 180,
        playedSeconds: pos,
        artist: curSong.artist,
        genre: curSong.genre,
        token: authService.token,
      );
    }

    await player.skipNext();
  }

  /// Fetch intelligent recommendation feed from NextViper AWS backend
  Future<void> loadInitialFeed() async {
    _isFeedLoading = true;
    _feedPage = 0;
    notifyListeners();

    try {
      final feed = await apiService.getFeed(token: authService.token);
      _isBackendConnected = feed != null;

      if (feed != null) {
        _featuredSong = feed.featured;
        _feedRecommendations = feed.recommended;
        _recommendedMixes = feed.mixes;
        _trendingTracks = feed.trending;
      } else {
        // Fallback to search-based discovery if feed endpoint is unreachable
        final results = await Future.wait([
          apiService.search('trending music').catchError((_) => <Song>[]),
          apiService.search('top hits billboard').catchError((_) => <Song>[]),
          apiService.checkHealth().catchError((_) => false),
        ]);

        final trending = results[0] as List<Song>;
        final topPicks = results[1] as List<Song>;
        _isBackendConnected = results[2] as bool;

        if (trending.isNotEmpty) _trendingTracks = trending.take(12).toList();
        if (topPicks.isNotEmpty) _feedRecommendations = topPicks.take(20).toList();
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

  // --- Cloud Playlists CRUD ---

  Future<void> loadUserPlaylists() async {
    _isPlaylistsLoading = true;
    notifyListeners();

    try {
      final playlists = await apiService.getPlaylists(token: authService.token);
      _userPlaylists = playlists;
    } catch (_) {}

    _isPlaylistsLoading = false;
    notifyListeners();
  }

  Future<bool> createPlaylist(String name, {String description = ''}) async {
    try {
      final newPl = await apiService.createPlaylist(
        name: name,
        description: description,
        token: authService.token,
      );
      if (newPl != null) {
        _userPlaylists = [newPl, ..._userPlaylists];
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> addSongToPlaylist(String playlistId, Song song) async {
    try {
      final updated = await apiService.addTrackToPlaylist(
        playlistId: playlistId,
        track: song,
        token: authService.token,
      );
      if (updated != null) {
        final idx = _userPlaylists.indexWhere((p) => p.id == playlistId);
        if (idx != -1) {
          _userPlaylists[idx] = updated;
        } else {
          _userPlaylists.add(updated);
        }
        notifyListeners();

        // Send telemetry: track added to playlist
        apiService.sendRecommendationEvent(
          trackId: song.id,
          eventType: 'add_to_playlist',
          artist: song.artist,
          genre: song.genre,
          token: authService.token,
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      final success = await apiService.removeTrackFromPlaylist(
        playlistId: playlistId,
        trackId: songId,
        token: authService.token,
      );
      if (success) {
        final idx = _userPlaylists.indexWhere((p) => p.id == playlistId);
        if (idx != -1) {
          final cur = _userPlaylists[idx];
          final updatedTracks = cur.tracks.where((t) => t.id != songId).toList();
          _userPlaylists[idx] = cur.copyWith(tracks: updatedTracks);
          notifyListeners();
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deletePlaylist(String playlistId) async {
    try {
      final success = await apiService.deletePlaylist(
        playlistId: playlistId,
        token: authService.token,
      );
      if (success) {
        _userPlaylists = _userPlaylists.where((p) => p.id != playlistId).toList();
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> saveRecommendationMix(Playlist mix) async {
    try {
      final saved = await apiService.saveMix(
        mix: mix,
        token: authService.token,
      );
      if (saved != null) {
        _userPlaylists = [saved, ..._userPlaylists];
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // --- Search ---

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

  @override
  void dispose() {
    player.removeListener(notifyListeners);
    downloads.removeListener(notifyListeners);
    authService.removeListener(_onAuthChanged);
    player.dispose();
    downloads.dispose();
    super.dispose();
  }

  // --- Instant Fallback Tracks ---
  static const List<Song> _defaultTrendingTracks = [
    Song(
      id: 'eVli-tstM5E',
      title: 'Espresso',
      artist: 'Sabrina Carpenter',
      thumbnailUrl: 'https://i.ytimg.com/vi/eVli-tstM5E/hqdefault.jpg',
      duration: '2:55',
      genre: 'Pop',
    ),
    Song(
      id: '4NRXx6U8ABQ',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      thumbnailUrl: 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg',
      duration: '3:20',
      genre: 'Pop',
    ),
    Song(
      id: 'H58vbez_m4E',
      title: 'Not Like Us',
      artist: 'Kendrick Lamar',
      thumbnailUrl: 'https://i.ytimg.com/vi/H58vbez_m4E/hqdefault.jpg',
      duration: '4:34',
      genre: 'Hip-Hop',
    ),
    Song(
      id: 'V9PVRfjEBTI',
      title: 'BIRDS OF A FEATHER',
      artist: 'Billie Eilish',
      thumbnailUrl: 'https://i.ytimg.com/vi/V9PVRfjEBTI/hqdefault.jpg',
      duration: '3:13',
      genre: 'Pop',
    ),
  ];

  static const List<Song> _defaultPicks = [
    Song(
      id: '2Vv-BfVoq4g',
      title: 'Perfect',
      artist: 'Ed Sheeran',
      thumbnailUrl: 'https://i.ytimg.com/vi/2Vv-BfVoq4g/hqdefault.jpg',
      duration: '4:23',
      genre: 'Acoustic',
    ),
    Song(
      id: 'bpOSxM0rNPM',
      title: 'Do I Wanna Know?',
      artist: 'Arctic Monkeys',
      thumbnailUrl: 'https://i.ytimg.com/vi/bpOSxM0rNPM/hqdefault.jpg',
      duration: '4:32',
      genre: 'Rock',
    ),
    Song(
      id: 'MV_3Dpw-BRY',
      title: 'Nightcall',
      artist: 'Kavinsky',
      thumbnailUrl: 'https://i.ytimg.com/vi/MV_3Dpw-BRY/hqdefault.jpg',
      duration: '4:19',
      genre: 'Electronic',
    ),
    Song(
      id: 'cr_V3aBffpY',
      title: 'MONACO',
      artist: 'Bad Bunny',
      thumbnailUrl: 'https://i.ytimg.com/vi/cr_V3aBffpY/hqdefault.jpg',
      duration: '4:27',
      genre: 'Latin',
    ),
  ];
}
