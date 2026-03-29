// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_server_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class McpServerConfigAdapter extends TypeAdapter<McpServerConfig> {
  @override
  final int typeId = 19;

  @override
  McpServerConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return McpServerConfig(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      command: fields[3] as String,
      args: (fields[4] as List).cast<String>(),
      url: fields[5] as String?,
      env: (fields[6] as Map).cast<String, String>(),
      enabled: fields[7] as bool,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      cachedTools: (fields[10] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
    );
  }

  @override
  void write(BinaryWriter writer, McpServerConfig obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.command)
      ..writeByte(4)
      ..write(obj.args)
      ..writeByte(5)
      ..write(obj.url)
      ..writeByte(6)
      ..write(obj.env)
      ..writeByte(7)
      ..write(obj.enabled)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.cachedTools);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is McpServerConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
