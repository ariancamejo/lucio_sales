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
import '../../../domain/models/sales_statistics.dart';


class SalesReportsScreen extends StatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  State<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends State<SalesReportsScreen> {
  final _statisticsService = sl<StatisticsService>();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  SalesStatistics? _statistics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _statisticsService.getSalesStatistics(
        startDate: _startDate,
        endDate: _endDate,
      );
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

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadStatistics();
    }
  }

  Future<void> _exportToExcel() async {
    if (_statistics == null) return;

    try {
      // Generate Excel content
      final excel = Excel.createExcel();
      final sheet = excel['Sales Report'];

      // Headers
      sheet.appendRow([
        TextCellValue('Period'),
        TextCellValue('${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}'),
      ]);
      sheet.appendRow([]);

      // Summary
      sheet.appendRow([TextCellValue('Summary')]);
      sheet.appendRow([TextCellValue('Total Revenue'), TextCellValue('\$${_statistics!.totalRevenue.toStringAsFixed(2)}')]);
      sheet.appendRow([TextCellValue('Total Sales'), IntCellValue(_statistics!.totalSales)]);
      sheet.appendRow([TextCellValue('Average Sale'), TextCellValue('\$${_statistics!.averageSaleValue.toStringAsFixed(2)}')]);
      sheet.appendRow([TextCellValue('Total Profit'), TextCellValue('\$${_statistics!.totalProfit.toStringAsFixed(2)}')]);
      sheet.appendRow([TextCellValue('Profit Margin'), TextCellValue('${_statistics!.profitMargin.toStringAsFixed(2)}%')]);
      sheet.appendRow([]);

      // Top Products
      sheet.appendRow([TextCellValue('Top Products')]);
      sheet.appendRow([
        TextCellValue('Product'),
        TextCellValue('Revenue'),
        TextCellValue('Quantity'),
        TextCellValue('Sales Count'),
      ]);
      for (final product in _statistics!.topProducts) {
        sheet.appendRow([
          TextCellValue(product.productName),
          TextCellValue('\$${product.totalRevenue.toStringAsFixed(2)}'),
          TextCellValue(product.totalQuantity.toStringAsFixed(2)),
          IntCellValue(product.salesCount),
        ]);
      }

      // Encode Excel to bytes
      final excelBytes = excel.encode()!;

      // Generate default filename
      final defaultFileName = 'sales_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

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
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Reports'),
        actions: [
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
                      _buildDateRangeSelector(),
                      const SizedBox(height: 12),
                      _buildSummaryCards(),
                      const SizedBox(height: 12),
                      _buildSalesTrendChart(),
                      const SizedBox(height: 12),
                      _buildTopProductsChart(),
                      const SizedBox(height: 12),
                      _buildSalesByTypeChart(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _selectDateRange,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
        children: [
          const Icon(Icons.calendar_today),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date Range',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit),
        ],
          ),
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
              'Total Revenue',
              '\$${_statistics!.totalRevenue.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.green,
            ),
            _buildStatCard(
              'Total Sales',
              '${_statistics!.totalSales}',
              Icons.shopping_cart,
              Colors.blue,
            ),
            _buildStatCard(
              'Avg Sale',
              '\$${_statistics!.averageSaleValue.toStringAsFixed(2)}',
              Icons.trending_up,
              Colors.orange,
            ),
            _buildStatCard(
              'Profit Margin',
              '${_statistics!.profitMargin.toStringAsFixed(1)}%',
              Icons.pie_chart,
              Colors.purple,
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

  Widget _buildSalesTrendChart() {
    if (_statistics!.dailySales.isEmpty) {
      return Card(child: Padding(padding: const EdgeInsets.all(16),
        child: const Center(child: Text('No sales data')),
      ),
      );
    }

    return Card(child: Padding(padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales Trend',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
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
                          if (value.toInt() >= 0 && value.toInt() < _statistics!.dailySales.length) {
                            final date = _statistics!.dailySales[value.toInt()].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('MM/dd').format(date),
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: _statistics!.dailySales.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.revenue);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    ),
    );
  }

  Widget _buildTopProductsChart() {
    final topProducts = _statistics!.topProducts.take(5).toList();
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
            'Top 5 Products',
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
                          toY: entry.value.totalRevenue,
                          color: Colors.blue,
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

  Widget _buildSalesByTypeChart() {
    if (_statistics!.salesByType.isEmpty) {
      return Card(child: Padding(padding: const EdgeInsets.all(16),
        child: const Center(child: Text('No sales type data')),
      ),
      );
    }

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];

    return Card(child: Padding(padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales by Type',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 500;
                int colorIndex = 0;

                if (isMobile) {
                  // Stack layout for mobile
                  return Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                            sections: _statistics!.salesByType.entries.map((entry) {
                              final color = colors[colorIndex++ % colors.length];
                              final percentage = (entry.value / _statistics!.totalRevenue) * 100;
                              return PieChartSectionData(
                                value: entry.value,
                                title: '${percentage.toStringAsFixed(1)}%',
                                color: color,
                                radius: 80,
                                titleStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: _statistics!.salesByType.entries.map((entry) {
                          final color = colors[(colorIndex++) % colors.length];
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(entry.key),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  );
                } else {
                  // Row layout for tablet/desktop
                  return SizedBox(
                    height: 250,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: _statistics!.salesByType.entries.map((entry) {
                                final color = colors[colorIndex++ % colors.length];
                                final percentage = (entry.value / _statistics!.totalRevenue) * 100;
                                return PieChartSectionData(
                                  value: entry.value,
                                  title: '${percentage.toStringAsFixed(1)}%',
                                  color: color,
                                  radius: 100,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _statistics!.salesByType.entries.map((entry) {
                            final color = colors[(colorIndex++) % colors.length];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(entry.key),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
    ),
    );
  }
}
