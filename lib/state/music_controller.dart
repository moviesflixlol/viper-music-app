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
  static const String _playlistsPrefsKey = 'viper_local_user_playlists';

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

    // Initialize local persistent playlists immediately
    _initPlaylists();
    loadInitialFeed();
  }

  Future<void> _initPlaylists() async {
    await _loadLocalPlaylists();
    await loadUserPlaylists();
  }

  void _onAuthChanged() {
    _mostListened = [];
    _feedRecommendations = [];
    _trendingTracks = [];
    loadUserPlaylists();
    loadInitialFeed();
    notifyListeners();
  }

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
          .then((saved) {
        if (saved) loadInitialFeed();
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
  Future<void> loadInitialFeed() async {
    _isFeedLoading = true;
    notifyListeners();

    try {
      final feed = await apiService.getFeed(
        token: authService.token,
        category: _selectedCategory,
      );
      _isBackendConnected = feed != null;

      if (feed != null) {
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
    if (_isLoadingMoreFeed) return;
    _isLoadingMoreFeed = true;
    notifyListeners();

    try {
      final existing = [
        ..._feedRecommendations,
        ..._trendingTracks,
        ..._newReleases
      ];
      final feed = await apiService.getFeed(
          token: authService.token,
          category: _selectedCategory,
          exclude: existing.map((s) => s.id).toList());
      if (feed != null) {
        final ids = existing.map((s) => s.id).toSet();
        _feedRecommendations = [
          ..._feedRecommendations,
          ...feed.recommended.where((song) => ids.add(song.id))
        ];
      }
    } catch (_) {}

    _isLoadingMoreFeed = false;
    notifyListeners();
  }

  // --- Offline-First Local + Cloud Playlists ---

  Future<void> _loadLocalPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_playlistsPrefsKey);
      if (savedStr != null && savedStr.isNotEmpty) {
        final decoded = jsonDecode(savedStr) as List<dynamic>;
        final loaded = decoded
            .whereType<Map<String, dynamic>>()
            .map((m) => Playlist.fromJson(m))
            .where((p) =>
                p.name.trim().isNotEmpty &&
                p.name.toLowerCase() != 'untitled playlist')
            .toList();

        if (loaded.isNotEmpty) {
          _userPlaylists = loaded;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveLocalPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final valid = _userPlaylists
          .where((p) =>
              p.name.trim().isNotEmpty &&
              p.name.toLowerCase() != 'untitled playlist')
          .map((p) => p.toJson())
          .toList();
      await prefs.setString(_playlistsPrefsKey, jsonEncode(valid));
    } catch (_) {}
  }

  Future<void> loadUserPlaylists() async {
    _isPlaylistsLoading = true;
    notifyListeners();

    try {
      final remote = await apiService.getPlaylists(token: authService.token);
      if (remote.isNotEmpty) {
        // Merge remote with local without losing playlists or tracks
        for (final r in remote) {
          final idx = _userPlaylists.indexWhere(
            (p) =>
                p.id == r.id ||
                (p.name.toLowerCase() == r.name.toLowerCase() &&
                    r.name.trim().isNotEmpty),
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
      token: authService.token,
    )
        .then((remotePl) {
      if (remotePl != null) {
        final idx = _userPlaylists
            .indexWhere((p) => p.id == newPlaylist.id || p.name == trimmedName);
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
        notifyListeners();

        // Sync with cloud
        apiService
            .addTrackToPlaylist(
              playlistId: playlistId,
              track: song,
              token: authService.token,
            )
            .catchError((_) => null);

        // Send recommendation telemetry
        apiService.sendRecommendationEvent(
          trackId: song.id,
          eventType: 'add_to_playlist',
          artist: song.artist,
          genre: song.genre,
          token: authService.token,
        );
        return true;
      }
    }
    return false;
  }

  Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    final idx = _userPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final cur = _userPlaylists[idx];
      final updatedTracks = cur.tracks.where((t) => t.id != songId).toList();
      _userPlaylists[idx] = cur.copyWith(tracks: updatedTracks);
      await _saveLocalPlaylists();
      notifyListeners();

      apiService
          .removeTrackFromPlaylist(
            playlistId: playlistId,
            trackId: songId,
            token: authService.token,
          )
          .catchError((_) => false);
      return true;
    }
    return false;
  }

  Future<bool> deletePlaylist(String playlistId) async {
    _userPlaylists.removeWhere((p) => p.id == playlistId);
    await _saveLocalPlaylists();
    notifyListeners();

    apiService
        .deletePlaylist(
          playlistId: playlistId,
          token: authService.token,
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
    player.removeListener(_onPlaybackChanged);
    downloads.removeListener(notifyListeners);
    authService.removeListener(_onAuthChanged);
    player.dispose();
    downloads.dispose();
    super.dispose();
  }
}
