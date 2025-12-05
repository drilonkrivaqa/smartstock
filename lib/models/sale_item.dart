import 'package:hive/hive.dart';

part 'sale_item.g.dart';

@HiveType(typeId: 2)
class SaleItem {
  SaleItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  @HiveField(0)
  int productId;

  @HiveField(1)
  int quantity;

  @HiveField(2)
  double unitPrice;
}
