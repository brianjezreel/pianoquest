import 'dart:math' as math;

class SongSnippet {
  final String id;
  final String title;
  final String composer;
  final String description;
  final int difficulty; // 1-5 scale
  final int bpm;
  final List<SongNote> notes;
  final String category; // e.g., "classical", "folk", "children"
  final List<String> requiredSkills; // Skills needed to play this snippet

  const SongSnippet({
    required this.id,
    required this.title,
    required this.composer,
    required this.description,
    required this.difficulty,
    required this.bpm,
    required this.notes,
    required this.category,
    required this.requiredSkills,
  });

  /// Get notes that should be played in sequence
  List<SongNote> get sequentialNotes =>
      notes.where((note) => note.isSequential).toList();

  /// Get notes that can be played simultaneously (chords)
  List<SongNote> get chordNotes =>
      notes.where((note) => !note.isSequential).toList();

  /// Get the duration of the entire snippet in seconds
  double get totalDuration {
    if (notes.isEmpty) return 0.0;
    return notes
        .map((note) => note.startTime + note.duration)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Check if this snippet is appropriate for a given lesson
  bool isAppropriateForLesson(int lessonId, List<String> completedSkills) {
    // Check if all required skills have been completed
    return requiredSkills.every((skill) => completedSkills.contains(skill));
  }
}

class SongNote {
  final String noteName; // e.g., "C", "D#", "F"
  final int octave; // e.g., 4, 5
  final double startTime; // Time in seconds from start of snippet
  final double duration; // Duration in seconds
  final bool isSequential; // true for melody notes, false for chord notes
  final int velocity; // 0-127 for MIDI velocity
  final String? lyric; // Optional lyric for this note

  const SongNote({
    required this.noteName,
    required this.octave,
    required this.startTime,
    required this.duration,
    this.isSequential = true,
    this.velocity = 80,
    this.lyric,
  });

  /// Get the note with octave (e.g., "C4", "D#5")
  String get noteWithOctave => '$noteName$octave';

  /// Get the frequency of this note
  double get frequency {
    // A4 = 440 Hz reference
    const a4Frequency = 440.0;
    const a4NoteNumber = 69; // A4 is MIDI note 69

    // Calculate MIDI note number
    final noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    final noteIndex = noteNames.indexOf(noteName);
    if (noteIndex == -1) return 0.0;

    final noteNumber = (octave + 1) * 12 + noteIndex;

    // Calculate frequency using the formula: f = 440 * 2^((n-69)/12)
    return a4Frequency * math.pow(2.0, (noteNumber - a4NoteNumber) / 12);
  }

