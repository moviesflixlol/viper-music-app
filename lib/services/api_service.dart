import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/song.dart';
import 'local_music_cache.dart';
import '../models/playlist.dart';
import '../models/user.dart';

class ArtistItem {
  final String id;
  final String name;
  final String imageUrl;
  final String genre;

  const ArtistItem({
    this.id = '',
    required this.name,
    required this.imageUrl,
    required this.genre,
  });

  factory ArtistItem.fromJson(Map<String, dynamic> json) {
    return ArtistItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Artist',
      imageUrl: json['imageUrl'] as String? ?? '',
      genre: json['genre'] as String? ?? 'Pop',
    );
  }
}

class ReleaseItem {
  final String id, title, artist, thumbnail, subtitle, section;
  const ReleaseItem(
      {required this.id,
      required this.title,
      required this.artist,
      required this.thumbnail,
      required this.subtitle,
      this.section = ''});
  factory ReleaseItem.fromJson(Map<String, dynamic> data) => ReleaseItem(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      artist: data['artist'] as String? ?? '',
      thumbnail: data['thumbnail'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      section: data['section'] as String? ?? '');
}

class CatalogResult {
  final List<Song> songs;
  final List<ArtistItem> artists;
  final List<ReleaseItem> albums;
  const CatalogResult(
      {this.songs = const [], this.artists = const [], this.albums = const []});
  factory CatalogResult.fromJson(Map<String, dynamic> data) => CatalogResult(
      songs: (data['songs'] ?? data['results'] ?? <dynamic>[])
          .map<Song>((e) => Song.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      artists: (data['artists'] ?? <dynamic>[])
          .map<ArtistItem>(
              (e) => ArtistItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      albums: (data['albums'] ?? <dynamic>[])
          .map<ReleaseItem>(
              (e) => ReleaseItem.fromJson(Map<String, dynamic>.from(e)))
          .toList());
}

class FeedResult {
  final String nextCursor;
  final bool hasMore;
  final Song? featured;
  final List<Song> mostListened, newReleases;
  final List<ReleaseItem> releaseAlbums;
  final List<Song> recommended;
  final List<Playlist> mixes;
  final List<Song> trending;
  final List<ArtistItem> artists;
  final String country;
  final List<String> userInterests;

  FeedResult({
    required this.featured,
    this.nextCursor = '', this.hasMore = false,
    this.mostListened = const [],
    this.newReleases = const [],
    this.releaseAlbums = const [],
    required this.recommended,
    required this.mixes,
    required this.trending,
    this.artists = const [],
    this.country = 'IN',
    this.userInterests = const [],
  });
  factory FeedResult.fromJson(Map<String, dynamic> data) {
        final featuredJson = data['featured'] as Map<String, dynamic>?;
        final featuredSong =
            featuredJson == null ? null : Song.fromJson(featuredJson);
        List<Song> songs(String key) => (data[key] as List<dynamic>? ?? [])
            .map((e) => Song.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        final recList = (data['recommendedForYou'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => Song.fromJson(e))
            .toList();

        final mixesList = (data['mixes'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => Playlist.fromJson(e))
            .toList();

        final trendList = (data['trending'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => Song.fromJson(e))
            .toList();

        final artistList = (data['artists'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => ArtistItem.fromJson(e))
            .toList();

        final userInterests = (data['userInterests'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList();

        return FeedResult(
          featured: featuredSong,
          nextCursor: data['nextCursor'] as String? ?? '', hasMore: data['hasMore'] as bool? ?? false,
          mostListened: songs('mostListened'),
          newReleases: songs('newReleases'),
          releaseAlbums: (data['releaseAlbums'] as List<dynamic>? ?? [])
              .map((e) => ReleaseItem.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
          recommended: recList,
          mixes: mixesList,
          trending: trendList,
          artists: artistList,
          country: data['country'] as String? ?? 'IN',
          userInterests: userInterests,
        );
  }
}

class ApiService {
  String baseUrl;
  final LocalMusicCache _cache = LocalMusicCache();
  final Map<String, Future<Map<String, dynamic>>> _inflight = {};
  final Map<String, int> _cacheEpoch = {};
  final http.Client _client;
  String cacheScope = 'guest';
  Uri? _lastFeedUri;
  String? _deviceId;
  String get deviceId => _deviceId ?? 'dev_guest';

  ApiService({this.baseUrl = ApiConstants.defaultBaseUrl, http.Client? client}) : _client = client ?? http.Client();

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString('device_session_id');
      if (_deviceId == null || _deviceId!.isEmpty) {
        _deviceId =
            'dev_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
        await prefs.setString('device_session_id', _deviceId!);
      }
      cacheScope = 'guest:$deviceId';
    } catch (_) {
      _deviceId ??= 'dev_session_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Map<String, String> _buildHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-device-id': deviceId,
      'x-session-id': deviceId,
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _cachedGet(Uri uri, {String? token,
      required String scope, Duration ttl = const Duration(minutes: 10), bool force = false,
      bool persist = true}) async {
    final key = uri.toString();
    final epoch = _cacheEpoch[scope] ?? 0;
    if (!force && persist) {
      try {
        final saved = await _cache.read(scope, key);
        if (saved != null) return saved;
      } catch (_) {}
    }
    final flight = '$scope|$key';
    if (_inflight.containsKey(flight)) return _inflight[flight]!;
    final request = () async {
      final response = await _client.get(uri, headers: _buildHeaders(token: token)).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) throw Exception('Request failed (${response.statusCode})');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (persist && epoch == (_cacheEpoch[scope] ?? 0)) {
        try { await _cache.write(scope, key, data, ttl); } catch (_) {}
      }
      return data;
    }();
    _inflight[flight] = request;
    try { return await request; } finally { _inflight.remove(flight); }
  }
  Future<FeedResult?> cacheQualifiedListen(Song song) async {
    final uri = _lastFeedUri;
    final scope = cacheScope;
    if (uri == null) return null;
    final data = await _cache.read(scope, uri.toString(), allowExpired: true);
    if (data == null) return null;
    final ranked = (data['mostListened'] as List<dynamic>? ?? [])
      .map((e) => Map<String,dynamic>.from(e)).toList();
    final previous = ranked.where((e) => e['id'] == song.id).firstOrNull;
    ranked.removeWhere((e) => e['id'] == song.id);
    ranked.add({...song.toJson(), 'playCount': ((previous?['playCount'] as num?) ?? 0) + 1,
      'lastPlayed': DateTime.now().millisecondsSinceEpoch / 1000});
    ranked.sort((a,b) { final count=(b['playCount'] as num).compareTo(a['playCount'] as num);
      return count != 0 ? count : (b['lastPlayed'] as num).compareTo(a['lastPlayed'] as num); });
    data['mostListened'] = ranked.take(12).toList();
    await _cache.write(scope, uri.toString(), data, const Duration(minutes: 10));
    return FeedResult.fromJson(data);
  }
  Future<void> clearUserCache() async {
    final scope = cacheScope;
    _cacheEpoch[scope] = (_cacheEpoch[scope] ?? 0) + 1;
    try { await _cache.clearScope(scope); } catch (_) {}
  }
  Future<void> invalidatePlaylists() => _cache.remove(cacheScope, '$baseUrl${ApiConstants.playlistsEndpoint}');

  /// Check NextViper backend connectivity
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.healthEndpoint}');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch intelligent recommendation feed from NextViper
  Future<FeedResult?> getFeed(
      {String? token,
      String? category,
      String? country,
      List<String> exclude = const [], String cursor = '', bool force = false}) async {
    try {
      final detectedCountry =
          country ?? ui.PlatformDispatcher.instance.locale.countryCode ?? 'IN';
      final queryParam =
          StringBuffer('?country=${Uri.encodeComponent(detectedCountry)}');
      if (category != null && category.isNotEmpty && category != 'All') {
        queryParam.write('&category=${Uri.encodeComponent(category)}');
      }
      if (exclude.isNotEmpty)
        queryParam.write(
            '&exclude=${Uri.encodeComponent(exclude.take(450).join(','))}');

      if (cursor.isNotEmpty) queryParam.write('&cursor=${Uri.encodeComponent(cursor)}');
      final uri = Uri.parse('$baseUrl${ApiConstants.feedEndpoint}$queryParam');
      if (cursor.isEmpty && exclude.isEmpty) _lastFeedUri = uri;
      final data = await _cachedGet(uri, token: token, scope: cacheScope,
        force: force, persist: cursor.isEmpty && exclude.isEmpty);
      return FeedResult.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Send recommendation signal event to NextViper engine
  Future<bool> sendRecommendationEvent({
    required String trackId,
    required String eventType,
    int duration = 180,
    int playedSeconds = 0,
    String artist = '',
    String genre = 'Pop',
    String? token,
    Song? song,
    String? playbackId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.telemetryEventEndpoint}');
      final body = jsonEncode({
        'trackId': trackId,
        'eventType': eventType,
        if (song != null) ...{
          'title': song.title,
          'thumbnail': song.thumbnailUrl
        },
        if (playbackId != null) 'playbackId': playbackId,
        'duration': duration,
        'playedSeconds': playedSeconds,
        'artist': artist,
        'genre': genre,
      });

      final response = await http
          .post(uri, headers: _buildHeaders(token: token), body: body)
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Search tracks via NextViper backend
  Future<List<Song>> search(String query) async {
    try {
      final uri = Uri.parse(
          '$baseUrl${ApiConstants.searchEndpoint}?q=${Uri.encodeComponent(query)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];

        return results
            .map((item) => Song.fromJson(item as Map<String, dynamic>))
            .where((s) => s.id.isNotEmpty && s.title.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<CatalogResult> searchCatalog(String query) async {
    if (query.trim().isEmpty) return const CatalogResult();
    final uri = Uri.parse('$baseUrl/api/search').replace(queryParameters: {'q': query});
    return CatalogResult.fromJson(await _cachedGet(uri, scope: 'public'));
  }

  Future<CatalogResult> browse(String id) async {
    final uri = Uri.parse('$baseUrl/api/browse').replace(queryParameters: {'id': id});
    return CatalogResult.fromJson(await _cachedGet(uri, scope: 'public'));
  }

  Future<List<Song>> related(String id) async {
    final uri = Uri.parse('$baseUrl/api/related').replace(queryParameters: {'id': id});
    return CatalogResult.fromJson(await _cachedGet(uri, scope: 'public')).songs;
  }

  /// Resolve stream information for a track
  Future<String?> resolveStreamUrl(String videoId) async {
    try {
      final uri =
          Uri.parse('$baseUrl${ApiConstants.resolveEndpoint}?id=$videoId');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final streams = data['audioStreams'] as List<dynamic>? ?? [];
        for (final s in streams) {
          final streamMap = s as Map<String, dynamic>;
          if (streamMap['hasDirectUrl'] == true && streamMap['url'] != null) {
            return streamMap['url'] as String;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // --- Auth APIs ---

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String name = 'Viper User',
    List<String> interests = const [],
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.registerEndpoint}');
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(),
            body: jsonEncode({
              'email': email,
              'password': password,
              'name': name,
              'interests': interests,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['verificationRequired'] == true) {
          return {
            'success': true,
            'verificationRequired': true,
            'email': email,
            'message':
                data['message'] ?? 'Verification code sent to your email',
          };
        }
        final token = data['token'] as String? ?? '';
        final userJson = data['user'] as Map<String, dynamic>? ?? {};
        final user = UserModel.fromJson(userJson, token: token);
        return {
          'success': true,
          'verificationRequired': false,
          'user': user,
          'token': token
        };
      }
      return {
        'success': false,
        'error': data['error'] ?? 'Registration failed'
      };
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.verifyEmailEndpoint}');
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(),
            body: jsonEncode({'email': email, 'code': code}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = data['token'] as String? ?? '';
        final userJson = data['user'] as Map<String, dynamic>? ?? {};
        final user = UserModel.fromJson(userJson, token: token);
        return {
          'success': true,
          'verificationRequired': false,
          'user': user,
          'token': token
        };
      }
      return {
        'success': false,
        'error': data['error'] ?? 'Verification failed'
      };
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.forgotPasswordEndpoint}');
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(),
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset code sent'
        };
      }
      return {'success': false, 'error': data['error'] ?? 'Request failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.resetPasswordEndpoint}');
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(),
            body: jsonEncode(
                {'email': email, 'code': code, 'newPassword': newPassword}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset successfully'
        };
      }
      return {'success': false, 'error': data['error'] ?? 'Reset failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> resendCode({
    required String email,
    String type = 'signup',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.resendCodeEndpoint}');
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(),
            body: jsonEncode({'email': email, 'type': type}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Code resent'};
      }
      return {'success': false, 'error': data['error'] ?? 'Resend failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.loginEndpoint}');
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(),
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final token = data['token'] as String? ?? '';
        final userJson = data['user'] as Map<String, dynamic>? ?? {};
        final user = UserModel.fromJson(userJson, token: token);
        return {
          'success': true,
          'verificationRequired': false,
          'user': user,
          'token': token
        };
      }
      return {
        'success': false,
        'error': data['error'] ?? 'Invalid credentials'
      };
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<UserModel?> getMe(
    String token, {
    Future<void> Function()? onUnauthorized,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.meEndpoint}');
      final response = await http
          .get(uri, headers: _buildHeaders(token: token))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userJson = data['user'] as Map<String, dynamic>? ?? {};
        return UserModel.fromJson(userJson, token: token);
      }
      if (response.statusCode == 401) {
        await onUnauthorized?.call();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // --- Playlist APIs ---

  Future<List<Playlist>> getPlaylists({String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.playlistsEndpoint}');
      final data = await _cachedGet(uri, token: token, scope: cacheScope,
        ttl: const Duration(minutes: 5));
      return (data['playlists'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()
        .map(Playlist.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Playlist?> createPlaylist({
    String? id,
    required String name,
    String description = '',
    String coverUrl = '',
    String? token,
  }) async {
    await invalidatePlaylists();
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.playlistsEndpoint}');
      final bodyMap = <String, dynamic>{
        'name': name,
        'description': description,
        'coverUrl': coverUrl,
      };
      if (id != null && id.isNotEmpty) {
        bodyMap['id'] = id;
      }
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(token: token),
            body: jsonEncode(bodyMap),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Playlist.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Playlist?> addTrackToPlaylist({
    required String playlistId,
    required Song track,
    String? token,
  }) async {
    await invalidatePlaylists();
    try {
      final uri = Uri.parse(
          '$baseUrl${ApiConstants.playlistsEndpoint}/$playlistId/tracks');
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(token: token),
            body: jsonEncode({
              'track': track.toJson(),
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Playlist.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
    String? token,
  }) async {
    await invalidatePlaylists();
    try {
      final uri = Uri.parse(
          '$baseUrl${ApiConstants.playlistsEndpoint}/$playlistId/tracks/$trackId');
      final response = await http
          .delete(uri, headers: _buildHeaders(token: token))
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePlaylist({
    required String playlistId,
    String? token,
  }) async {
    await invalidatePlaylists();
    try {
      final uri =
          Uri.parse('$baseUrl${ApiConstants.playlistsEndpoint}/$playlistId');
      final response = await http
          .delete(uri, headers: _buildHeaders(token: token))
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Playlist?> saveMix({
    required Playlist mix,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.saveMixEndpoint}');
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(token: token),
            body: jsonEncode({
              'title': mix.name,
              'description': mix.description,
              'coverUrl': mix.coverUrl,
              'tracks': mix.tracks.map((t) => t.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Playlist.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
