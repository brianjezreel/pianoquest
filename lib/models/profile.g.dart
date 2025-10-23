// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PreferencesAdapter extends TypeAdapter<Preferences> {
  @override
  final int typeId = 7;

  @override
  Preferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Preferences(
      goal: fields[0] as Goal,
      practiceStyle: fields[1] as PracticeStyle,
      difficultyRamp: fields[2] as DifficultyRamp,
      lessonMode: fields[3] as LessonMode,
    );
  }

  @override
  void write(BinaryWriter writer, Preferences obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.goal)
      ..writeByte(1)
      ..write(obj.practiceStyle)
      ..writeByte(2)
      ..write(obj.difficultyRamp)
      ..writeByte(3)
      ..write(obj.lessonMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InitialAssessmentAdapter extends TypeAdapter<InitialAssessment> {
  @override
  final int typeId = 8;

  @override
  InitialAssessment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InitialAssessment(
      confidenceRating: fields[0] as int,
      genrePreference: (fields[1] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, InitialAssessment obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.confidenceRating)
      ..writeByte(1)
      ..write(obj.genrePreference);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InitialAssessmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProfileMetadataAdapter extends TypeAdapter<ProfileMetadata> {
  @override
  final int typeId = 9;

  @override
  ProfileMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProfileMetadata(
      createdAt: fields[0] as DateTime,
      lastActive: fields[1] as DateTime,
      xp: fields[2] as int,
      level: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ProfileMetadata obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.createdAt)
      ..writeByte(1)
      ..write(obj.lastActive)
      ..writeByte(2)
      ..write(obj.xp)
      ..writeByte(3)
      ..write(obj.level);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProfileAdapter extends TypeAdapter<Profile> {
  @override
  final int typeId = 10;

  @override
  Profile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Profile(
      profileId: fields[0] as int?,
      name: fields[1] as String,
      avatar: fields[2] as String?,
      ageRange: fields[3] as AgeRange,
      skillLevel: fields[4] as SkillLevel,
      experience: fields[5] as bool,
      musicReading: fields[6] as MusicReading,
      preferences: fields[7] as Preferences,
      initialAssessment: fields[8] as InitialAssessment,
      metadata: fields[9] as ProfileMetadata,
    );
  }

  @override
  void write(BinaryWriter writer, Profile obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.profileId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatar)
      ..writeByte(3)
      ..write(obj.ageRange)
      ..writeByte(4)
      ..write(obj.skillLevel)
      ..writeByte(5)
      ..write(obj.experience)
      ..writeByte(6)
      ..write(obj.musicReading)
      ..writeByte(7)
      ..write(obj.preferences)
      ..writeByte(8)
      ..write(obj.initialAssessment)
      ..writeByte(9)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AgeRangeAdapter extends TypeAdapter<AgeRange> {
  @override
  final int typeId = 0;

  @override
  AgeRange read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AgeRange.child;
      case 1:
        return AgeRange.teen;
      case 2:
        return AgeRange.adult;
      default:
        return AgeRange.child;
    }
  }

  @override
  void write(BinaryWriter writer, AgeRange obj) {
    switch (obj) {
      case AgeRange.child:
        writer.writeByte(0);
        break;
      case AgeRange.teen:
        writer.writeByte(1);
        break;
      case AgeRange.adult:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgeRangeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SkillLevelAdapter extends TypeAdapter<SkillLevel> {
  @override
  final int typeId = 1;

  @override
  SkillLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SkillLevel.beginner;
      case 1:
        return SkillLevel.intermediate;
      case 2:
        return SkillLevel.advanced;
      default:
        return SkillLevel.beginner;
    }
  }

  @override
  void write(BinaryWriter writer, SkillLevel obj) {
    switch (obj) {
      case SkillLevel.beginner:
        writer.writeByte(0);
        break;
      case SkillLevel.intermediate:
        writer.writeByte(1);
        break;
      case SkillLevel.advanced:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MusicReadingAdapter extends TypeAdapter<MusicReading> {
  @override
  final int typeId = 2;

  @override
  MusicReading read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MusicReading.none;
      case 1:
        return MusicReading.basic;
      case 2:
        return MusicReading.fluent;
      default:
        return MusicReading.none;
    }
  }

  @override
  void write(BinaryWriter writer, MusicReading obj) {
    switch (obj) {
      case MusicReading.none:
        writer.writeByte(0);
        break;
      case MusicReading.basic:
        writer.writeByte(1);
        break;
      case MusicReading.fluent:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicReadingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final int typeId = 3;

  @override
  Goal read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Goal.fun;
      case 1:
        return Goal.technique;
      case 2:
        return Goal.theory;
      case 3:
        return Goal.songs;
      default:
        return Goal.fun;
    }
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    switch (obj) {
      case Goal.fun:
        writer.writeByte(0);
        break;
      case Goal.technique:
        writer.writeByte(1);
        break;
      case Goal.theory:
        writer.writeByte(2);
        break;
      case Goal.songs:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PracticeStyleAdapter extends TypeAdapter<PracticeStyle> {
  @override
  final int typeId = 4;

  @override
  PracticeStyle read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PracticeStyle.short_frequent;
      case 1:
        return PracticeStyle.long_focused;
      default:
        return PracticeStyle.short_frequent;
    }
  }

  @override
  void write(BinaryWriter writer, PracticeStyle obj) {
    switch (obj) {
      case PracticeStyle.short_frequent:
        writer.writeByte(0);
        break;
      case PracticeStyle.long_focused:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeStyleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DifficultyRampAdapter extends TypeAdapter<DifficultyRamp> {
  @override
  final int typeId = 5;

  @override
  DifficultyRamp read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DifficultyRamp.gentle;
      case 1:
        return DifficultyRamp.moderate;
      case 2:
        return DifficultyRamp.challenging;
      default:
        return DifficultyRamp.gentle;
    }
  }

  @override
  void write(BinaryWriter writer, DifficultyRamp obj) {
    switch (obj) {
      case DifficultyRamp.gentle:
        writer.writeByte(0);
        break;
      case DifficultyRamp.moderate:
        writer.writeByte(1);
        break;
      case DifficultyRamp.challenging:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DifficultyRampAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LessonModeAdapter extends TypeAdapter<LessonMode> {
  @override
  final int typeId = 6;

  @override
  LessonMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LessonMode.game;
      case 1:
        return LessonMode.structured;
      case 2:
        return LessonMode.free;
      default:
        return LessonMode.game;
    }
  }

  @override
  void write(BinaryWriter writer, LessonMode obj) {
    switch (obj) {
      case LessonMode.game:
        writer.writeByte(0);
        break;
      case LessonMode.structured:
        writer.writeByte(1);
        break;
      case LessonMode.free:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
