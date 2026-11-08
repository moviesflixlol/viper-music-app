import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/song.dart';

class ApiService {
  String baseUrl;

  ApiService({this.baseUrl = ApiConstants.defaultBaseUrl});

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

  /// Search tracks via NextViper backend
  Future<List<Song>> search(String query) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.searchEndpoint}?q=${Uri.encodeComponent(query)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 12));

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
}
