import 'package:hive/hive.dart';

part 'price_rule.g.dart';

@HiveType(typeId: 9)
class PriceRule extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime? activeFrom;

  @HiveField(3)
  DateTime? activeUntil;

  /// null = all stores, otherwise specific location id.
  @HiveField(4)
  int? locationScope;

  /// product / category / all
  @HiveField(5)
  String targetType;

  /// ids or codes matching target type
  @HiveField(6)
  List<String> targetIds;

  /// minQty / timeRange / dayOfWeek / always
  @HiveField(7)
  String conditionType;

  /// Optional minimum quantity threshold for the rule.
  @HiveField(8)
  int? conditionMinQty;

  /// Days of the week when the rule applies (1=Monday ... 7=Sunday)
  @HiveField(9)
  List<int>? daysOfWeek;

  /// percentageDiscount / fixedPrice / freeItem
  @HiveField(10)
  String effectType;

  /// Value meaning depends on [effectType]. Percentage for discounts, price for fixedPrice.
  @HiveField(11)
  double? effectValue;

  /// Number of free items to grant for each qualifying bundle.
  @HiveField(12)
  int? rewardQuantity;

  /// Product id to add as a free item (defaults to the matched product).
  @HiveField(13)
  int? rewardProductId;

  @HiveField(14)
  int priority;

  PriceRule({
    required this.id,
    required this.name,
    required this.targetType,
    required this.conditionType,
    required this.effectType,
    required this.priority,
    this.locationScope,
    this.targetIds = const [],
    this.conditionMinQty,
    this.daysOfWeek,
    this.effectValue,
    this.rewardQuantity,
    this.rewardProductId,
    this.activeFrom,
    this.activeUntil,
  });

  bool isActive(DateTime moment, {int? locationId}) {
    final matchesLocation = locationScope == null || locationScope == locationId;
    final matchesStart = activeFrom == null || !moment.isBefore(activeFrom!);
    final matchesEnd = activeUntil == null || !moment.isAfter(activeUntil!);
    final matchesDay =
        daysOfWeek == null || daysOfWeek!.contains(moment.weekday);
    return matchesLocation && matchesStart && matchesEnd && matchesDay;
  }
}
