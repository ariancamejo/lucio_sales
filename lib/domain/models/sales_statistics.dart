class SalesStatistics {
  final double totalRevenue;
  final int totalSales;
  final double averageSaleValue;
  final List<ProductSalesData> topProducts;
  final List<DailySalesData> dailySales;
  final Map<String, double> salesByType;
  final double totalProfit;
  final double profitMargin;

  SalesStatistics({
    required this.totalRevenue,
    required this.totalSales,
    required this.averageSaleValue,
    required this.topProducts,
    required this.dailySales,
    required this.salesByType,
    required this.totalProfit,
    required this.profitMargin,
  });
}

class ProductSalesData {
  final String productId;
  final String productName;
  final double totalRevenue;
  final double totalQuantity;
  final int salesCount;
  final double averagePrice;

  ProductSalesData({
    required this.productId,
    required this.productName,
    required this.totalRevenue,
    required this.totalQuantity,
    required this.salesCount,
    required this.averagePrice,
  });
}

class DailySalesData {
  final DateTime date;
  final double revenue;
  final int salesCount;

  DailySalesData({
    required this.date,
    required this.revenue,
    required this.salesCount,
  });
}
