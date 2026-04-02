// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swarm_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SwarmSessionAdapter extends TypeAdapter<SwarmSession> {
  @override
  final int typeId = 21;

  @override
  SwarmSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SwarmSession(
      id: fields[0] as String,
      taskId: fields[1] as String,
      worktreeId: fields[2] as String,
      codSessionId: fields[3] as String?,
      status: fields[4] as SwarmSessionStatus,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime?,
      agentType: fields[7] as String,
      title: fields[8] as String,
      branch: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SwarmSession obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.worktreeId)
      ..writeByte(3)
      ..write(obj.codSessionId)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.agentType)
      ..writeByte(8)
      ..write(obj.title)
      ..writeByte(9)
      ..write(obj.branch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwarmSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SwarmSessionStatusAdapter extends TypeAdapter<SwarmSessionStatus> {
  @override
  final int typeId = 26;

  @override
  SwarmSessionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SwarmSessionStatus.initializing;
      case 1:
        return SwarmSessionStatus.running;
      case 2:
        return SwarmSessionStatus.paused;
      case 3:
        return SwarmSessionStatus.completed;
      case 4:
        return SwarmSessionStatus.failed;
      default:
        return SwarmSessionStatus.initializing;
    }
  }

  @override
  void write(BinaryWriter writer, SwarmSessionStatus obj) {
    switch (obj) {
      case SwarmSessionStatus.initializing:
        writer.writeByte(0);
        break;
      case SwarmSessionStatus.running:
        writer.writeByte(1);
        break;
      case SwarmSessionStatus.paused:
        writer.writeByte(2);
        break;
      case SwarmSessionStatus.completed:
        writer.writeByte(3);
        break;
      case SwarmSessionStatus.failed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwarmSessionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
