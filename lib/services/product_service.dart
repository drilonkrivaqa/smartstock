import 'package:hive/hive.dart';

import '../models/product.dart';
import '../models/stock_movement.dart';
import 'hive_service.dart';

enum ProductFilter { all, lowStock, outOfStock }

class ProductService {
  ProductService({
    required this.productsBox,
    required this.movementsBox,
  });

  final Box<Product> productsBox;
  final Box<StockMovement> movementsBox;

  List<Product> getProducts({
    String searchQuery = '',
    ProductFilter filter = ProductFilter.all,
  }) {
    final lowerQuery = searchQuery.toLowerCase().trim();
    final products = productsBox.values.where((product) {
      final matchesQuery = lowerQuery.isEmpty ||
          product.name.toLowerCase().contains(lowerQuery) ||
          (product.sku ?? '').toLowerCase().contains(lowerQuery) ||
          (product.barcode ?? '').toLowerCase().contains(lowerQuery);
      final matchesFilter = switch (filter) {
        ProductFilter.all => true,
        ProductFilter.lowStock => product.quantity > 0 &&
            product.quantity <= product.minQuantity,
        ProductFilter.outOfStock => product.quantity == 0,
      };
      return matchesQuery && matchesFilter;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return products;
  }

  Future<void> addOrUpdateProduct(Product product) async {
    final existingIndex = productsBox.values
        .toList()
        .indexWhere((element) => element.id == product.id);
    if (existingIndex == -1) {
      await productsBox.add(product);
    } else {
      final key = productsBox.keyAt(existingIndex);
      await productsBox.put(key, product);
    }
  }

  Future<void> adjustStock({
    required Product product,
    required int change,
    required String type,
    String? note,
    DateTime? date,
    int? saleId,
  }) async {
    final updatedProduct = product.copyWith(
      quantity: product.quantity + change,
      updatedAt: date ?? DateTime.now(),
    );
    await addOrUpdateProduct(updatedProduct);
    final movement = StockMovement(
      id: DateTime.now().microsecondsSinceEpoch,
      productId: product.id,
      change: change,
      type: type,
      date: date ?? DateTime.now(),
      note: note,
      saleId: saleId,
    );
    await movementsBox.add(movement);
  }

  List<StockMovement> movementsForProduct(int productId) {
    final movements = movementsBox.values
        .where((movement) => movement.productId == productId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return movements;
  }

  Product? findById(int id) {
    try {
      return productsBox.values.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  Product? findByBarcode(String code) {
    try {
      return productsBox.values
          .firstWhere((product) => product.barcode == code);
    } catch (_) {
      return null;
    }
  }
}

Future<ProductService> buildProductService() async {
  final products = Hive.box<Product>(HiveService.productsBox);
  final movements = Hive.box<StockMovement>(HiveService.movementsBox);
  return ProductService(productsBox: products, movementsBox: movements);
}
