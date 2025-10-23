import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../models/pitch_detection_result.dart';
import '../../models/song_snippet.dart';
import '../../services/pitch_detection_service.dart';

class PracticeScreen extends StatefulWidget {
  final SongSnippet? selectedSong;

  const PracticeScreen({super.key, this.selectedSong});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final PitchDetectionService _pitchDetectionService = PitchDetectionService();
  StreamSubscription<PitchDetectionResult>? _subscription;
  bool _isListening = false;
  String _detectedNote = '';
  int _detectedOctave = 0;
  double _confidence = 0.0;
  final List<String> _recentNotes = [];
  List<DetectedNote> _currentDetectedNotes = [];

  // Song practice state
  int _currentNoteIndex = 0;
  bool _isPracticingWithSong = false;
  List<bool> _noteCompleted = [];
  Timer? _practiceTimer;
  double _songProgress = 0.0;
  final ScrollController _sheetMusicScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializePitchDetection();
    if (widget.selectedSong != null) {
      _noteCompleted = List.filled(widget.selectedSong!.notes.length, false);
      // Auto-start practicing when a song is selected
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _startPracticing();
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _practiceTimer?.cancel();
    _sheetMusicScrollController.dispose();
    _pitchDetectionService.dispose();
    super.dispose();
  }

