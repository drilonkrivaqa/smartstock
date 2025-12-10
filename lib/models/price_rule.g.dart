// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PriceRuleAdapter extends TypeAdapter<PriceRule> {
  @override
  final int typeId = 9;

  @override
  PriceRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceRule(
      id: fields[0] as int,
      name: fields[1] as String,
      targetType: fields[5] as String,
      conditionType: fields[7] as String,
      effectType: fields[10] as String,
      priority: fields[14] as int,
      locationScope: fields[4] as int?,
      targetIds: (fields[6] as List?)?.cast<String>() ?? const [],
      conditionMinQty: fields[8] as int?,
      daysOfWeek: (fields[9] as List?)?.cast<int>(),
      effectValue: fields[11] as double?,
      rewardQuantity: fields[12] as int?,
      rewardProductId: fields[13] as int?,
      activeFrom: fields[2] as DateTime?,
      activeUntil: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PriceRule obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.activeFrom)
      ..writeByte(3)
      ..write(obj.activeUntil)
      ..writeByte(4)
      ..write(obj.locationScope)
      ..writeByte(5)
      ..write(obj.targetType)
      ..writeByte(6)
      ..write(obj.targetIds)
      ..writeByte(7)
      ..write(obj.conditionType)
      ..writeByte(8)
      ..write(obj.conditionMinQty)
      ..writeByte(9)
      ..write(obj.daysOfWeek)
      ..writeByte(10)
      ..write(obj.effectType)
      ..writeByte(11)
      ..write(obj.effectValue)
      ..writeByte(12)
      ..write(obj.rewardQuantity)
      ..writeByte(13)
      ..write(obj.rewardProductId)
      ..writeByte(14)
      ..write(obj.priority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
