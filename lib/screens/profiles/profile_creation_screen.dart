import 'package:flutter/material.dart';
import '../../models/profile.dart';
import '../../repositories/profiles_repository.dart';

class ProfileCreationScreen extends StatefulWidget {
  final VoidCallback? onProfileCreated;

  const ProfileCreationScreen({super.key, this.onProfileCreated});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final PageController _pageController = PageController();
  final _nameController = TextEditingController();
  ProfilesRepository? _repository; // Keep repository instance

  int _currentPage = 0;
  bool _isLoading = false;

  // Profile data
  String _name = '';
  AgeRange _selectedAgeRange = AgeRange.adult;
  SkillLevel _selectedSkillLevel = SkillLevel.beginner;
  bool _hasExperience = false;
  MusicReading _selectedMusicReading = MusicReading.none;
  Goal _selectedGoal = Goal.fun;
  PracticeStyle _selectedPracticeStyle = PracticeStyle.short_frequent;
  DifficultyRamp _selectedDifficultyRamp = DifficultyRamp.moderate;
  LessonMode _selectedLessonMode = LessonMode.structured;
  int _confidenceRating = 5;

  // Slide configuration (removed music genre slide)
  final List<ProfileSlide> _slides = [
    const ProfileSlide(
      title: "Welcome to PianoQuest!",
      subtitle: "Let's create your personalized learning profile",
      icon: Icons.piano,
      color: Color(0xFF7BE5FF),
    ),
    const ProfileSlide(
      title: "What's your name?",
      subtitle: "This helps us personalize your experience",
      icon: Icons.person,
      color: Color(0xFF96EBD2),
    ),
    const ProfileSlide(
      title: "What's your age range?",
      subtitle: "We'll tailor lessons to your age group",
      icon: Icons.cake,
      color: Color(0xFFAEEFE0),
    ),
    const ProfileSlide(
      title: "What's your skill level?",
      subtitle: "Don't worry, we'll help you grow!",
      icon: Icons.trending_up,
      color: Color(0xFF8CEADF),
    ),
    const ProfileSlide(
      title: "Do you play any instruments?",
      subtitle: "Musical experience helps us understand your background",
      icon: Icons.music_note,
      color: Color(0xFF7BE5FF),
    ),
    const ProfileSlide(
      title: "Can you read music?",
      subtitle: "We'll adjust our teaching approach accordingly",
      icon: Icons.library_music,
      color: Color(0xFF96EBD2),
    ),
    const ProfileSlide(
      title: "What's your main goal?",
      subtitle: "This helps us choose the right lessons for you",
      icon: Icons.flag,
      color: Color(0xFFAEEFE0),
    ),
    const ProfileSlide(
      title: "How do you prefer to practice?",
      subtitle: "Choose what works best for your schedule",
      icon: Icons.schedule,
      color: Color(0xFF8CEADF),
    ),
    const ProfileSlide(
      title: "What learning pace suits you?",
      subtitle: "We'll adjust the difficulty progression",
      icon: Icons.speed,
      color: Color(0xFF7BE5FF),
    ),
    const ProfileSlide(
      title: "What lesson style do you prefer?",
      subtitle: "Choose how you like to learn",
      icon: Icons.school,
      color: Color(0xFF96EBD2),
    ),
    const ProfileSlide(
      title: "How confident are you?",
      subtitle: "Rate your confidence about learning piano",
      icon: Icons.sentiment_very_satisfied,
      color: Color(0xFFAEEFE0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    try {
      _repository = ProfilesRepository();
      await _repository!.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing storage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    // Don't close repository here - will be closed in _createProfile
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenWidth < 400;
        final isTablet = screenWidth > 768;
        final isLandscape = screenWidth > screenHeight;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: _currentPage > 0
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: isSmallScreen ? 20.0 : 24.0,
                    ),
                    onPressed: _goToPreviousPage,
                  )
                : null,
            title: Text(
              'Step ${_currentPage + 1} of ${_slides.length}',
              style: TextStyle(
                color: Colors.black,
                fontSize: isSmallScreen ? 14.0 : 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Progress bar
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12.0 : (isTablet ? 48 : 24),
                  vertical: isSmallScreen ? 4.0 : 8.0,
                ),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / _slides.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _slides[_currentPage].color,
                  ),
                  minHeight: isSmallScreen ? 4.0 : 6.0,
                ),
              ),

