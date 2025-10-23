import 'package:flutter/material.dart';
import 'dart:async';
import '../models/pitch_detection_result.dart';
import '../services/pitch_detection_service.dart';

class ImmediateNoteDetector extends StatefulWidget {
  final PitchDetectionService pitchDetectionService;
  final Function(DetectedNote)? onNoteDetected;

  const ImmediateNoteDetector({
    super.key,
    required this.pitchDetectionService,
    this.onNoteDetected,
  });

  @override
  State<ImmediateNoteDetector> createState() => _ImmediateNoteDetectorState();
}

class _ImmediateNoteDetectorState extends State<ImmediateNoteDetector>
    with TickerProviderStateMixin {
  StreamSubscription<PitchDetectionResult>? _subscription;
  bool _isListening = false;
  String _currentNote = '';
  int _currentOctave = 0;
  double _confidence = 0.0;
  double _frequency = 0.0;
  List<DetectedNote> _recentNotes = [];
  int _detectionCount = 0;
  
  // Animation controllers for visual feedback
  late AnimationController _pulseController;
  late AnimationController _colorController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;
  
  Timer? _noteDecayTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade300,
      end: Colors.green.shade400,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pulseController.dispose();
    _colorController.dispose();
    _noteDecayTimer?.cancel();
    super.dispose();
  }

  void toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    try {
      final success = await widget.pitchDetectionService.startDetection();
      if (success && mounted) {
        _subscription = widget.pitchDetectionService.pitchStream?.listen(
          _onPitchDetected,
          onError: (error) {
            debugPrint('Note detection error: $error');
            _stopListening();
          },
        );
        setState(() {
          _isListening = true;
          _detectionCount = 0; // Reset counter
        });
        debugPrint('Immediate note detection started');
      }
    } catch (e) {
      debugPrint('Error starting immediate detection: $e');
    }
  }

  Future<void> _stopListening() async {
    try {
      await widget.pitchDetectionService.stopDetection();
      await _subscription?.cancel();
      _subscription = null;
      if (mounted) {
        setState(() {
          _isListening = false;
          _currentNote = '';
          _currentOctave = 0;
          _confidence = 0.0;
          _frequency = 0.0;
        });
        _colorController.reverse();
      }
    } catch (e) {
      debugPrint('Error stopping detection: $e');
    }
  }

  void _onPitchDetected(PitchDetectionResult result) {
    if (!mounted) return;

    // Cancel any existing decay timer
    _noteDecayTimer?.cancel();

    // Track detection attempts
    _detectionCount++;
    
    // Only log when there's an actual detection or every 100th attempt for debugging
    if (result.hasValidDetection || (_detectionCount % 100 == 0)) {
      debugPrint('Detection #$_detectionCount: notes=${result.detectedNotes.length}, confidence=${result.overallConfidence.toStringAsFixed(3)}, hasValid=${result.hasValidDetection}');
    }
    
    if (result.hasValidDetection && result.detectedNotes.isNotEmpty) {
      final note = result.detectedNotes.first;
      
      setState(() {
        _currentNote = note.noteName;
        _currentOctave = note.octave;
        _confidence = note.confidence;
        _frequency = note.frequency;
        
        // Update recent notes list
        _recentNotes.insert(0, note);
        if (_recentNotes.length > 20) {
          _recentNotes.removeLast();
        }
      });

      // Trigger immediate visual feedback
      _pulseController.forward().then((_) {
        if (mounted) _pulseController.reverse();
      });
      
      _colorController.forward();

      // Callback for detected note
      widget.onNoteDetected?.call(note);

      // Set decay timer to clear note if no new detection
      _noteDecayTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _currentNote = '';
            _currentOctave = 0;
            _confidence = 0.0;
            _frequency = 0.0;
          });
          _colorController.reverse();
        }
      });

      debugPrint(
        'IMMEDIATE: ${note.noteWithOctave} '
        '(${note.frequency.toStringAsFixed(1)}Hz, '
        '${(note.confidence * 100).toInt()}%)',
      );
    } else {
      // Start decay timer for no detection
      _noteDecayTimer ??= Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _currentNote = '';
            _currentOctave = 0;
            _confidence = 0.0;
            _frequency = 0.0;
          });
          _colorController.reverse();
        }
      });
    }
  }

  void _testNoteDisplay() {
    // Test the note display with a fake C4 note
    final testNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final randomNote = testNotes[DateTime.now().millisecond % testNotes.length];
    
    setState(() {
      _currentNote = randomNote;
      _currentOctave = 4;
      _confidence = 0.8;
      _frequency = 440.0;
    });
    
    // Trigger animations
    _pulseController.forward().then((_) {
      if (mounted) _pulseController.reverse();
    });
    
    _colorController.forward();
    
    debugPrint('TEST: Displaying ${randomNote}4');
    
    // Auto-clear after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentNote = '';
          _currentOctave = 0;
          _confidence = 0.0;
          _frequency = 0.0;
        });
        _colorController.reverse();
      }
    });
  }

  Color _getNoteColor() {
    if (_currentNote.isEmpty) return Colors.grey.shade300;
    
    // Color-code notes for visual feedback
    switch (_currentNote) {
      case 'C': return Colors.red.shade400;
      case 'C#': return Colors.red.shade600;
      case 'D': return Colors.orange.shade400;
      case 'D#': return Colors.orange.shade600;
      case 'E': return Colors.yellow.shade600;
      case 'F': return Colors.green.shade400;
      case 'F#': return Colors.green.shade600;
      case 'G': return Colors.blue.shade400;
      case 'G#': return Colors.blue.shade600;
      case 'A': return Colors.purple.shade400;
      case 'A#': return Colors.purple.shade600;
      case 'B': return Colors.pink.shade400;
      default: return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
        // Main detection display
        AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _colorAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentNote.isEmpty 
                      ? _colorAnimation.value 
                      : _getNoteColor(),
                  boxShadow: [
                    BoxShadow(
                      color: (_currentNote.isEmpty 
                          ? Colors.grey 
                          : _getNoteColor()).withValues(alpha: 0.3),
                      blurRadius: _confidence * 20,
                      spreadRadius: _confidence * 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentNote.isEmpty ? '--' : '$_currentNote$_currentOctave',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_frequency > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_frequency.toStringAsFixed(1)}Hz',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${(_confidence * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton.extended(
              onPressed: toggleListening,
              backgroundColor: _isListening ? Colors.red : Colors.green,
              icon: Icon(
                _isListening ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
              ),
              label: Text(
                _isListening ? 'Stop' : 'Start',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            FloatingActionButton(
              onPressed: _testNoteDisplay,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.music_note, color: Colors.white),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Status indicator with debug info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isListening ? Colors.green.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_off,
                    color: _isListening ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? 'Listening...' : 'Press to start',
                    style: TextStyle(
                      color: _isListening ? Colors.green.shade700 : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (_isListening && _detectionCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Detections: $_detectionCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        if (_recentNotes.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Recent Detections',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentNotes.take(10).map((note) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getNoteColorForNote(note.noteName),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${note.noteName}${note.octave}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
      ),
    );
  }
  
  Color _getNoteColorForNote(String noteName) {
    switch (noteName) {
      case 'C': return Colors.red.shade400;
      case 'C#': return Colors.red.shade600;
      case 'D': return Colors.orange.shade400;
      case 'D#': return Colors.orange.shade600;
      case 'E': return Colors.yellow.shade600;
      case 'F': return Colors.green.shade400;
      case 'F#': return Colors.green.shade600;
      case 'G': return Colors.blue.shade400;
      case 'G#': return Colors.blue.shade600;
      case 'A': return Colors.purple.shade400;
      case 'A#': return Colors.purple.shade600;
      case 'B': return Colors.pink.shade400;
      default: return Colors.grey.shade400;
    }
  }
}