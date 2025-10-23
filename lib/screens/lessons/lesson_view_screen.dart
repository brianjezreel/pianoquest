import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../models/profile.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/profiles_repository.dart';
import '../../services/song_snippet_service.dart';
import '../../widgets/song_snippet_play_widget.dart';

class LessonViewScreen extends StatefulWidget {
  final Lesson lesson;
  final Profile profile;

  const LessonViewScreen({
    super.key,
    required this.lesson,
    required this.profile,
  });

  @override
  State<LessonViewScreen> createState() => _LessonViewScreenState();
}

class _LessonViewScreenState extends State<LessonViewScreen> {
  late PageController _pageController;
  late ProgressRepository _progressRepository;
  late ProfilesRepository _profilesRepository;
  final SongSnippetService _songSnippetService = SongSnippetService();

  int _currentSlideIndex = 0;
  bool _isLoading = false;
  final Map<String, dynamic> _interactionState = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeRepositories();
  }

  Future<void> _initializeRepositories() async {
    _progressRepository = ProgressRepository();
    _profilesRepository = ProfilesRepository();
    await _progressRepository.initialize();
    await _profilesRepository.initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressRepository.close();
    _profilesRepository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 400;

        // Responsive sizing
        final padding = isSmallScreen ? 16.0 : 24.0;
        final titleFontSize = isSmallScreen ? 20.0 : 24.0;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              widget.lesson.title,
              style: TextStyle(fontSize: isSmallScreen ? 18.0 : 20.0),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              // Progress indicator
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentSlideIndex + 1}/${widget.lesson.slides.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: (_currentSlideIndex + 1) / widget.lesson.slides.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                minHeight: 4,
              ),

              // Lesson content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentSlideIndex = index;
                    });
                  },
                  itemCount: widget.lesson.slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlideContent(
                      widget.lesson.slides[index],
                      isSmallScreen,
                      titleFontSize,
                      padding,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlideContent(
    LessonSlide slide,
    bool isSmallScreen,
    double titleFontSize,
    double padding,
  ) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slide title
          Text(
            slide.title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Main content area - using Expanded with SingleChildScrollView to prevent overflow
          Expanded(
            child: SingleChildScrollView(
              child: _buildSlideTypeContent(slide, isSmallScreen),
            ),
          ),

          // Navigation controls - now part of each slide content
          const SizedBox(height: 12),
          _buildNavigationControls(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildNavigationControls([bool isSmallScreen = false]) {
    final buttonHeight = isSmallScreen ? 38.0 : 42.0;
    final fontSize = isSmallScreen ? 13.0 : 14.0;
    final iconSize = isSmallScreen ? 16.0 : 18.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Previous button
          if (_currentSlideIndex > 0)
            Expanded(
              child: SizedBox(
                height: buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: _goToPreviousSlide,
                  icon: Icon(Icons.arrow_back, size: iconSize),
                  label: Text('Previous', style: TextStyle(fontSize: fontSize)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),

          const SizedBox(width: 12),

          // Next/Complete button
          Expanded(
            child: SizedBox(
              height: buttonHeight,
              child: FilledButton.icon(
                onPressed: _canProceed() ? _goToNextSlideOrComplete : null,
                icon: Icon(
                  _isLastSlide() ? Icons.check : Icons.arrow_forward,
                  size: iconSize,
                ),
                label: Text(
                  _isLastSlide() ? 'Complete' : 'Next',
                  style: TextStyle(fontSize: fontSize),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideTypeContent(LessonSlide slide, bool isSmallScreen) {
    switch (slide.type) {
      case LessonSlideType.instruction:
        return _buildInstructionSlide(slide, isSmallScreen);
      case LessonSlideType.interaction:
        return _buildInteractionSlide(slide, isSmallScreen);
      case LessonSlideType.quiz:
        return _buildQuizSlide(slide, isSmallScreen);
      case LessonSlideType.practice:
        return _buildPracticeSlide(slide, isSmallScreen);
      case LessonSlideType.songSnippet:
        return _buildSongSnippetSlide(slide, isSmallScreen);
      case LessonSlideType.reward:
        return _buildRewardSlide(slide, isSmallScreen);
    }
  }

  Widget _buildInstructionSlide(LessonSlide slide, bool isSmallScreen) {
    final textFontSize = isSmallScreen ? 16.0 : 18.0;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instruction text
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            slide.instruction,
            style: TextStyle(fontSize: textFontSize, height: 1.5),
          ),
        ),
        const SizedBox(height: 24),

        // Visual aid placeholder
        if (slide.visualAid != null)
          Container(height: 200, child: _buildVisualAid(slide.visualAid!)),
      ],
    );
  }

  Widget _buildInteractionSlide(LessonSlide slide, bool isSmallScreen) {
    final textFontSize = isSmallScreen ? 16.0 : 18.0;
    final interactionData = slide.interactionData ?? {};
    final interactionType = interactionData['type'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instruction
        Text(
          slide.instruction,
          style: TextStyle(fontSize: textFontSize, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Interactive element
        Container(
          height: 250,
          child: _buildInteractiveElement(
            interactionType,
            interactionData,
            isSmallScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizSlide(LessonSlide slide, bool isSmallScreen) {
    final questionFontSize = isSmallScreen ? 18.0 : 20.0;
    final optionFontSize = isSmallScreen ? 14.0 : 16.0;
    final padding = isSmallScreen ? 16.0 : 20.0;

    final quizData = slide.interactionData ?? {};
    final question = quizData['question'] as String? ?? slide.instruction;
    final options = quizData['options'] as List<dynamic>? ?? [];
    final correctAnswer = quizData['correct'] as String?;
    final selectedAnswer =
        _interactionState['quiz_${slide.slideId}'] as String?;
    final hasAnswered = selectedAnswer != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            question,
            style: TextStyle(
              fontSize: questionFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Options
        Container(
          height: 300,
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index] as String;
              final isSelected = selectedAnswer == option;
              final isCorrect = option == correctAnswer;
              final showResult = hasAnswered;

              Color? backgroundColor;
              Color? borderColor;

              if (showResult) {
                if (isCorrect) {
                  backgroundColor = Colors.green.shade100;
                  borderColor = Colors.green;
                } else if (isSelected && !isCorrect) {
                  backgroundColor = Colors.red.shade100;
                  borderColor = Colors.red;
                }
              } else if (isSelected) {
                backgroundColor = Colors.grey.shade200;
                borderColor = Colors.grey.shade400;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: hasAnswered
                      ? null
                      : () {
                          setState(() {
                            _interactionState['quiz_${slide.slideId}'] = option;
                          });
                        },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: borderColor ?? Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: isSmallScreen ? 20 : 24,
                          height: isSmallScreen ? 20 : 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.black
                                : Colors.transparent,
                            border: Border.all(color: Colors.grey.shade600),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: isSmallScreen ? 14 : 16,
                                )
                              : null,
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: optionFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (showResult && isCorrect)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: isSmallScreen ? 18 : 24,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Explanation after answering
        if (hasAnswered && quizData['explanation'] != null)
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            decoration: BoxDecoration(
              color: Colors.yellow.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.yellow.shade700,
                  size: isSmallScreen ? 18 : 24,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    quizData['explanation'] as String,
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPracticeSlide(LessonSlide slide, bool isSmallScreen) {
    final textFontSize = isSmallScreen ? 16.0 : 18.0;
    final pianoHeight = isSmallScreen ? 120.0 : 150.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slide.instruction,
          style: TextStyle(fontSize: textFontSize, height: 1.5),
        ),
        const SizedBox(height: 24),
        // Practice area with piano visualization
        Container(
          constraints: BoxConstraints(minHeight: 300, maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Piano visualization
                Container(
                  height: pianoHeight,
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                  child: Row(
                    children: [
                      // White keys
                      ...List.generate(5, (index) {
                        final notes = ['C', 'D', 'E', 'F', 'G'];
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 1 : 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Center(
                              child: Text(
                                notes[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 24),

                // Practice instructions
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  margin: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Practice Tips:',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Text(
                        '• Play each note clearly and evenly\n'
                        '• Keep a steady rhythm\n'
                        '• Focus on proper finger placement\n'
                        '• Listen to the sound of each note',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 24),

                // Practice timer
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer,
                        color: Colors.green,
                        size: isSmallScreen ? 18 : 24,
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Text(
                        'Practice for 2 minutes',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardSlide(LessonSlide slide, bool isSmallScreen) {
    final titleFontSize = isSmallScreen ? 20.0 : 24.0;
    final textFontSize = isSmallScreen ? 14.0 : 16.0;
    final iconSize = isSmallScreen ? 50.0 : 60.0;
    final circleSize = isSmallScreen ? 100.0 : 120.0;

    final rewardData = slide.interactionData ?? {};
    final message = rewardData['message'] as String?;

    return SingleChildScrollView(
      // Added SingleChildScrollView to prevent overflow
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Celebration animation placeholder
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.yellow.shade400, width: 4),
            ),
            child: Icon(
              Icons.emoji_events,
              size: iconSize,
              color: Colors.yellow,
            ),
          ),
          SizedBox(height: isSmallScreen ? 24 : 32),

          Text(
            slide.instruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (message != null) ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: textFontSize,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          SizedBox(height: isSmallScreen ? 24 : 32),

          // XP reward display
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20,
              vertical: isSmallScreen ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              '+${widget.lesson.xpReward} XP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 16 : 18,
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // Practice suggestion
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'Keep Practicing!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Text(
                  'Continue to the Practice Mode to reinforce what you\'ve learned',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongSnippetSlide(LessonSlide slide, bool isSmallScreen) {
    final textFontSize = isSmallScreen ? 16.0 : 18.0;
    final interactionData = slide.interactionData ?? {};
    final snippetId = interactionData['snippet_id'] as String?;

    if (snippetId == null) {
      return Container(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
        child: Text(
          'Song snippet not found',
          style: TextStyle(fontSize: textFontSize),
        ),
      );
    }

    // Get the song snippet
    final snippet = _songSnippetService.getSnippetById(snippetId);
    if (snippet == null) {
      return Container(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
        child: Text(
          'Song snippet not available',
          style: TextStyle(fontSize: textFontSize),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction text
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              slide.instruction,
              style: TextStyle(fontSize: textFontSize, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),

          // Full-screen button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          FullScreenSongView(snippet: snippet),
                    ),
                  );
                },
                icon: const Icon(Icons.fullscreen),
                label: const Text('Full Screen View'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Song snippet widget with fixed height
          Container(
            height: 500, // Fixed height to prevent layout issues
            child: SongSnippetPlayWidget(
              snippet: snippet,
              onCompleted: () {
                // Mark the song snippet as completed
                setState(() {
                  _interactionState['song_snippet_${slide.slideId}'] = true;
                });
              },
              onNotePlayed: () {
                // Optional: Add feedback or progress tracking
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualAid(String visualAidKey, [bool isSmallScreen = false]) {
    // Placeholder for visual aids - in a real app, these would be images or interactive diagrams
    switch (visualAidKey) {
      case 'keyboard_layout':
        return _buildKeyboardDiagram(isSmallScreen);
      case 'c_to_g_pattern':
        return _buildCToGDiagram(isSmallScreen);
      case 'quarter_note_symbol':
        return _buildQuarterNoteDiagram(isSmallScreen);
      default:
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image,
                  size: isSmallScreen ? 40 : 48,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 8),
                Text(
                  'Visual Aid: $visualAidKey',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildKeyboardDiagram(bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 100 : 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          '🎹 Piano Keyboard Layout\n(Interactive diagram coming soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
      ),
    );
  }

  Widget _buildCToGDiagram(bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 100 : 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          '🎵 C - D - E - F - G Pattern\n(Interactive diagram coming soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
      ),
    );
  }

  Widget _buildQuarterNoteDiagram(bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 100 : 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          '♩ Quarter Note = 1 Beat\n(Interactive diagram coming soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
      ),
    );
  }

  Widget _buildInteractiveElement(
    String? type,
    Map<String, dynamic> data, [
    bool isSmallScreen = false,
  ]) {
    switch (type) {
      case 'piano_key_tap':
        return _buildPianoKeyTap(data, isSmallScreen);
      case 'note_identification_drill':
        return _buildNoteIdentificationDrill(data, isSmallScreen);
      case 'rhythm_clap':
        return _buildRhythmClap(data, isSmallScreen);
      case 'rhythm_piano':
        return _buildRhythmPiano(data, isSmallScreen);
      default:
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app,
                  size: isSmallScreen ? 40 : 48,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 8),
                Text(
                  'Interactive Element: ${type ?? 'Unknown'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
                Text(
                  '(Interactive features coming soon)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildPianoKeyTap(Map<String, dynamic> data, bool isSmallScreen) {
    final targetNote = data['target_note'] as String?;
    final hint = data['hint'] as String?;
    final textFontSize = isSmallScreen ? 14.0 : 16.0;
    final titleFontSize = isSmallScreen ? 16.0 : 18.0;

    return Column(
      children: [
        if (hint != null)
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(hint, style: TextStyle(fontSize: textFontSize)),
          ),

        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.piano,
                    size: isSmallScreen ? 50 : 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Text(
                    'Tap $targetNote on the piano',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '(Interactive piano coming soon)',
                    style: TextStyle(fontSize: textFontSize),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteIdentificationDrill(
    Map<String, dynamic> data,
    bool isSmallScreen,
  ) {
    final textFontSize = isSmallScreen ? 14.0 : 16.0;
    final titleFontSize = isSmallScreen ? 16.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: isSmallScreen ? 50 : 64,
              color: Colors.grey,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Note Identification Drill',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '(Interactive drill coming soon)',
              style: TextStyle(fontSize: textFontSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRhythmClap(Map<String, dynamic> data, bool isSmallScreen) {
    final textFontSize = isSmallScreen ? 14.0 : 16.0;
    final titleFontSize = isSmallScreen ? 16.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gesture,
              size: isSmallScreen ? 50 : 64,
              color: Colors.grey,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Rhythm Clapping Exercise',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '(Interactive clapping coming soon)',
              style: TextStyle(fontSize: textFontSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRhythmPiano(Map<String, dynamic> data, bool isSmallScreen) {
    final textFontSize = isSmallScreen ? 14.0 : 16.0;
    final titleFontSize = isSmallScreen ? 16.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.piano,
              size: isSmallScreen ? 50 : 64,
              color: Colors.grey,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Rhythm Piano Exercise',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '(Interactive piano with rhythm coming soon)',
              style: TextStyle(fontSize: textFontSize),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    final currentSlide = widget.lesson.slides[_currentSlideIndex];

    // For quiz slides, require an answer
    if (currentSlide.type == LessonSlideType.quiz) {
      return _interactionState.containsKey('quiz_${currentSlide.slideId}');
    }

    // For song snippet slides, require completion
    if (currentSlide.type == LessonSlideType.songSnippet) {
      return _interactionState.containsKey(
        'song_snippet_${currentSlide.slideId}',
      );
    }

    // For other slide types, always allow proceeding
    return true;
  }

  bool _isLastSlide() {
    return _currentSlideIndex == widget.lesson.slides.length - 1;
  }

  void _goToPreviousSlide() {
    if (_currentSlideIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextSlideOrComplete() {
    if (_isLastSlide()) {
      _completeLesson();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeLesson() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Calculate score based on quiz answers
      int score = _calculateScore();

      // Mark lesson as completed
      await _progressRepository.markLessonCompleted(
        widget.profile.profileId!,
        widget.lesson.lessonId,
        score: score,
      );

      // Add XP to profile
      await _profilesRepository.addXP(
        widget.profile.profileId!,
        widget.lesson.xpReward,
      );

      if (mounted) {
        // Show completion dialog
        await _showCompletionDialog(score);

        // Navigate back
        Navigator.of(context).pop(true); // Return true to indicate completion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing lesson: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _calculateScore() {
    int totalQuizzes = 0;
    int correctAnswers = 0;

    for (final slide in widget.lesson.slides) {
      if (slide.type == LessonSlideType.quiz) {
        totalQuizzes++;
        final userAnswer =
            _interactionState['quiz_${slide.slideId}'] as String?;
        final correctAnswer = slide.interactionData?['correct'] as String?;

        if (userAnswer == correctAnswer) {
          correctAnswers++;
        }
      }
    }

    if (totalQuizzes == 0) return 100; // Perfect score if no quizzes
    return ((correctAnswers / totalQuizzes) * 100).round();
  }

  Future<void> _showCompletionDialog(int score) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.orange),
            SizedBox(width: 8),
            Text('Lesson Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Congratulations! You completed "${widget.lesson.title}"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Score:'),
                      Text(
                        '$score%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('XP Earned:'),
                      Text(
                        '+${widget.lesson.xpReward}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
