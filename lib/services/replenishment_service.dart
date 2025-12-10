import 'package:hive/hive.dart';

import '../models/product.dart';
import '../models/replenishment.dart';
import '../services/hive_service.dart';
import '../services/location_service.dart';
import '../services/sale_service.dart';
import '../services/stock_service.dart';

class ReplenishmentService {
  ReplenishmentService({
    required this.saleService,
    required this.stockService,
    required this.locationService,
    required this.products,
  });

  final SaleService saleService;
  final StockService stockService;
  final LocationService locationService;
  final List<Product> products;

  List<ReplenishmentSuggestion> suggestionsForLocation({
    required int locationId,
    int historyDays = 30,
    double targetDays = 7,
    double safetyStockDays = 3,
  }) {
    final location = locationService.getAll().firstWhere(
          (loc) => loc.id == locationId,
          orElse: () => locationService.getWarehouse()!,
        );
    final cutoff = DateTime.now().subtract(Duration(days: historyDays));
    final saleHistory = saleService
        .getSales()
        .where((sale) => sale.date.isAfter(cutoff))
        .where((sale) => sale.locationName == null ||
            sale.locationName!.toLowerCase() == location.name.toLowerCase())
        .toList();

    final totals = <int, int>{};
    for (final sale in saleHistory) {
      for (final item in sale.items) {
        totals.update(item.productId, (value) => value + item.quantity,
            ifAbsent: () => item.quantity);
      }
    }

    final days = historyDays.clamp(1, 365);
    final suggestions = <ReplenishmentSuggestion>[];

    for (final product in products) {
      final currentStock = stockService.getQuantity(
        productId: product.id,
        locationId: locationId,
      );
      final sold = totals[product.id] ?? 0;
      final avgDailySales = sold / days;
      final daysLeft = avgDailySales > 0 ? currentStock / avgDailySales : double.infinity;
      final suggestedOrderQty = ((targetDays + safetyStockDays) * avgDailySales) - currentStock;

      suggestions.add(
        ReplenishmentSuggestion(
          productId: product.id,
          locationId: locationId,
          currentStock: currentStock,
          avgDailySales: avgDailySales,
          daysLeft: daysLeft.isFinite ? daysLeft : 9999,
          suggestedOrderQty: suggestedOrderQty > 0 ? suggestedOrderQty : 0,
          targetDays: targetDays,
          safetyStockDays: safetyStockDays,
        ),
      );
    }

    suggestions.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return suggestions;
  }
}

Future<ReplenishmentService> buildReplenishmentService({
  required SaleService saleService,
  required StockService stockService,
  required LocationService locationService,
}) async {
  final productsBox = Hive.box<Product>(HiveService.productsBox);
  return ReplenishmentService(
    saleService: saleService,
    stockService: stockService,
    locationService: locationService,
    products: productsBox.values.toList(),
  );
}
