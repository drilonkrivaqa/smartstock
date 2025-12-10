import 'package:hive/hive.dart';

part 'stock_movement.g.dart';

@HiveType(typeId: 1)
class StockMovement extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String type;

  @HiveField(2)
  int? fromLocationId;

  @HiveField(3)
  int? toLocationId;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String? note;

  @HiveField(6)
  List<StockMovementLine> lines;

  /// Optional reason for adjustments and waste (expired, broken, stolen, etc.).
  @HiveField(7)
  String? reasonCode;

  StockMovement({
    required this.id,
    required this.type,
    required this.date,
    required this.lines,
    this.fromLocationId,
    this.toLocationId,
    this.note,
    this.reasonCode,
  });
}

@HiveType(typeId: 6)
class StockMovementLine {
  @HiveField(0)
  int productId;

  @HiveField(1)
  double quantity;

  @HiveField(2)
  double unitCost;

  @HiveField(3)
  String? batchCode;

  @HiveField(4)
  DateTime? expiryDate;

  StockMovementLine({
    required this.productId,
    required this.quantity,
    required this.unitCost,
    this.batchCode,
    this.expiryDate,
  });
}
