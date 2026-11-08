import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  final ApiService _apiService;
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;

  AuthService({required ApiService apiService}) : _apiService = apiService;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty && _currentUser != null;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_keyToken);
      final userJsonStr = prefs.getString(_keyUser);

      if (_token != null && _token!.isNotEmpty && userJsonStr != null) {
        final userMap = jsonDecode(userJsonStr) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userMap, token: _token!);

        // Background verify with server
        _apiService.getMe(_token!).then((verifiedUser) {
          if (verifiedUser != null) {
            _currentUser = verifiedUser;
            notifyListeners();
          }
        }).catchError((_) {});
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.login(email: email, password: password);
    _isLoading = false;

    if (result['success'] == true) {
      _token = result['token'] as String;
      _currentUser = result['user'] as UserModel;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, _token!);
      await prefs.setString(_keyUser, jsonEncode(_currentUser!.toJson()));

      notifyListeners();
      return {'success': true, 'verificationRequired': false};
    } else {
      notifyListeners();
      return {'success': false, 'error': result['error'] ?? 'Login failed'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String name = 'Viper User',
    List<String> interests = const [],
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.register(
      email: email,
      password: password,
      name: name,
      interests: interests,
    );
    _isLoading = false;

    if (result['success'] == true) {
      if (result['verificationRequired'] == true) {
        notifyListeners();
        return {
          'success': true,
          'verificationRequired': true,
          'email': email,
          'message': result['message'] ?? 'Verification code sent to your email',
        };
      }
      _token = result['token'] as String;
      _currentUser = result['user'] as UserModel;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, _token!);
      await prefs.setString(_keyUser, jsonEncode(_currentUser!.toJson()));

      notifyListeners();
      return {'success': true, 'verificationRequired': false};
    } else {
      notifyListeners();
      return {'success': false, 'error': result['error'] ?? 'Registration failed'};
    }
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.verifyEmail(email: email, code: code);
    _isLoading = false;

    if (result['success'] == true) {
      _token = result['token'] as String;
      _currentUser = result['user'] as UserModel;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, _token!);
      await prefs.setString(_keyUser, jsonEncode(_currentUser!.toJson()));

      notifyListeners();
      return {'success': true, 'verificationRequired': false};
    } else {
      notifyListeners();
      return {'success': false, 'error': result['error'] ?? 'Verification failed'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    _isLoading = true;
    notifyListeners();
    final result = await _apiService.forgotPassword(email: email);
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await _apiService.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> resendCode({
    required String email,
    String type = 'signup',
  }) async {
    return await _apiService.resendCode(email: email, type: type);
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } catch (_) {}
    notifyListeners();
  }
}
