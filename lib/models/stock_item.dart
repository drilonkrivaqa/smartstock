import 'package:hive/hive.dart';

part 'stock_item.g.dart';

@HiveType(typeId: 5)
class StockItem extends HiveObject {
  @HiveField(0)
  int productId;

  @HiveField(1)
  int locationId;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  double reservedQuantity;

  StockItem({
    required this.productId,
    required this.locationId,
    required this.quantity,
    this.reservedQuantity = 0,
  });
}
