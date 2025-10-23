import '../models/song_snippet.dart';

class SongSnippetService {
  static final SongSnippetService _instance = SongSnippetService._internal();
  factory SongSnippetService() => _instance;
  SongSnippetService._internal();

  /// Get all available song snippets
  List<SongSnippet> getAllSnippets() {
    return SongSnippetData.getAllSnippets();
  }

  /// Get snippets appropriate for a specific lesson
  List<SongSnippet> getSnippetsForLesson(
    int lessonId,
    List<String> completedSkills,
  ) {
    return SongSnippetData.getSnippetsForLesson(lessonId, completedSkills);
  }

  /// Get a random snippet for a lesson
  SongSnippet? getRandomSnippetForLesson(
    int lessonId,
    List<String> completedSkills,
  ) {
    return SongSnippetData.getRandomSnippetForLesson(lessonId, completedSkills);
  }

  /// Get snippets by difficulty level
  List<SongSnippet> getSnippetsByDifficulty(int difficulty) {
    return getAllSnippets()
        .where((snippet) => snippet.difficulty == difficulty)
        .toList();
  }

  /// Get snippets by category
  List<SongSnippet> getSnippetsByCategory(String category) {
    return getAllSnippets()
        .where((snippet) => snippet.category == category)
        .toList();
  }

  /// Get a snippet by ID
  SongSnippet? getSnippetById(String id) {
    return getAllSnippets().where((snippet) => snippet.id == id).firstOrNull;
  }

  /// Check if a snippet is appropriate for a user's skill level
  bool isSnippetAppropriate(SongSnippet snippet, List<String> completedSkills) {
    return snippet.requiredSkills.every(
      (skill) => completedSkills.contains(skill),
    );
  }

  /// Get the next appropriate snippet for progression
  SongSnippet? getNextSnippetForProgression(
    int currentLessonId,
    List<String> completedSkills,
  ) {
    final appropriateSnippets = getSnippetsForLesson(
      currentLessonId,
      completedSkills,
    );

    if (appropriateSnippets.isEmpty) return null;

    // Return the snippet with the lowest difficulty that the user hasn't mastered
    appropriateSnippets.sort((a, b) => a.difficulty.compareTo(b.difficulty));
    return appropriateSnippets.first;
  }

  /// Get skill requirements for a lesson based on its content
  List<String> getRequiredSkillsForLesson(int lessonId) {
    switch (lessonId) {
      case 1:
        return ['middle_c'];
      case 2:
        return ['middle_c', 'c_to_g_notes'];
      case 3:
        return ['middle_c', 'c_to_g_notes', 'rhythm_basics'];
      case 4:
        return ['middle_c', 'c_to_g_notes', 'rhythm_basics', 'extended_range'];
      default:
        return ['middle_c', 'c_to_g_notes', 'rhythm_basics'];
    }
  }

  /// Convert lesson skills to snippet skills
  List<String> convertLessonSkillsToSnippetSkills(List<String> lessonSkills) {
    // Map lesson-specific skills to snippet skills
    final skillMap = {
      'middle_c': 'middle_c',
      'c_to_g_notes': 'c_to_g_notes',
      'rhythm_basics': 'rhythm_basics',
      'extended_range': 'extended_range',
      'chord_basics': 'chord_basics',
      'scales': 'scales',
    };

    return lessonSkills
        .map((skill) => skillMap[skill] ?? skill)
        .where((skill) => skill.isNotEmpty)
        .toList();
  }
}
