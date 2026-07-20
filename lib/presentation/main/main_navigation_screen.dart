import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/home_screen.dart';
import '../map/map_screen.dart';
import '../time_together/time_together_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';
import 'nav_controller.dart';

class MainTabView extends StatelessWidget {
  const MainTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    final screens = <Widget>[
      const HomeScreen(),
      const MapScreen(),
      const TimeTogetherScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];
    return IndexedStack(index: nav.currentIndex, children: screens);
  }
}
