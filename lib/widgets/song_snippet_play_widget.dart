import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../models/song_snippet.dart';
import '../models/pitch_detection_result.dart';
import '../services/pitch_detection_service.dart';
import 'custom_staff_widget.dart';

// Full-screen song view widget
class FullScreenSongView extends StatefulWidget {
  final SongSnippet snippet;

  const FullScreenSongView({super.key, required this.snippet});

  @override
  State<FullScreenSongView> createState() => _FullScreenSongViewState();
}

class _FullScreenSongViewState extends State<FullScreenSongView>
    with TickerProviderStateMixin {
  final PitchDetectionService _pitchDetectionService = PitchDetectionService();
  StreamSubscription<PitchDetectionResult>? _subscription;

  bool _isListening = false;
  bool _isCompleted = false;
  int _currentNoteIndex = 0;
  List<bool> _noteCorrectness = [];
  SongNote? _currentTargetNote;

  late AnimationController _noteController;
  late Animation<double> _noteAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePitchDetection();
    _initializeNoteCorrectness();
    _updateCurrentTargetNote();
  }

  void _initializeAnimations() {
    _noteController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _noteAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _noteController, curve: Curves.elasticOut),
    );
  }

  void _initializePitchDetection() async {
    await _pitchDetectionService.initialize();
  }

  void _initializeNoteCorrectness() {
    _noteCorrectness = List.filled(widget.snippet.notes.length, false);
  }

  void _updateCurrentTargetNote() {
    if (_currentNoteIndex < widget.snippet.notes.length) {
      _currentTargetNote = widget.snippet.notes[_currentNoteIndex];
    } else {
      _currentTargetNote = null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pitchDetectionService.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _startListening() async {
    if (_isListening) return;

    try {
      final success = await _pitchDetectionService.startDetection();
      if (success) {
        _subscription = _pitchDetectionService.pitchStream?.listen(
          _onPitchDetected,
          onError: (error) {
            debugPrint('Pitch detection error: $error');
            _stopListening();
          },
        );
        setState(() {
          _isListening = true;
        });
        debugPrint('Song snippet pitch detection started');
      }
    } catch (e) {
      debugPrint('Error starting pitch detection: $e');
    }
  }

  void _stopListening() async {
    if (!_isListening) return;

    try {
      await _pitchDetectionService.stopDetection();
      await _subscription?.cancel();
      _subscription = null;
      setState(() {
        _isListening = false;
      });
      debugPrint('Song snippet pitch detection stopped');
    } catch (e) {
      debugPrint('Error stopping pitch detection: $e');
    }
  }

  void _onPitchDetected(PitchDetectionResult result) {
    if (_isCompleted || !mounted || _currentTargetNote == null) return;

    if (result.hasValidDetection && result.detectedNotes.isNotEmpty) {
      final detectedNote = result.detectedNotes.first;

      // Check if this matches the current expected note
      if (_isNoteMatch(detectedNote, _currentTargetNote!)) {
        setState(() {
          _noteCorrectness[_currentNoteIndex] = true;
          _currentNoteIndex++;
          _updateCurrentTargetNote();
        });

        // Trigger success animation
        _noteController.forward().then((_) {
          if (mounted) {
            _noteController.reset();
          }
        });

        // Check if all notes have been played
        if (_currentNoteIndex >= widget.snippet.notes.length) {
          _completeSnippet();
        }
      }
    }
  }

  bool _isNoteMatch(DetectedNote detected, SongNote target) {
    return detected.noteName == target.noteName &&
        detected.octave == target.octave;
  }

  void _resetSnippet() {
    setState(() {
      _isCompleted = false;
      _currentNoteIndex = 0;
      _initializeNoteCorrectness();
      _updateCurrentTargetNote();
    });
    _stopListening();
  }

  void _completeSnippet() {
    setState(() {
      _isCompleted = true;
    });
    _stopListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.snippet.title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_currentNoteIndex + 1}/${widget.snippet.notes.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 8,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Large staff widget - takes up most of the screen
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _currentTargetNote != null
                      ? AnimatedBuilder(
                          animation: _noteAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _noteAnimation.value,
                              child: CustomStaffWidget(
                                noteName: _currentTargetNote!.noteName,
                                octave: _currentTargetNote!.octave,
                                isHighlighted: _isListening,
                                isCompleted:
                                    _noteCorrectness[_currentNoteIndex],
                                staffHeight: 400,
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.celebration,
                                size: 64,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'All notes completed!',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),

            // Status and controls - bottom section
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status text
                    Text(
                      _getStatusText(),
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!_isListening && !_isCompleted)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _startListening,
                              icon: const Icon(Icons.play_arrow, size: 24),
                              label: const Text(
                                'Start',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                        if (_isListening)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _stopListening,
                              icon: const Icon(Icons.stop, size: 24),
                              label: const Text(
                                'Stop',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                        if (_isCompleted)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _resetSnippet,
                              icon: const Icon(Icons.refresh, size: 24),
                              label: const Text(
                                'Try Again',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (_isCompleted) {
      final correctNotes = _noteCorrectness.where((correct) => correct).length;
      return 'Great job! You played $correctNotes out of ${widget.snippet.notes.length} notes correctly!';
    } else if (_isListening) {
      return 'Play the note shown on the staff!';
    } else {
      return 'Press Start to begin playing the song snippet';
    }
  }

  Color _getStatusColor() {
    if (_isCompleted) {
      return Colors.green;
    } else if (_isListening) {
      return Colors.blue;
    } else {
      return Colors.grey.shade600;
    }
  }
}

class SongSnippetPlayWidget extends StatefulWidget {
  final SongSnippet snippet;
  final VoidCallback? onCompleted;
  final VoidCallback? onNotePlayed;

  const SongSnippetPlayWidget({
    super.key,
    required this.snippet,
    this.onCompleted,
    this.onNotePlayed,
  });

  @override
  State<SongSnippetPlayWidget> createState() => _SongSnippetPlayWidgetState();
}

class _SongSnippetPlayWidgetState extends State<SongSnippetPlayWidget>
    with TickerProviderStateMixin {
  final PitchDetectionService _pitchDetectionService = PitchDetectionService();
  StreamSubscription<PitchDetectionResult>? _subscription;

  bool _isListening = false;
  bool _isCompleted = false;
  int _currentNoteIndex = 0;
  List<bool> _noteCorrectness = [];
  SongNote? _currentTargetNote;

  late AnimationController _noteController;
  late Animation<double> _noteAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePitchDetection();
    _initializeNoteCorrectness();
    _updateCurrentTargetNote();
  }

  void _initializeAnimations() {
    _noteController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _noteAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _noteController, curve: Curves.elasticOut),
    );
  }

  void _initializePitchDetection() async {
    await _pitchDetectionService.initialize();
  }

  void _initializeNoteCorrectness() {
    _noteCorrectness = List.filled(widget.snippet.notes.length, false);
  }

  void _updateCurrentTargetNote() {
    if (_currentNoteIndex < widget.snippet.notes.length) {
      _currentTargetNote = widget.snippet.notes[_currentNoteIndex];
    } else {
      _currentTargetNote = null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pitchDetectionService.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _startListening() async {
    if (_isListening) return;

    try {
      final success = await _pitchDetectionService.startDetection();
      if (success) {
        _subscription = _pitchDetectionService.pitchStream?.listen(
          _onPitchDetected,
          onError: (error) {
            debugPrint('Pitch detection error: $error');
            _stopListening();
          },
        );
        setState(() {
          _isListening = true;
        });
        debugPrint('Song snippet pitch detection started');
      }
    } catch (e) {
      debugPrint('Error starting pitch detection: $e');
    }
  }

  void _stopListening() async {
    if (!_isListening) return;

    try {
      await _pitchDetectionService.stopDetection();
      await _subscription?.cancel();
      _subscription = null;
      setState(() {
        _isListening = false;
      });
      debugPrint('Song snippet pitch detection stopped');
    } catch (e) {
      debugPrint('Error stopping pitch detection: $e');
    }
  }

  void _onPitchDetected(PitchDetectionResult result) {
    if (_isCompleted || !mounted || _currentTargetNote == null) return;

    if (result.hasValidDetection && result.detectedNotes.isNotEmpty) {
      final detectedNote = result.detectedNotes.first;

      // Check if this matches the current expected note
      if (_isNoteMatch(detectedNote, _currentTargetNote!)) {
        setState(() {
          _noteCorrectness[_currentNoteIndex] = true;
          _currentNoteIndex++;
          _updateCurrentTargetNote();
        });

        // Trigger success animation
        _noteController.forward().then((_) {
          if (mounted) {
            _noteController.reset();
          }
        });

        widget.onNotePlayed?.call();

        // Check if all notes have been played
        if (_currentNoteIndex >= widget.snippet.notes.length) {
          _completeSnippet();
        }
      }
    }
  }

  bool _isNoteMatch(DetectedNote detected, SongNote target) {
    return detected.noteName == target.noteName &&
        detected.octave == target.octave;
  }

  void _startSnippet() {
    if (_isListening) return;
    _startListening();
  }

  void _resetSnippet() {
    setState(() {
      _isCompleted = false;
      _currentNoteIndex = 0;
      _initializeNoteCorrectness();
      _updateCurrentTargetNote();
    });
    _stopListening();
  }

  void _completeSnippet() {
    setState(() {
      _isCompleted = true;
    });
    _stopListening();
    widget.onCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Song title and composer
            Text(
              widget.snippet.title,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.snippet.composer.isNotEmpty)
              Text(
                'by ${widget.snippet.composer}',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: isSmallScreen ? 16 : 20),

            // Musical staff using custom widget
            Container(
              height: 200,
              child: _currentTargetNote != null
                  ? AnimatedBuilder(
                      animation: _noteAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _noteAnimation.value,
                          child: CustomStaffWidget(
                            noteName: _currentTargetNote!.noteName,
                            octave: _currentTargetNote!.octave,
                            isHighlighted: _isListening,
                            isCompleted: _noteCorrectness[_currentNoteIndex],
                            staffHeight:
                                200, // Specify staff height for better control
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'All notes completed!',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 16 : 18,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Status text
            Text(
              _getStatusText(),
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_isListening && !_isCompleted)
                  ElevatedButton.icon(
                    onPressed: _startSnippet,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),

                if (_isListening)
                  ElevatedButton.icon(
                    onPressed: _stopListening,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),

                if (_isCompleted)
                  ElevatedButton.icon(
                    onPressed: _resetSnippet,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),

            SizedBox(height: isSmallScreen ? 8 : 12),

            // Note progress
            Text(
              'Note ${_currentNoteIndex + 1} of ${widget.snippet.notes.length}',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (_isCompleted) {
      final correctNotes = _noteCorrectness.where((correct) => correct).length;
      return 'Great job! You played $correctNotes out of ${widget.snippet.notes.length} notes correctly!';
    } else if (_isListening) {
      return 'Play the note shown on the staff!';
    } else {
      return 'Press Start to begin playing the song snippet';
    }
  }

  Color _getStatusColor() {
    if (_isCompleted) {
      return Colors.green;
    } else if (_isListening) {
      return Colors.blue;
    } else {
      return Colors.grey.shade600;
    }
  }
}
