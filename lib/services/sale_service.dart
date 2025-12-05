import 'package:hive/hive.dart';

import '../models/sale.dart';
import '../models/sale_item.dart';
import 'hive_service.dart';
import 'product_service.dart';

class SaleService {
  SaleService({
    required this.salesBox,
    required this.productService,
  });

  final Box<Sale> salesBox;
  final ProductService productService;

  Future<Sale> recordSale({
    required List<SaleItem> items,
    String? customerName,
    String? note,
  }) async {
    final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalValue =
        items.fold<double>(0, (sum, item) => sum + (item.unitPrice * item.quantity));
    final sale = Sale(
      id: DateTime.now().microsecondsSinceEpoch,
      date: DateTime.now(),
      totalItems: totalItems,
      totalValue: totalValue,
      items: items,
      customerName: customerName,
      note: note,
    );
    await salesBox.add(sale);
    return sale;
  }

  List<Sale> getSales() {
    final sales = salesBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sales;
  }

  double totalSalesForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return salesBox.values
        .where((sale) => sale.date.isAfter(start) && sale.date.isBefore(end))
        .fold(0.0, (sum, sale) => sum + sale.totalValue);
  }

  double totalSalesForRange(DateTime start) {
    final end = DateTime.now();
    return salesBox.values
        .where((sale) => sale.date.isAfter(start) && sale.date.isBefore(end))
        .fold(0.0, (sum, sale) => sum + sale.totalValue);
  }
}

Future<SaleService> buildSaleService(ProductService productService) async {
  final sales = Hive.box<Sale>(HiveService.salesBox);
  return SaleService(
    salesBox: sales,
    productService: productService,
  );
}
