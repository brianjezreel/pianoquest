import 'dart:convert';

enum NoteEventType {
  noteOn,
  noteOff,
  detection, // For audio-detected notes that don't have distinct on/off
}

enum InputSource {
  audio,
  midi,
}

class NoteEvent {
  final String id;
  final String noteName;
  final int octave;
  final double frequency;
  final double confidence;
  final int velocity; // 0-127 for MIDI, or normalized from amplitude for audio
  final NoteEventType type;
  final InputSource source;
  final DateTime timestamp;
  final int? midiChannel;
  final double? amplitude;
  final Duration? duration; // For completed note events
  
  const NoteEvent({
    required this.id,
    required this.noteName,
    required this.octave,
    required this.frequency,
    required this.confidence,
    required this.velocity,
    required this.type,
    required this.source,
    required this.timestamp,
    this.midiChannel,
    this.amplitude,
    this.duration,
  });

  /// Create a note event from audio detection
  factory NoteEvent.fromAudioDetection({
    required String noteName,
    required int octave,
    required double frequency,
    required double confidence,
    required double amplitude,
    DateTime? timestamp,
  }) {
    return NoteEvent(
      id: _generateId(),
      noteName: noteName,
      octave: octave,
      frequency: frequency,
      confidence: confidence,
      velocity: (amplitude * 127).round().clamp(1, 127),
      type: NoteEventType.detection,
      source: InputSource.audio,
      timestamp: timestamp ?? DateTime.now(),
      amplitude: amplitude,
    );
  }

  /// Create a note event from MIDI input
  factory NoteEvent.fromMidiEvent({
    required String noteName,
    required int octave,
    required double frequency,
    required int velocity,
    required bool isNoteOn,
    required int channel,
    DateTime? timestamp,
  }) {
    return NoteEvent(
      id: _generateId(),
      noteName: noteName,
      octave: octave,
      frequency: frequency,
      confidence: 1.0, // MIDI is always 100% confident
      velocity: velocity,
      type: isNoteOn ? NoteEventType.noteOn : NoteEventType.noteOff,
      source: InputSource.midi,
      timestamp: timestamp ?? DateTime.now(),
      midiChannel: channel,
    );
  }

  /// Generate a unique ID for the event
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           '_${DateTime.now().microsecond}';
  }

  /// Get the note with octave (e.g., "C4", "A#3")
  String get noteWithOctave => '$noteName$octave';

  /// Get velocity as a normalized value between 0.0 and 1.0
  double get normalizedVelocity => velocity / 127.0;

  /// Get formatted timestamp for display
  String get formattedTime {
    final time = timestamp;
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}.'
           '${time.millisecond.toString().padLeft(3, '0')}';
  }

  /// Get relative timestamp from now
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 1) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Get source icon for display
  String get sourceIcon {
    switch (source) {
      case InputSource.audio:
        return '🎤';
      case InputSource.midi:
        return '🎹';
    }
  }

  /// Get type icon for display
  String get typeIcon {
    switch (type) {
      case NoteEventType.noteOn:
        return '▶️';
      case NoteEventType.noteOff:
        return '⏹️';
      case NoteEventType.detection:
        return '🎵';
    }
  }

  /// Copy with new values
  NoteEvent copyWith({
    String? id,
    String? noteName,
    int? octave,
    double? frequency,
    double? confidence,
    int? velocity,
    NoteEventType? type,
    InputSource? source,
    DateTime? timestamp,
    int? midiChannel,
    double? amplitude,
    Duration? duration,
  }) {
    return NoteEvent(
      id: id ?? this.id,
      noteName: noteName ?? this.noteName,
      octave: octave ?? this.octave,
      frequency: frequency ?? this.frequency,
      confidence: confidence ?? this.confidence,
      velocity: velocity ?? this.velocity,
      type: type ?? this.type,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
      midiChannel: midiChannel ?? this.midiChannel,
      amplitude: amplitude ?? this.amplitude,
      duration: duration ?? this.duration,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'noteName': noteName,
      'octave': octave,
      'frequency': frequency,
      'confidence': confidence,
      'velocity': velocity,
      'type': type.index,
      'source': source.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'midiChannel': midiChannel,
      'amplitude': amplitude,
      'duration': duration?.inMilliseconds,
    };
  }

  /// Create from JSON
  factory NoteEvent.fromJson(Map<String, dynamic> json) {
    return NoteEvent(
      id: json['id'],
      noteName: json['noteName'],
      octave: json['octave'],
      frequency: json['frequency'],
      confidence: json['confidence'],
      velocity: json['velocity'],
      type: NoteEventType.values[json['type']],
      source: InputSource.values[json['source']],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      midiChannel: json['midiChannel'],
      amplitude: json['amplitude'],
      duration: json['duration'] != null 
          ? Duration(milliseconds: json['duration'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NoteEvent($noteWithOctave, ${frequency.toStringAsFixed(1)}Hz, '
           'vel:$velocity, conf:${(confidence * 100).toInt()}%, '
           'src:${source.name}, type:${type.name}, time:$formattedTime)';
  }
}