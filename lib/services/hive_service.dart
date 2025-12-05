import 'package:hive_flutter/hive_flutter.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../models/stock_movement.dart';

class HiveService {
  static const String productsBox = 'products';
  static const String movementsBox = 'movements';
  static const String salesBox = 'sales';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive
      ..registerAdapter(ProductAdapter())
      ..registerAdapter(SaleAdapter())
      ..registerAdapter(SaleItemAdapter())
      ..registerAdapter(StockMovementAdapter());
    await Future.wait([
      Hive.openBox<Product>(productsBox),
      Hive.openBox<Sale>(salesBox),
      Hive.openBox<StockMovement>(movementsBox),
      Hive.openBox(settingsBox),
    ]);
  }
}
