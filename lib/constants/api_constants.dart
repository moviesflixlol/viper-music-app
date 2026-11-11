class ApiConstants {
  ApiConstants._();

  /// Default live NextViper music backend deployed on AWS EC2
  static const String defaultBaseUrl = 'https://music.movieflix.lol';
  static const String directHttpUrl = 'http://34.232.210.74:8080';
  static const String emulatorUrl = 'http://10.0.2.2:8080';

  static const String healthEndpoint = '/health';
  static const String searchEndpoint = '/api/search';
  static const String resolveEndpoint = '/api/resolve';

  // Auth Endpoints
  static const String registerEndpoint = '/api/auth/register';
  static const String verifyEmailEndpoint = '/api/auth/verify-email';
  static const String loginEndpoint = '/api/auth/login';
  static const String meEndpoint = '/api/auth/me';
  static const String forgotPasswordEndpoint = '/api/auth/forgot-password';
  static const String resetPasswordEndpoint = '/api/auth/reset-password';
  static const String resendCodeEndpoint = '/api/auth/resend-code';

  // Playlist Endpoints
  static const String playlistsEndpoint = '/api/playlists';
  static const String saveMixEndpoint = '/api/playlists/save-mix';

  // Recommendation & Telemetry Endpoints
  static const String feedEndpoint = '/api/recommendations/feed';
  static const String telemetryEventEndpoint = '/api/recommendations/event';
}
