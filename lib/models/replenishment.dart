class ReplenishmentSuggestion {
  ReplenishmentSuggestion({
    required this.productId,
    required this.locationId,
    required this.currentStock,
    required this.avgDailySales,
    required this.daysLeft,
    required this.suggestedOrderQty,
    required this.targetDays,
    required this.safetyStockDays,
  });

  final int productId;
  final int locationId;
  final double currentStock;
  final double avgDailySales;
  final double daysLeft;
  final double suggestedOrderQty;
  final double targetDays;
  final double safetyStockDays;
}
