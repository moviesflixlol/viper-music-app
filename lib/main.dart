import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/colors.dart';
import 'services/api_service.dart';
import 'state/music_controller.dart';
import 'ui/screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style (transparent dark status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ViperMusicApp());
}

class ViperMusicApp extends StatefulWidget {
  const ViperMusicApp({super.key});

  @override
  State<ViperMusicApp> createState() => _ViperMusicAppState();
}

class _ViperMusicAppState extends State<ViperMusicApp> {
  late final ApiService _apiService;
  late final MusicController _controller;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _controller = MusicController(apiService: _apiService);
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
          home: MainNavigationScreen(controller: _controller),
        );
      },
    );
  }
}
