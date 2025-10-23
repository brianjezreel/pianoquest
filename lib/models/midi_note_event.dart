import 'dart:math' as math;

class MidiNoteEvent {
  final String noteName;
  final int octave;
  final double frequency;
  final int velocity;
  final bool isNoteOn;
  final int channel;
  final int timestamp;
  final int midiNoteNumber;

  const MidiNoteEvent({
    required this.noteName,
    required this.octave,
    required this.frequency,
    required this.velocity,
    required this.isNoteOn,
    required this.channel,
    required this.timestamp,
    required this.midiNoteNumber,
  });

  /// Create a MidiNoteEvent from a MIDI note number
  factory MidiNoteEvent.fromMidiNote({
    required int midiNoteNumber,
    required int velocity,
    required bool isNoteOn,
    required int channel,
    required int timestamp,
  }) {
    final noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final noteName = noteNames[midiNoteNumber % 12];
    final octave = (midiNoteNumber ~/ 12) - 1;
    
    // Calculate frequency: A4 (MIDI note 69) = 440 Hz
    final frequency = 440.0 * math.pow(2, (midiNoteNumber - 69) / 12.0);

    return MidiNoteEvent(
      noteName: noteName,
      octave: octave,
      frequency: frequency,
      velocity: velocity,
      isNoteOn: isNoteOn,
      channel: channel,
      timestamp: timestamp,
      midiNoteNumber: midiNoteNumber,
    );
  }

  /// Get the note with octave (e.g., "C4", "A#3")
  String get noteWithOctave => '$noteName$octave';

  /// Get velocity as a normalized value between 0.0 and 1.0
  double get normalizedVelocity => velocity / 127.0;

  /// Get confidence level based on velocity (for compatibility with audio detection)
  double get confidence => normalizedVelocity;

  MidiNoteEvent copyWith({
    String? noteName,
    int? octave,
    double? frequency,
    int? velocity,
    bool? isNoteOn,
    int? channel,
    int? timestamp,
    int? midiNoteNumber,
  }) {
    return MidiNoteEvent(
      noteName: noteName ?? this.noteName,
      octave: octave ?? this.octave,
      frequency: frequency ?? this.frequency,
      velocity: velocity ?? this.velocity,
      isNoteOn: isNoteOn ?? this.isNoteOn,
      channel: channel ?? this.channel,
      timestamp: timestamp ?? this.timestamp,
      midiNoteNumber: midiNoteNumber ?? this.midiNoteNumber,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MidiNoteEvent &&
        other.noteName == noteName &&
        other.octave == octave &&
        other.frequency == frequency &&
        other.velocity == velocity &&
        other.isNoteOn == isNoteOn &&
        other.channel == channel &&
        other.timestamp == timestamp &&
        other.midiNoteNumber == midiNoteNumber;
  }

  @override
  int get hashCode {
    return noteName.hashCode ^
        octave.hashCode ^
        frequency.hashCode ^
        velocity.hashCode ^
        isNoteOn.hashCode ^
        channel.hashCode ^
        timestamp.hashCode ^
        midiNoteNumber.hashCode;
  }

  @override
  String toString() {
    final action = isNoteOn ? 'ON' : 'OFF';
    return 'MidiNoteEvent($noteWithOctave $action, vel: $velocity, freq: ${frequency.toStringAsFixed(1)}Hz, ch: $channel)';
  }
}
