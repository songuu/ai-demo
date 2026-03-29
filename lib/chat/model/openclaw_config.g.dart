// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'openclaw_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OpenClawConfigAdapter extends TypeAdapter<OpenClawConfig> {
  @override
  final int typeId = 20;

  @override
  OpenClawConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OpenClawConfig(
      id: fields[0] as String,
      gatewayUrl: fields[1] as String,
      enabled: fields[2] as bool,
      acpxPath: fields[3] as String?,
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
      cachedStatus: (fields[6] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, OpenClawConfig obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.gatewayUrl)
      ..writeByte(2)
      ..write(obj.enabled)
      ..writeByte(3)
      ..write(obj.acpxPath)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.cachedStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenClawConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
