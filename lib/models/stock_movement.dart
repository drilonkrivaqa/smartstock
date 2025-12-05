import 'package:hive/hive.dart';

part 'stock_movement.g.dart';

@HiveType(typeId: 1)
class StockMovement extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int productId;

  @HiveField(2)
  int change;

  @HiveField(3)
  String type;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String? note;

  @HiveField(6)
  int? saleId;

  StockMovement({
    required this.id,
    required this.productId,
    required this.change,
    required this.type,
    required this.date,
    this.note,
    this.saleId,
  });
}