              // Slide content - use landscape layout with flexible height
              Expanded(
                child: LayoutBuilder(
                  builder: (context, slideConstraints) {
                    return PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: slideConstraints.maxHeight,
                            ),
                            child: _buildLandscapeSlide(
                              index,
                              isTablet,
                              isLandscape,
                              isSmallScreen,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Navigation buttons
              _buildNavigationButtons(isTablet, isSmallScreen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLandscapeSlide(
    int index,
    bool isTablet,
    bool isLandscape,
    bool isSmallScreen,
  ) {
    final slide = _slides[index];
    final iconSize = isSmallScreen ? 30.0 : (isTablet ? 50.0 : 40.0);
    final containerSize = isSmallScreen ? 60.0 : (isTablet ? 100.0 : 80.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8.0 : (isTablet ? 32.0 : 16.0),
              vertical: isSmallScreen ? 4.0 : 8.0,
            ),
            child: Row(
              children: [
                // Left side - Icon and header (more compact)
                Flexible(
                  flex: isSmallScreen ? 2 : 3,

                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: isSmallScreen ? 100.0 : 150.0,

                      maxWidth: isSmallScreen
                          ? 150.0
                          : (isLandscape ? 240 : 200),
                    ),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: containerSize,
                          height: containerSize,
                          decoration: BoxDecoration(
                            color: slide.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: slide.color,
                              width: isSmallScreen ? 1.0 : 2.0,
                            ),
                          ),
                          child: Icon(
                            slide.icon,
                            size: iconSize,
                            color: slide.color,
                          ),
                        ),
                        SizedBox(
                          height: isSmallScreen ? 8.0 : (isTablet ? 16 : 12),
                        ),

                        // Title
                        Text(
                          slide.title,
                          style: TextStyle(
                            fontSize: isSmallScreen
                                ? 14.0
                                : (isTablet ? 20 : 18),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: isSmallScreen ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(
                          height: isSmallScreen ? 4.0 : (isTablet ? 8 : 6),
                        ),

                        // Subtitle
                        Text(
                          slide.subtitle,
                          style: TextStyle(
                            fontSize: isSmallScreen
                                ? 10.0
                                : (isTablet ? 14 : 12),
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: isSmallScreen ? 4 : 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: isSmallScreen ? 8.0 : (isTablet ? 24 : 16)),

                // Right side - Interactive content (flexible)
                Flexible(
                  flex: isSmallScreen ? 3 : 4,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 4.0 : (isTablet ? 16 : 8),
                        vertical: isSmallScreen ? 4.0 : (isTablet ? 16 : 8),
                      ),
                      child: _buildSlideContent(index, isTablet, isSmallScreen),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlideContent(int index, bool isTablet, bool isSmallScreen) {
    switch (index) {
      case 0: // Welcome
        return _buildWelcomeContent(isTablet, isSmallScreen);
      case 1: // Name
        return _buildNameContent(isTablet, isSmallScreen);
      case 2: // Age Range
        return _buildAgeRangeContent(isTablet, isSmallScreen);
      case 3: // Skill Level
        return _buildSkillLevelContent(isTablet, isSmallScreen);
      case 4: // Experience
        return _buildExperienceContent(isTablet, isSmallScreen);
      case 5: // Music Reading
        return _buildMusicReadingContent(isTablet, isSmallScreen);
      case 6: // Goal
        return _buildGoalContent(isTablet, isSmallScreen);
      case 7: // Practice Style
        return _buildPracticeStyleContent(isTablet, isSmallScreen);
      case 8: // Difficulty Ramp
        return _buildDifficultyRampContent(isTablet, isSmallScreen);
      case 9: // Lesson Mode
        return _buildLessonModeContent(isTablet, isSmallScreen);
      case 10: // Confidence
        return _buildConfidenceContent(isTablet, isSmallScreen);
      default:
        return const SizedBox();
    }
  }

  Widget _buildWelcomeContent(bool isTablet, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : (isTablet ? 32 : 24)),
          decoration: BoxDecoration(
            color: const Color(0xFFCAF4E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF8CEADF), width: 2),
          ),
          child: Column(
            children: [
              Text(
                '🎹 Learn Piano',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18.0 : (isTablet ? 28 : 24),
                ),
              ),
              SizedBox(height: isSmallScreen ? 4.0 : 8.0),
              Text(
                '🎵 Interactive Lessons',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18.0 : (isTablet ? 28 : 24),
                ),
              ),
              SizedBox(height: isSmallScreen ? 4.0 : 8.0),
              Text(
                '🏆 Track Progress',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18.0 : (isTablet ? 28 : 24),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 12.0 : 24.0),
        Text(
          'Get ready for an amazing musical journey!',
          style: TextStyle(
            fontSize: isSmallScreen ? 14.0 : (isTablet ? 20 : 18),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNameContent(bool isTablet, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : (isTablet ? 32 : 24),
        vertical: isSmallScreen ? 16.0 : (isTablet ? 32 : 24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: TextField(
              controller: _nameController,
              autofocus: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.all(
                  isSmallScreen ? 12.0 : (isTablet ? 24 : 20),
                ),
              ),
              style: TextStyle(
                fontSize: isSmallScreen ? 14.0 : (isTablet ? 20 : 18),
              ),
              textAlign: TextAlign.center,
              onChanged: (value) {
                setState(() {
                  _name = value;
                });
              },
              onSubmitted: (value) {
                // Move to next slide when user presses done
                if (value.trim().isNotEmpty &&
                    _currentPage < _slides.length - 1) {
                  _goToNextPage();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeRangeContent(bool isTablet, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: AgeRange.values.map((range) {
        return SizedBox(
          width: isSmallScreen ? 150.0 : (isTablet ? 200 : 180),
          child: _buildOptionCard(
            title: _getAgeRangeDisplayName(range),
            subtitle: _getAgeRangeDescription(range),
            isSelected: _selectedAgeRange == range,
            onTap: () {
              setState(() {
                _selectedAgeRange = range;
              });
            },
            isTablet: isTablet,
            isSmallScreen: isSmallScreen,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkillLevelContent(bool isTablet, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: SkillLevel.values.map((level) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            bottom: isSmallScreen ? 4.0 : (isTablet ? 12 : 8),
          ),
          child: _buildOptionCard(
            title: _getSkillLevelDisplayName(level),
            subtitle: _getSkillLevelDescription(level),
            isSelected: _selectedSkillLevel == level,
            onTap: () {
              setState(() {
                _selectedSkillLevel = level;
              });
            },
            isTablet: isTablet,
            isSmallScreen: isSmallScreen,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExperienceContent(bool isTablet, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildOptionCard(
          title: 'Yes, I play instruments',
          subtitle: 'I have musical experience',
          isSelected: _hasExperience == true,
          onTap: () {
            setState(() {
              _hasExperience = true;
            });
          },
          isTablet: isTablet,
          isSmallScreen: isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 4.0 : (isTablet ? 8 : 6)),
        _buildOptionCard(
          title: 'No, I\'m new to music',
          subtitle: 'Piano will be my first instrument',
          isSelected: _hasExperience == false,
          onTap: () {
            setState(() {
              _hasExperience = false;
            });
          },
          isTablet: isTablet,
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildMusicReadingContent(bool isTablet, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: MusicReading.values.map((reading) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            bottom: isSmallScreen ? 4.0 : (isTablet ? 8 : 6),
          ),
          child: _buildOptionCard(
            title: _getMusicReadingDisplayName(reading),
            subtitle: _getMusicReadingDescription(reading),
            isSelected: _selectedMusicReading == reading,
            onTap: () {
              setState(() {
                _selectedMusicReading = reading;
              });
            },
            isTablet: isTablet,
            isSmallScreen: isSmallScreen,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalContent(bool isTablet, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: Goal.values.map((goal) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            bottom: isSmallScreen ? 4.0 : (isTablet ? 8 : 6),
          ),
          child: _buildOptionCard(
            title: _getGoalDisplayName(goal),
            subtitle: _getGoalDescription(goal),
            isSelected: _selectedGoal == goal,
            onTap: () {
              setState(() {
                _selectedGoal = goal;
              });
            },
            isTablet: isTablet,
            isSmallScreen: isSmallScreen,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPracticeStyleContent(bool isTablet, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: PracticeStyle.values.map((style) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            bottom: isSmallScreen ? 4.0 : (isTablet ? 8 : 6),
          ),
          child: _buildOptionCard(
            title: _getPracticeStyleDisplayName(style),
            subtitle: _getPracticeStyleDescription(style),
            isSelected: _selectedPracticeStyle == style,
            onTap: () {
              setState(() {
                _selectedPracticeStyle = style;
              });
            },
            isTablet: isTablet,
            isSmallScreen: isSmallScreen,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultyRampContent(bool isTablet, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: DifficultyRamp.values.map((ramp) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            bottom: isSmallScreen ? 4.0 : (isTablet ? 8 : 6),
          ),
          child: _buildOptionCard(
            title: _getDifficultyRampDisplayName(ramp),
            subtitle: _getDifficultyRampDescription(ramp),
            isSelected: _selectedDifficultyRamp == ramp,
            onTap: () {
              setState(() {
                _selectedDifficultyRamp = ramp;
              });
            },
            isTablet: isTablet,
            isSmallScreen: isSmallScreen,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLessonModeContent(bool isTablet, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: LessonMode.values.map((mode) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            bottom: isSmallScreen ? 4.0 : (isTablet ? 8 : 6),
          ),
          child: _buildOptionCard(
            title: _getLessonModeDisplayName(mode),
            subtitle: _getLessonModeDescription(mode),
            isSelected: _selectedLessonMode == mode,
            onTap: () {
              setState(() {
                _selectedLessonMode = mode;
              });
            },
            isTablet: isTablet,
            isSmallScreen: isSmallScreen,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfidenceContent(bool isTablet, bool isSmallScreen) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? 200.0 : (isTablet ? 400 : 300),
        ),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : (isTablet ? 20 : 16)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 8.0 : 12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_confidenceRating',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24.0 : (isTablet ? 40 : 32),
                  fontWeight: FontWeight.bold,
                  color: _slides[_currentPage].color,
                ),
              ),
              SizedBox(height: isSmallScreen ? 6.0 : (isTablet ? 12 : 8)),
              Slider(
                value: _confidenceRating.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: _slides[_currentPage].color,
                onChanged: (value) {
                  setState(() {
                    _confidenceRating = value.round();
                  });
                },
              ),
              SizedBox(height: isSmallScreen ? 4.0 : (isTablet ? 8 : 6)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Not confident',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: isSmallScreen ? 8.0 : (isTablet ? 12 : 10),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'Very confident',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: isSmallScreen ? 8.0 : (isTablet ? 12 : 10),
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isTablet,
    required bool isSmallScreen,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : (isTablet ? 16 : 14)),
        decoration: BoxDecoration(
          color: isSelected ? _slides[_currentPage].color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _slides[_currentPage].color
                : Colors.grey.shade300,
            width: isSmallScreen ? 1.0 : 2.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 12.0 : (isTablet ? 16 : 14),
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
              maxLines: isSmallScreen ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isSmallScreen ? 1.0 : 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isSmallScreen ? 10.0 : (isTablet ? 14 : 12),
                color: isSelected ? Colors.white70 : Colors.grey.shade600,
                height: 1.2,
              ),
              maxLines: isSmallScreen ? 2 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(bool isTablet, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : (isTablet ? 24 : 16),
        vertical: isSmallScreen ? 4.0 : (isTablet ? 12 : 8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: isSmallScreen ? 2.0 : 4.0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // Skip button (only on first slide)
              if (_currentPage == 0)
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12.0 : (isTablet ? 14 : 12),
                      ),
                    ),
                  ),
                ),

              if (_currentPage == 0)
                SizedBox(width: isSmallScreen ? 8.0 : (isTablet ? 16 : 12)),

              // Next/Continue button
              Expanded(
                flex: _currentPage == 0 ? 1 : 2,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_currentPage == _slides.length - 1) {
                            _createProfile();
                          } else {
                            _goToNextPage();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _slides[_currentPage].color,
                    foregroundColor: Colors.white,
                    elevation: isSmallScreen ? 1.0 : 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 8.0 : (isTablet ? 12 : 10),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: isSmallScreen ? 12.0 : (isTablet ? 20 : 16),
                          width: isSmallScreen ? 12.0 : (isTablet ? 20 : 16),
                          child: CircularProgressIndicator(
                            strokeWidth: isSmallScreen ? 1.0 : 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _currentPage == _slides.length - 1
                              ? 'Create Profile'
                              : 'Next',
                          style: TextStyle(
                            fontSize: isSmallScreen
                                ? 12.0
                                : (isTablet ? 16 : 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createProfile() async {
    if (_isLoading || _repository == null) return;

    setState(() => _isLoading = true);

    try {
      final profile = Profile(
        name: _name.trim(),
        ageRange: _selectedAgeRange,
        skillLevel: _selectedSkillLevel,
        experience: _hasExperience,
        musicReading: _selectedMusicReading,
        preferences: Preferences(
          goal: _selectedGoal,
          practiceStyle: _selectedPracticeStyle,
          difficultyRamp: _selectedDifficultyRamp,
          lessonMode: _selectedLessonMode,
        ),
        initialAssessment: InitialAssessment(
          confidenceRating: _confidenceRating,
          genrePreference: [], // Empty since we removed genre selection
        ),
        metadata: ProfileMetadata(
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          xp: 0,
          level: 1,
        ),
      );

      await _repository!.createProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to PianoQuest, $_name! 🎉'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onProfileCreated?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Close repository only after profile creation is done
      await _repository?.close();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper methods for display names and descriptions
  String _getAgeRangeDisplayName(AgeRange range) {
    switch (range) {
      case AgeRange.child:
        return 'Child (5-12)';
      case AgeRange.teen:
        return 'Teen (13-17)';
      case AgeRange.adult:
        return 'Adult (18+)';
    }
  }

  String _getAgeRangeDescription(AgeRange range) {
    switch (range) {
      case AgeRange.child:
        return 'Fun, game-based learning approach';
      case AgeRange.teen:
        return 'Engaging lessons with popular music';
      case AgeRange.adult:
        return 'Structured learning at your own pace';
    }
  }

  String _getSkillLevelDisplayName(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.intermediate:
        return 'Intermediate';
      case SkillLevel.advanced:
        return 'Advanced';
    }
  }

  String _getSkillLevelDescription(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return 'Never played piano before';
      case SkillLevel.intermediate:
        return 'Know some basics, ready to grow';
      case SkillLevel.advanced:
        return 'Experienced, want to master skills';
    }
  }

  String _getMusicReadingDisplayName(MusicReading reading) {
    switch (reading) {
      case MusicReading.none:
        return 'Cannot read music';
      case MusicReading.basic:
        return 'Basic music reading';
      case MusicReading.fluent:
        return 'Fluent music reader';
    }
  }

  String _getMusicReadingDescription(MusicReading reading) {
    switch (reading) {
      case MusicReading.none:
        return 'We\'ll teach you from scratch';
      case MusicReading.basic:
        return 'You know some notes and rhythms';
      case MusicReading.fluent:
        return 'You can read sheet music well';
    }
  }

  String _getGoalDisplayName(Goal goal) {
    switch (goal) {
      case Goal.fun:
        return 'Play for Fun';
      case Goal.technique:
        return 'Master Technique';
      case Goal.theory:
        return 'Learn Music Theory';
      case Goal.songs:
        return 'Play Favorite Songs';
    }
  }

  String _getGoalDescription(Goal goal) {
    switch (goal) {
      case Goal.fun:
        return 'Enjoy music and express creativity';
      case Goal.technique:
        return 'Build proper finger technique';
      case Goal.theory:
        return 'Understand how music works';
      case Goal.songs:
        return 'Learn to play songs you love';
    }
  }

  String _getPracticeStyleDisplayName(PracticeStyle style) {
    switch (style) {
      case PracticeStyle.short_frequent:
        return 'Short & Frequent';
      case PracticeStyle.long_focused:
        return 'Long & Focused';
    }
  }

  String _getPracticeStyleDescription(PracticeStyle style) {
    switch (style) {
      case PracticeStyle.short_frequent:
        return '10-15 minutes daily';
      case PracticeStyle.long_focused:
        return '30+ minutes per session';
    }
  }

  String _getDifficultyRampDisplayName(DifficultyRamp ramp) {
    switch (ramp) {
      case DifficultyRamp.gentle:
        return 'Gentle Progression';
      case DifficultyRamp.moderate:
        return 'Steady Progress';
      case DifficultyRamp.challenging:
        return 'Challenge Me!';
    }
  }

  String _getDifficultyRampDescription(DifficultyRamp ramp) {
    switch (ramp) {
      case DifficultyRamp.gentle:
        return 'Take it slow and steady';
      case DifficultyRamp.moderate:
        return 'Balanced learning pace';
      case DifficultyRamp.challenging:
        return 'Push me to improve faster';
    }
  }

  String _getLessonModeDisplayName(LessonMode mode) {
    switch (mode) {
      case LessonMode.game:
        return 'Game-like';
      case LessonMode.structured:
        return 'Structured';
      case LessonMode.free:
        return 'Free-form';
    }
  }

  String _getLessonModeDescription(LessonMode mode) {
    switch (mode) {
      case LessonMode.game:
        return 'Fun, interactive challenges';
      case LessonMode.structured:
        return 'Step-by-step guided lessons';
      case LessonMode.free:
        return 'Explore at your own pace';
    }
  }
}

class ProfileSlide {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ProfileSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
