// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockMovementAdapter extends TypeAdapter<StockMovement> {
  @override
  final int typeId = 1;

  @override
  StockMovement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockMovement(
      id: fields[0] as int,
      productId: fields[1] as int,
      change: fields[2] as int,
      type: fields[3] as String,
      date: fields[4] as DateTime,
      note: fields[5] as String?,
      saleId: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, StockMovement obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.change)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.saleId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
