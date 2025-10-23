// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonProgressAdapter extends TypeAdapter<LessonProgress> {
  @override
  final int typeId = 11;

  @override
  LessonProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonProgress(
      profileId: fields[0] as int,
      lessonId: fields[1] as int,
      completed: fields[2] as bool,
      score: fields[3] as int?,
      attempts: fields[4] as int,
      completedAt: fields[5] as DateTime?,
      lastAttemptAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LessonProgress obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.profileId)
      ..writeByte(1)
      ..write(obj.lessonId)
      ..writeByte(2)
      ..write(obj.completed)
      ..writeByte(3)
      ..write(obj.score)
      ..writeByte(4)
      ..write(obj.attempts)
      ..writeByte(5)
      ..write(obj.completedAt)
      ..writeByte(6)
      ..write(obj.lastAttemptAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
