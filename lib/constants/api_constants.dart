class ApiConstants {
  ApiConstants._();

  /// Default URL for NextViper music backend
  /// For Android emulator use 10.0.2.2, for real devices use your LAN or AWS server IP.
  static const String defaultBaseUrl = 'http://10.0.2.2:8080';

  static const String healthEndpoint = '/health';
  static const String searchEndpoint = '/api/search';
  static const String resolveEndpoint = '/api/resolve';
}
