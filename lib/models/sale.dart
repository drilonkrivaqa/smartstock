import 'package:hive/hive.dart';

part 'sale.g.dart';

@HiveType(typeId: 2)
class Sale extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  int totalItems;

  @HiveField(3)
  double totalValue;

  @HiveField(4)
  List<SaleItem> items;

  @HiveField(5)
  String? customerName;

  @HiveField(6)
  String? note;

  Sale({
    required this.id,
    required this.date,
    required this.totalItems,
    required this.totalValue,
    required this.items,
    this.customerName,
    this.note,
  });
}

@HiveType(typeId: 3)
class SaleItem {
  @HiveField(0)
  int productId;

  @HiveField(1)
  int quantity;

  @HiveField(2)
  double unitPrice;

  SaleItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });
}
