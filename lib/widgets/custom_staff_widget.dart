import 'package:flutter/material.dart';
import 'package:simple_sheet_music/simple_sheet_music.dart';

class CustomStaffWidget extends StatelessWidget {
  final String noteName;
  final int octave;
  final bool isHighlighted;
  final bool isCompleted;
  final double? staffHeight; // Optional parameter for custom height

  const CustomStaffWidget({
    super.key,
    required this.noteName,
    required this.octave,
    this.isHighlighted = false,
    this.isCompleted = false,
    this.staffHeight, // Default will be calculated in build method
  });

  @override
  Widget build(BuildContext context) {
    // Convert note name and octave to Pitch enum
    final pitch = _getPitchFromNoteName(noteName, octave);

    // Create a measure with the note
    final measure = Measure([
      const Clef(ClefType.treble),
      const KeySignature(KeySignatureType.cMajor),
      Note(pitch, noteDuration: NoteDuration.quarter),
    ]);

    // Use custom height if provided, otherwise use default
    final containerHeight = staffHeight ?? 200;

    return Container(
      height: containerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SimpleSheetMusic(
        measures: [measure],
        height:
            containerHeight *
            0.9, // Use 90% of container height for the sheet music
        width: double.infinity,
      ),
    );
  }

  Pitch _getPitchFromNoteName(String noteName, int octave) {
    // Map note names and octaves to Pitch enum values
    final noteWithOctave = '${noteName.toUpperCase()}$octave';

    switch (noteWithOctave) {
      case 'C3':
        return Pitch.c3;
      case 'D3':
        return Pitch.d3;
      case 'E3':
        return Pitch.e3;
      case 'F3':
        return Pitch.f3;
      case 'G3':
        return Pitch.g3;
      case 'A3':
        return Pitch.a3;
      case 'B3':
        return Pitch.b3;
      case 'C4':
        return Pitch.c4;
      case 'D4':
        return Pitch.d4;
      case 'E4':
        return Pitch.e4;
      case 'F4':
        return Pitch.f4;
      case 'G4':
        return Pitch.g4;
      case 'A4':
        return Pitch.a4;
      case 'B4':
        return Pitch.b4;
      case 'C5':
        return Pitch.c5;
      case 'D5':
        return Pitch.d5;
      case 'E5':
        return Pitch.e5;
      case 'F5':
        return Pitch.f5;
      case 'G5':
        return Pitch.g5;
      case 'A5':
        return Pitch.a5;
      case 'B5':
        return Pitch.b5;
      default:
        return Pitch.c4; // Default to middle C
    }
  }
}
