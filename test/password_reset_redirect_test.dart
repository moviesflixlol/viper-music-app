import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viper_music/services/api_service.dart';
import 'package:viper_music/services/auth_service.dart';
import 'package:viper_music/ui/screens/auth_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Forgot Password opens the MovieFlix reset page', (tester) async {
    String? destination;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch') destination = call.arguments['url'] as String?;
      return true;
    });
    final auth = AuthService(apiService: ApiService());
    await tester.pumpWidget(MaterialApp(home: AuthScreen(authService: auth)));
    await tester.ensureVisible(find.text('Forgot Password?'));
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    expect(destination, 'https://movieflix.lol/reset-password');
    expect(find.text('Enter Reset Code'), findsNothing);
    auth.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
