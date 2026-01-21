// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cod_skill.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CodSkillAdapter extends TypeAdapter<CodSkill> {
  @override
  final int typeId = 14;

  @override
  CodSkill read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CodSkill(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      content: fields[3] as String,
      type: fields[4] as CodSkillType,
      provider: fields[5] as CodSkillProvider,
      tags: (fields[6] as List?)?.cast<String>(),
      isFavorite: fields[7] as bool,
      isEnabled: fields[8] as bool,
      useCount: fields[9] as int,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
      lastUsedAt: fields[12] as DateTime?,
      syncId: fields[13] as String?,
      syncStatus: fields[14] as int,
      metadata: (fields[15] as Map?)?.cast<String, dynamic>(),
      shortcut: fields[16] as String?,
      variables: (fields[17] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CodSkill obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.provider)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.isFavorite)
      ..writeByte(8)
      ..write(obj.isEnabled)
      ..writeByte(9)
      ..write(obj.useCount)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.lastUsedAt)
      ..writeByte(13)
      ..write(obj.syncId)
      ..writeByte(14)
      ..write(obj.syncStatus)
      ..writeByte(15)
      ..write(obj.metadata)
      ..writeByte(16)
      ..write(obj.shortcut)
      ..writeByte(17)
      ..write(obj.variables);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodSkillAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CodSkillTypeAdapter extends TypeAdapter<CodSkillType> {
  @override
  final int typeId = 12;

  @override
  CodSkillType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CodSkillType.systemPrompt;
      case 1:
        return CodSkillType.codeTemplate;
      case 2:
        return CodSkillType.workflow;
      case 3:
        return CodSkillType.customCommand;
      case 4:
        return CodSkillType.promptSnippet;
      default:
        return CodSkillType.systemPrompt;
    }
  }

  @override
  void write(BinaryWriter writer, CodSkillType obj) {
    switch (obj) {
      case CodSkillType.systemPrompt:
        writer.writeByte(0);
        break;
      case CodSkillType.codeTemplate:
        writer.writeByte(1);
        break;
      case CodSkillType.workflow:
        writer.writeByte(2);
        break;
      case CodSkillType.customCommand:
        writer.writeByte(3);
        break;
      case CodSkillType.promptSnippet:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodSkillTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CodSkillProviderAdapter extends TypeAdapter<CodSkillProvider> {
  @override
  final int typeId = 13;

  @override
  CodSkillProvider read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CodSkillProvider.all;
      case 1:
        return CodSkillProvider.claude;
      case 2:
        return CodSkillProvider.codex;
      case 3:
        return CodSkillProvider.gemini;
      default:
        return CodSkillProvider.all;
    }
  }

  @override
  void write(BinaryWriter writer, CodSkillProvider obj) {
    switch (obj) {
      case CodSkillProvider.all:
        writer.writeByte(0);
        break;
      case CodSkillProvider.claude:
        writer.writeByte(1);
        break;
      case CodSkillProvider.codex:
        writer.writeByte(2);
        break;
      case CodSkillProvider.gemini:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodSkillProviderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
