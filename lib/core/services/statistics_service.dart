import '../../data/datasources/local/output_local_datasource.dart';
import '../../data/datasources/local/product_local_datasource.dart';
import '../../data/datasources/local/output_type_local_datasource.dart';
import '../../domain/models/sales_statistics.dart';
import '../../domain/models/inventory_statistics.dart';
import '../../domain/models/dashboard_metrics.dart';

class StatisticsService {
  final OutputLocalDataSource outputDataSource;
  final ProductLocalDataSource productDataSource;
  final OutputTypeLocalDataSource outputTypeDataSource;

  StatisticsService({
    required this.outputDataSource,
    required this.productDataSource,
    required this.outputTypeDataSource,
  });

  Future<SalesStatistics> getSalesStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final allOutputs = await outputDataSource.getByDateRange(startDate, endDate);
    final products = await productDataSource.getAll(includeInactive: true);
    final outputTypes = await outputTypeDataSource.getAll();

    // Filter only sales (outputs where type.isSale = true)
    final outputs = allOutputs.where((output) {
      final outputType = outputTypes.firstWhere(
        (t) => t.id == output.outputTypeId,
        orElse: () => outputTypes.first,
      );
      return outputType.isSale;
    }).toList();

    // Calculate total revenue and sales count
    double totalRevenue = 0;
    int totalSales = outputs.length;
    double totalCost = 0;

    // Sales by product
    final Map<String, ProductSalesData> productSalesMap = {};

    // Daily sales
    final Map<String, DailySalesData> dailySalesMap = {};

    // Sales by type
    final Map<String, double> salesByType = {};

    for (final output in outputs) {
      totalRevenue += output.totalAmount;

      // Find product to get cost
      final product = products.firstWhere(
        (p) => p.id == output.productId,
        orElse: () => products.first,
      );
      final outputCost = product.cost * output.quantity;
      totalCost += outputCost;

      // Product sales data
      final productKey = output.productId;
      if (productSalesMap.containsKey(productKey)) {
        final existing = productSalesMap[productKey]!;
        productSalesMap[productKey] = ProductSalesData(
          productId: existing.productId,
          productName: existing.productName,
          totalRevenue: existing.totalRevenue + output.totalAmount,
          totalQuantity: existing.totalQuantity + output.quantity,
          salesCount: existing.salesCount + 1,
          averagePrice: (existing.totalRevenue + output.totalAmount) /
                       (existing.salesCount + 1),
        );
      } else {
        productSalesMap[productKey] = ProductSalesData(
          productId: product.id,
          productName: product.name,
          totalRevenue: output.totalAmount,
          totalQuantity: output.quantity,
          salesCount: 1,
          averagePrice: output.totalAmount,
        );
      }

      // Daily sales
      final dateKey = DateTime(
        output.date.year,
        output.date.month,
        output.date.day,
      ).toIso8601String();

      if (dailySalesMap.containsKey(dateKey)) {
        final existing = dailySalesMap[dateKey]!;
        dailySalesMap[dateKey] = DailySalesData(
          date: existing.date,
          revenue: existing.revenue + output.totalAmount,
          salesCount: existing.salesCount + 1,
        );
      } else {
        dailySalesMap[dateKey] = DailySalesData(
          date: DateTime(output.date.year, output.date.month, output.date.day),
          revenue: output.totalAmount,
          salesCount: 1,
        );
      }

      // Sales by type
      final outputType = outputTypes.firstWhere(
        (t) => t.id == output.outputTypeId,
        orElse: () => outputTypes.first,
      );
      salesByType[outputType.name] = (salesByType[outputType.name] ?? 0) + output.totalAmount;
    }

