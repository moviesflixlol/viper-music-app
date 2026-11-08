import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../state/music_controller.dart';
import '../components/mini_player.dart';
import 'downloads_screen.dart';
import 'feed_screen.dart';
import 'full_player_screen.dart';
import 'search_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  final MusicController controller;

  const MainNavigationScreen({super.key, required this.controller});

  void _openFullPlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FullPlayerScreen(controller: controller),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = controller.player;
    final currentSong = player.currentSong;

    final screens = [
      FeedScreen(controller: controller),
      SearchScreen(controller: controller),
      DownloadsScreen(controller: controller),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Active Screen Tab
          IndexedStack(
            index: controller.selectedTabIndex,
            children: screens,
          ),

          // Floating Sticky Mini Player above Bottom Bar
          if (currentSong != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(
                song: currentSong,
                state: player.state,
                position: player.position,
                duration: player.duration,
                onTogglePlay: player.togglePlayPause,
                onNext: player.skipNext,
                onTap: () => _openFullPlayer(context),
              ),
            ),
        ],
      ),

      // Minimalist Netflix Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
        ),
        child: BottomNavigationBar(
          currentIndex: controller.selectedTabIndex,
          onTap: (index) => controller.setTab(index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primaryRed,
          unselectedItemColor: AppColors.iconUnselected,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              activeIcon: Icon(Icons.home_filled, color: AppColors.primaryRed),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded, color: AppColors.primaryRed),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.file_download_outlined),
              activeIcon: Icon(Icons.file_download_rounded, color: AppColors.primaryRed),
              label: 'Downloads',
            ),
          ],
        ),
      ),
    );
  }
}
