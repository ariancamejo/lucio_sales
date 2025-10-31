import 'package:flutter/material.dart';
import 'login_screen.dart';

/// Legacy AuthWrapper - No longer used.
/// Authentication is now handled by go_router's redirect logic.
/// This file is kept for backward compatibility but is not used in the app.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // This should never be called as go_router handles auth
    return const LoginScreen();
  }
}