    // Sort top products by revenue
    final topProducts = productSalesMap.values.toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    // Sort daily sales by date
    final dailySales = dailySalesMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final averageSaleValue = totalSales > 0 ? (totalRevenue / totalSales).toDouble() : 0.0;
    final totalProfit = totalRevenue - totalCost;
    final profitMargin = totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100).toDouble() : 0.0;

    return SalesStatistics(
      totalRevenue: totalRevenue,
      totalSales: totalSales,
      averageSaleValue: averageSaleValue,
      topProducts: topProducts.take(10).toList(),
      dailySales: dailySales,
      salesByType: salesByType,
      totalProfit: totalProfit,
      profitMargin: profitMargin,
    );
  }

  Future<InventoryStatistics> getInventoryStatistics({
    DateTime? referenceDate,
  }) async {
    final products = await productDataSource.getAll(includeInactive: false);
    final allProducts = await productDataSource.getAll(includeInactive: true);
    final now = referenceDate ?? DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentOutputs = await outputDataSource.getByDateRange(thirtyDaysAgo, now);

    double totalInventoryValue = 0;
    int lowStockCount = 0;
    final List<ProductInventoryData> inventoryData = [];
    final List<ProductInventoryData> lowStockItems = [];
    final List<ProductInventoryData> deadStockItems = [];

    // Calculate product statistics
    for (final product in products) {
      final totalValue = product.quantity * product.cost;
      totalInventoryValue += totalValue;

      // Find recent sales for this product
      final productOutputs = recentOutputs
          .where((o) => o.productId == product.id)
          .toList();

      final daysSinceLastSale = productOutputs.isEmpty
          ? 999
          : now.difference(productOutputs.last.date).inDays;

      // Simple turnover rate calculation
      final totalSold = productOutputs.fold<double>(
        0,
        (sum, output) => sum + output.quantity,
      );
      final turnoverRate = product.quantity > 0
          ? ((totalSold / product.quantity) * 100).toDouble()
          : 0.0;

      // Check if low stock (less than 10 units or less than 1 week of sales)
      final avgDailySales = (totalSold / 30).toDouble();
      final daysOfStock = avgDailySales > 0 ? (product.quantity / avgDailySales).toDouble() : 999.0;
      final isLowStock = product.quantity < 10 || daysOfStock < 7;

      if (isLowStock) {
        lowStockCount++;
      }

      final inventoryItem = ProductInventoryData(
        productId: product.id,
        productName: product.name,
        code: product.code,
        quantity: product.quantity,
        cost: product.cost,
        price: product.price,
        totalValue: totalValue,
        turnoverRate: turnoverRate,
        daysSinceLastSale: daysSinceLastSale,
        isLowStock: isLowStock,
      );

      inventoryData.add(inventoryItem);

      if (isLowStock) {
        lowStockItems.add(inventoryItem);
      }

      // Dead stock: no sales in 30+ days
      if (daysSinceLastSale >= 30) {
        deadStockItems.add(inventoryItem);
      }
    }

    // Sort by value for top products
    final topValueProducts = [...inventoryData]
      ..sort((a, b) => b.totalValue.compareTo(a.totalValue));

    return InventoryStatistics(
      totalInventoryValue: totalInventoryValue,
      totalProducts: allProducts.length,
      activeProducts: products.length,
      lowStockProducts: lowStockCount,
      topValueProducts: topValueProducts.take(10).toList(),
      lowStockItems: lowStockItems,
      deadStockItems: deadStockItems,
      inventoryByCategory: {}, // Can be extended with categories
    );
  }

  Future<DashboardMetrics> getDashboardMetrics() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Get today's outputs
    final todayOutputs = await outputDataSource.getByDateRange(todayStart, todayEnd);

    // Get all outputs for total calculation
    final allOutputs = await outputDataSource.getAll();

    // Get products for low stock calculation
    final products = await productDataSource.getAll(includeInactive: false);

    // Calculate metrics
    double todayRevenue = todayOutputs.fold<double>(0, (sum, output) => sum + output.totalAmount);
    double totalRevenue = allOutputs.fold<double>(0, (sum, output) => sum + output.totalAmount);

    int todaySales = todayOutputs.length;
    int totalSales = allOutputs.length;

    double averageSaleValue = totalSales > 0 ? totalRevenue / totalSales : 0;

    // Calculate profit margin
    double totalCost = 0;
    for (final output in allOutputs) {
      final product = products.firstWhere(
        (p) => p.id == output.productId,
        orElse: () => products.isNotEmpty ? products.first : throw Exception('No products found'),
      );
      totalCost += product.cost * output.quantity;
    }

    double profitMargin = totalRevenue > 0 ? ((totalRevenue - totalCost) / totalRevenue * 100) : 0;

    // Count low stock products (less than 10 units)
    int lowStockProducts = products.where((p) => p.quantity < 10).length;

    return DashboardMetrics(
      totalRevenue: totalRevenue,
      todayRevenue: todayRevenue,
      totalSales: totalSales,
      todaySales: todaySales,
      totalProducts: products.length,
      lowStockProducts: lowStockProducts,
      averageSaleValue: averageSaleValue,
      profitMargin: profitMargin,
    );
  }
}
