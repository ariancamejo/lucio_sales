import 'package:flutter/material.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/auth_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = sl<AuthService>();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading only if we're actively waiting (not the initial state)
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Use current data from snapshot, or fall back to currentUser if no events yet
        final user = snapshot.hasData ? snapshot.data : authService.currentUser;

        if (user != null) {
          return HomeScreen(key: homeScreenKey);
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
