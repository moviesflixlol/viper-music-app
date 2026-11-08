import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../state/music_controller.dart';
import '../components/mini_player.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import 'playlists_screen.dart';
import 'profile_screen.dart';
import 'full_player_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final MusicController controller;

  const MainNavigationScreen({super.key, required this.controller});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.controller.selectedTabIndex);
    widget.controller.addListener(_syncPageWithController);
  }

  void _syncPageWithController() {
    if (_pageController.hasClients && _pageController.page?.round() != widget.controller.selectedTabIndex) {
      _pageController.animateToPage(
        widget.controller.selectedTabIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncPageWithController);
    _pageController.dispose();
    super.dispose();
  }

  void _openFullPlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FullPlayerScreen(controller: widget.controller),
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
    final controller = widget.controller;
    final player = controller.player;
    final currentSong = player.currentSong;
    final currentTab = controller.selectedTabIndex;

    final screens = [
      FeedScreen(controller: controller),
      SearchScreen(controller: controller),
      PlaylistsScreen(controller: controller),
      ProfileScreen(controller: controller),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Swipeable Screens PageView (Enables full horizontal swipe turning between screens)
          PageView(
            controller: _pageController,
            physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
            onPageChanged: (index) {
              controller.setTab(index);
            },
            children: screens,
          ),

          // 2. Floating Sticky Mini Player sitting directly above Floating Nav Bar
          if (currentSong != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 82,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MiniPlayer(
                  song: currentSong,
                  state: player.state,
                  position: player.position,
                  duration: player.duration,
                  onTogglePlay: player.togglePlayPause,
                  onNext: controller.skipNextWithTelemetry,
                  onTap: () => _openFullPlayer(context),
                ),
              ),
            ),

          // 3. Floating Capsule Bottom Navigation Bar (Spotify + Netflix hybrid)
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Center(
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xF0181818),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home_filled,
                        label: 'Home',
                        isActive: currentTab == 0,
                        onTap: () => controller.setTab(0),
                      ),
                      const SizedBox(width: 4),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.search_rounded,
                        label: 'Search',
                        isActive: currentTab == 1,
                        onTap: () => controller.setTab(1),
                      ),
                      const SizedBox(width: 4),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.library_music_rounded,
                        label: 'Library',
                        isActive: currentTab == 2,
                        onTap: () => controller.setTab(2),
                      ),
                      const SizedBox(width: 4),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Me',
                        isActive: currentTab == 3,
                        onTap: () => controller.setTab(3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    IconData? activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? (activeIcon ?? icon) : icon,
              color: isActive ? Colors.white : Colors.white60,
              size: 20,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
