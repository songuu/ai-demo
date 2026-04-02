// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AgentTaskAdapter extends TypeAdapter<AgentTask> {
  @override
  final int typeId = 22;

  @override
  AgentTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AgentTask(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      repoPath: fields[3] as String,
      agentType: fields[4] as String,
      status: fields[5] as AgentTaskStatus,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AgentTask obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.repoPath)
      ..writeByte(4)
      ..write(obj.agentType)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AgentTaskStatusAdapter extends TypeAdapter<AgentTaskStatus> {
  @override
  final int typeId = 25;

  @override
  AgentTaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AgentTaskStatus.pending;
      case 1:
        return AgentTaskStatus.running;
      case 2:
        return AgentTaskStatus.completed;
      case 3:
        return AgentTaskStatus.failed;
      case 4:
        return AgentTaskStatus.cancelled;
      default:
        return AgentTaskStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, AgentTaskStatus obj) {
    switch (obj) {
      case AgentTaskStatus.pending:
        writer.writeByte(0);
        break;
      case AgentTaskStatus.running:
        writer.writeByte(1);
        break;
      case AgentTaskStatus.completed:
        writer.writeByte(2);
        break;
      case AgentTaskStatus.failed:
        writer.writeByte(3);
        break;
      case AgentTaskStatus.cancelled:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentTaskStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
