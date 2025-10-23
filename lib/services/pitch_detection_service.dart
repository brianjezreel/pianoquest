import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_pitch_detection/flutter_pitch_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/pitch_detection_result.dart';
import '../models/midi_note_event.dart';
import 'midi_service.dart';

enum InputMode { audio, midi, both }

class PitchDetectionService {
  final FlutterPitchDetection _pitchDetector = FlutterPitchDetection();
  final MidiService _midiService = MidiService();

  StreamController<PitchDetectionResult>? _pitchStreamController;
  StreamSubscription<Map<String, dynamic>>? _audioSubscription;
  StreamSubscription<MidiNoteEvent>? _midiSubscription;

  bool _isActive = false;
  bool _isInitialized = false;
  InputMode _inputMode = InputMode.audio;

  // MIDI note tracking for polyphonic detection simulation
  final Map<int, DetectedNote> _activeMidiNotes = {};
  int _debugCount = 0;

  Stream<PitchDetectionResult>? get pitchStream =>
      _pitchStreamController?.stream;
  bool get isActive => _isActive;
  InputMode get inputMode => _inputMode;
  MidiService get midiService => _midiService;
  bool get isMidiConnected => _midiService.hasConnectedDevices;

  Future<bool> initialize() async {
    try {
      // Request microphone permission first
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      _isInitialized = true;

      // Initialize MIDI service
      await _midiService.initialize();

      return true;
    } catch (e) {
      debugPrint('Error initializing pitch detection: $e');
      return false;
    }
  }

  /// Set the input mode for pitch detection
  Future<bool> setInputMode(InputMode mode) async {
    if (_isActive) {
      await stopDetection();
    }

    _inputMode = mode;
    debugPrint('Input mode changed to: $mode');

    return true;
  }

