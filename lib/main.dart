import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/app_constants.dart';
import 'presentation/auth/auth_provider.dart';
import 'presentation/auth/auth_wrapper.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('APP STARTED');
  NotificationService.init();
  runApp(const LoveApp());
}

class LoveApp extends StatefulWidget {
  const LoveApp({super.key});
  @override
  State<LoveApp> createState() => _LoveAppState();
}

class _LoveAppState extends State<LoveApp> {
  Future<void>? _firebaseInit;

  @override
  void initState() {
    super.initState();
    _firebaseInit = _initApp();
  }

  Future<void> _initApp() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final fbUser = FirebaseAuth.instance.currentUser;
    debugPrint('Firebase initialized — currentUser: uid=${fbUser?.uid ?? 'null'} email=${fbUser?.email ?? 'null'}');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _firebaseInit,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Color(0xFFFFF5F8),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, size: 80, color: Color(0xFFE8547C)),
                    SizedBox(height: 20),
                    Text(
                      KhmerText.appName,
                      style: TextStyle(fontSize: 24, color: Color(0xFFE8547C)),
                    ),
                    SizedBox(height: 16),
                    CircularProgressIndicator(color: Color(0xFFE8547C)),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFFFFF5F8),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Color(0xFFE8547C)),
                      const SizedBox(height: 20),
                      const Text(
                        'មិនអាចភ្ជាប់ទៅ Firebase បានទេ',
                        style: TextStyle(fontSize: 18, color: Color(0xFF3A2A32)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _firebaseInit = _initApp();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8547C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text('ព្យាយាមម្តងទៀត'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
            ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => MaterialApp(
              title: KhmerText.appName,
              debugShowCheckedModeBanner: false,
              theme: themeProvider.theme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              home: const AuthWrapper(),
            ),
          ),
        );
      },
    );
  }
}
