class DashboardMetrics {
  final double totalRevenue;
  final double todayRevenue;
  final int totalSales;
  final int todaySales;
  final int totalProducts;
  final int lowStockProducts;
  final double averageSaleValue;
  final double profitMargin;

  DashboardMetrics({
    required this.totalRevenue,
    required this.todayRevenue,
    required this.totalSales,
    required this.todaySales,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.averageSaleValue,
    required this.profitMargin,
  });

  factory DashboardMetrics.empty() {
    return DashboardMetrics(
      totalRevenue: 0,
      todayRevenue: 0,
      totalSales: 0,
      todaySales: 0,
      totalProducts: 0,
      lowStockProducts: 0,
      averageSaleValue: 0,
      profitMargin: 0,
    );
  }
}
