import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/api_service.dart';
import '../services/listening_tracker.dart';
import '../services/audio_player_service.dart';
import '../services/auth_service.dart';
import '../services/download_service.dart';

class ArtistInfo {
  final String id;
  final String name;
  final String imageUrl;
  final String genre;

  const ArtistInfo({
    this.id = '',
    required this.name,
    required this.imageUrl,
    required this.genre,
  });
}

class MusicController extends ChangeNotifier {
  String get _playlistsPrefsKey => 'viper_playlists_v3_${authService.currentUser?.id ?? apiService.deviceId}';
  String _activeScope = '';
  String _nextCursor = '';
  bool _feedHasMore = false;
  String? _feedMessage;
  List<Song> _moreFeed = [];
  bool _disposed = false;
  int _feedGeneration = 0;

  final ApiService apiService;
  final AuthService authService;
  late final AudioPlayerService player;
  late final DownloadService downloads;

  int _selectedTabIndex = 0;
  String _selectedCategory = 'All';
  Song? _featuredSong;
  List<Song> _feedRecommendations = [];
  List<Song> _trendingTracks = [];
  List<Song> _mostListened = [], _newReleases = [];
  List<ReleaseItem> _releaseAlbums = [];
  List<ArtistItem> _searchArtists = [];
  String? _searchError;
  final _sessionPrefix = DateTime.now().microsecondsSinceEpoch.toString();
  final _listening = ListeningTracker();

  List<Playlist> _userPlaylists = [];
  List<ArtistInfo> _popularArtists = [];

  List<Playlist> _serverMixes = []; // Personalized mixes from backend
  bool _isFeedLoading = false;
  bool _isLoadingMoreFeed = false;
  bool _isPlaylistsLoading = false;
  bool _isBackendConnected = false;

  // Search state
  List<Song> _searchResults = [];
  bool _isSearching = false;
  String _currentQuery = '';

  // Categories — no Podcasts, no Artists (those were mock)
  static const List<String> categories = [
    'All',
    'Music',
    'Charts',
  ];

  List<ArtistInfo> get popularArtists => _popularArtists;
  List<Playlist> get chartPlaylists => _trendingTracks.isEmpty
      ? []
      : [
          Playlist(
              id: 'youtube-charts',
              name: 'YouTube Music charts',
              tracks: _trendingTracks,
              description: 'Tracks returned by YouTube Music charts')
        ];
  List<Song> get mostListened => _mostListened;
  List<Song> get newReleases => _newReleases;
  List<ReleaseItem> get releaseAlbums => _releaseAlbums;
  List<ArtistItem> get searchArtists => _searchArtists;
  String? get searchError => _searchError;

  MusicController({
    required this.apiService,
    required this.authService,
  }) {
    player = AudioPlayerService(apiService: apiService);
    downloads = DownloadService(apiService: apiService);

    player.addListener(_onPlaybackChanged);
    downloads.addListener(notifyListeners);
    authService.addListener(_onAuthChanged);

    _activeScope = authService.currentUser?.id ?? apiService.deviceId;
    // Initialize local persistent playlists immediately
    _initPlaylists();
    loadInitialFeed();
  }

  Future<void> _initPlaylists() async {
    await _loadLocalPlaylists();
    await loadUserPlaylists();
  }

  void _onAuthChanged() {
    final scope = authService.currentUser?.id ?? apiService.deviceId;
    if (_activeScope == scope) return;
    _activeScope = scope;
    _isLoadingMoreFeed = false;
    _feedHasMore = false;
    _feedGeneration++;
    _userPlaylists = [];
    _mostListened = [];
    _feedRecommendations = [];
    _trendingTracks = [];
    _newReleases = [];
    _releaseAlbums = [];
    _moreFeed = [];
    _initPlaylists();
    loadInitialFeed();
    notifyListeners();
  }
  List<Song> get moreFeed => _moreFeed;
  bool get feedHasMore => _feedHasMore;
  String? get feedMessage => _feedMessage;
  Future<void> refreshFeed() => loadInitialFeed(force: true);

