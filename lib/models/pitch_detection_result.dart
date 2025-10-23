class PitchDetectionResult {
  final List<DetectedNote> detectedNotes;
  final double timestamp;
  final double overallConfidence;

  const PitchDetectionResult({
    required this.detectedNotes,
    required this.timestamp,
    required this.overallConfidence,
  });

  bool get hasValidDetection => detectedNotes.isNotEmpty && overallConfidence > 0.1; // Lower threshold for more responsive detection
  
  DetectedNote? get primaryNote => detectedNotes.isNotEmpty ? detectedNotes.first : null;
}

class DetectedNote {
  final String noteName;
  final int octave;
  final double frequency;
  final double confidence;
  final double amplitude;

  const DetectedNote({
    required this.noteName,
    required this.octave,
    required this.frequency,
    required this.confidence,
    required this.amplitude,
  });

  String get noteWithOctave => '$noteName$octave';

  @override
  String toString() => '$noteWithOctave (${frequency.toStringAsFixed(1)}Hz, ${(confidence * 100).toInt()}%)';
}

class CQTConfig {
  final int sampleRate;
  final int hopLength;
  final int binsPerOctave;
  final double fMin;
  final double fMax;
  final int nBins;
  final double threshold;

  const CQTConfig({
    this.sampleRate = 44100,
    this.hopLength = 128, // Smaller for better temporal resolution
    this.binsPerOctave = 36, // Higher resolution for better piano note discrimination
    this.fMin = 65.0, // C2 - covers full piano range
    this.fMax = 4200.0, // C8 - full piano range
    this.nBins = 252, // 7 octaves * 36 bins for full piano coverage
    this.threshold = 0.02, // Very low threshold for immediate detection
  });
} 