  Future<bool> startDetection([InputMode? mode]) async {
    if (_isActive) return true;

    if (mode != null) {
      _inputMode = mode;
    }

    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Initialize pitch detection stream
      _pitchStreamController =
          StreamController<PitchDetectionResult>.broadcast();

      bool hasActiveInput = false;

      // Start audio input if needed
      if (_inputMode == InputMode.audio || _inputMode == InputMode.both) {
        try {
          // Start pitch detection with flutter_pitch_detection
          // Using smaller buffer for more responsive detection
          await _pitchDetector.startDetection(
            sampleRate: 44100,
            bufferSize: 4096, // Smaller buffer for faster response
          );

          // Note: Some flutter_pitch_detection versions don't support setToleranceCents/setMinPrecision
          // We'll handle sensitivity through our processing logic instead

          // Listen to the pitch detection stream
          _audioSubscription = _pitchDetector.onPitchDetected.listen(
            _processPitchResult,
            onError: (error) {
              debugPrint('Pitch detection error: $error');
              stopDetection();
            },
          );
          hasActiveInput = true;
          debugPrint(
            'Audio pitch detection started successfully with enhanced settings',
          );
        } catch (e) {
          debugPrint('Failed to start pitch detection: $e');
        }
      }
      // Start MIDI input if needed
      if (_inputMode == InputMode.midi || _inputMode == InputMode.both) {
        if (_midiService.hasConnectedDevices) {
          _midiSubscription = _midiService.noteEventsStream?.listen(
            _processMidiNoteEvent,
            onError: (error) {
              debugPrint('MIDI stream error: $error');
            },
          );
          hasActiveInput = true;
          debugPrint('MIDI input started successfully');
        } else {
          debugPrint('No MIDI devices connected');
        }
      }

      if (!hasActiveInput) {
        debugPrint('No input sources available for pitch detection');
        return false;
      }

      _isActive = true;
      debugPrint('Pitch detection started successfully with mode: $_inputMode');
      return true;
    } catch (e) {
      debugPrint('Error starting pitch detection: $e');
      return false;
    }
  }

  void _processPitchResult(Map<String, dynamic> pitchResult) {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;

      // Debug: Log raw data to understand what we're receiving
      if (_debugCount % 50 == 0) {
        // Log every 50th result for debugging
        debugPrint('Raw pitch data: $pitchResult');
      }
      _debugCount++;

      // Extract data from flutter_pitch_detection result
      // Try multiple field names as different versions might use different keys
      final pitch =
          (pitchResult['pitch'] ??
                  pitchResult['frequency'] ??
                  pitchResult['freq'])
              as num?;
      final note = (pitchResult['note'] ?? pitchResult['noteName']) as String?;
      final octave =
          (pitchResult['octave'] ?? pitchResult['octaveNumber']) as num?;
      final accuracy =
          (pitchResult['accuracy'] ??
                  pitchResult['confidence'] ??
                  pitchResult['probability'])
              as num?;

      // Very lenient validation - accept almost any positive frequency
      if (pitch != null && pitch > 20) {
        // Very low threshold (20Hz catches almost everything)
        // If note/octave not provided, calculate them from frequency
        String finalNote = note ?? '';
        int finalOctave = octave?.toInt() ?? 0;

        if (finalNote.isEmpty && pitch > 0) {
          // Calculate note from frequency if not provided
          final noteInfo = _frequencyToNote(pitch.toDouble());
          if (noteInfo != null) {
            finalNote = noteInfo['note'] as String;
            finalOctave = noteInfo['octave'] as int;
          }
        }

        // Calculate confidence with fallbacks - be more generous with confidence
        double confidence = 0.7; // Higher default confidence
        if (accuracy != null) {
          confidence = accuracy > 1 ? accuracy / 100.0 : accuracy.toDouble();
          // Boost low confidence values to make detection more responsive
          if (confidence < 0.3) {
            confidence = 0.5; // Minimum useful confidence
          }
        }

        // Only create detection if we have a valid note
        if (finalNote.isNotEmpty) {
          final detectedNote = DetectedNote(
            noteName: finalNote,
            octave: finalOctave,
            frequency: pitch.toDouble(),
            confidence: confidence,
            amplitude: 0.5,
          );

          final result = PitchDetectionResult(
            detectedNotes: [detectedNote],
            timestamp: timestamp,
            overallConfidence: confidence,
          );

          _pitchStreamController?.add(result);

          debugPrint(
            'PITCH DETECTION: ${detectedNote.noteWithOctave} '
            '(${pitch.toStringAsFixed(1)}Hz, ${(confidence * 100).toInt()}% confidence)',
          );
        } else {
          // Have frequency but couldn't determine note
          _pitchStreamController?.add(
            PitchDetectionResult(
              detectedNotes: [],
              timestamp: timestamp,
              overallConfidence: 0.0,
            ),
          );
        }
      } else {
        // No pitch detected - emit empty result
        _pitchStreamController?.add(
          PitchDetectionResult(
            detectedNotes: [],
            timestamp: timestamp,
            overallConfidence: 0.0,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error processing pitch result: $e - Data: $pitchResult');
      _pitchStreamController?.add(
        PitchDetectionResult(
          detectedNotes: [],
          timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
          overallConfidence: 0.0,
        ),
      );
    }
  }

  Map<String, dynamic>? _frequencyToNote(double frequency) {
    // A4 = 440 Hz reference
    const a4Frequency = 440.0;
    const a4NoteNumber = 69; // A4 is MIDI note 69

    // Calculate MIDI note number
    final noteNumber =
        (12 * math.log(frequency / a4Frequency) / math.ln2 + a4NoteNumber)
            .round();

    if (noteNumber < 21 || noteNumber > 108) {
      return null; // Outside piano range
    }

    // Convert MIDI note number to note name and octave
    const noteNames = [
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
    final noteName = noteNames[noteNumber % 12];
    final octave = (noteNumber ~/ 12) - 1;

    return {'note': noteName, 'octave': octave};
  }

  /// Process MIDI note events and convert to pitch detection results
  void _processMidiNoteEvent(MidiNoteEvent noteEvent) {
    try {
      if (noteEvent.isNoteOn) {
        // Add or update active MIDI note
        final detectedNote = DetectedNote(
          noteName: noteEvent.noteName,
          octave: noteEvent.octave,
          frequency: noteEvent.frequency,
          confidence: noteEvent.confidence,
          amplitude: noteEvent.normalizedVelocity,
        );
        _activeMidiNotes[noteEvent.midiNoteNumber] = detectedNote;
      } else {
        // Remove the note
        _activeMidiNotes.remove(noteEvent.midiNoteNumber);
      }

      // Create pitch detection result from active MIDI notes
      final activeNotes = _activeMidiNotes.values.toList();
      final result = PitchDetectionResult(
        detectedNotes: activeNotes,
        timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
        overallConfidence: activeNotes.isEmpty
            ? 0.0
            : activeNotes
                  .map((n) => n.confidence)
                  .reduce((a, b) => math.max(a, b)),
      );

      _pitchStreamController?.add(result);

      if (activeNotes.isNotEmpty) {
        final noteNames = activeNotes.map((n) => n.noteWithOctave).join(', ');
        debugPrint('MIDI DETECTION: $noteNames');
      }
    } catch (e) {
      debugPrint('Error processing MIDI note event: $e');
    }
  }

  Future<void> stopDetection() async {
    if (!_isActive) return;

    try {
      _isActive = false;

      // Cancel audio subscription
      await _audioSubscription?.cancel();
      _audioSubscription = null;

      // Cancel MIDI subscription
      await _midiSubscription?.cancel();
      _midiSubscription = null;

      // Stop pitch detection
      if (_inputMode == InputMode.audio || _inputMode == InputMode.both) {
        await _pitchDetector.stopDetection();
      }

      // Clear active MIDI notes
      _activeMidiNotes.clear();

      // Close pitch stream
      await _pitchStreamController?.close();
      _pitchStreamController = null;

      debugPrint('Pitch detection stopped');
    } catch (e) {
      debugPrint('Error stopping pitch detection: $e');
    }
  }

  void dispose() {
    stopDetection();
    _midiService.dispose();
  }
}
