import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/image_cache.dart';
import '../auth/auth_provider.dart';
import '../notes/notes_screen.dart';
import '../memories/memories_screen.dart';
import '../gallery/gallery_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';
import '../debug/debug_screen.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onNavigateHome;
  const AppDrawer({super.key, required this.onNavigateHome});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final navKey = context.read<GlobalKey<NavigatorState>>();

    void push(Widget page) {
      Navigator.pop(context);
      navKey.currentState?.push(MaterialPageRoute(builder: (_) => page));
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.heroGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    backgroundImage: (user != null && user.profileImageUrl.isNotEmpty)
                        ? cachedMemoryImage(user.profileImageUrl)
                        : null,
                    child: (user == null || user.profileImageUrl.isEmpty)
                        ? const Icon(Icons.person, size: 38, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'KantumruyPro'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'KantumruyPro'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    label: KhmerText.drawerHome,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateHome();
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.note_alt_outlined,
                    label: KhmerText.drawerNotes,
                    onTap: () => push(const NotesScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.photo_album_outlined,
                    label: KhmerText.drawerMemories,
                    onTap: () => push(const MemoriesScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.collections_outlined,
                    label: KhmerText.drawerGallery,
                    onTap: () => push(const GalleryScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: KhmerText.drawerSettings,
                    onTap: () => push(const SettingsScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    label: KhmerText.drawerAbout,
                    onTap: () => push(const AboutScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.bug_report_outlined,
                    label: 'Debug',
                    onTap: () => push(const DebugScreen()),
                  ),
                  const Divider(height: 24, indent: 20, endIndent: 20),
                  _DrawerItem(
                    icon: Icons.logout,
                    label: KhmerText.drawerLogout,
                    color: AppColors.error,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(KhmerText.drawerLogout, style: TextStyle(fontFamily: 'KantumruyPro')),
        content: const Text(KhmerText.logoutConfirm, style: TextStyle(fontFamily: 'KantumruyPro')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(KhmerText.cancel, style: TextStyle(fontFamily: 'KantumruyPro')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<AuthProvider>().logout();
            },
            child: const Text(
              KhmerText.confirm,
              style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        label,
        style: TextStyle(fontFamily: 'KantumruyPro', color: color ?? AppColors.textDark, fontSize: 15),
      ),
      onTap: onTap,
    );
  }
}
