import 'dart:math' as math;
import 'dart:typed_data';

enum MidiMessageType {
  noteOn,
  noteOff,
  controlChange,
  pitchBend,
  programChange,
  aftertouch,
  systemExclusive,
  unknown,
}

class MidiMessage {
  final MidiMessageType type;
  final int channel;
  final int timestamp;
  final Uint8List data;

  const MidiMessage({
    required this.type,
    required this.channel,
    required this.timestamp,
    required this.data,
  });

  /// Create a MIDI message from raw data
  factory MidiMessage.fromData(Uint8List data, int timestamp) {
    if (data.isEmpty) {
      return MidiMessage(
        type: MidiMessageType.unknown,
        channel: 0,
        timestamp: timestamp,
        data: data,
      );
    }

    final status = data[0];
    final channel = status & 0x0F;
    final messageType = (status & 0xF0) >> 4;

    MidiMessageType type;
    switch (messageType) {
      case 0x8:
        type = MidiMessageType.noteOff;
        break;
      case 0x9:
        type = data.length > 2 && data[2] > 0 
            ? MidiMessageType.noteOn 
            : MidiMessageType.noteOff;
        break;
      case 0xA:
        type = MidiMessageType.aftertouch;
        break;
      case 0xB:
        type = MidiMessageType.controlChange;
        break;
      case 0xC:
        type = MidiMessageType.programChange;
        break;
      case 0xE:
        type = MidiMessageType.pitchBend;
        break;
      case 0xF:
        type = MidiMessageType.systemExclusive;
        break;
      default:
        type = MidiMessageType.unknown;
    }

    return MidiMessage(
      type: type,
      channel: channel,
      timestamp: timestamp,
      data: data,
    );
  }

  /// Get the note number for note on/off messages
  int? get noteNumber {
    if ((type == MidiMessageType.noteOn || type == MidiMessageType.noteOff) && data.length >= 2) {
      return data[1];
    }
    return null;
  }

  /// Get the velocity for note on/off messages
  int? get velocity {
    if ((type == MidiMessageType.noteOn || type == MidiMessageType.noteOff) && data.length >= 3) {
      return data[2];
    }
    return null;
  }

  /// Convert MIDI note number to note name and octave
  String? get noteName {
    final note = noteNumber;
    if (note == null) return null;
    
    final noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return noteNames[note % 12];
  }

  /// Get octave number from MIDI note number
  int? get octave {
    final note = noteNumber;
    if (note == null) return null;
    return (note ~/ 12) - 1;
  }

  /// Get note with octave (e.g., "C4", "A#3")
  String? get noteWithOctave {
    final name = noteName;
    final oct = octave;
    if (name == null || oct == null) return null;
    return '$name$oct';
  }

  /// Convert MIDI note number to frequency in Hz
  double? get frequency {
    final note = noteNumber;
    if (note == null) return null;
    // A4 (note 69) = 440 Hz
    return 440.0 * math.pow(2, (note - 69) / 12.0);
  }

  @override
  String toString() {
    if (type == MidiMessageType.noteOn || type == MidiMessageType.noteOff) {
      return 'MidiMessage(type: $type, channel: $channel, note: $noteWithOctave, velocity: $velocity, timestamp: $timestamp)';
    }
    return 'MidiMessage(type: $type, channel: $channel, data: $data, timestamp: $timestamp)';
  }
}
