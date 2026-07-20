import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import 'app_drawer.dart';
import 'nav_controller.dart';
import 'main_navigation_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final NavController _navController = NavController();

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _navigatorKey.currentState?.popUntil((route) => route.settings.name == 'home');
    _navController.goToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NavController>.value(value: _navController),
        Provider<GlobalKey<NavigatorState>>.value(value: _navigatorKey),
        Provider<GlobalKey<ScaffoldState>>.value(value: _scaffoldKey),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(onNavigateHome: () => _onTabTapped(0)),
        body: Navigator(
          key: _navigatorKey,
          initialRoute: 'home',
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (_) => const MainTabView(),
              settings: settings,
            );
          },
        ),
        bottomNavigationBar: Consumer<NavController>(
          builder: (context, nav, _) => BottomNavigationBar(
            currentIndex: nav.currentIndex,
            onTap: _onTabTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: KhmerText.navHome,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: KhmerText.navMap,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.hourglass_empty),
                activeIcon: Icon(Icons.hourglass_bottom),
                label: KhmerText.navTime,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: KhmerText.navMessages,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: KhmerText.navProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
