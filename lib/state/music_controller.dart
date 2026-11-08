import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/auth_service.dart';
import '../services/download_service.dart';

class ArtistInfo {
  final String name;
  final String imageUrl;
  final String genre;

  const ArtistInfo({
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
  List<Playlist> _userPlaylists = [];
  List<ArtistInfo> _popularArtists = [];

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

  // Real Spotify-style Category Filter Chips (from Screenshot 2, 3, 5)
  static const List<String> categories = [
    'All',
    'Music',
    'Podcasts',
    'Charts',
    'Artists',
  ];

  static const List<String> _feedQueries = [
    'bollywood hits',
    'hot hits hindi',
    'top hits global',
    'punjabi party hits',
    'viral pop 2026',
    'hip hop essentials',
    'acoustic chill vibes',
  ];

  // Diverse pool of popular artists for dynamic rotation
  static const List<ArtistInfo> _allCuratedArtists = [
    ArtistInfo(
      name: 'Arijit Singh',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5eb5ba2d75eb08a2d672f9b69b7',
      genre: 'Bollywood',
    ),
    ArtistInfo(
      name: 'Yo Yo Honey Singh',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5ebcb6926f44f620555ba444fca',
      genre: 'Hip-Hop',
    ),
    ArtistInfo(
      name: 'Sidhu Moose Wala',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5ebb7ee13a9d9e60057cbe80164',
      genre: 'Punjabi',
    ),
    ArtistInfo(
      name: 'The Weeknd',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5eb214f3cf1cbe7139c1e26ffbb',
      genre: 'R&B / Pop',
    ),
    ArtistInfo(
      name: 'Diljit Dosanjh',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5eb2be4a480cb4a106d4fb0fb9b',
      genre: 'Punjabi Pop',
    ),
    ArtistInfo(
      name: 'Billie Eilish',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5eb38d1544a475510688a25faab',
      genre: 'Alt Pop',
    ),
    ArtistInfo(
      name: 'Karan Aujla',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5ebfe3462f6b864a66a1a141b71',
      genre: 'Punjabi Hip-Hop',
    ),
    ArtistInfo(
      name: 'Coldplay',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5eb8654c6b845c4885cc0a2569c',
      genre: 'Rock / Alternative',
    ),
    ArtistInfo(
      name: 'Shreya Ghoshal',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5ebba9ca876cb862a9b3d09a06e',
      genre: 'Bollywood Melodies',
    ),
    ArtistInfo(
      name: 'Anirudh Ravichander',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5eb74b341c888d3d9229adad066',
      genre: 'South Indian Viral',
    ),
    ArtistInfo(
      name: 'Badshah',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5ebb6b95d7f1d24c3a2c7cf9915',
      genre: 'Party Hits',
    ),
    ArtistInfo(
      name: 'Pritam',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5ebcb3005a7698504a79b0072b2',
      genre: 'Bollywood Hits',
    ),
    ArtistInfo(
      name: 'Taylor Swift',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5eb5a00969a4698c3132a15fbb0',
      genre: 'Pop / Acoustic',
    ),
    ArtistInfo(
      name: 'Travis Scott',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5ebe707b87e3f65e03909e3b977',
      genre: 'Trap / Hip-Hop',
    ),
    ArtistInfo(
      name: 'AP Dhillon',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5eb6dfdd7d6363c46b6279f0fb5',
      genre: 'Indie Punjabi',
    ),
    ArtistInfo(
      name: 'Dua Lipa',
      imageUrl: 'https://i.scdn.co/image/ab6761610000e5ebd42a27db3286b58553da8858',
      genre: 'Dance Pop',
    ),
  ];

  List<ArtistInfo> get popularArtists =>
      _popularArtists.isNotEmpty ? _popularArtists : _allCuratedArtists.take(8).toList();

  // Real Curated Playlists (Spotify Style matching Screenshot 2, 3, 5)
  static final List<Playlist> curatedPlaylists = [
    Playlist(
      id: 'chart_hot_hits_hindi',
      name: 'Hot Hits Hindi',
      description: 'The hottest Hindi songs right now. Cover: Tauba Tauba',
      coverUrl: 'https://i.scdn.co/image/ab67706f000000021c5756df6ad4720973a11681',
      tracks: const [
        Song(id: 'Tauba_Tauba', title: 'Tauba Tauba', artist: 'Karan Aujla', thumbnailUrl: 'https://i.ytimg.com/vi/LK7-_dgAVQE/hqdefault.jpg', duration: '3:28', genre: 'Hindi Pop'),
        Song(id: 'O_Maahi', title: 'O Maahi', artist: 'Arijit Singh', thumbnailUrl: 'https://i.ytimg.com/vi/8N_QzO_E3zE/hqdefault.jpg', duration: '3:53', genre: 'Bollywood'),
        Song(id: 'Ve_Kamleya', title: 'Ve Kamleya', artist: 'Arijit Singh, Shreya Ghoshal', thumbnailUrl: 'https://i.ytimg.com/vi/V1Pl8z57fzs/hqdefault.jpg', duration: '4:06', genre: 'Romantic'),
        Song(id: 'Chaleya', title: 'Chaleya', artist: 'Arijit Singh, Shilpa Rao', thumbnailUrl: 'https://i.ytimg.com/vi/VAdGW7QDJjU/hqdefault.jpg', duration: '3:20', genre: 'Bollywood'),
      ],
      isAutoGenerated: false,
    ),
    Playlist(
      id: 'chart_bollywood_central',
      name: 'Bollywood Central',
      description: 'Essential Bollywood blockbusters & chart toppers.',
      coverUrl: 'https://i.scdn.co/image/ab67706f0000000201dc9ebc44122d256cd1b5b2',
      tracks: const [
        Song(id: 'Kesariya', title: 'Kesariya', artist: 'Pritam, Arijit Singh', thumbnailUrl: 'https://i.ytimg.com/vi/BddP6PYo2gs/hqdefault.jpg', duration: '4:28', genre: 'Bollywood'),
        Song(id: 'Apna_Bana_Le', title: 'Apna Bana Le', artist: 'Arijit Singh, Sachin-Jigar', thumbnailUrl: 'https://i.ytimg.com/vi/ElZfdU54Cp8/hqdefault.jpg', duration: '4:21', genre: 'Bollywood'),
        Song(id: 'Tum_Hi_Ho', title: 'Tum Hi Ho', artist: 'Arijit Singh', thumbnailUrl: 'https://i.ytimg.com/vi/IJq0yyWug1k/hqdefault.jpg', duration: '4:22', genre: 'Acoustic Romantic'),
        Song(id: 'Heeriye', title: 'Heeriye', artist: 'Jasleen Royal, Arijit Singh', thumbnailUrl: 'https://i.ytimg.com/vi/RLzC55ai0eo/hqdefault.jpg', duration: '3:15', genre: 'Acoustic'),
      ],
      isAutoGenerated: false,
    ),
    Playlist(
      id: 'chart_top_50_global',
      name: 'Top 50 - Global',
      description: 'Your daily update of the most played tracks right now.',
      coverUrl: 'https://i.scdn.co/image/ab67706f00000002b8d00938f38634812a321cfc',
      tracks: const [
        Song(id: 'eVli-tstM5E', title: 'Espresso', artist: 'Sabrina Carpenter', thumbnailUrl: 'https://i.ytimg.com/vi/eVli-tstM5E/hqdefault.jpg', duration: '2:55', genre: 'Pop'),
        Song(id: 'V9PVRfjEBTI', title: 'BIRDS OF A FEATHER', artist: 'Billie Eilish', thumbnailUrl: 'https://i.ytimg.com/vi/V9PVRfjEBTI/hqdefault.jpg', duration: '3:13', genre: 'Pop'),
        Song(id: '4NRXx6U8ABQ', title: 'Blinding Lights', artist: 'The Weeknd', thumbnailUrl: 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg', duration: '3:20', genre: 'Pop'),
        Song(id: 'H5v3kku4y6Q', title: 'As It Was', artist: 'Harry Styles', thumbnailUrl: 'https://i.ytimg.com/vi/H5v3kku4y6Q/hqdefault.jpg', duration: '2:47', genre: 'Pop'),
      ],
      isAutoGenerated: false,
    ),
    Playlist(
      id: 'chart_party_punjabi',
      name: 'Party Hits Punjabi',
      description: 'High energy Punjabi beats to turn up the volume.',
      coverUrl: 'https://i.scdn.co/image/ab67706f0000000234e4026ceb61c56598c114f6',
      tracks: const [
        Song(id: 'White_Brown_Black', title: 'White Brown Black', artist: 'Karan Aujla, Avvy Sra', thumbnailUrl: 'https://i.ytimg.com/vi/9r8Lg7Cq_n0/hqdefault.jpg', duration: '3:05', genre: 'Punjabi'),
        Song(id: 'Softly', title: 'Softly', artist: 'Karan Aujla, Ikky', thumbnailUrl: 'https://i.ytimg.com/vi/cWMxCE2HTag/hqdefault.jpg', duration: '2:36', genre: 'Punjabi'),
        Song(id: 'Born_To_Shine', title: 'Born to Shine', artist: 'Diljit Dosanjh', thumbnailUrl: 'https://i.ytimg.com/vi/p8bX8o39fio/hqdefault.jpg', duration: '3:34', genre: 'Punjabi'),
        Song(id: 'Dope_Shope', title: 'Dope Shope', artist: 'Yo Yo Honey Singh, Deep Money', thumbnailUrl: 'https://i.ytimg.com/vi/z93f8e6eWfA/hqdefault.jpg', duration: '3:08', genre: 'Hip-Hop'),
      ],
      isAutoGenerated: false,
    ),
    Playlist(
      id: 'chart_rapcaviar',
      name: 'RapCaviar',
      description: 'New music from Kendrick Lamar, Travis Scott, Drake and more.',
      coverUrl: 'https://i.scdn.co/image/ab67706f000000025f17101683935391e4dbfb3b',
      tracks: const [
        Song(id: 'H58vbez_m4E', title: 'Not Like Us', artist: 'Kendrick Lamar', thumbnailUrl: 'https://i.ytimg.com/vi/H58vbez_m4E/hqdefault.jpg', duration: '4:34', genre: 'Hip-Hop'),
        Song(id: 'B9synWjqBn8', title: 'FE!N', artist: 'Travis Scott', thumbnailUrl: 'https://i.ytimg.com/vi/B9synWjqBn8/hqdefault.jpg', duration: '3:11', genre: 'Hip-Hop'),
        Song(id: 'uxpDa-c-4Mc', title: 'God\'s Plan', artist: 'Drake', thumbnailUrl: 'https://i.ytimg.com/vi/uxpDa-c-4Mc/hqdefault.jpg', duration: '3:18', genre: 'Hip-Hop'),
      ],
      isAutoGenerated: false,
    ),
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

    _trendingTracks = _defaultTrendingTracks;
    _feedRecommendations = _defaultPicks;
    _featuredSong = _defaultTrendingTracks[0];

    // Initialize local persistent playlists immediately
    _initPlaylists();
    loadInitialFeed();
  }

  Future<void> _initPlaylists() async {
    await _loadLocalPlaylists();
    await loadUserPlaylists();
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
  List<Playlist> get userPlaylists => _userPlaylists;
  List<Playlist> get recommendedMixes => curatedPlaylists;

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

  Future<void> setCategory(String cat) async {
    if (_selectedCategory == cat) return;
    _selectedCategory = cat;
    notifyListeners();
    await loadInitialFeed();
  }

  /// Play a song with background audio & media metadata
  Future<void> playSong(Song song, {List<Song>? queueContext}) async {
    await player.playSong(song, queueContext: queueContext);

    // Send recommendation telemetry signal to NextViper engine
    apiService.sendRecommendationEvent(
      trackId: song.id,
      eventType: 'play',
      artist: song.artist,
      genre: song.genre,
      token: authService.token,
    );
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
    _feedPage = 0;
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

        // Dynamic artists update: blend server-provided feed artists with rotating pool
        final dynamicList = feed.artists.map((a) => ArtistInfo(
          name: a.name,
          imageUrl: a.imageUrl,
          genre: a.genre,
        )).where((a) => a.imageUrl.isNotEmpty).toList();

        final pool = List<ArtistInfo>.from(_allCuratedArtists)..shuffle();
        final blendedArtists = <ArtistInfo>[];
        final seen = <String>{};

        for (final a in [...dynamicList, ...pool]) {
          final norm = a.name.toLowerCase().trim();
          if (!seen.contains(norm) && norm != 'various artists' && norm != 'song' && norm != 'video') {
            seen.add(norm);
            blendedArtists.add(a);
            if (blendedArtists.length >= 8) break;
          }
        }
        _popularArtists = blendedArtists;
      } else {
        final query = _selectedCategory == 'Podcasts'
            ? 'trending podcasts hindi'
            : _selectedCategory == 'Artists'
                ? 'top artist songs'
                : 'trending bollywood music';
        final results = await Future.wait([
          apiService.search(query).catchError((_) => <Song>[]),
          apiService.search('top global hits').catchError((_) => <Song>[]),
          apiService.checkHealth().catchError((_) => false),
        ]);

        final trending = results[0] as List<Song>;
        final topPicks = results[1] as List<Song>;
        _isBackendConnected = results[2] as bool;

        if (trending.isNotEmpty) _trendingTracks = trending.take(15).toList();
        if (topPicks.isNotEmpty) _feedRecommendations = topPicks.take(20).toList();

        final pool = List<ArtistInfo>.from(_allCuratedArtists)..shuffle();
        _popularArtists = pool.take(8).toList();
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
            .where((p) => p.name.trim().isNotEmpty && p.name.toLowerCase() != 'untitled playlist')
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
          .where((p) => p.name.trim().isNotEmpty && p.name.toLowerCase() != 'untitled playlist')
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
            (p) => p.id == r.id || (p.name.toLowerCase() == r.name.toLowerCase() && r.name.trim().isNotEmpty),
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
              coverUrl: mergedTracks.isNotEmpty ? mergedTracks.first.thumbnailUrl : r.coverUrl,
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
    if (trimmedName.isEmpty || trimmedName.toLowerCase() == 'untitled playlist') {
      return false;
    }

    final newPlaylist = Playlist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmedName,
      description: description,
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&q=80',
      tracks: [],
      createdAt: DateTime.now().millisecondsSinceEpoch / 1000,
      updatedAt: DateTime.now().millisecondsSinceEpoch / 1000,
    );

    // 1. Save locally instantly
    _userPlaylists.insert(0, newPlaylist);
    await _saveLocalPlaylists();
    notifyListeners();

    // 2. Sync with cloud backend in background with exact ID
    apiService.createPlaylist(
      id: newPlaylist.id,
      name: trimmedName,
      description: description,
      token: authService.token,
    ).then((remotePl) {
      if (remotePl != null) {
        final idx = _userPlaylists.indexWhere((p) => p.id == newPlaylist.id || p.name == trimmedName);
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
        final updatedCover = song.thumbnailUrl.isNotEmpty ? song.thumbnailUrl : cur.coverUrl;
        _userPlaylists[idx] = cur.copyWith(
          tracks: updatedTracks,
          coverUrl: updatedCover,
          updatedAt: DateTime.now().millisecondsSinceEpoch / 1000,
        );
        await _saveLocalPlaylists();
        notifyListeners();

        // Sync with cloud
        apiService.addTrackToPlaylist(
          playlistId: playlistId,
          track: song,
          token: authService.token,
        ).catchError((_) => null);

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

      apiService.removeTrackFromPlaylist(
        playlistId: playlistId,
        trackId: songId,
        token: authService.token,
      ).catchError((_) => false);
      return true;
    }
    return false;
  }

  Future<bool> deletePlaylist(String playlistId) async {
    _userPlaylists.removeWhere((p) => p.id == playlistId);
    await _saveLocalPlaylists();
    notifyListeners();

    apiService.deletePlaylist(
      playlistId: playlistId,
      token: authService.token,
    ).catchError((_) => false);
    return true;
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

  // Fallback tracks
  static const List<Song> _defaultTrendingTracks = [
    Song(
      id: 'Tauba_Tauba',
      title: 'Tauba Tauba',
      artist: 'Karan Aujla',
      thumbnailUrl: 'https://i.ytimg.com/vi/LK7-_dgAVQE/hqdefault.jpg',
      duration: '3:28',
      genre: 'Hindi Pop',
    ),
    Song(
      id: 'Kesariya',
      title: 'Kesariya',
      artist: 'Arijit Singh, Pritam',
      thumbnailUrl: 'https://i.ytimg.com/vi/BddP6PYo2gs/hqdefault.jpg',
      duration: '4:28',
      genre: 'Bollywood',
    ),
    Song(
      id: 'eVli-tstM5E',
      title: 'Espresso',
      artist: 'Sabrina Carpenter',
      thumbnailUrl: 'https://i.ytimg.com/vi/eVli-tstM5E/hqdefault.jpg',
      duration: '2:55',
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
  ];

  static const List<Song> _defaultPicks = [
    Song(
      id: 'O_Maahi',
      title: 'O Maahi',
      artist: 'Arijit Singh',
      thumbnailUrl: 'https://i.ytimg.com/vi/8N_QzO_E3zE/hqdefault.jpg',
      duration: '3:53',
      genre: 'Bollywood',
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
      id: 'V9PVRfjEBTI',
      title: 'BIRDS OF A FEATHER',
      artist: 'Billie Eilish',
      thumbnailUrl: 'https://i.ytimg.com/vi/V9PVRfjEBTI/hqdefault.jpg',
      duration: '3:13',
      genre: 'Pop',
    ),
    Song(
      id: 'Apna_Bana_Le',
      title: 'Apna Bana Le',
      artist: 'Arijit Singh, Sachin-Jigar',
      thumbnailUrl: 'https://i.ytimg.com/vi/ElZfdU54Cp8/hqdefault.jpg',
      duration: '4:21',
      genre: 'Bollywood',
    ),
  ];
}
