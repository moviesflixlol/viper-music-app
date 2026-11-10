import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viper_music/models/user.dart';
import 'package:viper_music/services/api_service.dart';
import 'package:viper_music/services/auth_service.dart';

class SessionApi extends ApiService {
  Future<UserModel?> Function(String, Future<void> Function()?) verify;
  SessionApi(this.verify);

  @override
  Future<UserModel?> getMe(String token, {Future<void> Function()? onUnauthorized}) =>
      verify(token, onUnauthorized);

  @override
  Future<Map<String, dynamic>> login({required String email, required String password}) async => {
        'success': true,
        'token': 'new-test-session',
        'user': const UserModel(id: 'new-user', email: 'new@example.test', name: 'New user'),
      };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'restored-test-session',
      'auth_user': jsonEncode({'id': 'old-user', 'email': 'old@example.test', 'name': 'Old user'}),
    });
  });

  test('a rejected restored session is removed from memory and preferences', () async {
    final verified = Completer<void>();
    final api = SessionApi((_, unauthorized) async {
      await unauthorized!();
      verified.complete();
      return null;
    });
    final auth = AuthService(apiService: api);
    await auth.initialize();
    await verified.future;
    expect(auth.isLoggedIn, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull);
    expect(prefs.getString('auth_user'), isNull);
    auth.dispose();
  });

  test('a transient profile failure does not erase the stored session', () async {
    final auth = AuthService(apiService: SessionApi((_, __) async => null));
    await auth.initialize();
    await Future<void>.delayed(Duration.zero);
    expect(auth.token, 'restored-test-session');
    auth.dispose();
  });

  test('an old background rejection cannot log out a newer login', () async {
    final proceed = Completer<void>();
    final verified = Completer<void>();
    final auth = AuthService(apiService: SessionApi((_, unauthorized) async {
      await proceed.future;
      await unauthorized!();
      verified.complete();
      return null;
    }));
    await auth.initialize();
    await auth.login(email: 'new@example.test', password: 'test-password');
    proceed.complete();
    await verified.future;
    expect(auth.token, 'new-test-session');
    expect(auth.currentUser?.id, 'new-user');
    auth.dispose();
  });
}