  int get selectedTabIndex => _selectedTabIndex;
  String get selectedCategory => _selectedCategory;
  Song? get featuredSong => _featuredSong;
  List<Song> get feedRecommendations => _feedRecommendations;
  List<Song> get trendingTracks => _trendingTracks;
  List<Playlist> get userPlaylists => _userPlaylists;
  List<Playlist> get recommendedMixes => _serverMixes;

  bool get isFeedLoading => _isFeedLoading;
  bool get isLoadingMoreFeed => _isLoadingMoreFeed;
  bool get isPlaylistsLoading => _isPlaylistsLoading;
  bool get isBackendConnected => _isBackendConnected;

  List<Song> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get currentQuery => _currentQuery;

  void setTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  Future<void> setCategory(String cat) async {
    if (_selectedCategory == cat) return;
    _selectedCategory = cat;
    notifyListeners();
    await loadInitialFeed();
  }

  /// Play a song with background audio & media metadata
  Future<void> playSong(Song song, {List<Song>? queueContext}) async {
    await player.playSong(song, queueContext: queueContext);
  }

  void _onPlaybackChanged() {
    final qualified = _listening.update(
        session: player.playbackSession,
        position: player.position,
        playing: player.isPlaying);
    final song = player.currentSong;
    if (qualified && song != null) {
      final scope = _activeScope;
      apiService
          .sendRecommendationEvent(
              trackId: song.id,
              eventType: 'listen',
              playedSeconds: _listening.playedSeconds,
              artist: song.artist,
              genre: song.genre,
              token: authService.token,
              song: song,
              playbackId: '$_sessionPrefix-${player.playbackSession}')
          .then((saved) async {
        if (!saved || _disposed || scope != _activeScope) return;
        final cached = await apiService.cacheQualifiedListen(song);
        if (cached != null && !_disposed && scope == _activeScope) {
          _mostListened = cached.mostListened;
          notifyListeners();
        }
      });
    }
    notifyListeners();
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

  /// Fetch recommendation feed from NextViper AWS backend
  Future<void> loadInitialFeed({bool force = false}) async {
    final generation = ++_feedGeneration;
    final scope = _activeScope;
    _isFeedLoading = true;
    notifyListeners();

    try {
      final feed = await apiService.getFeed(
        token: authService.token,
        category: _selectedCategory, force: force,
      );
      if (_disposed || generation != _feedGeneration || scope != _activeScope) return;
      _isBackendConnected = feed != null;

      if (feed != null) {
        _nextCursor = feed.nextCursor;
        _feedHasMore = feed.hasMore;
        _feedMessage = null;
        _moreFeed = [];
        _featuredSong = feed.featured;
        _feedRecommendations = feed.recommended;
        _trendingTracks = feed.trending;

        // Store personalized mixes from server — these are per-user, not static
        if (feed.mixes.isNotEmpty) {
          _serverMixes = feed.mixes;
        }

        _mostListened = feed.mostListened;
        _newReleases = feed.newReleases;
        _releaseAlbums = feed.releaseAlbums;
        _popularArtists = feed.artists
            .map((a) => ArtistInfo(
                id: a.id, name: a.name, imageUrl: a.imageUrl, genre: a.genre))
            .toList();
      }
    } catch (_) {}

    _isFeedLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreFeed() async {
    if (_isLoadingMoreFeed || !_feedHasMore) return;
    final scope = _activeScope;
    _isLoadingMoreFeed = true;
    _feedMessage = null;
    notifyListeners();
    try {
      final existing = [..._feedRecommendations, ..._trendingTracks, ..._newReleases];
      final ids = existing.map((song) => song.id).toSet();
      final additions = <Song>[];
      for (var attempt = 0; attempt < 2 && _nextCursor.isNotEmpty; attempt++) {
        final oldCursor = _nextCursor;
        final feed = await apiService.getFeed(token: authService.token, category: _selectedCategory,
          exclude: ids.toList(), cursor: oldCursor);
        if (_disposed || scope != _activeScope) return;
        if (feed == null) throw StateError('Feed unavailable');
        _nextCursor = feed.nextCursor;
        _feedHasMore = feed.hasMore && _nextCursor != oldCursor;
        additions.addAll(feed.recommended.where((song) => ids.add(song.id)));
        if (additions.isNotEmpty || !_feedHasMore) break;
      }
      _moreFeed = [..._moreFeed, ...additions];
      _feedRecommendations = [..._feedRecommendations, ...additions];
      if (additions.isEmpty) _feedMessage = _feedHasMore ? 'No new songs on this page. Try the next page.' : 'You’re up to date. Refresh later for more music.';
    } catch (_) { _feedMessage = 'Could not load more songs. Please try again.'; }
    finally { if (!_disposed && scope == _activeScope) { _isLoadingMoreFeed = false; notifyListeners(); } }
  }

  // --- Offline-First Local + Cloud Playlists ---

  Future<void> _loadLocalPlaylists() async {
    final key = _playlistsPrefsKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(key);
      if (savedStr != null && savedStr.isNotEmpty) {
        final decoded = jsonDecode(savedStr) as List<dynamic>;
        final loaded = decoded
            .whereType<Map<String, dynamic>>()
            .map((m) => Playlist.fromJson(m))
            .where((p) =>
                p.name.trim().isNotEmpty &&
                p.name.toLowerCase() != 'untitled playlist')
            .toList();

        if (!_disposed && key == _playlistsPrefsKey && loaded.isNotEmpty) {
          _userPlaylists = loaded;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveLocalPlaylists() async {
    final key = _playlistsPrefsKey;
    try {
      final valid = _userPlaylists
          .where((p) =>
              p.name.trim().isNotEmpty &&
              p.name.toLowerCase() != 'untitled playlist')
          .map((p) => p.toJson())
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(valid));
    } catch (_) {}
  }

  Future<void> loadUserPlaylists() async {
    final scope = _activeScope;
    _isPlaylistsLoading = true;
    notifyListeners();

    try {
      final remote = await apiService.getPlaylists(token: authService.token);
      if (_disposed || scope != _activeScope) return;
      if (remote.isNotEmpty) {
        // Merge remote with local without losing playlists or tracks
        for (final r in remote) {
          final idx = _userPlaylists.indexWhere(
            (p) =>
                p.id == r.id,
          );
          if (idx != -1) {
            final localPl = _userPlaylists[idx];
            final trackIds = localPl.tracks.map((t) => t.id).toSet();
            final mergedTracks = [...localPl.tracks];
            for (final rt in r.tracks) {
              if (!trackIds.contains(rt.id)) {
                mergedTracks.add(rt);
              }
            }
            _userPlaylists[idx] = r.copyWith(
              id: localPl.id,
              tracks: mergedTracks,
              coverUrl: mergedTracks.isNotEmpty
                  ? mergedTracks.first.thumbnailUrl
                  : r.coverUrl,
            );
          } else if (r.name.trim().isNotEmpty) {
            _userPlaylists.add(r);
          }
        }
        await _saveLocalPlaylists();
      }
    } catch (_) {}

    _isPlaylistsLoading = false;
    notifyListeners();
  }

  /// Create a real playlist immediately with 100% guarantee
  Future<bool> createPlaylist(String name, {String description = ''}) async {
    final scope = _activeScope;
    final token = authService.token;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty ||
        trimmedName.toLowerCase() == 'untitled playlist') {
      return false;
    }

    final newPlaylist = Playlist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmedName,
      description: description,
      coverUrl:
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&q=80',
      tracks: [],
      createdAt: DateTime.now().millisecondsSinceEpoch / 1000,
      updatedAt: DateTime.now().millisecondsSinceEpoch / 1000,
    );

    // 1. Save locally instantly
    _userPlaylists.insert(0, newPlaylist);
    await _saveLocalPlaylists();
    notifyListeners();

    // 2. Sync with cloud backend in background with exact ID
    apiService
        .createPlaylist(
      id: newPlaylist.id,
      name: trimmedName,
      description: description,
      token: token,
    )
        .then((remotePl) {
      if (remotePl != null && !_disposed && scope == _activeScope) {
        final idx = _userPlaylists
            .indexWhere((p) => p.id == newPlaylist.id);
        if (idx != -1) {
          final localTracks = _userPlaylists[idx].tracks;
          _userPlaylists[idx] = remotePl.copyWith(
            id: newPlaylist.id,
            tracks: localTracks.isNotEmpty ? localTracks : remotePl.tracks,
          );
          _saveLocalPlaylists();
          notifyListeners();
        }
      }
    }).catchError((_) => null);

    return true;
  }

  Future<bool> addSongToPlaylist(String playlistId, Song song) async {
    final scope = _activeScope;
    final token = authService.token;
    final idx = _userPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final cur = _userPlaylists[idx];
      if (!cur.tracks.any((t) => t.id == song.id)) {
        final updatedTracks = [...cur.tracks, song];
        final updatedCover =
            song.thumbnailUrl.isNotEmpty ? song.thumbnailUrl : cur.coverUrl;
        _userPlaylists[idx] = cur.copyWith(
          tracks: updatedTracks,
          coverUrl: updatedCover,
          updatedAt: DateTime.now().millisecondsSinceEpoch / 1000,
        );
        await _saveLocalPlaylists();
      if (_disposed || scope != _activeScope) return true;
        notifyListeners();

        // Sync with cloud
        apiService
            .addTrackToPlaylist(
              playlistId: playlistId,
              track: song,
              token: token,
            )
            .catchError((_) => null);

        // Send recommendation telemetry
        apiService.sendRecommendationEvent(
          trackId: song.id,
          eventType: 'add_to_playlist',
          artist: song.artist,
          genre: song.genre,
          token: token,
        );
        return true;
      }
    }
    return false;
  }

  Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    final scope = _activeScope;
    final token = authService.token;
    final idx = _userPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final cur = _userPlaylists[idx];
      final updatedTracks = cur.tracks.where((t) => t.id != songId).toList();
      _userPlaylists[idx] = cur.copyWith(tracks: updatedTracks);
      await _saveLocalPlaylists();
      if (_disposed || scope != _activeScope) return true;
      notifyListeners();

      apiService
          .removeTrackFromPlaylist(
            playlistId: playlistId,
            trackId: songId,
            token: token,
          )
          .catchError((_) => false);
      return true;
    }
    return false;
  }

  Future<bool> deletePlaylist(String playlistId) async {
    final scope = _activeScope;
    final token = authService.token;
    _userPlaylists.removeWhere((p) => p.id == playlistId);
    await _saveLocalPlaylists();
      if (_disposed || scope != _activeScope) return true;
    notifyListeners();

    apiService
        .deletePlaylist(
          playlistId: playlistId,
          token: token,
        )
        .catchError((_) => false);
    return true;
  }

  // --- Search ---

  Future<void> search(String query) async {
    _currentQuery = query.trim();
    final requestedQuery = _currentQuery;
    _searchError = null;
    _searchResults = [];
    _searchArtists = [];
    _isSearching = requestedQuery.isNotEmpty;
    notifyListeners();
    if (requestedQuery.isEmpty) return;
    try {
      final catalog = await apiService.searchCatalog(requestedQuery);
      if (_currentQuery != requestedQuery) return;
      _searchResults = catalog.songs;
      _searchArtists = catalog.artists;
    } catch (_) {
      if (_currentQuery != requestedQuery) return;
      _searchError = 'Search is unavailable. Please try again.';
    }
    _isSearching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    player.removeListener(_onPlaybackChanged);
    downloads.removeListener(notifyListeners);
    authService.removeListener(_onAuthChanged);
    player.dispose();
    downloads.dispose();
    super.dispose();
  }
}
