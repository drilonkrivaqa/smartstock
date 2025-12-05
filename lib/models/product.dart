import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? sku;

  @HiveField(3)
  String? barcode;

  @HiveField(4)
  String? category;

  @HiveField(5)
  String? location;

  @HiveField(6)
  double? purchasePrice;

  @HiveField(7)
  double? salePrice;

  @HiveField(8)
  int quantity;

  @HiveField(9)
  int minQuantity;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  @HiveField(12)
  String? notes;

  @HiveField(13)
  DateTime? expiryDate;

  Product({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.category,
    this.location,
    this.purchasePrice,
    this.salePrice,
    required this.quantity,
    required this.minQuantity,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.expiryDate,
  });

  Product copyWith({
    String? name,
    String? sku,
    String? barcode,
    String? category,
    String? location,
    double? purchasePrice,
    double? salePrice,
    int? quantity,
    int? minQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    DateTime? expiryDate,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      location: location ?? this.location,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}
