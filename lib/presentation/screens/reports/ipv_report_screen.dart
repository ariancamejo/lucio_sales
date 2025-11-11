import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/statistics_service.dart';
import '../../../core/utils/file_download.dart';
import '../../../domain/models/inventory_statistics.dart';


class IpvReportScreen extends StatefulWidget {
  const IpvReportScreen({super.key});

  @override
  State<IpvReportScreen> createState() => _IpvReportScreenState();
}

class _IpvReportScreenState extends State<IpvReportScreen> {
  late final StatisticsService _statisticsService;
  InventoryStatistics? _statistics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // StatisticsService now available on all platforms
    try {
      _statisticsService = sl<StatisticsService>();
      _loadStatistics();
    } catch (e) {
      // Service not available, set loading to false
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _statisticsService.getInventoryStatistics();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    if (_statistics == null) return;

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Inventory Report'];

      // Headers
      sheet.appendRow([
        TextCellValue('Inventory Performance & Value Report'),
      ]);
      sheet.appendRow([
        TextCellValue('Generated on: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}'),
      ]);
      sheet.appendRow([]);

      // Summary
      sheet.appendRow([TextCellValue('Summary')]);
      sheet.appendRow([TextCellValue('Total Inventory Value'), TextCellValue('\$${_statistics!.totalInventoryValue.toStringAsFixed(2)}')]);
      sheet.appendRow([TextCellValue('Total Products'), IntCellValue(_statistics!.totalProducts)]);
      sheet.appendRow([TextCellValue('Active Products'), IntCellValue(_statistics!.activeProducts)]);
      sheet.appendRow([TextCellValue('Low Stock Products'), IntCellValue(_statistics!.lowStockProducts)]);
      sheet.appendRow([]);

      // Top Value Products
      sheet.appendRow([TextCellValue('Top Value Products')]);
      sheet.appendRow([
        TextCellValue('Product'),
        TextCellValue('Code'),
        TextCellValue('Quantity'),
        TextCellValue('Cost'),
        TextCellValue('Total Value'),
      ]);
      for (final product in _statistics!.topValueProducts) {
        sheet.appendRow([
          TextCellValue(product.productName),
          TextCellValue(product.code),
          TextCellValue(product.quantity.toStringAsFixed(2)),
          TextCellValue('\$${product.cost.toStringAsFixed(2)}'),
          TextCellValue('\$${product.totalValue.toStringAsFixed(2)}'),
        ]);
      }
      sheet.appendRow([]);

      // Low Stock Items
      sheet.appendRow([TextCellValue('Low Stock Items')]);
      sheet.appendRow([
        TextCellValue('Product'),
        TextCellValue('Code'),
        TextCellValue('Current Stock'),
        TextCellValue('Days Since Last Sale'),
      ]);
      for (final product in _statistics!.lowStockItems) {
        sheet.appendRow([
          TextCellValue(product.productName),
          TextCellValue(product.code),
          TextCellValue(product.quantity.toStringAsFixed(2)),
          IntCellValue(product.daysSinceLastSale),
        ]);
      }

      // Encode Excel to bytes
      final excelBytes = excel.encode()!;

      // Generate default filename
      final defaultFileName = 'inventory_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      if (kIsWeb) {
        // For Web: Use browser download functionality
        downloadFile(excelBytes, defaultFileName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel file downloaded successfully!')),
          );
        }
      } else {
        // For Desktop/Mobile: Use file picker to let user choose location
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Excel File',
          fileName: defaultFileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (outputPath == null) {
          // User canceled the picker
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export canceled')),
            );
          }
          return;
        }

        // Write file to selected location
        final file = File(outputPath);
        await file.writeAsBytes(excelBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exported to: $outputPath')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Performance & Value'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _statistics != null ? _exportToExcel : null,
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _statistics == null
              ? const Center(child: Text('No data available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 12),
                      _buildTopValueChart(),
                      const SizedBox(height: 12),
                      _buildLowStockList(),
                      const SizedBox(height: 12),
                      _buildDeadStockList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Value',
              '\$${_statistics!.totalInventoryValue.toStringAsFixed(2)}',
              Icons.inventory,
              Colors.green,
            ),
            _buildStatCard(
              'Total Products',
              '${_statistics!.totalProducts}',
              Icons.category,
              Colors.blue,
            ),
            _buildStatCard(
              'Active',
              '${_statistics!.activeProducts}',
              Icons.check_circle,
              Colors.orange,
            ),
            _buildStatCard(
              'Low Stock',
              '${_statistics!.lowStockProducts}',
              Icons.warning,
              Colors.red,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(child: Padding(padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTopValueChart() {
    final topProducts = _statistics!.topValueProducts.take(5).toList();
    if (topProducts.isEmpty) {
      return Card(child: Padding(padding: const EdgeInsets.all(16),
        child: const Center(child: Text('No product data')),
      ),
      );
    }

    return Card(child: Padding(padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 5 Products by Value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < topProducts.length) {
                            final name = topProducts[value.toInt()].productName;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                name.length > 8 ? '${name.substring(0, 8)}...' : name,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: topProducts.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.totalValue,
                          color: Colors.green,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
    ),
    );
  }

  Widget _buildLowStockList() {
    if (_statistics!.lowStockItems.isEmpty) {
      return Card(child: Padding(padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'All products have sufficient stock',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
      );
    }

    return Card(child: Padding(padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Low Stock Items (${_statistics!.lowStockItems.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _statistics!.lowStockItems.take(10).length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = _statistics!.lowStockItems[index];
                return ListTile(
                  title: Text(product.productName),
                  subtitle: Text('Code: ${product.code}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Stock: ${product.quantity.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        'Last sale: ${product.daysSinceLastSale}d ago',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
    ),
    );
  }

  Widget _buildDeadStockList() {
    if (_statistics!.deadStockItems.isEmpty) {
      return Card(child: Padding(padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'No dead stock items',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
      );
    }

    return Card(child: Padding(padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_down, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dead Stock (No sales in 30+ days)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _statistics!.deadStockItems.take(10).length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = _statistics!.deadStockItems[index];
                return ListTile(
                  title: Text(product.productName),
                  subtitle: Text(
                    'Value: \$${product.totalValue.toStringAsFixed(2)} (${product.quantity.toStringAsFixed(1)} units)',
                  ),
                  trailing: Text(
                    '${product.daysSinceLastSale} days',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
    ),
    );
  }
}
