import 'pro_screen.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../state/music_controller.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  final MusicController controller;

  const ProfileScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final auth = controller.authService;
    final user = auth.currentUser;
    final isLoggedIn = auth.isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Account & Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isLoggedIn ? (user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U') : 'M',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn ? (user?.name ?? 'Viper Member') : 'Guest Listener',
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLoggedIn ? (user?.email ?? '') : 'Sign in to sync cloud playlists & history',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primaryRed, width: 0.6),
                        ),
                        child: Text(
                          isLoggedIn ? 'MEMBER' : 'FREE TIER',
                          style: const TextStyle(color: AppColors.primaryRed, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sign In Action if not logged in
          if (!isLoggedIn)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => AuthScreen(authService: auth),
                      fullscreenDialog: true,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Sign In or Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),

          ListTile(leading: const Icon(Icons.workspace_premium),title: const Text('Music Pro'),
            subtitle: const Text('Plans and promo redemption · Annual includes MovieFlix'),
            trailing: const Icon(Icons.chevron_right),onTap:()=>Navigator.of(context).push(MaterialPageRoute(
              builder:(_)=>ProScreen(controller:controller)))),
          const SizedBox(height:16),
          // User Statistics Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Playlists', '${controller.userPlaylists.length}'),
                _buildStatColumn('Downloads', '${controller.downloads.downloadedSongs.length}'),
                _buildStatColumn('Mixes', '${controller.recommendedMixes.length}'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Audio Quality & App Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.high_quality_rounded, color: Colors.greenAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Audio & Streaming Quality', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPreferenceRow('Streaming Bitrate', '320 kbps (Lossless Hi-Fi)'),
                _buildPreferenceRow('Audio Codec', 'Viper Audio Stream'),
                _buildPreferenceRow('Equalizer', 'Viper Dynamic Clarity'),
                _buildPreferenceRow('App Version', '2.0.0 (Production)'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Settings / Logout Options
          if (isLoggedIn)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.6),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.primaryRed),
                title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Sign out of this device', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out successfully')),
                    );
                  }
                },
              ),
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      ],
    );
  }

  Widget _buildPreferenceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
