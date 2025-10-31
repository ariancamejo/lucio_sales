import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/home/home_content.dart';
import '../../presentation/screens/measurement_unit/measurement_unit_list_screen.dart';
import '../../presentation/screens/measurement_unit/measurement_unit_form_screen.dart';
import '../../presentation/screens/product/product_list_screen.dart';
import '../../presentation/screens/product/product_form_screen.dart';
import '../../presentation/screens/product_entry/product_entry_list_screen.dart';
import '../../presentation/screens/product_entry/product_entry_form_screen.dart';
import '../../presentation/screens/output_type/output_type_list_screen.dart';
import '../../presentation/screens/output_type/output_type_form_screen.dart';
import '../../presentation/screens/output/output_list_screen.dart';
import '../../presentation/screens/output/output_form_screen.dart';
import '../../presentation/screens/reports/sales_reports_screen.dart';
import '../../presentation/screens/reports/ipv_report_screen.dart';
import '../../presentation/screens/audit/audit_history_screen.dart';
import '../di/injection_container.dart';
import '../services/auth_service.dart';

/// Router configuration for the entire application.
///
/// This uses go_router for declarative routing with the following features:
/// - Authentication guards (redirect to login if not authenticated)
/// - Nested routes within HomeScreen shell
/// - Deep linking support
/// - Type-safe route navigation
///
/// Route Structure:
/// - /login - Login screen (public)
/// - / - Home shell (requires authentication)
///   - /home - Home dashboard
///   - /measurement-units - Measurement units list
///     - /measurement-units/new - Create new unit
///     - /measurement-units/:id/edit - Edit unit
///   - /products - Products list
///     - /products/new - Create new product
///     - /products/:id/edit - Edit product
///   - /stock-entries - Stock entries list
///     - /stock-entries/new - Create new entry
///     - /stock-entries/:id/edit - Edit entry
///   - /output-types - Output types list
///     - /output-types/new - Create new type
///     - /output-types/:id/edit - Edit type
///   - /outputs - Outputs list
///     - /outputs/new - Create new output
///     - /outputs/:id/edit - Edit output
///   - /reports/sales - Sales reports
///   - /reports/ipv - IPV report
///   - /audit-history - Audit history
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Get the router configuration
  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    initialLocation: '/home',

    /// Redirect logic for authentication
    /// - If user is not authenticated, redirect to /login
    /// - If user is authenticated and on /login, redirect to /home
    redirect: (BuildContext context, GoRouterState state) {
      final authService = sl<AuthService>();
      final isAuthenticated = authService.currentUser != null;
      final isLoginRoute = state.matchedLocation == '/login';

      // Redirect to login if not authenticated and not already on login
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      // Redirect to home if authenticated and trying to access login
      if (isAuthenticated && isLoginRoute) {
        return '/home';
      }

      // No redirect needed
      return null;
    },

    /// Listen to auth state changes to trigger redirects
    refreshListenable: _AuthChangeNotifier(),

    routes: [
      // Public routes (no authentication required)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Shell route - wraps all authenticated routes with HomeScreen
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return HomeScreenShell(child: child);
        },
        routes: [
          // Home dashboard
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: HomeContent(
                onNavigate: (index) {
                  // Navigate to corresponding route based on index
                  switch (index) {
                    case 0:
                      context.go('/home');
                      break;
                    case 1:
                      context.go('/measurement-units');
                      break;
                    case 2:
                      context.go('/products');
                      break;
                    case 3:
                      context.go('/stock-entries');
                      break;
                    case 4:
                      context.go('/output-types');
                      break;
                    case 5:
                      context.go('/outputs');
                      break;
                    case 6:
                      context.go('/reports/sales');
                      break;
                    case 7:
                      context.go('/reports/ipv');
                      break;
                    case 8:
                      context.go('/audit-history');
                      break;
                  }
                },
              ),
            ),
          ),

          // Measurement Units routes
          GoRoute(
            path: '/measurement-units',
            name: 'measurement-units',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const MeasurementUnitListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'measurement-unit-new',
                builder: (context, state) => const MeasurementUnitFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'measurement-unit-edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MeasurementUnitFormScreen(measurementUnitId: id);
                },
              ),
            ],
          ),

          // Products routes
          GoRoute(
            path: '/products',
            name: 'products',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProductListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'product-new',
                builder: (context, state) => const ProductFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'product-edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ProductFormScreen(productId: id);
                },
              ),
            ],
          ),

          // Stock Entries routes
          GoRoute(
            path: '/stock-entries',
            name: 'stock-entries',
            pageBuilder: (context, state) {
              // Support for query parameters (product filter)
              final productId = state.uri.queryParameters['productId'];
              final productName = state.uri.queryParameters['productName'];

              return NoTransitionPage(
                key: state.pageKey,
                child: ProductEntryListScreen(
                  key: productEntryListKey,
                  initialProductIdFilter: productId,
                  initialProductName: productName,
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'new',
                name: 'stock-entry-new',
                builder: (context, state) {
                  // Support for pre-selected product
                  final productId = state.uri.queryParameters['productId'];
                  return ProductEntryFormScreen(preSelectedProductId: productId);
                },
              ),
              GoRoute(
                path: ':id/edit',
                name: 'stock-entry-edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ProductEntryFormScreen(entryId: id);
                },
              ),
            ],
          ),

          // Output Types routes
          GoRoute(
            path: '/output-types',
            name: 'output-types',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const OutputTypeListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'output-type-new',
                builder: (context, state) => const OutputTypeFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'output-type-edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return OutputTypeFormScreen(outputTypeId: id);
                },
              ),
            ],
          ),

          // Outputs routes
          GoRoute(
            path: '/outputs',
            name: 'outputs',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const OutputListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'output-new',
                builder: (context, state) => const OutputFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'output-edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return OutputFormScreen(outputId: id);
                },
              ),
            ],
          ),

          // Reports routes
          GoRoute(
            path: '/reports/sales',
            name: 'reports-sales',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SalesReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/reports/ipv',
            name: 'reports-ipv',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const IpvReportScreen(),
            ),
          ),

          // Audit History route
          GoRoute(
            path: '/audit-history',
            name: 'audit-history',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AuditHistoryScreen(),
            ),
          ),
        ],
      ),
    ],

    /// Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A custom ChangeNotifier that listens to auth state changes
