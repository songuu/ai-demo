// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cod_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CodSessionAdapter extends TypeAdapter<CodSession> {
  @override
  final int typeId = 10;

  @override
  CodSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CodSession(
      id: fields[0] as String,
      provider: fields[1] as String,
      title: fields[2] as String,
      cwd: fields[3] as String,
      command: fields[4] as String,
      args: (fields[5] as List).cast<String>(),
      logPath: fields[6] as String,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      exitCode: fields[10] as int?,
      status: fields[9] as CodSessionStatus,
    );
  }

  @override
  void write(BinaryWriter writer, CodSession obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.provider)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.cwd)
      ..writeByte(4)
      ..write(obj.command)
      ..writeByte(5)
      ..write(obj.args)
      ..writeByte(6)
      ..write(obj.logPath)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.exitCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CodSessionStatusAdapter extends TypeAdapter<CodSessionStatus> {
  @override
  final int typeId = 9;

  @override
  CodSessionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CodSessionStatus.pending;
      case 1:
        return CodSessionStatus.running;
      case 2:
        return CodSessionStatus.completed;
      case 3:
        return CodSessionStatus.failed;
      default:
        return CodSessionStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, CodSessionStatus obj) {
    switch (obj) {
      case CodSessionStatus.pending:
        writer.writeByte(0);
        break;
      case CodSessionStatus.running:
        writer.writeByte(1);
        break;
      case CodSessionStatus.completed:
        writer.writeByte(2);
        break;
      case CodSessionStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodSessionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
