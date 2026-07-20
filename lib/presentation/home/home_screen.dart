import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/romantic_card.dart';
import '../auth/auth_provider.dart';
import '../main/nav_controller.dart';
import '../notes/notes_screen.dart';
import '../memories/memories_screen.dart';
import '../gallery/gallery_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 210,
          pinned: true,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => context.read<GlobalKey<ScaffoldState>>().currentState?.openDrawer(),
          ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.heroGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${KhmerText.homeGreeting}, ${user?.name ?? ''} 💕',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'KantumruyPro',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${KhmerText.homeTogetherSince} ${DateFormat('dd/MM/yyyy').format(AppConstants.relationshipStartDate)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: 'KantumruyPro',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TimeCounters(),
                  const SizedBox(height: 28),
                  Text(
                    KhmerText.homeQuickAccess,
                    style: TextStyle(fontSize: 17, color: AppColors.textDark, fontFamily: 'KantumruyPro'),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.5,
                    children: [
                      _QuickCard(
                        icon: Icons.chat_bubble_outline,
                        label: KhmerText.navMessages,
                        onTap: () => context.read<NavController>().goToTab(3),
                      ),
                      _QuickCard(
                        icon: Icons.map_outlined,
                        label: KhmerText.navMap,
                        onTap: () => context.read<NavController>().goToTab(1),
                      ),
                      _QuickCard(
                        icon: Icons.note_alt_outlined,
                        label: KhmerText.drawerNotes,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen())),
                      ),
                      _QuickCard(
                        icon: Icons.photo_album_outlined,
                        label: KhmerText.drawerMemories,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoriesScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    KhmerText.homeOurStory,
                    style: TextStyle(fontSize: 17, color: AppColors.textDark, fontFamily: 'KantumruyPro'),
                  ),
                  const SizedBox(height: 14),
                  RomanticCard(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GalleryScreen())),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                KhmerText.galleryTitle,
                                style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textDark, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'មើលរូបភាពទាំងអស់របស់អ្នកទាំងពីរនាក់',
                                style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textLight, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.textLight),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeCounters extends StatefulWidget {
  const _TimeCounters();

  @override
  State<_TimeCounters> createState() => _TimeCountersState();
}

class _TimeCountersState extends State<_TimeCounters> {
  Timer? _timer;
  int _days = 0;
  int _anniversaryDays = 0;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    final start = AppConstants.relationshipStartDate;
    var nextAnniversary = DateTime(now.year, start.month, start.day);
    if (nextAnniversary.isBefore(now)) {
      nextAnniversary = DateTime(now.year + 1, start.month, start.day);
    }
    setState(() {
      _days = now.difference(start).inDays;
      _anniversaryDays = nextAnniversary.difference(now).inDays;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RomanticCard(
            gradient: const LinearGradient(colors: AppColors.softGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.favorite, color: AppColors.primary),
                const SizedBox(height: 10),
                Text(
                  '$_days',
                  style: const TextStyle(
                    fontSize: 28,
                    color: AppColors.primaryDark,
                    fontFamily: 'KantumruyPro',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  KhmerText.homeDaysTogether,
                  style: TextStyle(fontSize: 13, color: AppColors.textLight, fontFamily: 'KantumruyPro'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: RomanticCard(
            gradient: const LinearGradient(colors: AppColors.softGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cake_outlined, color: AppColors.primary),
                const SizedBox(height: 10),
                Text(
                  '$_anniversaryDays',
                  style: const TextStyle(
                    fontSize: 28,
                    color: AppColors.primaryDark,
                    fontFamily: 'KantumruyPro',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  KhmerText.homeNextAnniversary,
                  style: TextStyle(fontSize: 13, color: AppColors.textLight, fontFamily: 'KantumruyPro'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return RomanticCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textDark, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