  /// Get the MIDI note number
  int get midiNoteNumber {
    final noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    final noteIndex = noteNames.indexOf(noteName);
    if (noteIndex == -1) return 0;

    return (octave + 1) * 12 + noteIndex;
  }
}

/// Static data for song snippets
class SongSnippetData {
  static List<SongSnippet> getAllSnippets() {
    return [
      // Beginner snippets for lesson 1 (Middle C)
      SongSnippet(
        id: 'twinkle_twinkle',
        title: 'Twinkle, Twinkle, Little Star',
        composer: 'Traditional',
        description: 'A simple melody using only Middle C',
        difficulty: 1,
        bpm: 60,
        category: 'children',
        requiredSkills: ['middle_c'],
        notes: [
          SongNote(noteName: 'C', octave: 4, startTime: 0.0, duration: 1.0),
          SongNote(noteName: 'C', octave: 4, startTime: 1.0, duration: 1.0),
          SongNote(noteName: 'G', octave: 4, startTime: 2.0, duration: 1.0),
          SongNote(noteName: 'G', octave: 4, startTime: 3.0, duration: 1.0),
          SongNote(noteName: 'A', octave: 4, startTime: 4.0, duration: 1.0),
          SongNote(noteName: 'A', octave: 4, startTime: 5.0, duration: 1.0),
          SongNote(noteName: 'G', octave: 4, startTime: 6.0, duration: 2.0),
        ],
      ),

      // Snippets for lesson 2 (C-G notes)
      SongSnippet(
        id: 'mary_had_little_lamb',
        title: 'Mary Had a Little Lamb',
        composer: 'Traditional',
        description: 'A simple melody using C, D, E, F, G',
        difficulty: 2,
        bpm: 80,
        category: 'children',
        requiredSkills: ['c_to_g_notes'],
        notes: [
          SongNote(noteName: 'E', octave: 4, startTime: 0.0, duration: 0.5),
          SongNote(noteName: 'D', octave: 4, startTime: 0.5, duration: 0.5),
          SongNote(noteName: 'C', octave: 4, startTime: 1.0, duration: 0.5),
          SongNote(noteName: 'D', octave: 4, startTime: 1.5, duration: 0.5),
          SongNote(noteName: 'E', octave: 4, startTime: 2.0, duration: 0.5),
          SongNote(noteName: 'E', octave: 4, startTime: 2.5, duration: 0.5),
          SongNote(noteName: 'E', octave: 4, startTime: 3.0, duration: 1.0),
          SongNote(noteName: 'D', octave: 4, startTime: 4.0, duration: 0.5),
          SongNote(noteName: 'D', octave: 4, startTime: 4.5, duration: 0.5),
          SongNote(noteName: 'D', octave: 4, startTime: 5.0, duration: 1.0),
          SongNote(noteName: 'E', octave: 4, startTime: 6.0, duration: 0.5),
          SongNote(noteName: 'G', octave: 4, startTime: 6.5, duration: 1.0),
        ],
      ),

      // Snippets for lesson 3 (Rhythm basics)
      SongSnippet(
        id: 'hot_cross_buns',
        title: 'Hot Cross Buns',
        composer: 'Traditional',
        description: 'A simple rhythm exercise with quarter notes',
        difficulty: 2,
        bpm: 100,
        category: 'children',
        requiredSkills: ['rhythm_basics', 'c_to_g_notes'],
        notes: [
          SongNote(noteName: 'E', octave: 4, startTime: 0.0, duration: 1.0),
          SongNote(noteName: 'D', octave: 4, startTime: 1.0, duration: 1.0),
          SongNote(noteName: 'C', octave: 4, startTime: 2.0, duration: 2.0),
          SongNote(noteName: 'E', octave: 4, startTime: 4.0, duration: 1.0),
          SongNote(noteName: 'D', octave: 4, startTime: 5.0, duration: 1.0),
          SongNote(noteName: 'C', octave: 4, startTime: 6.0, duration: 2.0),
        ],
      ),

      // More advanced snippets for later lessons
      SongSnippet(
        id: 'ode_to_joy',
        title: 'Ode to Joy (Excerpt)',
        composer: 'Ludwig van Beethoven',
        description: 'A famous melody using a wider range of notes',
        difficulty: 3,
        bpm: 120,
        category: 'classical',
        requiredSkills: ['c_to_g_notes', 'rhythm_basics', 'extended_range'],
        notes: [
          SongNote(noteName: 'E', octave: 4, startTime: 0.0, duration: 0.5),
          SongNote(noteName: 'E', octave: 4, startTime: 0.5, duration: 0.5),
          SongNote(noteName: 'F', octave: 4, startTime: 1.0, duration: 0.5),
          SongNote(noteName: 'G', octave: 4, startTime: 1.5, duration: 0.5),
          SongNote(noteName: 'G', octave: 4, startTime: 2.0, duration: 0.5),
          SongNote(noteName: 'F', octave: 4, startTime: 2.5, duration: 0.5),
          SongNote(noteName: 'E', octave: 4, startTime: 3.0, duration: 0.5),
          SongNote(noteName: 'D', octave: 4, startTime: 3.5, duration: 0.5),
          SongNote(noteName: 'C', octave: 4, startTime: 4.0, duration: 0.5),
          SongNote(noteName: 'C', octave: 4, startTime: 4.5, duration: 0.5),
          SongNote(noteName: 'D', octave: 4, startTime: 5.0, duration: 0.5),
          SongNote(noteName: 'E', octave: 4, startTime: 5.5, duration: 1.0),
        ],
      ),
    ];
  }

  /// Get snippets appropriate for a specific lesson
  static List<SongSnippet> getSnippetsForLesson(
    int lessonId,
    List<String> completedSkills,
  ) {
    final allSnippets = getAllSnippets();
    return allSnippets
        .where(
          (snippet) =>
              snippet.isAppropriateForLesson(lessonId, completedSkills),
        )
        .toList();
  }

  /// Get a random snippet for a lesson
  static SongSnippet? getRandomSnippetForLesson(
    int lessonId,
    List<String> completedSkills,
  ) {
    final appropriateSnippets = getSnippetsForLesson(lessonId, completedSkills);
    if (appropriateSnippets.isEmpty) return null;

    // For now, return the first appropriate snippet
    // In a real app, you might want to randomize this
    return appropriateSnippets.first;
  }
}