  Future<void> _initializePitchDetection() async {
    await _pitchDetectionService.initialize();
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() async {
    try {
      await _pitchDetectionService.startDetection();
      _subscription = _pitchDetectionService.pitchStream?.listen(
        _onPitchDetected,
      );
      setState(() {
        _isListening = true;
      });
    } catch (e) {
      debugPrint('Error starting pitch detection: $e');
    }
  }

  void _stopListening() async {
    await _pitchDetectionService.stopDetection();
    _subscription?.cancel();
    setState(() {
      _isListening = false;
      _detectedNote = '';
      _detectedOctave = 0;
      _confidence = 0.0;
      _currentDetectedNotes = [];
    });
  }

  void _onPitchDetected(PitchDetectionResult result) {
    if (result.detectedNotes.isNotEmpty) {
      final primaryNote = result.detectedNotes.first;
      setState(() {
        _detectedNote = primaryNote.noteName;
        _detectedOctave = primaryNote.octave;
        _confidence = primaryNote.confidence;
        _currentDetectedNotes = result.detectedNotes;

        final noteDisplay = result.detectedNotes.length > 1
            ? '${primaryNote.noteName}${primaryNote.octave} +${result.detectedNotes.length - 1}'
            : '${primaryNote.noteName}${primaryNote.octave}';

        if (_recentNotes.isEmpty || _recentNotes.first != noteDisplay) {
          _recentNotes.insert(0, noteDisplay);
          if (_recentNotes.length > 10) {
            _recentNotes.removeLast();
          }
        }

        // Check if playing the correct note from the song
        if (_isPracticingWithSong && widget.selectedSong != null) {
          _checkSongNote(primaryNote);
        }
      });
    } else {
      setState(() {
        _currentDetectedNotes = [];
      });
    }
  }

  void _checkSongNote(DetectedNote detectedNote) {
    if (_currentNoteIndex >= widget.selectedSong!.notes.length) {
      return;
    }

    final targetNote = widget.selectedSong!.notes[_currentNoteIndex];
    final isCorrect =
        detectedNote.noteName == targetNote.noteName &&
        detectedNote.octave == targetNote.octave &&
        detectedNote.confidence > 0.6;

    if (isCorrect && !_noteCompleted[_currentNoteIndex]) {
      // Provide visual feedback
      setState(() {
        _noteCompleted[_currentNoteIndex] = true;
        _currentNoteIndex++;
        _songProgress = _currentNoteIndex / widget.selectedSong!.notes.length;
      });

      // Auto-scroll to current note
      _scrollToCurrentNote();

      // Check if song is complete
      if (_currentNoteIndex >= widget.selectedSong!.notes.length) {
        _onSongComplete();
      }
    }
  }

  void _scrollToCurrentNote() {
    if (_sheetMusicScrollController.hasClients) {
      // Calculate position (each note card is 88 pixels wide: 80 + 8 margin)
      final targetPosition = _currentNoteIndex * 88.0;
      _sheetMusicScrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSongComplete() {
    _stopPracticing();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Song Complete!'),
        content: Text(
          'Congratulations! You completed "${widget.selectedSong!.title}"!\n\nWould you like to practice again?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Back to Song Selection'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPractice();
              _startPracticing();
            },
            child: const Text('Practice Again'),
          ),
        ],
      ),
    );
  }

  void _startPracticing() {
    setState(() {
      _isPracticingWithSong = true;
      _currentNoteIndex = 0;
      _songProgress = 0.0;
      _noteCompleted = List.filled(widget.selectedSong!.notes.length, false);
    });
    _startListening();
  }

  void _stopPracticing() {
    setState(() {
      _isPracticingWithSong = false;
    });
    _stopListening();
  }

  void _resetPractice() {
    setState(() {
      _currentNoteIndex = 0;
      _songProgress = 0.0;
      _noteCompleted = List.filled(widget.selectedSong!.notes.length, false);
      _recentNotes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;
        final isLandscape = screenWidth > screenHeight;

        // Responsive sizing
        final responsivePadding = (screenWidth * 0.01).clamp(4.0, 16.0);
        final baseFontSize = (screenWidth * 0.03).clamp(10.0, 18.0);
        final iconSize = (screenWidth * 0.08).clamp(24.0, 48.0);
        final circleSize = (screenWidth * 0.12).clamp(40.0, 80.0);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.selectedSong != null
                  ? widget.selectedSong!.title
                  : 'CQT Practice Mode',
              style: TextStyle(fontSize: baseFontSize),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            actions: [
              if (widget.selectedSong != null && _isPracticingWithSong)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '${_currentNoteIndex}/${widget.selectedSong!.notes.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(responsivePadding),
              child: isLandscape
                  ? _buildLandscapeLayout(
                      constraints,
                      baseFontSize,
                      iconSize,
                      circleSize,
                    )
                  : _buildPortraitLayout(
                      constraints,
                      baseFontSize,
                      iconSize,
                      circleSize,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(
    BoxConstraints constraints,
    double baseFontSize,
    double iconSize,
    double circleSize,
  ) {
    // When a song is selected, show ONLY the sheet music
    if (widget.selectedSong != null) {
      return Column(
        children: [
          // Song header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFCAF4E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.music_note,
                      color: Color(0xFF00838F),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.selectedSong!.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.selectedSong!.composer,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF8CEADF),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '${_currentNoteIndex}/${widget.selectedSong!.notes.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00838F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _songProgress,
                  backgroundColor: const Color(0xFFAEEFE0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00ACC1),
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                if (_isPracticingWithSong &&
                    _currentNoteIndex < widget.selectedSong!.notes.length)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00838F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Play: ${widget.selectedSong!.notes[_currentNoteIndex].noteName}${widget.selectedSong!.notes[_currentNoteIndex].octave}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sheet music - takes up all remaining space
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sheet Music',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildMusicSheet()),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Compact detection status at bottom
          if (_isPracticingWithSong)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _detectedNote.isNotEmpty
                    ? const Color(0xFF96EBD2)
                    : const Color(0xFFCAF4E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_off,
                    size: 24,
                    color: _isListening ? const Color(0xFF00838F) : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _detectedNote.isEmpty ? 'Ready to play...' : 'Playing: ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_detectedNote.isNotEmpty)
                    Text(
                      '$_detectedNote$_detectedOctave',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00838F),
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    }

    // Default layout when no song is selected
    return Column(
      children: [
        if (widget.selectedSong == null)
          // Show full controls when not practicing with song
          Column(
            children: [
              // Top controls section
              Container(
                height: constraints.maxHeight * 0.25,
                child: Row(
                  children: [
                    // Controls
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(constraints.maxWidth * 0.02),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isListening ? Icons.mic : Icons.mic_off,
                                size: iconSize,
                                color: _isListening ? Colors.red : Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                _isListening
                                    ? 'Listening with CQT...'
                                    : 'Ready for Detection',
                                style: TextStyle(
                                  fontSize: baseFontSize * 0.8,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _toggleListening,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isListening
                                      ? Colors.red
                                      : Colors.green,
                                  minimumSize: Size(120, 36),
                                ),
                                child: Text(
                                  _isListening ? 'Stop' : 'Start',
                                  style: TextStyle(
                                    fontSize: baseFontSize * 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 8),

                    // Detection display
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(constraints.maxWidth * 0.02),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Detected Note',
                                style: TextStyle(
                                  fontSize: baseFontSize * 0.8,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                width: circleSize * 0.8,
                                height: circleSize * 0.8,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _detectedNote.isEmpty
                                        ? '--'
                                        : '$_detectedNote$_detectedOctave',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: baseFontSize * 0.8,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Confidence: ${(_confidence * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: baseFontSize * 0.7,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8),

              // Middle section - Recent notes
              Container(
                height: constraints.maxHeight * 0.2,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Notes',
                          style: TextStyle(
                            fontSize: baseFontSize * 0.9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: _recentNotes.isEmpty
                              ? Center(
                                  child: Text(
                                    'No notes detected yet.\nStart practicing!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: baseFontSize * 0.7,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: math.min(_recentNotes.length, 5),
                                  separatorBuilder: (context, index) =>
                                      SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _recentNotes[index],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: baseFontSize * 0.7,
                                            ),
                                          ),
                                          if (index == 0 &&
                                              _currentDetectedNotes.isNotEmpty)
                                            Text(
                                              '${(_currentDetectedNotes.first.frequency).toStringAsFixed(1)}Hz',
                                              style: TextStyle(
                                                fontSize: baseFontSize * 0.6,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

        SizedBox(height: 8),

        // Bottom section - Virtual Piano and Test Panel
        Expanded(
          child: Row(
            children: [
              // Virtual Piano
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Virtual Piano',
                          style: TextStyle(
                            fontSize: baseFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: _buildVirtualPiano(constraints, baseFontSize),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(width: 8),

              // Test Panel - hide when practicing with song
              if (widget.selectedSong == null || !_isPracticingWithSong)
                Expanded(flex: 1, child: Container()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BoxConstraints constraints,
    double baseFontSize,
    double iconSize,
    double circleSize,
  ) {
    // When a song is selected, show ONLY the sheet music (landscape optimized)
    if (widget.selectedSong != null) {
      return Row(
        children: [
          // Left side - Song info and current note
          Container(
            width: constraints.maxWidth * 0.3,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Song header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCAF4E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.music_note,
                            color: Color(0xFF00838F),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.selectedSong!.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.selectedSong!.composer,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _songProgress,
                        backgroundColor: const Color(0xFFAEEFE0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00838F),
                        ),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF8CEADF),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_currentNoteIndex}/${widget.selectedSong!.notes.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00838F),
                              ),
                            ),
                            const Text(
                              ' notes',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Current note to play
                if (_isPracticingWithSong &&
                    _currentNoteIndex < widget.selectedSong!.notes.length)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00838F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Play This Note:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${widget.selectedSong!.notes[_currentNoteIndex].noteName}${widget.selectedSong!.notes[_currentNoteIndex].octave}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget
                                .selectedSong!
                                .notes[_currentNoteIndex]
                                .lyric !=
                            null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '"${widget.selectedSong!.notes[_currentNoteIndex].lyric}"',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Detection status
                if (_isPracticingWithSong)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _detectedNote.isNotEmpty
                          ? const Color(0xFF96EBD2)
                          : const Color(0xFFCAF4E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isListening ? Icons.mic : Icons.mic_off,
                              size: 28,
                              color: _isListening
                                  ? const Color(0xFF00838F)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isListening ? 'Listening' : 'Ready',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (_detectedNote.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'You\'re Playing:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_detectedNote$_detectedOctave',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00838F),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right side - LARGE sheet music
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sheet Music',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(child: _buildMusicSheet()),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Default layout when no song is selected (keep original landscape layout)
    return Row(
      children: [
        // Left side - Controls and Detection
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Controls
              Flexible(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isListening ? Icons.mic : Icons.mic_off,
                          size: iconSize,
                          color: _isListening ? Colors.red : Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          _isListening ? 'Listening...' : 'Ready for Detection',
                          style: TextStyle(
                            fontSize: baseFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _toggleListening,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isListening
                                ? Colors.red
                                : Colors.green,
                            minimumSize: Size(120, 48),
                          ),
                          child: Text(
                            _isListening ? 'Stop' : 'Start',
                            style: TextStyle(fontSize: baseFontSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 8),

              // Detection Results
              Flexible(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Detected Note',
                          style: TextStyle(
                            fontSize: baseFontSize,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _detectedNote.isEmpty
                                  ? '--'
                                  : '$_detectedNote$_detectedOctave',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: baseFontSize,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Confidence: ${(_confidence * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: baseFontSize * 0.8,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (_currentDetectedNotes.length > 1)
                          Text(
                            'Polyphonic: ${_currentDetectedNotes.length} notes',
                            style: TextStyle(
                              fontSize: baseFontSize * 0.7,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: 8),

        // Right side - Piano and Test Panel
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Virtual Piano
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Virtual Piano',
                          style: TextStyle(
                            fontSize: baseFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: _buildVirtualPiano(constraints, baseFontSize),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 8),

              // Test Panel
              Flexible(
                flex: 1,
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight * 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMusicSheet() {
    if (widget.selectedSong == null) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      controller: _sheetMusicScrollController,
      scrollDirection: Axis.horizontal,
      itemCount: widget.selectedSong!.notes.length,
      itemBuilder: (context, index) {
        final note = widget.selectedSong!.notes[index];
        final isCompleted = _noteCompleted[index];
        final isCurrent = index == _currentNoteIndex && _isPracticingWithSong;
        final isNext = index == _currentNoteIndex + 1 && _isPracticingWithSong;

        // Check if currently playing the correct note
        final isPlayingCorrect =
            isCurrent &&
            _currentDetectedNotes.any(
              (detected) =>
                  detected.noteName == note.noteName &&
                  detected.octave == note.octave &&
                  detected.confidence > 0.5,
            );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          margin: const EdgeInsets.only(right: 8),
          child: Column(
            children: [
              // Note display
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 70,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF8CEADF)
                      : isPlayingCorrect
                      ? const Color(0xFF96EBD2)
                      : isCurrent
                      ? const Color(0xFFCAF4E9)
                      : isNext
                      ? const Color(0xFFAEEFE0)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPlayingCorrect
                        ? const Color(0xFF00838F)
                        : isCurrent
                        ? const Color(0xFF00838F)
                        : isCompleted
                        ? const Color(0xFF00838F)
                        : Colors.grey.shade300,
                    width: (isCurrent || isPlayingCorrect) ? 3 : 1,
                  ),
                  boxShadow: isPlayingCorrect
                      ? [
                          const BoxShadow(
                            color: Color(0xFF00838F),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPlayingCorrect
                            ? Icons.play_circle_filled
                            : Icons.music_note,
                        size: 24,
                        color: isCompleted
                            ? const Color(0xFF00695C)
                            : isPlayingCorrect
                            ? Colors.white
                            : isCurrent
                            ? const Color(0xFF00838F)
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${note.noteName}${note.octave}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? const Color(0xFF00695C)
                              : isPlayingCorrect
                              ? Colors.white
                              : isCurrent
                              ? const Color(0xFF00838F)
                              : Colors.grey.shade700,
                        ),
                      ),
                      if (isCompleted)
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF00695C),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Lyric if available
              if (note.lyric != null)
                Text(
                  note.lyric!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVirtualPiano(BoxConstraints constraints, double baseFontSize) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // White keys
          Row(
            children: List.generate(7, (index) {
              List<String> whiteKeys = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

              bool isPressed = _currentDetectedNotes.any(
                (note) => note.noteName == whiteKeys[index],
              );
              Color keyColor = Colors.white;

              if (isPressed) {
                final matchingNotes = _currentDetectedNotes.where(
                  (note) => note.noteName == whiteKeys[index],
                );
                final maxConfidence = matchingNotes
                    .map((n) => n.confidence)
                    .reduce(math.max);
                final opacity = math.min(maxConfidence * 2, 1.0);
                keyColor = Colors.blue.withValues(alpha: opacity);
              }

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: keyColor,
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      whiteKeys[index],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize * 0.8,
                        color: isPressed ? Colors.blue.shade800 : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          // Black keys
          Positioned.fill(
            child: Row(
              children: List.generate(7, (index) {
                List<String?> blackKeys = [
                  'C#',
                  'D#',
                  null,
                  'F#',
                  'G#',
                  'A#',
                  null,
                ];

                if (blackKeys[index] == null) {
                  return Expanded(child: Container());
                }

                String keyName = blackKeys[index]!;
                bool isPressed = _currentDetectedNotes.any(
                  (note) => note.noteName == keyName,
                );
                Color keyColor = Colors.black;

                if (isPressed) {
                  final matchingNotes = _currentDetectedNotes.where(
                    (note) => note.noteName == keyName,
                  );
                  final maxConfidence = matchingNotes
                      .map((n) => n.confidence)
                      .reduce(math.max);
                  final opacity = math.min(maxConfidence * 2, 1.0);
                  keyColor = Colors.red.withValues(alpha: opacity);
                }

                return Expanded(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      width: constraints.maxWidth * 0.05,
                      height: constraints.maxHeight * 0.4,
                      margin: EdgeInsets.only(
                        right: constraints.maxWidth * 0.02,
                      ),
                      decoration: BoxDecoration(
                        color: keyColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(2),
                          bottomRight: Radius.circular(2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          keyName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: baseFontSize * 0.6,
                            color: isPressed
                                ? Colors.red.shade200
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
