// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyLogModelAdapter extends TypeAdapter<DailyLogModel> {
  @override
  final int typeId = 1;

  @override
  DailyLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyLogModel(
      id: fields[0] as String,
      odIduserId: fields[1] as String,
      activityId: fields[2] as int,
      date: fields[3] as DateTime,
      value: fields[4] as int,
      status: fields[5] as String,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime?,
      isSynced: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DailyLogModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.odIduserId)
      ..writeByte(2)
      ..write(obj.activityId)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.value)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
