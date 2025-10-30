class InventoryStatistics {
  final double totalInventoryValue;
  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;
  final List<ProductInventoryData> topValueProducts;
  final List<ProductInventoryData> lowStockItems;
  final List<ProductInventoryData> deadStockItems;
  final Map<String, int> inventoryByCategory;

  InventoryStatistics({
    required this.totalInventoryValue,
    required this.totalProducts,
    required this.activeProducts,
    required this.lowStockProducts,
    required this.topValueProducts,
    required this.lowStockItems,
    required this.deadStockItems,
    required this.inventoryByCategory,
  });
}

class ProductInventoryData {
  final String productId;
  final String productName;
  final String code;
  final double quantity;
  final double cost;
  final double price;
  final double totalValue;
  final double turnoverRate;
  final int daysSinceLastSale;
  final bool isLowStock;

  ProductInventoryData({
    required this.productId,
    required this.productName,
    required this.code,
    required this.quantity,
    required this.cost,
    required this.price,
    required this.totalValue,
    required this.turnoverRate,
    required this.daysSinceLastSale,
    required this.isLowStock,
  });
}
