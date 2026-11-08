class ApiConstants {
  ApiConstants._();

  /// Default live NextViper music backend deployed on AWS EC2
  /// Supports both HTTPS (via Let's Encrypt / sslip.io) for web browsers and HTTP for mobile.
  static const String defaultBaseUrl = 'https://34-232-210-74.sslip.io';
  static const String directHttpUrl = 'http://34.232.210.74:8080';
  static const String emulatorUrl = 'http://10.0.2.2:8080';

  static const String healthEndpoint = '/health';
  static const String searchEndpoint = '/api/search';
  static const String resolveEndpoint = '/api/resolve';
}
