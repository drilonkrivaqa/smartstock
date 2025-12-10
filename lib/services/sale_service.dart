import 'package:hive/hive.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../services/stock_service.dart';
import '../services/hive_service.dart';

class SaleService {
  SaleService({
    required this.salesBox,
    required this.productsBox,
    required this.stockService,
  });

  final Box<Sale> salesBox;
  final Box<Product> productsBox;
  final StockService stockService;

  Future<void> recordSale(Sale sale, {required int locationId}) async {
    await salesBox.add(sale);
    final products = productLookup();
    for (final item in sale.items) {
      final unitCost = products[item.productId]?.purchasePrice ?? 0;
      await stockService.adjustStock(
        productId: item.productId,
        locationId: locationId,
        quantityChange: -item.quantity.toDouble(),
        type: 'sale',
        note: 'Sale ${sale.id}',
        unitCost: unitCost,
      );
    }
  }

  List<Sale> getSales() {
    return salesBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Sale> getSalesInRange(DateTime start, DateTime end) {
    return salesBox.values
        .where((sale) => sale.date.isAfter(start) && sale.date.isBefore(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double salesTotalFor(DateTime start, DateTime end) {
    return salesBox.values
        .where((sale) => sale.date.isAfter(start) && sale.date.isBefore(end))
        .fold(0.0, (sum, sale) => sum + sale.totalValue);
  }

  Map<int, Product> productLookup() {
    return {for (final p in productsBox.values) p.id: p};
  }

  Map<int, int> quantitySoldSince(DateTime startDate) {
    final totals = <int, int>{};
    for (final sale in salesBox.values.where((sale) => sale.date.isAfter(startDate))) {
      for (final item in sale.items) {
        totals.update(item.productId, (value) => value + item.quantity,
            ifAbsent: () => item.quantity);
      }
    }
    return totals;
  }

  double grossProfitFor(DateTime start, DateTime end) {
    double profit = 0;
    final products = productLookup();
    for (final sale in getSalesInRange(start, end)) {
      for (final item in sale.items) {
        final costPrice = products[item.productId]?.purchasePrice ?? 0;
        final revenue = item.quantity * item.unitPrice;
        profit += revenue - (item.quantity * costPrice);
      }
    }
    return profit;
  }

  int uniqueCustomersCount() {
    return salesBox.values
        .map((sale) => sale.customerName?.trim())
        .where((name) => name != null && name!.isNotEmpty)
        .toSet()
        .length;
  }
}

Future<SaleService> buildSaleService(StockService stockService) async {
  final sales = Hive.box<Sale>(HiveService.salesBox);
  final products = Hive.box<Product>(HiveService.productsBox);
  return SaleService(
    salesBox: sales,
    productsBox: products,
    stockService: stockService,
  );
}
