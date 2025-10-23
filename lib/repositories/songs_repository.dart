import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/song_snippet.dart';

class SongsRepository {
  static const String _songsFilePath = 'assets/data/songs.json';

  List<SongSnippet>? _cachedSongs;

  /// Load all songs from the JSON file
  Future<List<SongSnippet>> loadSongs() async {
    if (_cachedSongs != null) {
      return _cachedSongs!;
    }

    try {
      final String jsonString = await rootBundle.loadString(_songsFilePath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> songsJson = jsonData['songs'] ?? [];

      _cachedSongs = songsJson.map((songJson) => _parseSong(songJson)).toList();
      return _cachedSongs!;
    } catch (e) {
      print('Error loading songs: $e');
      return [];
    }
  }

  /// Parse a song from JSON
  SongSnippet _parseSong(Map<String, dynamic> json) {
    return SongSnippet(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      composer: json['composer'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 1,
      bpm: json['bpm'] ?? 60,
      category: json['category'] ?? '',
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      notes:
          (json['notes'] as List<dynamic>?)
              ?.map((noteJson) => _parseNote(noteJson))
              .toList() ??
          [],
    );
  }

  /// Parse a note from JSON
  SongNote _parseNote(Map<String, dynamic> json) {
    return SongNote(
      noteName: json['noteName'] ?? '',
      octave: json['octave'] ?? 4,
      startTime: (json['startTime'] ?? 0.0).toDouble(),
      duration: (json['duration'] ?? 1.0).toDouble(),
      isSequential: json['isSequential'] ?? true,
      velocity: json['velocity'] ?? 80,
      lyric: json['lyric'],
    );
  }

  /// Get a song by ID
  Future<SongSnippet?> getSongById(String id) async {
    final songs = await loadSongs();
    try {
      return songs.firstWhere((song) => song.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get songs by category
  Future<List<SongSnippet>> getSongsByCategory(String category) async {
    final songs = await loadSongs();
    return songs.where((song) => song.category == category).toList();
  }

  /// Get songs by difficulty
  Future<List<SongSnippet>> getSongsByDifficulty(int difficulty) async {
    final songs = await loadSongs();
    return songs.where((song) => song.difficulty == difficulty).toList();
  }

  /// Get all categories
  Future<List<String>> getAllCategories() async {
    final songs = await loadSongs();
    return songs.map((song) => song.category).toSet().toList();
  }

  /// Clear cache (useful for testing)
  void clearCache() {
    _cachedSongs = null;
  }
}
