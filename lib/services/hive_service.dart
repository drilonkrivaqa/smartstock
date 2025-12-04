import 'package:hive_flutter/hive_flutter.dart';

import '../models/product.dart';
import '../models/product.g.dart';
import '../models/stock_movement.dart';
import '../models/stock_movement.g.dart';

class HiveService {
  static const String productsBox = 'products';
  static const String movementsBox = 'movements';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive
      ..registerAdapter(ProductAdapter())
      ..registerAdapter(StockMovementAdapter());
    await Future.wait([
      Hive.openBox<Product>(productsBox),
      Hive.openBox<StockMovement>(movementsBox),
      Hive.openBox(settingsBox),
    ]);
  }
}
