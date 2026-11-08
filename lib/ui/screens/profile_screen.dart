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
                          isLoggedIn ? 'VIP STREAMER' : 'FREE TIER',
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

          // Production Server Info Card
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
                    Icon(Icons.cloud_done_rounded, color: Colors.greenAccent, size: 18),
                    SizedBox(width: 8),
                    Text('AWS Production Backend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Runtime: Pure NextViper 1.0.0 (Apex)\nHost: AWS EC2 (34.232.210.74)\nSecurity: TLS 1.3 / Let\'s Encrypt / PBKDF2 Hashing\nAlgorithm: Intelligent Hybrid Recommendation Engine',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, height: 1.5),
                ),
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
}
