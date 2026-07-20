import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../main/app_shell.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    debugPrint('AuthWrapper status: $status');

    switch (status) {
      case AuthStatus.authenticated:
        return const AppShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.unknown:
        return const _SplashLoading();
    }
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF5F8),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 80, color: Color(0xFFE8547C)),
              const SizedBox(height: 20),
              Text(
                KhmerText.appName,
                style: const TextStyle(fontSize: 24, color: Color(0xFFE8547C)),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: Color(0xFFE8547C)),
            ],
          ),
        ),
      ),
    );
  }
}
