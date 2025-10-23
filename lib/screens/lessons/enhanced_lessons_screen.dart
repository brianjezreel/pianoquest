import 'package:flutter/material.dart';
import '../../models/profile.dart';
import '../../models/lesson.dart';
import '../../repositories/lessons_repository.dart';
import '../../repositories/progress_repository.dart';
import 'lesson_view_screen.dart';

class EnhancedLessonsScreen extends StatefulWidget {
  final Profile profile;

  const EnhancedLessonsScreen({super.key, required this.profile});

  @override
  State<EnhancedLessonsScreen> createState() => _EnhancedLessonsScreenState();
}

class _EnhancedLessonsScreenState extends State<EnhancedLessonsScreen> {
  late LessonsRepository _lessonsRepository;
  late ProgressRepository _progressRepository;

  List<int> _completedLessonIds = [];
  String _selectedCategory = 'Basics';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    _lessonsRepository = LessonsRepository();
    _progressRepository = ProgressRepository();

    await _progressRepository.initialize();

    _loadLessonsData();
  }

  void _loadLessonsData() {
    setState(() {
      _completedLessonIds = _progressRepository.getCompletedLessonIds(
        widget.profile.profileId!,
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 768;
        final isSmallScreen = screenWidth < 400;

        // Responsive sizing
        final sidebarWidth = isTablet ? 220.0 : 180.0;
        final padding = isSmallScreen ? 10.0 : 12.0;
        final gap = isSmallScreen ? 10.0 : 12.0;

        if (isSmallScreen) {
          // Mobile layout - single column
          return Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getAvatarColor(widget.profile.profileId!),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.profile.name.isNotEmpty
                            ? widget.profile.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lessons', style: TextStyle(fontSize: 18)),
                      Text(
                        '${widget.profile.name} • Level ${widget.profile.currentLevel}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.school),
                  onPressed: _showLessonOverview,
                  tooltip: 'Lesson Overview',
                ),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    // Fixed header sections
                    _buildProgressSummary(),
                    SizedBox(height: gap),
                    _buildCategoriesSection(),
                    SizedBox(height: gap),
                    // Scrollable lessons content
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildLessonsContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Tablet/desktop layout - two columns
          return Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getAvatarColor(widget.profile.profileId!),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.profile.name.isNotEmpty
                            ? widget.profile.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lessons', style: TextStyle(fontSize: 18)),
                      Text(
                        '${widget.profile.name} • Level ${widget.profile.currentLevel}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.school),
                  onPressed: _showLessonOverview,
                  tooltip: 'Lesson Overview',
                ),
              ],
            ),
            body: Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left sidebar - Categories and progress
                  SizedBox(
                    width: sidebarWidth,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressSummary(),
                          SizedBox(height: gap),
                          _buildCategoriesSection(),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: gap),

                  // Right side - Lesson details
                  Expanded(
                    child: SingleChildScrollView(child: _buildLessonsContent()),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildProgressSummary() {
    final overview = _lessonsRepository.getLessonOverview(_completedLessonIds);
    final completedCount = overview['completedLessons'] as int;
    final totalCount = overview['totalLessons'] as int;
    final completionPercentage = overview['completionPercentage'] as int;

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Progress',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completedCount/$totalCount lessons',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  '$completionPercentage%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: completedCount / totalCount,
              backgroundColor: const Color(0xFFCAF4E9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00ACC1),
              ),
              minHeight: 4,
            ),

            // Only show next lesson recommendation if not all completed
            if (completionPercentage < 100) ...[
              const SizedBox(height: 10),
              _buildNextLessonRecommendation(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextLessonRecommendation() {
    final nextLesson = _lessonsRepository.getNextLesson(_completedLessonIds);

    if (nextLesson == null) {
      return Row(
        children: const [
          Icon(Icons.celebration, color: Color(0xFF00838F), size: 14),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'All lessons completed! 🎉',
              style: TextStyle(
                color: Color(0xFF00838F),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => _startLesson(nextLesson),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFCAF4E9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF8CEADF), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle, color: Color(0xFF00838F), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next:',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    nextLesson.title,
                    style: const TextStyle(
                      color: Color(0xFF00838F),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF00838F),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = _lessonsRepository.getCategories();

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categories',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            ...categories.map((category) => _buildCategoryItem(category)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category) {
    final categoryLessons = _lessonsRepository.getLessonsByCategory(category);
    final completedInCategory = categoryLessons
        .where((lesson) => _completedLessonIds.contains(lesson.lessonId))
        .length;
    final isSelected = _selectedCategory == category;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = category),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7BE5FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                color: isSelected ? Colors.white : const Color(0xFF00838F),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completedInCategory/${categoryLessons.length} lessons',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 35,
                height: 3,
                child: LinearProgressIndicator(
                  value: completedInCategory / categoryLessons.length,
                  backgroundColor: isSelected
                      ? Colors.white30
                      : const Color(0xFFCAF4E9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSelected ? Colors.white : const Color(0xFF00ACC1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonsContent() {
    final categoryLessons = _lessonsRepository.getLessonsByCategory(
      _selectedCategory,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_selectedCategory Lessons',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFCAF4E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF8CEADF)),
              ),
              child: Text(
                '${categoryLessons.where((l) => _completedLessonIds.contains(l.lessonId)).length}/${categoryLessons.length} Complete',
                style: const TextStyle(
                  color: Color(0xFF00838F),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          height: 600, // Fixed height to prevent unbounded constraints
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              final aspectRatio = constraints.maxWidth > 600 ? 1.2 : 1.1;

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: categoryLessons.length,
                itemBuilder: (context, index) {
                  return _buildLessonCard(categoryLessons[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    final isCompleted = _completedLessonIds.contains(lesson.lessonId);
    final isUnlocked = lesson.isUnlocked(_completedLessonIds);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isCompleted) {
      statusColor = const Color(0xFF00897B);
      statusText = 'Completed';
      statusIcon = Icons.check_circle;
    } else if (isUnlocked) {
      statusColor = const Color(0xFF00ACC1);
      statusText = 'Available';
      statusIcon = Icons.play_circle;
    } else {
      statusColor = Colors.grey;
      statusText = 'Locked';
      statusIcon = Icons.lock;
    }

    return Card(
      color: isUnlocked ? Colors.white : Colors.grey.shade50,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: isUnlocked ? () => _startLesson(lesson) : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Text(
                lesson.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isUnlocked ? Colors.black : Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              Text(
                lesson.description,
                style: TextStyle(
                  fontSize: 11,
                  color: isUnlocked ? Colors.grey.shade600 : Colors.grey,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    size: 12,
                    color: isUnlocked ? const Color(0xFF00838F) : Colors.grey,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${lesson.xpReward} XP',
                    style: TextStyle(
                      fontSize: 10,
                      color: isUnlocked ? const Color(0xFF00838F) : Colors.grey,
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

  Future<void> _startLesson(Lesson lesson) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            LessonViewScreen(lesson: lesson, profile: widget.profile),
      ),
    );

    // Refresh data if lesson was completed
    if (result == true) {
      _loadLessonsData();
    }
  }

  void _showLessonOverview() {
    final overview = _lessonsRepository.getLessonOverview(_completedLessonIds);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lesson Overview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewRow('Total Lessons', '${overview['totalLessons']}'),
            _buildOverviewRow('Completed', '${overview['completedLessons']}'),
            _buildOverviewRow('Available', '${overview['availableLessons']}'),
            _buildOverviewRow(
              'Progress',
              '${overview['completionPercentage']}%',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'basics':
        return Icons.school;
      case 'scales':
        return Icons.trending_up;
      case 'chords':
        return Icons.piano;
      case 'songs':
        return Icons.audiotrack;
      case 'advanced':
        return Icons.star;
      default:
        return Icons.music_note;
    }
  }

  Color _getAvatarColor(int profileId) {
    final colors = [
      const Color(0xFF7BE5FF),
      const Color(0xFF96EBD2),
      const Color(0xFFAEEFE0),
      const Color(0xFF8CEADF),
      const Color(0xFF7BE5FF),
      const Color(0xFF96EBD2),
      const Color(0xFFAEEFE0),
      const Color(0xFF8CEADF),
    ];
    return colors[profileId % colors.length];
  }

  @override
  void dispose() {
    _progressRepository.close();
    super.dispose();
  }
}
