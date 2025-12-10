// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuditSessionAdapter extends TypeAdapter<AuditSession> {
  @override
  final int typeId = 7;

  @override
  AuditSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuditSession(
      id: fields[0] as int,
      locationId: fields[1] as int,
      startedAt: fields[2] as DateTime,
      status: fields[4] as String,
      finishedAt: fields[3] as DateTime?,
      lines: (fields[5] as List?)?.cast<AuditLine>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, AuditSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.locationId)
      ..writeByte(2)
      ..write(obj.startedAt)
      ..writeByte(3)
      ..write(obj.finishedAt)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.lines);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AuditLineAdapter extends TypeAdapter<AuditLine> {
  @override
  final int typeId = 8;

  @override
  AuditLine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuditLine(
      productId: fields[0] as int,
      countedQuantity: fields[1] as double,
      expectedQuantity: fields[2] as double,
      difference: fields[3] as double?,
      differenceValue: fields[4] as double?,
      unitCost: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, AuditLine obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.countedQuantity)
      ..writeByte(2)
      ..write(obj.expectedQuantity)
      ..writeByte(3)
      ..write(obj.difference)
      ..writeByte(4)
      ..write(obj.differenceValue)
      ..writeByte(5)
      ..write(obj.unitCost);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
