import 'package:hive/hive.dart';
import '../models/lesson_progress.dart';

class ProgressRepository {
  static const String _boxName = 'lesson_progress';
  static Box<LessonProgress>? _sharedBox;
  late Box<LessonProgress> _progressBox;

  // Initialize the repository
  Future<void> initialize() async {
    // Use shared box if already open, otherwise open it
    if (_sharedBox == null || !_sharedBox!.isOpen) {
      _sharedBox = await Hive.openBox<LessonProgress>(_boxName);
    }
    _progressBox = _sharedBox!;
  }

  // Create or update lesson progress
  Future<void> updateProgress(LessonProgress progress) async {
    await _progressBox.put(progress.uniqueKey, progress);
  }

  // Get progress for a specific profile and lesson
  LessonProgress? getProgress(int profileId, int lessonId) {
    final key = '${profileId}_$lessonId';
    return _progressBox.get(key);
  }

  // Get all progress for a specific profile
  List<LessonProgress> getProfileProgress(int profileId) {
    return _progressBox.values
        .where((progress) => progress.profileId == profileId)
        .toList();
  }

  // Get completed lesson IDs for a profile
  List<int> getCompletedLessonIds(int profileId) {
    return _progressBox.values
        .where((progress) => 
            progress.profileId == profileId && progress.completed)
        .map((progress) => progress.lessonId)
        .toList();
  }

  // Mark a lesson as completed
  Future<void> markLessonCompleted(
    int profileId, 
    int lessonId, 
    {int? score}
  ) async {
    final existing = getProgress(profileId, lessonId);
    final now = DateTime.now();
    
    final progress = LessonProgress(
      profileId: profileId,
      lessonId: lessonId,
      completed: true,
      score: score,
      attempts: (existing?.attempts ?? 0) + 1,
      completedAt: now,
      lastAttemptAt: now,
    );
    
    await updateProgress(progress);
  }

  // Record a lesson attempt (not necessarily completed)
  Future<void> recordAttempt(
    int profileId, 
    int lessonId, 
    {int? score, bool completed = false}
  ) async {
    final existing = getProgress(profileId, lessonId);
    final now = DateTime.now();
    
    final progress = LessonProgress(
      profileId: profileId,
      lessonId: lessonId,
      completed: completed,
      score: score,
      attempts: (existing?.attempts ?? 0) + 1,
      completedAt: completed ? now : existing?.completedAt,
      lastAttemptAt: now,
    );
    
    await updateProgress(progress);
  }

  // Get total completed lessons count for a profile
  int getCompletedLessonsCount(int profileId) {
    return getCompletedLessonIds(profileId).length;
  }

  // Get average score for completed lessons
  double getAverageScore(int profileId) {
    final completedLessons = _progressBox.values
        .where((progress) => 
            progress.profileId == profileId && 
            progress.completed && 
            progress.score != null)
        .toList();
    
    if (completedLessons.isEmpty) return 0.0;
    
    final totalScore = completedLessons
        .map((progress) => progress.score!)
        .reduce((a, b) => a + b);
    
    return totalScore / completedLessons.length;
  }

  // Delete all progress for a profile (when profile is deleted)
  Future<void> deleteProfileProgress(int profileId) async {
    final keysToDelete = _progressBox.values
        .where((progress) => progress.profileId == profileId)
        .map((progress) => progress.uniqueKey)
        .toList();
    
    for (final key in keysToDelete) {
      await _progressBox.delete(key);
    }
  }

  // Check if a lesson is unlocked for a profile (based on prerequisites)
  bool isLessonUnlocked(int profileId, List<int> prerequisites) {
    final completedIds = getCompletedLessonIds(profileId);
    return prerequisites.every((prereqId) => completedIds.contains(prereqId));
  }

  // Get progress statistics for a profile
  Map<String, dynamic> getProgressStats(int profileId) {
    final allProgress = getProfileProgress(profileId);
    final completed = allProgress.where((p) => p.completed).toList();
    final totalAttempts = allProgress.isNotEmpty 
        ? allProgress.map((p) => p.attempts).reduce((a, b) => a + b) 
        : 0;
    
    return {
      'totalLessonsAttempted': allProgress.length,
      'totalLessonsCompleted': completed.length,
      'totalAttempts': totalAttempts,
      'averageScore': getAverageScore(profileId),
      'lastActivity': allProgress.isNotEmpty 
          ? allProgress.map((p) => p.lastAttemptAt).reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }

  // Close the repository
  Future<void> close() async {
    // Don't close the shared box - it will be closed when the app terminates
    // This prevents "box already closed" errors when multiple repositories exist
  }

  // Close the shared box - call this when app terminates
  static Future<void> closeSharedBox() async {
    if (_sharedBox != null && _sharedBox!.isOpen) {
      await _sharedBox!.close();
      _sharedBox = null;
    }
  }
} 