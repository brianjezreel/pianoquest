import '../models/lesson.dart';

class LessonsRepository {
  // Cache for loaded lessons
  List<Lesson>? _cachedLessons;

  // Load all lessons from static data
  List<Lesson> getAllLessons() {
    _cachedLessons ??= LessonsData.getAllLessons();
    return _cachedLessons!;
  }

  // Get a specific lesson by ID
  Lesson? getLessonById(int lessonId) {
    return LessonsData.getLessonById(lessonId);
  }

  // Get lessons by category
  List<Lesson> getLessonsByCategory(String category) {
    return LessonsData.getLessonsByCategory(category);
  }

  // Get available categories
  List<String> getCategories() {
    final lessons = getAllLessons();
    return lessons.map((lesson) => lesson.category).toSet().toList();
  }

  // Get lessons that are unlocked for a profile
  List<Lesson> getUnlockedLessons(List<int> completedLessonIds) {
    final allLessons = getAllLessons();
    return allLessons.where((lesson) => lesson.isUnlocked(completedLessonIds)).toList();
  }

  // Get the next recommended lesson for a profile
  Lesson? getNextLesson(List<int> completedLessonIds) {
    final unlockedLessons = getUnlockedLessons(completedLessonIds);
    final incompleteLessons = unlockedLessons
        .where((lesson) => !completedLessonIds.contains(lesson.lessonId))
        .toList();
    
    if (incompleteLessons.isEmpty) return null;
    
    // Sort by lesson ID to get the next logical lesson
    incompleteLessons.sort((a, b) => a.lessonId.compareTo(b.lessonId));
    return incompleteLessons.first;
  }

  // Get lesson progress information
  Map<String, dynamic> getLessonOverview(List<int> completedLessonIds) {
    final allLessons = getAllLessons();
    final unlockedLessons = getUnlockedLessons(completedLessonIds);
    final completedLessons = allLessons
        .where((lesson) => completedLessonIds.contains(lesson.lessonId))
        .toList();

    return {
      'totalLessons': allLessons.length,
      'completedLessons': completedLessons.length,
      'unlockedLessons': unlockedLessons.length,
      'availableLessons': unlockedLessons.length - completedLessons.length,
      'completionPercentage': (completedLessons.length / allLessons.length * 100).round(),
    };
  }

  // TODO: Future expansion - Load lessons from assets/JSON
  // Future<List<Lesson>> loadLessonsFromAssets() async {
  //   final String jsonString = await rootBundle.loadString('assets/data/lessons.json');
  //   final List<dynamic> jsonData = json.decode(jsonString);
  //   return jsonData.map((json) => Lesson.fromJson(json)).toList();
  // }

  // TODO: Future expansion - Integration with AI tutor
  // Future<List<LessonSlide>> generateAdaptiveLessonSlides(
  //   int profileId, 
  //   int lessonId, 
  //   Map<String, dynamic> performanceData
  // ) async {
  //   // This would call an AI service to generate personalized lesson content
  //   // based on the student's performance and learning style
  //   throw UnimplementedError('AI tutor integration coming soon');
  // }

  // TODO: Future expansion - Cloud sync
  // Future<void> syncLessonsWithCloud() async {
  //   // This would sync lesson content and progress with a cloud service
  //   throw UnimplementedError('Cloud sync coming soon');
  // }
} 