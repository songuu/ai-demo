// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worktree.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorktreeAdapter extends TypeAdapter<Worktree> {
  @override
  final int typeId = 23;

  @override
  Worktree read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Worktree(
      id: fields[0] as String,
      sessionId: fields[1] as String,
      path: fields[2] as String,
      branch: fields[3] as String,
      commit: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      remotePath: fields[6] as String,
      status: fields[7] as WorktreeStatus,
    );
  }

  @override
  void write(BinaryWriter writer, Worktree obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.branch)
      ..writeByte(4)
      ..write(obj.commit)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.remotePath)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorktreeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorktreeStatusAdapter extends TypeAdapter<WorktreeStatus> {
  @override
  final int typeId = 24;

  @override
  WorktreeStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WorktreeStatus.active;
      case 1:
        return WorktreeStatus.idle;
      case 2:
        return WorktreeStatus.stale;
      case 3:
        return WorktreeStatus.deleted;
      default:
        return WorktreeStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, WorktreeStatus obj) {
    switch (obj) {
      case WorktreeStatus.active:
        writer.writeByte(0);
        break;
      case WorktreeStatus.idle:
        writer.writeByte(1);
        break;
      case WorktreeStatus.stale:
        writer.writeByte(2);
        break;
      case WorktreeStatus.deleted:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorktreeStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
