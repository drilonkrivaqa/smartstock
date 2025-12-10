import 'package:hive/hive.dart';

import '../models/location.dart';
import '../models/product.dart';
import '../models/stock_item.dart';
import '../models/stock_movement.dart';
import 'hive_service.dart';
import 'location_service.dart';

class StockService {
  StockService({
    required this.locationService,
    required this.stockItemsBox,
    required this.stockMovementsBox,
    required this.productsBox,
  });

  final LocationService locationService;
  final Box<StockItem> stockItemsBox;
  final Box<StockMovement> stockMovementsBox;
  final Box<Product> productsBox;

  double getQuantity({required int productId, required int locationId}) {
    final item = _findStockItem(productId: productId, locationId: locationId);
    return item?.quantity ?? 0;
  }

  Map<int, double> getQuantitiesForLocation(int locationId) {
    final quantities = <int, double>{};
    for (final item in stockItemsBox.values
        .where((element) => element.locationId == locationId)) {
      quantities[item.productId] = item.quantity;
    }
    return quantities;
  }

  Future<void> bootstrapFromProducts() async {
    if (stockItemsBox.isNotEmpty) return;
    final warehouse =
        locationService.getWarehouse() ?? await locationService.ensureDefaultWarehouse();
    for (final product in productsBox.values) {
      if (product.quantity <= 0) continue;
      await stockItemsBox.add(
        StockItem(
          productId: product.id,
          locationId: warehouse.id,
          quantity: product.quantity.toDouble(),
        ),
      );
    }
  }

  List<StockMovement> movementsForProduct(int productId) {
    final movements = stockMovementsBox.values
        .where(
          (movement) => movement.lines
              .any((line) => line.productId == productId),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return movements;
  }

  Future<void> purchaseToWarehouse({
    required int productId,
    required double quantity,
    required double unitCost,
    String? note,
  }) async {
    final warehouse =
        locationService.getWarehouse() ?? await locationService.ensureDefaultWarehouse();

    await _changeStock(
      productId: productId,
      locationId: warehouse.id,
      change: quantity,
    );

    final movement = StockMovement(
      id: DateTime.now().microsecondsSinceEpoch,
      type: 'purchase',
      date: DateTime.now(),
      toLocationId: warehouse.id,
      note: note,
      lines: [
        StockMovementLine(
          productId: productId,
          quantity: quantity,
          unitCost: unitCost,
        ),
      ],
    );

    await stockMovementsBox.add(movement);
  }

  Future<void> transfer({
    required int productId,
    required int fromLocationId,
    required int toLocationId,
    required double quantity,
    String? note,
  }) async {
    final available = getQuantity(productId: productId, locationId: fromLocationId);
    if (available < quantity) {
      throw Exception('Insufficient stock to transfer.');
    }

    await _changeStock(
      productId: productId,
      locationId: fromLocationId,
      change: -quantity,
    );
    await _changeStock(
      productId: productId,
      locationId: toLocationId,
      change: quantity,
    );

    final movement = StockMovement(
      id: DateTime.now().microsecondsSinceEpoch,
      type: 'transfer',
      date: DateTime.now(),
      fromLocationId: fromLocationId,
      toLocationId: toLocationId,
      note: note,
      lines: [
        StockMovementLine(
          productId: productId,
          quantity: quantity,
          unitCost: 0,
        ),
      ],
    );

    await stockMovementsBox.add(movement);
  }

  Future<void> adjustStock({
    required int productId,
    required int locationId,
    required double quantityChange,
    required String type,
    String? note,
    double unitCost = 0,
  }) async {
    final available = getQuantity(productId: productId, locationId: locationId);
    if (quantityChange < 0 && available + quantityChange < 0) {
      throw Exception('Insufficient stock.');
    }

    await _changeStock(
      productId: productId,
      locationId: locationId,
      change: quantityChange,
    );

    final movement = StockMovement(
      id: DateTime.now().microsecondsSinceEpoch,
      type: type,
      date: DateTime.now(),
      fromLocationId: quantityChange < 0 ? locationId : null,
      toLocationId: quantityChange > 0 ? locationId : null,
      note: note,
      lines: [
        StockMovementLine(
          productId: productId,
          quantity: quantityChange,
          unitCost: unitCost,
        ),
      ],
    );

    await stockMovementsBox.add(movement);
  }

  StockItem? _findStockItem({
    required int productId,
    required int locationId,
  }) {
    try {
      return stockItemsBox.values.firstWhere(
        (item) => item.productId == productId && item.locationId == locationId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _changeStock({
    required int productId,
    required int locationId,
    required double change,
  }) async {
    final existing = _findStockItem(productId: productId, locationId: locationId);
    if (existing != null) {
      final newQuantity = existing.quantity + change;
      if (newQuantity < 0) {
        throw Exception('Resulting stock cannot be negative.');
      }
      final key = stockItemsBox.keyAt(stockItemsBox.values.toList().indexOf(existing));
      await stockItemsBox.put(
        key,
        StockItem(
          productId: existing.productId,
          locationId: existing.locationId,
          quantity: newQuantity,
          reservedQuantity: existing.reservedQuantity,
        ),
      );
    } else {
      if (change < 0) {
        throw Exception('Resulting stock cannot be negative.');
      }
      await stockItemsBox.add(
        StockItem(
          productId: productId,
          locationId: locationId,
          quantity: change,
        ),
      );
    }

    await _syncProductQuantity(productId);
  }

  Future<void> _syncProductQuantity(int productId) async {
    final totalQuantity = stockItemsBox.values
        .where((item) => item.productId == productId)
        .fold<double>(0, (sum, item) => sum + item.quantity);

    final index = productsBox.values
        .toList()
        .indexWhere((product) => product.id == productId);
    if (index == -1) return;
    final key = productsBox.keyAt(index);
    final product = productsBox.getAt(index);
    if (product == null) return;

    await productsBox.put(
      key,
      product.copyWith(
        quantity: totalQuantity.round(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

Future<StockService> buildStockService(LocationService locationService) async {
  final stockItems = Hive.box<StockItem>(HiveService.stockItemsBox);
  final stockMovements = Hive.box<StockMovement>(HiveService.movementsBox);
  final products = Hive.box<Product>(HiveService.productsBox);
  final service = StockService(
    locationService: locationService,
    stockItemsBox: stockItems,
    stockMovementsBox: stockMovements,
    productsBox: products,
  );
  await service.bootstrapFromProducts();
  return service;
}