/// and notifies go_router to re-evaluate redirects
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    final authService = sl<AuthService>();
    authService.authStateChanges.listen((_) {
      notifyListeners();
    });
  }
}

/// Shell wrapper for HomeScreen that provides the sidebar navigation
/// while allowing child routes to be displayed in the main content area
class HomeScreenShell extends StatefulWidget {
  final Widget child;

  const HomeScreenShell({
    super.key,
    required this.child,
  });

  @override
  State<HomeScreenShell> createState() => _HomeScreenShellState();
}

class _HomeScreenShellState extends State<HomeScreenShell> {
  /// Determine the selected index based on current route
  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/measurement-units')) return 1;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/stock-entries')) return 3;
    if (location.startsWith('/output-types')) return 4;
    if (location.startsWith('/outputs')) return 5;
    if (location.startsWith('/reports/sales')) return 6;
    if (location.startsWith('/reports/ipv')) return 7;
    if (location.startsWith('/audit-history')) return 8;

    return 0; // Default to home
  }

  /// Navigate to route based on sidebar index
  void _onNavigate(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/measurement-units');
        break;
      case 2:
        context.go('/products');
        break;
      case 3:
        context.go('/stock-entries');
        break;
      case 4:
        context.go('/output-types');
        break;
      case 5:
        context.go('/outputs');
        break;
      case 6:
        context.go('/reports/sales');
        break;
      case 7:
        context.go('/reports/ipv');
        break;
      case 8:
        context.go('/audit-history');
        break;
      case 9:
        // Logout - handled in HomeScreen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return HomeScreen(
      selectedIndex: selectedIndex,
      onNavigate: _onNavigate,
      child: widget.child,
    );
  }
}
