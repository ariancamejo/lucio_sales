import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/database/seed_data.dart';
import '../../../core/utils/error_messages.dart';
import '../../../resources/app_images.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = sl<AuthService>();
      final user = await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (user != null && mounted) {
        // Seed default data for new users (only on native platforms)
        if (PlatformInfo.isNative) {
          try {
            final seeder = sl<DatabaseSeeder>();
            await seeder.seedAll(user.id);
          } catch (e) {
            // Ignore seed errors - data may already exist
            print('Seed error (safe to ignore): $e');
          }
        }

        // go_router will automatically redirect to /home based on auth state
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessages.getAuthErrorMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authService = sl<AuthService>();
      await authService.signInWithGoogle();

      // Seed default data for new users (only on native platforms)
      final user = authService.currentUser;
      if (user != null && PlatformInfo.isNative) {
        try {
          final seeder = sl<DatabaseSeeder>();
          await seeder.seedAll(user.id);
        } catch (e) {
          // Ignore seed errors - data may already exist
          print('Seed error (safe to ignore): $e');
        }
      }

      // The auth state change listener will handle navigation
      // So we don't need to manually navigate here
    } catch (e) {
      print('🔴 Google Sign-In Error: $e');

      // Wait a moment to check if auth actually succeeded
      await Future.delayed(const Duration(milliseconds: 1000));

      final authService = sl<AuthService>();
      final isAuthenticated = authService.currentUser != null;

      // Seed default data if authenticated (only on native platforms)
      if (isAuthenticated && PlatformInfo.isNative) {
        final user = authService.currentUser;
        if (user != null) {
          try {
            final seeder = sl<DatabaseSeeder>();
            await seeder.seedAll(user.id);
          } catch (e) {
            // Ignore seed errors
            print('Seed error (safe to ignore): $e');
          }
        }
      }

      // Only show error if not authenticated and not a known false positive
      final isFalsePositive = e.toString().contains('popup_closed') ||
          e.toString().contains('Error while launching') ||
          e.toString().contains('PlatformException');

      if (mounted && !isAuthenticated && !isFalsePositive) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessages.getAuthErrorMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      } else if (isAuthenticated) {
        print('✅ Google Sign-In succeeded despite error');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

          if (isDesktop || isTablet) {
            // Split screen layout for tablet and desktop
            return Row(
              children: [
                // Left side - Branding
                Expanded(
                  flex: isDesktop ? 5 : 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            AppImages.logo,
                            width: isDesktop ? 200 : 150,
                            height: isDesktop ? 200 : 150,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Lucio Sales',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              'Manage your inventory with ease',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Right side - Login Form
                Expanded(
                  flex: isDesktop ? 5 : 6,
                  child: _buildLoginForm(context, maxWidth: 450),
                ),
              ],
            );
          } else {
            // Mobile layout - single column
            return _buildLoginForm(context);
          }
        },
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, {double? maxWidth}) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? double.infinity,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Show logo only on mobile
                  if (maxWidth == null) ...[
                    Center(
                      child: SvgPicture.asset(
                        AppImages.logo,
                        width: 120,
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Lucio Sales',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (maxWidth != null) ...[
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'Sign in to continue',
                    textAlign: maxWidth == null ? TextAlign.center : TextAlign.left,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : () => context.go('/forgot-password'),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    icon: Image.network(
                      'https://www.google.com/favicon.ico',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.g_mobiledata, size: 24);
                      },
                    ),
                    label: const Text('Sign in with Google'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                    child: const Text("Don't have an account? Sign Up"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
