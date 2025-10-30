import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/statistics_service.dart';
import '../../../domain/models/dashboard_metrics.dart';
import '../../blocs/sync/sync_bloc.dart';
import '../../blocs/sync/sync_state.dart';
import '../product/product_form_screen.dart';
import '../output/output_form_screen.dart';
import '../product_entry/product_entry_form_screen.dart';

class HomeContent extends StatefulWidget {
  final Function(int) onNavigate;

  const HomeContent({super.key, required this.onNavigate});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _statisticsService = sl<StatisticsService>();
  DashboardMetrics? _metrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load metrics after a short delay to ensure sync has started
    Future.delayed(const Duration(milliseconds: 500), _loadMetrics);
  }

  Future<void> _loadMetrics() async {
    try {
      final metrics = await _statisticsService.getDashboardMetrics();
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _metrics = DashboardMetrics.empty();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return BlocListener<SyncBloc, SyncState>(
      listener: (context, state) {
        // Reload metrics after successful sync
        if (state is SyncSuccess) {
          _loadMetrics();
        }
      },
      child: RefreshIndicator(
        onRefresh: _loadMetrics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Welcome Header
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Overview of your business',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Today's Metrics
              _buildTodayMetrics(context, currencyFormat),
              const SizedBox(height: 12),

              // Main Metrics Grid
              _buildMetricsGrid(context, currencyFormat),
              const SizedBox(height: 16),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _buildQuickActions(context),
            ],
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayMetrics(BuildContext context, NumberFormat currencyFormat) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Today',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(_metrics!.todayRevenue),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sales',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_metrics!.todaySales}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, NumberFormat currencyFormat) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : MediaQuery.of(context).size.width > 600 ? 3 : 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        _buildMetricCard(
          context,
          'Total Revenue',
          currencyFormat.format(_metrics!.totalRevenue),
          Icons.attach_money,
          Colors.green,
        ),
        _buildMetricCard(
          context,
          'Total Sales',
          '${_metrics!.totalSales}',
          Icons.shopping_cart,
          Colors.blue,
        ),
        _buildMetricCard(
          context,
          'Products',
          '${_metrics!.totalProducts}',
          Icons.inventory_2,
          Colors.orange,
        ),
        _buildMetricCard(
          context,
          'Low Stock',
          '${_metrics!.lowStockProducts}',
          Icons.warning,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        'New Sale',
        Icons.add_shopping_cart,
        Colors.blue,
        () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const OutputFormScreen(),
            ),
          );
        },
      ),
      _QuickAction(
        'Add Stock',
        Icons.inventory,
        Colors.teal,
        () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProductEntryFormScreen(),
            ),
          );
        },
      ),
      _QuickAction(
        'New Product',
        Icons.add_box,
        Colors.green,
        () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProductFormScreen(),
            ),
          );
        },
      ),
      _QuickAction(
        'Low Stock',
        Icons.warning_amber,
        Colors.orange,
        () => widget.onNavigate(2),
      ),
      _QuickAction(
        'View Reports',
        Icons.assessment,
        Colors.purple,
        () => widget.onNavigate(6),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : MediaQuery.of(context).size.width > 600 ? 3 : 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: action.onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, size: 32, color: action.color),
                  const SizedBox(height: 8),
                  Text(
                    action.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAction(this.title, this.icon, this.color, this.onTap);
}
