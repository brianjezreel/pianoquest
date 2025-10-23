import 'package:hive/hive.dart';

part 'lesson_progress.g.dart';

@HiveType(typeId: 11)
class LessonProgress {
  @HiveField(0)
  final int profileId; // Link to Profile
  @HiveField(1)
  final int lessonId;
  @HiveField(2)
  final bool completed;
  @HiveField(3)
  final int? score; // Optional score out of 100
  @HiveField(4)
  final int attempts;
  @HiveField(5)
  final DateTime? completedAt;
  @HiveField(6)
  final DateTime lastAttemptAt;

  LessonProgress({
    required this.profileId,
    required this.lessonId,
    required this.completed,
    this.score,
    required this.attempts,
    this.completedAt,
    required this.lastAttemptAt,
  });

  LessonProgress copyWith({
    int? profileId,
    int? lessonId,
    bool? completed,
    int? score,
    int? attempts,
    DateTime? completedAt,
    DateTime? lastAttemptAt,
  }) {
    return LessonProgress(
      profileId: profileId ?? this.profileId,
      lessonId: lessonId ?? this.lessonId,
      completed: completed ?? this.completed,
      score: score ?? this.score,
      attempts: attempts ?? this.attempts,
      completedAt: completedAt ?? this.completedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  // Helper method to create a unique key for this progress entry
  String get uniqueKey => '${profileId}_$lessonId';
} 