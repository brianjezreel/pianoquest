class LessonSlide {
  final int slideId;
  final String title;
  final String instruction;
  final String? visualAid; // Path to image or description
  final LessonSlideType type;
  final Map<String, dynamic>? interactionData; // Data for interactive elements

  LessonSlide({
    required this.slideId,
    required this.title,
    required this.instruction,
    this.visualAid,
    required this.type,
    this.interactionData,
  });
}

enum LessonSlideType {
  instruction, // Show text and visual
  interaction, // Interactive element (piano keys, quiz, etc.)
  quiz, // Multiple choice question
  practice, // Free practice with feedback
  reward, // Show completion reward
  songSnippet, // Play a song snippet with note detection
}

class Lesson {
  final int lessonId;
  final String title;
  final String description;
  final String category;
  final int xpReward;
  final List<int>
  prerequisites; // List of lesson IDs that must be completed first
  final List<LessonSlide> slides;

  Lesson({
    required this.lessonId,
    required this.title,
    required this.description,
    required this.category,
    required this.xpReward,
    required this.prerequisites,
    required this.slides,
  });

  // Helper to check if lesson is unlocked for a profile
  bool isUnlocked(List<int> completedLessonIds) {
    return prerequisites.every(
      (prereqId) => completedLessonIds.contains(prereqId),
    );
  }
}

