// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cod_provider_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CodProviderConfigAdapter extends TypeAdapter<CodProviderConfig> {
  @override
  final int typeId = 11;

  @override
  CodProviderConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CodProviderConfig(
      provider: fields[0] as String,
      displayName: fields[1] as String,
      enabled: fields[2] as bool,
      command: fields[3] as String,
      apiKey: fields[4] as String?,
      environmentVariables: (fields[5] as Map?)?.cast<String, String>(),
      defaultArgs: (fields[6] as List?)?.cast<String>(),
      workingDirectoryTemplate: fields[7] as String?,
      historyPathTemplate: fields[8] as String?,
      autoImportHistory: fields[9] as bool,
      maxConcurrentSessions: fields[10] as int,
      timeoutSeconds: fields[11] as int,
      runInShell: fields[12] as bool,
      extraConfig: (fields[13] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[14] as DateTime?,
      updatedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CodProviderConfig obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.provider)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.enabled)
      ..writeByte(3)
      ..write(obj.command)
      ..writeByte(4)
      ..write(obj.apiKey)
      ..writeByte(5)
      ..write(obj.environmentVariables)
      ..writeByte(6)
      ..write(obj.defaultArgs)
      ..writeByte(7)
      ..write(obj.workingDirectoryTemplate)
      ..writeByte(8)
      ..write(obj.historyPathTemplate)
      ..writeByte(9)
      ..write(obj.autoImportHistory)
      ..writeByte(10)
      ..write(obj.maxConcurrentSessions)
      ..writeByte(11)
      ..write(obj.timeoutSeconds)
      ..writeByte(12)
      ..write(obj.runInShell)
      ..writeByte(13)
      ..write(obj.extraConfig)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodProviderConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
