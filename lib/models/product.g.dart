// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as int,
      name: fields[1] as String,
      sku: fields[2] as String?,
      barcode: fields[3] as String?,
      category: fields[4] as String?,
      location: fields[5] as String?,
      purchasePrice: fields[6] as double?,
      salePrice: fields[7] as double?,
      quantity: fields[8] as int,
      minQuantity: fields[9] as int,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
      notes: fields[12] as String?,
      expiryDate: fields[13] as DateTime?,
      photoPath: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sku)
      ..writeByte(3)
      ..write(obj.barcode)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.purchasePrice)
      ..writeByte(7)
      ..write(obj.salePrice)
      ..writeByte(8)
      ..write(obj.quantity)
      ..writeByte(9)
      ..write(obj.minQuantity)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.expiryDate)
      ..writeByte(14)
      ..write(obj.photoPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