// Static lesson content
class LessonsData {
  static List<Lesson> getAllLessons() {
    return [
      // Lesson 1: Meet the Piano
      Lesson(
        lessonId: 1,
        title: "Meet the Piano",
        description: "Learn about the piano keyboard layout and find Middle C",
        category: "Basics",
        xpReward: 100,
        prerequisites: [], // No prerequisites for first lesson
        slides: [
          LessonSlide(
            slideId: 1,
            title: "Welcome to Piano!",
            instruction:
                "Welcome to your first piano lesson! Today we'll explore the piano keyboard and learn about the most important key - Middle C.",
            type: LessonSlideType.instruction,
          ),
          LessonSlide(
            slideId: 2,
            title: "The Piano Keyboard",
            instruction:
                "The piano has white keys and black keys. The white keys are the natural notes: C, D, E, F, G, A, B. They repeat across the keyboard.",
            visualAid: "keyboard_layout",
            type: LessonSlideType.instruction,
          ),
          LessonSlide(
            slideId: 3,
            title: "Finding Middle C",
            instruction:
                "Middle C is your home base on the piano. It's usually located near the center of the keyboard. Can you find and tap Middle C?",
            type: LessonSlideType.interaction,
            interactionData: {
              'type': 'piano_key_tap',
              'target_note': 'C4',
              'hint':
                  'Look for the C that\'s closest to the center of the keyboard',
            },
          ),
          LessonSlide(
            slideId: 4,
            title: "Let's Play a Song!",
            instruction:
                "Now let's put your Middle C knowledge to use! Try playing this simple melody. The app will listen and help you get it right.",
            type: LessonSlideType.songSnippet,
            interactionData: {
              'snippet_id': 'twinkle_twinkle',
              'description': 'A simple melody using only Middle C',
            },
          ),
          LessonSlide(
            slideId: 5,
            title: "Great Job!",
            instruction:
                "Excellent! You found Middle C and played your first song snippet. This will be your reference point for all future lessons. You've earned your first badge!",
            type: LessonSlideType.reward,
            interactionData: {
              'badge': 'first_steps',
              'message': 'Piano Explorer - You found Middle C!',
            },
          ),
        ],
      ),

      // Lesson 2: Notes C-G
      Lesson(
        lessonId: 2,
        title: "Notes C-G",
        description: "Learn the first five notes and practice finding them",
        category: "Basics",
        xpReward: 150,
        prerequisites: [1], // Must complete lesson 1 first
        slides: [
          LessonSlide(
            slideId: 1,
            title: "The First Five Notes",
            instruction:
                "Now that you know Middle C, let's learn the next four notes: D, E, F, and G. These five notes are the foundation of piano playing.",
            type: LessonSlideType.instruction,
          ),
          LessonSlide(
            slideId: 2,
            title: "C to G Pattern",
            instruction:
                "Starting from Middle C, the notes go: C - D - E - F - G. Notice there are no black keys between E and F!",
            visualAid: "c_to_g_pattern",
            type: LessonSlideType.instruction,
          ),
          LessonSlide(
            slideId: 3,
            title: "Practice: Find Each Note",
            instruction:
                "Let's practice! I'll ask you to find each note. Take your time and listen carefully.",
            type: LessonSlideType.interaction,
            interactionData: {
              'type': 'note_identification_drill',
              'notes': ['C4', 'D4', 'E4', 'F4', 'G4'],
              'randomOrder': true,
            },
          ),
          LessonSlide(
            slideId: 4,
            title: "Quick Quiz",
            instruction: "Which note comes after E?",
            type: LessonSlideType.quiz,
            interactionData: {
              'question': 'Which note comes after E?',
              'options': ['D', 'F', 'G', 'A'],
              'correct': 'F',
              'explanation':
                  'F comes after E. Remember, there\'s no black key between E and F!',
            },
          ),
          LessonSlide(
            slideId: 5,
            title: "Let's Play a Song!",
            instruction:
                "Now let's use all five notes you've learned! Try playing this melody. The app will guide you through each note.",
            type: LessonSlideType.songSnippet,
            interactionData: {
              'snippet_id': 'mary_had_little_lamb',
              'description': 'A simple melody using C, D, E, F, G',
            },
          ),
          LessonSlide(
            slideId: 6,
            title: "Note Master!",
            instruction:
                "Fantastic! You've mastered the first five notes of the piano and played a real song. You're ready to start making music!",
            type: LessonSlideType.reward,
            interactionData: {
              'badge': 'note_master',
              'message': 'Note Master - You know C through G!',
            },
          ),
        ],
      ),

      // Lesson 3: Rhythm Basics
      Lesson(
        lessonId: 3,
        title: "Rhythm Basics",
        description: "Understanding beats, timing, and quarter notes",
        category: "Basics",
        xpReward: 150,
        prerequisites: [2], // Must complete lesson 2 first
        slides: [
          LessonSlide(
            slideId: 1,
            title: "What is Rhythm?",
            instruction:
                "Rhythm is the pattern of beats in music. Think of it like the heartbeat of a song - it keeps everything together!",
            type: LessonSlideType.instruction,
          ),
          LessonSlide(
            slideId: 2,
            title: "Quarter Notes",
            instruction:
                "A quarter note gets one beat. When you see a quarter note, you play it for exactly one count. Let's clap along to quarter notes!",
            visualAid: "quarter_note_symbol",
            type: LessonSlideType.instruction,
          ),
          LessonSlide(
            slideId: 3,
            title: "Clap the Beat",
            instruction:
                "Listen to the steady beat and clap along. Try to keep your claps exactly with the beat. Count: 1 - 2 - 3 - 4!",
            type: LessonSlideType.interaction,
            interactionData: {
              'type': 'rhythm_clap',
              'bpm': 80,
              'beats': 16, // 4 measures of 4 beats
              'pattern': 'quarter_notes',
            },
          ),
          LessonSlide(
            slideId: 4,
            title: "Play with Rhythm",
            instruction:
                "Now let's combine rhythm with notes! Play Middle C on each beat. Remember to keep it steady!",
            type: LessonSlideType.interaction,
            interactionData: {
              'type': 'rhythm_piano',
              'note': 'C4',
              'bpm': 80,
              'beats': 8,
            },
          ),
          LessonSlide(
            slideId: 5,
            title: "Practice Time!",
            instruction:
                "Let's practice what you've learned! Try playing the C-G pattern with a steady rhythm. Focus on keeping your timing consistent.",
            type: LessonSlideType.practice,
          ),
          LessonSlide(
            slideId: 6,
            title: "Let's Play a Song!",
            instruction:
                "Now let's combine rhythm with melody! Try playing this song with proper timing. Keep the beat steady!",
            type: LessonSlideType.songSnippet,
            interactionData: {
              'snippet_id': 'hot_cross_buns',
              'description': 'A simple rhythm exercise with quarter notes',
            },
          ),
          LessonSlide(
            slideId: 7,
            title: "Rhythm Master!",
            instruction:
                "Excellent rhythm! You're developing a great sense of timing and played a real song. Music is all about combining notes and rhythm!",
            type: LessonSlideType.reward,
            interactionData: {
              'badge': 'rhythm_master',
              'message': 'Rhythm Master - You can keep the beat!',
            },
          ),
        ],
      ),
    ];
  }

  // Helper method to get a specific lesson
  static Lesson? getLessonById(int lessonId) {
    try {
      return getAllLessons().firstWhere(
        (lesson) => lesson.lessonId == lessonId,
      );
    } catch (e) {
      return null;
    }
  }

  // Helper method to get lessons by category
  static List<Lesson> getLessonsByCategory(String category) {
    return getAllLessons()
        .where((lesson) => lesson.category == category)
        .toList();
  }
}
