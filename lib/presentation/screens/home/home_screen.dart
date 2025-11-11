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

// Global key para acceder al HomeScreen desde otras pantallas
final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends StatefulWidget {
  /// The currently selected index in the sidebar
  final int selectedIndex;

  /// Callback when a sidebar item is selected
  final void Function(int) onNavigate;

  /// The child widget to display in the main content area
  final Widget child;

  const HomeScreen({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
    required this.child,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late SidebarXController _controller;
  final _key = GlobalKey<ScaffoldState>();
  bool _isProgrammaticChange = false;

  @override
  void initState() {
    super.initState();
    _controller = SidebarXController(
      selectedIndex: widget.selectedIndex,
      extended: true,
    );

    // Listen to sidebar selection changes to close drawer on mobile
    _controller.addListener(() {
      if (_isMobile(context) && _key.currentState?.isDrawerOpen == true) {
        Navigator.of(context).pop();
      }
      // Only call navigation callback when the change is from user interaction
      // Skip if the change is programmatic (from didUpdateWidget)
      if (!_isProgrammaticChange) {
        widget.onNavigate(_controller.selectedIndex);
      }
    });

    // Trigger automatic sync when user logs in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncBloc>().add(AutoSync());
    });
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller when selectedIndex changes from outside
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Set flag to prevent listener from triggering navigation
          _isProgrammaticChange = true;
          _controller.selectIndex(widget.selectedIndex);
          // Reset flag after a brief delay to allow listener to complete
          Future.microtask(() => _isProgrammaticChange = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
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
      case 8:
        return 'Audit History';
      case 9:
        return 'Settings';
      default:
        return 'Dashboard';
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
            icon: Icons.history,
            label: 'Audit History',
          ),
          SidebarXItem(
            icon: Icons.settings,
            label: 'Settings',
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
      child: widget.child,
    );
  }
}
