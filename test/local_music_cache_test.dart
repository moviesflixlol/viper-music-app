import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viper_music/services/local_music_cache.dart';
import 'package:viper_music/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('cache persists, expires and separates account data', () async {
    var now = DateTime.utc(2026);
    final cache = LocalMusicCache(clock: () => now);
    await cache.write('user:a', 'feed', {'mostListened': ['a']}, const Duration(minutes: 10));
    expect((await cache.read('user:a', 'feed'))!['mostListened'], ['a']);
    expect(await cache.read('user:b', 'feed'), isNull);
    now = now.add(const Duration(minutes: 11));
    expect(await cache.read('user:a', 'feed'), isNull);
    expect(await cache.read('user:a', 'feed', allowExpired: true), isNotNull);
    await cache.clearScope('user:a');
    expect(await cache.read('user:a', 'feed', allowExpired: true), isNull);
  });
  test('warm feed and parallel calls reuse one request; refresh bypasses cache', () async {
    var calls = 0;
    final api = ApiService(baseUrl:'https://example.test',client:MockClient((req) async {
      calls++; await Future<void>.delayed(const Duration(milliseconds: 20));
      return http.Response(jsonEncode({'hasMore':true,'nextCursor':'next-1'}),200);
    }));
    final feeds = await Future.wait([api.getFeed(country:'IN'),api.getFeed(country:'IN')]);
    expect(calls,1); expect(feeds.first!.nextCursor,'next-1');
    await api.getFeed(country:'IN');expect(calls,1);
    await api.getFeed(country:'IN',force:true);expect(calls,2);
    api.cacheScope='user:b';await api.getFeed(country:'IN');expect(calls,3);
  });
  test('pagination requests the next cursor and keeps the returned page state', () async {
    final api = ApiService(baseUrl:'https://example.test',client:MockClient((req) async {
      expect(req.url.queryParameters['cursor'],'next-1');
      return http.Response(jsonEncode({'recommendedForYou':[{'id':'abcdefghijk','title':'New song','artist':'A','thumbnail':'own.jpg'}], 'hasMore':false,'nextCursor':''}),200);
    }));
    final page=await api.getFeed(cursor:'next-1',exclude:['old-song']);
    expect(page!.recommended.single.title,'New song');expect(page.hasMore,isFalse);
  });
  test('a response finishing after logout cannot restore the cleared user cache', () async {
    final gate=Completer<void>();final started=Completer<void>();
    var calls=0;
    final api=ApiService(baseUrl:'https://example.test',client:MockClient((req) async {
      calls++;if(calls==1){started.complete();await gate.future;}
      return http.Response('{}',200);
    }));
    api.cacheScope='user:a';final pending=api.getFeed(country:'IN');await started.future;
    await api.clearUserCache();gate.complete();await pending;
    await api.getFeed(country:'IN');expect(calls,2);
  });
}
