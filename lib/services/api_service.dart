import 'dart:convert';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../models/user.dart';

class ArtistItem {
  final String name;
  final String imageUrl;
  final String genre;

  const ArtistItem({
    required this.name,
    required this.imageUrl,
    required this.genre,
  });

  factory ArtistItem.fromJson(Map<String, dynamic> json) {
    return ArtistItem(
      name: json['name'] as String? ?? 'Artist',
      imageUrl: json['imageUrl'] as String? ?? '',
      genre: json['genre'] as String? ?? 'Pop',
    );
  }
}

class FeedResult {
  final Song featured;
  final List<Song> recommended;
  final List<Playlist> mixes;
  final List<Song> trending;
  final List<ArtistItem> artists;
  final String country;

  FeedResult({
    required this.featured,
    required this.recommended,
    required this.mixes,
    required this.trending,
    this.artists = const [],
    this.country = 'IN',
  });
}

class ApiService {
  String baseUrl;

  ApiService({this.baseUrl = ApiConstants.defaultBaseUrl});

  Map<String, String> _buildHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

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
  Future<FeedResult?> getFeed({String? token, String? category, String? country}) async {
    try {
      final detectedCountry = country ?? ui.PlatformDispatcher.instance.locale.countryCode ?? 'IN';
      final queryParam = StringBuffer('?country=${Uri.encodeComponent(detectedCountry)}');
      if (category != null && category.isNotEmpty && category != 'All') {
        queryParam.write('&category=${Uri.encodeComponent(category)}');
      }
      queryParam.write('&r=${DateTime.now().millisecondsSinceEpoch}');

      final uri = Uri.parse('$baseUrl${ApiConstants.feedEndpoint}$queryParam');
      final response = await http
          .get(uri, headers: _buildHeaders(token: token))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final featuredJson = data['featured'] as Map<String, dynamic>?;
        final featuredSong = featuredJson != null
            ? Song.fromJson(featuredJson)
            : const Song(
                id: '4NRXx6U8ABQ',
                title: 'Blinding Lights',
                artist: 'The Weeknd',
                thumbnailUrl: 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg',
              );

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

        return FeedResult(
          featured: featuredSong,
          recommended: recList,
          mixes: mixesList,
          trending: trendList,
          artists: artistList,
          country: data['country'] as String? ?? detectedCountry,
        );
      }
      return null;
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
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.telemetryEventEndpoint}');
      final body = jsonEncode({
        'trackId': trackId,
        'eventType': eventType,
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
      final uri = Uri.parse('$baseUrl${ApiConstants.searchEndpoint}?q=${Uri.encodeComponent(query)}');
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

  /// Resolve stream information for a track
  Future<String?> resolveStreamUrl(String videoId) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.resolveEndpoint}?id=$videoId');
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
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.registerEndpoint}');
      final response = await http.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode({'email': email, 'password': password, 'name': name}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        final token = data['token'] as String? ?? '';
        final userJson = data['user'] as Map<String, dynamic>? ?? {};
        final user = UserModel.fromJson(userJson, token: token);
        return {'success': true, 'user': user, 'token': token};
      }
      return {'success': false, 'error': data['error'] ?? 'Registration failed'};
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
      final response = await http.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final token = data['token'] as String? ?? '';
        final userJson = data['user'] as Map<String, dynamic>? ?? {};
        final user = UserModel.fromJson(userJson, token: token);
        return {'success': true, 'user': user, 'token': token};
      }
      return {'success': false, 'error': data['error'] ?? 'Invalid credentials'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<UserModel?> getMe(String token) async {
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
      return null;
    } catch (_) {
      return null;
    }
  }

  // --- Playlist APIs ---

  Future<List<Playlist>> getPlaylists({String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.playlistsEndpoint}');
      final response = await http
          .get(uri, headers: _buildHeaders(token: token))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['playlists'] as List<dynamic>? ?? [];
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => Playlist.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Playlist?> createPlaylist({
    required String name,
    String description = '',
    String coverUrl = '',
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.playlistsEndpoint}');
      final response = await http.post(
        uri,
        headers: _buildHeaders(token: token),
        body: jsonEncode({
          'name': name,
          'description': description,
          'coverUrl': coverUrl,
        }),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 201) {
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
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.playlistsEndpoint}/$playlistId/tracks');
      final response = await http.post(
        uri,
        headers: _buildHeaders(token: token),
        body: jsonEncode({
          'track': track.toJson(),
        }),
      ).timeout(const Duration(seconds: 6));

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
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.playlistsEndpoint}/$playlistId/tracks/$trackId');
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
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.playlistsEndpoint}/$playlistId');
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
      final response = await http.post(
        uri,
        headers: _buildHeaders(token: token),
        body: jsonEncode({
          'title': mix.name,
          'description': mix.description,
          'coverUrl': mix.coverUrl,
          'tracks': mix.tracks.map((t) => t.toJson()).toList(),
        }),
      ).timeout(const Duration(seconds: 6));

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
