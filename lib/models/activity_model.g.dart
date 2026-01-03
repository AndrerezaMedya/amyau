// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityModelAdapter extends TypeAdapter<ActivityModel> {
  @override
  final int typeId = 0;

  @override
  ActivityModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityModel(
      id: fields[0] as int,
      name: fields[1] as String,
      target: fields[2] as String,
      jenis: fields[3] as ActivityJenis,
      evaluationPeriod: fields[4] as EvaluationPeriod,
      keterangan: fields[5] as String,
      threshold: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.target)
      ..writeByte(3)
      ..write(obj.jenis)
      ..writeByte(4)
      ..write(obj.evaluationPeriod)
      ..writeByte(5)
      ..write(obj.keterangan)
      ..writeByte(6)
      ..write(obj.threshold);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
