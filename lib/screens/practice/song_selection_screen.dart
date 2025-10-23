import 'package:flutter/material.dart';
import '../../models/song_snippet.dart';
import '../../repositories/songs_repository.dart';
import 'practice_screen.dart';

class SongSelectionScreen extends StatefulWidget {
  const SongSelectionScreen({super.key});

  @override
  State<SongSelectionScreen> createState() => _SongSelectionScreenState();
}

class _SongSelectionScreenState extends State<SongSelectionScreen> {
  final SongsRepository _songsRepository = SongsRepository();
  List<SongSnippet> _songs = [];
  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
    });

    final songs = await _songsRepository.loadSongs();
    setState(() {
      _songs = songs;
      _isLoading = false;
    });
  }

  List<SongSnippet> get _filteredSongs {
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return _songs;
    }
    return _songs.where((song) => song.category == _selectedCategory).toList();
  }

  void _selectSong(SongSnippet song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeScreen(selectedSong: song),
      ),
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return const Color(0xFF96EBD2); // Mint green
      case 2:
        return const Color(0xFF7BE5FF); // Cyan
      case 3:
        return const Color(0xFFAEEFE0); // Light teal
      case 4:
        return const Color(0xFF8CEADF); // Medium mint
      case 5:
        return const Color(0xFF96EBD2); // Darker mint
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Easy';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Song'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
          ? const Center(
              child: Text(
                'No songs available.\nCheck your songs database.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                // Category filter
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('children'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('classical'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('folk'),
                      ],
                    ),
                  ),
                ),

                // Songs list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = _filteredSongs[index];
                      return _buildSongCard(song);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected =
        _selectedCategory == category ||
        (category == 'All' && _selectedCategory == null);

    return FilterChip(
      label: Text(
        category == 'children'
            ? 'Children\'s Songs'
            : category == 'classical'
            ? 'Classical'
            : category == 'folk'
            ? 'Folk'
            : category,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = category == 'All' ? null : category;
        });
      },
      backgroundColor: const Color(0xFFCAF4E9),
      selectedColor: const Color(0xFF7BE5FF),
      side: BorderSide(
        color: isSelected ? const Color(0xFF7BE5FF) : const Color(0xFF8CEADF),
        width: 2,
      ),
    );
  }

  Widget _buildSongCard(SongSnippet song) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF8CEADF), width: 2),
      ),
      child: InkWell(
        onTap: () => _selectSong(song),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Song icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCAF4E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getDifficultyColor(song.difficulty),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.music_note,
                      size: 32,
                      color: _getDifficultyColor(song.difficulty),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.composer,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Difficulty badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(song.difficulty),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getDifficultyLabel(song.difficulty),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                song.description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),

              const SizedBox(height: 12),

              // Song details
              Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Color(0xFF00838F)),
                  const SizedBox(width: 4),
                  Text(
                    '${song.totalDuration.toStringAsFixed(0)}s',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF00838F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Icon(
                    Icons.music_note,
                    size: 16,
                    color: Color(0xFF00838F),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${song.notes.length} notes',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF00838F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Icon(Icons.speed, size: 16, color: Color(0xFF00838F)),
                  const SizedBox(width: 4),
                  Text(
                    '${song.bpm} BPM',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF00838F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
