import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/colors.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'state/music_controller.dart';
import 'ui/screens/main_navigation_screen.dart';
import 'ui/screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style (transparent dark status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final apiService = ApiService();
  await apiService.initialize();
  final authService = AuthService(apiService: apiService);
  await authService.initialize();

  runApp(ViperMusicApp(apiService: apiService, authService: authService));
}

class ViperMusicApp extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;

  const ViperMusicApp({
    super.key,
    required this.apiService,
    required this.authService,
  });

  @override
  State<ViperMusicApp> createState() => _ViperMusicAppState();
}

class _ViperMusicAppState extends State<ViperMusicApp> {
  late final MusicController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MusicController(
      apiService: widget.apiService,
      authService: widget.authService,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Viper Music',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.background,
            primaryColor: AppColors.primaryRed,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryRed,
              surface: AppColors.surface,
              background: AppColors.background,
            ),
            textTheme: GoogleFonts.interTextTheme(
              ThemeData.dark().textTheme,
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => MainNavigationScreen(controller: _controller),
            '/auth': (context) => AuthScreen(authService: widget.authService),
          },
        );
      },
    );
  }
}
