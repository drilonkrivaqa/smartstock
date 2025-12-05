import 'package:hive/hive.dart';

import 'sale_item.dart';

part 'sale.g.dart';

@HiveType(typeId: 3)
class Sale extends HiveObject {
  Sale({
    required this.id,
    required this.date,
    required this.totalItems,
    required this.totalValue,
    required this.items,
    this.customerName,
    this.note,
  });

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
}
