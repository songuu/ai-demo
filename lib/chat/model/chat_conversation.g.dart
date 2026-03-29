// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_conversation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatConversationAdapter extends TypeAdapter<ChatConversation> {
  @override
  final int typeId = 17;

  @override
  ChatConversation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatConversation(
      id: fields[0] as String,
      title: fields[1] as String,
      modelId: fields[2] as String?,
      providerId: fields[3] as String?,
      systemPrompt: fields[4] as String?,
      temperature: fields[5] as double,
      maxTokens: fields[6] as int,
      isPinned: fields[7] as bool,
      isArchived: fields[8] as bool,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
      webSearchEnabled: fields[11] as bool,
      mcpServerIds: (fields[12] as List).cast<String>(),
      messageCount: fields[13] as int,
      lastMessagePreview: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatConversation obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.modelId)
      ..writeByte(3)
      ..write(obj.providerId)
      ..writeByte(4)
      ..write(obj.systemPrompt)
      ..writeByte(5)
      ..write(obj.temperature)
      ..writeByte(6)
      ..write(obj.maxTokens)
      ..writeByte(7)
      ..write(obj.isPinned)
      ..writeByte(8)
      ..write(obj.isArchived)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.webSearchEnabled)
      ..writeByte(12)
      ..write(obj.mcpServerIds)
      ..writeByte(13)
      ..write(obj.messageCount)
      ..writeByte(14)
      ..write(obj.lastMessagePreview);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatConversationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
