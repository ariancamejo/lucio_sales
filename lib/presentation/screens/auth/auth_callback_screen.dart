import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Screen that handles OAuth callback from providers like Google Sign-In.
/// This screen is displayed briefly while Supabase processes the authentication
/// token from the URL parameters.
class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    // Give Supabase a moment to process the auth callback
    // Supabase automatically processes the URL parameters for OAuth
    // After a short delay, redirect to home
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        // The _AuthChangeNotifier will have detected the auth state change by now
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Completing sign in...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
