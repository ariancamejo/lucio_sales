import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sidebarx/sidebarx.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/auth_service.dart';
import '../../blocs/sync/sync_bloc.dart';
import '../../blocs/sync/sync_event.dart';
import '../../blocs/sync/sync_state.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../blocs/theme/theme_event.dart';
import '../../blocs/theme/theme_state.dart';
import '../../blocs/measurement_unit/measurement_unit_bloc.dart';
import '../../blocs/measurement_unit/measurement_unit_event.dart';
import '../../blocs/output_type/output_type_bloc.dart';
import '../../blocs/output_type/output_type_event.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product_entry/product_entry_bloc.dart';
import '../../blocs/product_entry/product_entry_event.dart';
import '../../blocs/output/output_bloc.dart';
import '../../blocs/output/output_event.dart';
import '../measurement_unit/measurement_unit_list_screen.dart';
import '../product/product_list_screen.dart';
import '../product_entry/product_entry_list_screen.dart';
import '../output_type/output_type_list_screen.dart';
import '../output/output_list_screen.dart';
import '../auth/login_screen.dart';
import '../reports/sales_reports_screen.dart';
import '../reports/ipv_report_screen.dart';
import 'home_content.dart';

// Global key para acceder al HomeScreen desde otras pantallas
final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();

  // Método público para navegar a ProductEntry con filtro
  void navigateToProductEntryWithFilter(String productId, String productName) {
    // Cambiar al tab de ProductEntry (índice 3)
    _controller.selectIndex(3);
    // Esperar un frame para que se renderice la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      productEntryListKey.currentState?.applyProductFilter(productId, productName);
    });
  }

  @override
  void initState() {
    super.initState();
    // Listen to sidebar selection changes to close drawer on mobile
    _controller.addListener(() {
      if (_isMobile(context) && _key.currentState?.isDrawerOpen == true) {
        Navigator.of(context).pop();
      }
    });

    // Trigger automatic sync when user logs in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncBloc>().add(AutoSync());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  void _onItemSelected(int index) {
    _controller.selectIndex(index);
    // Close drawer only on mobile
    if (_isMobile(context) && _key.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Lucio Sales';
      case 1:
        return 'Measurement Units';
      case 2:
        return 'Products';
      case 3:
        return 'Stock Entries';
      case 4:
        return 'Output Types';
      case 5:
        return 'Outputs';
      case 6:
        return 'Sales Reports';
      case 7:
        return 'IPV Report';
      default:
        return 'Lucio Sales';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          key: _key,
          appBar: AppBar(
            title: Text(_getPageTitle(_controller.selectedIndex)),
            leading: isMobile
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _key.currentState?.openDrawer();
                    },
                  )
                : null,
            automaticallyImplyLeading: isMobile,
            actions: [
          BlocBuilder<SyncBloc, SyncState>(
            builder: (context, state) {
              if (state is SyncInProgress) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () {
                  context.read<SyncBloc>().add(StartSync());
                },
                tooltip: 'Sync data',
              );
            },
          ),
        ],
          ),
          drawer: isMobile ? _buildSidebar(context) : null,
          body: isMobile
              ? _buildBody()
              : Row(
                  children: [
                    _buildSidebar(context),
                    Expanded(child: _buildBody()),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return SidebarX(
        controller: _controller,
        theme: SidebarXTheme(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          textStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          selectedTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
          hoverTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          itemTextPadding: const EdgeInsets.only(left: 24),
          selectedItemTextPadding: const EdgeInsets.only(left: 24),
          itemDecoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          selectedItemDecoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          itemMargin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            size: 20,
          ),
          selectedIconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.onPrimary,
            size: 20,
          ),
        ),
        extendedTheme: const SidebarXTheme(
          width: 250,
          padding: EdgeInsets.all(16),
        ),
        headerBuilder: (context, extended) {
          final authService = sl<AuthService>();
          final user = authService.currentUser;

          return SafeArea(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (extended) ...[
                        Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                // Telegram-style theme toggle icon in top-right corner
                Positioned(
                  top: 8,
                  right: 8,
                  child: BlocBuilder<ThemeBloc, ThemeState>(
                    builder: (context, state) {
                      final isDark = state.themeMode == ThemeMode.dark;
                      return IconButton(
                        icon: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          size: 20,
                        ),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {
                          context.read<ThemeBloc>().add(const ToggleTheme());
                        },
                        tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        items: const [
          SidebarXItem(
            icon: Icons.home,
            label: 'Home',
          ),
          SidebarXItem(
            icon: Icons.straighten,
            label: 'Measurement Units',
          ),
          SidebarXItem(
            icon: Icons.inventory_2,
            label: 'Products',
          ),
          SidebarXItem(
            icon: Icons.add_shopping_cart,
            label: 'Stock Entries',
          ),
          SidebarXItem(
            icon: Icons.category,
            label: 'Output Types',
          ),
          SidebarXItem(
            icon: Icons.output,
            label: 'Outputs',
          ),
          SidebarXItem(
            icon: Icons.bar_chart,
            label: 'Sales Reports',
          ),
          SidebarXItem(
            icon: Icons.analytics,
            label: 'IPV Report',
          ),
          SidebarXItem(
            icon: Icons.logout,
            label: 'Logout',
          ),
        ],
    );
  }

  Widget _buildBody() {
    return BlocListener<SyncBloc, SyncState>(
        listener: (context, state) {
          if (state is SyncSuccess) {
            // After successful sync, load data in all blocs
            context.read<MeasurementUnitBloc>().add(LoadMeasurementUnits());
            context.read<OutputTypeBloc>().add(LoadOutputTypes());
            context.read<ProductBloc>().add(const LoadProducts());
            context.read<ProductEntryBloc>().add(LoadProductEntries());
            context.read<OutputBloc>().add(LoadOutputs());

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is SyncFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return _getScreenForIndex(_controller.selectedIndex);
          },
        ),
    );
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const MeasurementUnitListScreen();
      case 2:
        return const ProductListScreen();
      case 3:
        return ProductEntryListScreen(key: productEntryListKey);
      case 4:
        return const OutputTypeListScreen();
      case 5:
        return const OutputListScreen();
      case 6:
        return const SalesReportsScreen();
      case 7:
        return const IpvReportScreen();
      case 8:
        return _buildLogoutScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return HomeContent(onNavigate: _onItemSelected);
  }

  Widget _buildLogoutScreen() {
    final authService = sl<AuthService>();
    final user = authService.currentUser;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              user?.name.substring(0, 1).toUpperCase() ?? 'U',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'User',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
