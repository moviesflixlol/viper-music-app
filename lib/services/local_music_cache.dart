import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Bounded, account-scoped metadata cache. Never stores passwords or API keys.
class LocalMusicCache {
  static const _prefix = 'music_metadata_v3:';
  final DateTime Function() now;
  LocalMusicCache({DateTime Function()? clock}) : now = clock ?? DateTime.now;
  String _key(String scope, String key) => '$_prefix${Uri.encodeComponent(scope)}:$key';

  Future<Map<String, dynamic>?> read(String scope, String key, {bool allowExpired = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(scope, key));
    if (raw == null) return null;
    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      if (!allowExpired && (entry['expires'] as num) <= now().millisecondsSinceEpoch) return null;
      return Map<String, dynamic>.from(entry['data'] as Map);
    } catch (_) { await prefs.remove(_key(scope, key)); return null; }
  }
  Future<void> write(String scope, String key, Map<String, dynamic> data, Duration ttl) async {
    final value = jsonEncode({'expires': now().add(ttl).millisecondsSinceEpoch, 'data': data});
    if (value.length > 400000) return;
    final prefs = await SharedPreferences.getInstance();
    final name = _key(scope, key);
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix) && k != name).toList();
    var total = keys.fold<int>(0, (size, key) => size + (prefs.getString(key)?.length ?? 0));
    while (keys.isNotEmpty && (keys.length >= 39 || total + value.length > 2000000)) {
      final oldest = keys.removeAt(0);
      total -= prefs.getString(oldest)?.length ?? 0;
      await prefs.remove(oldest);
    }
    await prefs.setString(name, value);
  }
  Future<void> remove(String scope, String key) async {
    final prefs = await SharedPreferences.getInstance(); await prefs.remove(_key(scope,key));
  }
  Future<void> clearScope(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((key) => key.startsWith('$_prefix${Uri.encodeComponent(scope)}:'))) {
      await prefs.remove(key);
    }
  }
}
