// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatProviderAdapter extends TypeAdapter<ChatProvider> {
  @override
  final int typeId = 15;

  @override
  ChatProvider read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatProvider(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      apiHost: fields[3] as String,
      apiKey: fields[4] as String,
      enabled: fields[5] as bool,
      models: (fields[6] as List).cast<String>(),
      extraHeaders: (fields[7] as Map).cast<String, String>(),
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      sortOrder: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ChatProvider obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.apiHost)
      ..writeByte(4)
      ..write(obj.apiKey)
      ..writeByte(5)
      ..write(obj.enabled)
      ..writeByte(6)
      ..write(obj.models)
      ..writeByte(7)
      ..write(obj.extraHeaders)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatProviderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
