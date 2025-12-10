import 'package:hive_flutter/hive_flutter.dart';

import '../models/location.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/stock_item.dart';
import '../models/stock_movement.dart';
import '../models/audit.dart';
import '../models/price_rule.dart';

class HiveService {
  static const String productsBox = 'products';
  static const String locationsBox = 'locations';
  static const String movementsBox = 'movements';
  static const String stockItemsBox = 'stock_items';
  static const String salesBox = 'sales';
  static const String settingsBox = 'settings';
  static const String auditSessionsBox = 'audit_sessions';
  static const String priceRulesBox = 'price_rules';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive
      ..registerAdapter(ProductAdapter())
      ..registerAdapter(LocationAdapter())
      ..registerAdapter(SaleAdapter())
      ..registerAdapter(SaleItemAdapter())
      ..registerAdapter(StockItemAdapter())
      ..registerAdapter(StockMovementAdapter())
      ..registerAdapter(StockMovementLineAdapter())
      ..registerAdapter(AuditSessionAdapter())
      ..registerAdapter(AuditLineAdapter())
      ..registerAdapter(PriceRuleAdapter());
    await Future.wait([
      Hive.openBox<Product>(productsBox),
      Hive.openBox<Location>(locationsBox),
      Hive.openBox<StockItem>(stockItemsBox),
      Hive.openBox<Sale>(salesBox),
      Hive.openBox<StockMovement>(movementsBox),
      Hive.openBox<AuditSession>(auditSessionsBox),
      Hive.openBox<PriceRule>(priceRulesBox),
      Hive.openBox(settingsBox),
    ]);
  }
}
