import 'package:hive/hive.dart';

part 'audit.g.dart';

@HiveType(typeId: 7)
class AuditSession extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int locationId;

  @HiveField(2)
  DateTime startedAt;

  @HiveField(3)
  DateTime? finishedAt;

  @HiveField(4)
  String status; // in_progress / completed

  @HiveField(5)
  List<AuditLine> lines;

  AuditSession({
    required this.id,
    required this.locationId,
    required this.startedAt,
    required this.status,
    this.finishedAt,
    List<AuditLine>? lines,
  }) : lines = lines ?? [];

  double get totalDifferenceValue =>
      lines.fold(0.0, (value, line) => value + line.differenceValue);

  int get totalItemsCounted =>
      lines.fold(0, (value, line) => value + line.countedQuantity.round());
}

@HiveType(typeId: 8)
class AuditLine {
  @HiveField(0)
  int productId;

  @HiveField(1)
  double countedQuantity;

  @HiveField(2)
  double expectedQuantity;

  @HiveField(3)
  double difference;

  @HiveField(4)
  double differenceValue;

  @HiveField(5)
  double unitCost;

  AuditLine({
    required this.productId,
    required this.countedQuantity,
    required this.expectedQuantity,
    required this.unitCost,
    double? difference,
    double? differenceValue,
  })  : difference = difference ?? countedQuantity - expectedQuantity,
        differenceValue =
            differenceValue ?? (difference ?? countedQuantity - expectedQuantity) * unitCost;

  AuditLine copyWith({
    double? countedQuantity,
    double? expectedQuantity,
    double? unitCost,
  }) {
    final newCount = countedQuantity ?? this.countedQuantity;
    final newExpected = expectedQuantity ?? this.expectedQuantity;
    final newUnitCost = unitCost ?? this.unitCost;
    final newDifference = newCount - newExpected;
    return AuditLine(
      productId: productId,
      countedQuantity: newCount,
      expectedQuantity: newExpected,
      unitCost: newUnitCost,
      difference: newDifference,
      differenceValue: newDifference * newUnitCost,
    );
  }
}
