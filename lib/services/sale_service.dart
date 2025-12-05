import 'package:hive/hive.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../services/hive_service.dart';

class SaleService {
  SaleService({
    required this.salesBox,
    required this.productsBox,
  });

  final Box<Sale> salesBox;
  final Box<Product> productsBox;

  Future<void> recordSale(Sale sale) async {
    await salesBox.add(sale);
  }

  List<Sale> getSales() {
    return salesBox.values.toList()
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
}

Future<SaleService> buildSaleService() async {
  final sales = Hive.box<Sale>(HiveService.salesBox);
  final products = Hive.box<Product>(HiveService.productsBox);
  return SaleService(salesBox: sales, productsBox: products);
}
