import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/profiles/profile_selection_screen.dart';
import 'screens/lessons/enhanced_lessons_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/practice/song_selection_screen.dart';
import 'models/profile.dart';
import 'models/lesson_progress.dart';
import 'repositories/profiles_repository.dart';
import 'repositories/progress_repository.dart';
import 'services/pitch_detection_service.dart';
import 'widgets/immediate_note_detector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(AgeRangeAdapter());
  Hive.registerAdapter(SkillLevelAdapter());
  Hive.registerAdapter(MusicReadingAdapter());
  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(PracticeStyleAdapter());
  Hive.registerAdapter(DifficultyRampAdapter());
  Hive.registerAdapter(LessonModeAdapter());
  Hive.registerAdapter(PreferencesAdapter());
  Hive.registerAdapter(InitialAssessmentAdapter());
  Hive.registerAdapter(ProfileMetadataAdapter());
  Hive.registerAdapter(ProfileAdapter());
  Hive.registerAdapter(LessonProgressAdapter());

  // Force landscape orientation for piano app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const PianoQuestApp());
}

class PianoQuestApp extends StatefulWidget {
  const PianoQuestApp({super.key});

  @override
  State<PianoQuestApp> createState() => _PianoQuestAppState();
}

class _PianoQuestAppState extends State<PianoQuestApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached) {
      // App is being terminated, close shared boxes
      _closeSharedBoxes();
    }
  }

  Future<void> _closeSharedBoxes() async {
    try {
      await ProfilesRepository.closeSharedBox();
      await ProgressRepository.closeSharedBox();
    } catch (e) {
      // Ignore errors during app termination
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PianoQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          surfaceContainerHighest: Color(0xFFF5F5F5),
          onSurfaceVariant: Color(0xFF424242),
          primaryContainer: Color(0xFFF0F0F0),
          onPrimaryContainer: Colors.black,
        ),
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          // Modern, bold headings
          headlineLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          // Body text
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          // Labels
          labelLarge: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// Simplified Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToAppropriateScreen();
  }

  Future<void> _navigateToAppropriateScreen() async {
    // Simple delay for splash
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    try {
      final profilesRepository = ProfilesRepository();
      await profilesRepository.initialize();

      final hasProfiles = profilesRepository.hasProfiles();
      await profilesRepository.close();

      if (!mounted) return;

      if (hasProfiles) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ProfileSelectionScreen(
              onProfileSelected: (profile) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        MainDashboard(selectedProfile: profile),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(
              onProfileSelected: (profile) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        MainDashboard(selectedProfile: profile),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(
            onProfileSelected: (profile) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => MainDashboard(selectedProfile: profile),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFCAF4E9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7BE5FF).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset(
                  'assets/images/PQ LOGO.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'PianoQuest',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00838F),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Learn piano with AI-powered feedback',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ACC1)),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final String title;
  final IconData icon;
  final int index;

  NavigationItem(this.title, this.icon, this.index);
}

class MainDashboard extends StatefulWidget {
  final Profile? selectedProfile;

  const MainDashboard({super.key, this.selectedProfile});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Update profile last active time when MainDashboard loads
    _updateProfileLastActive();
  }

  Future<void> _updateProfileLastActive() async {
    if (widget.selectedProfile != null) {
      try {
        final repository = ProfilesRepository();
        await repository.initialize();
        await repository.updateProfile(widget.selectedProfile!);
        await repository.close();
      } catch (e) {
        debugPrint('Error updating profile last active: $e');
      }
    }
  }

  void navigateToIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _screens => [
    DashboardHome(profile: widget.selectedProfile),
    widget.selectedProfile != null
        ? EnhancedLessonsScreen(profile: widget.selectedProfile!)
        : const LessonsScreen(),
    const SongSelectionScreen(),
    const AchievementsScreen(),
    const ProgressScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  'assets/images/PQ LOGO.png',
                  fit: BoxFit.contain,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'PianoQuest',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          // Profile indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF7BE5FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                widget.selectedProfile?.name.isNotEmpty == true
                    ? widget.selectedProfile!.name[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildNavigationDrawer(),
      body: _screens[_selectedIndex],
    );
  }

  Widget _buildNavigationDrawer() {
    final List<NavigationItem> navigationItems = [
      NavigationItem('Dashboard', Icons.grid_view_rounded, 0),
      NavigationItem('Lessons', Icons.menu_book_rounded, 1),
      NavigationItem('Practice', Icons.piano, 2),
      NavigationItem('Achievements', Icons.emoji_events_rounded, 3),
      NavigationItem('Progress', Icons.trending_up_rounded, 4),
    ];

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/images/PQ LOGO.png',
                            fit: BoxFit.contain,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'PianoQuest',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (widget.selectedProfile != null) ...[
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      widget.selectedProfile!.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),

            // Navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: navigationItems
                    .map((item) => _buildDrawerItem(item))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(NavigationItem item) {
    bool isSelected = _selectedIndex == item.index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isSelected ? Colors.white : Colors.grey.shade600,
          size: 24,
        ),
        title: Text(
          item.title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
        selected: isSelected,
        selectedTileColor: const Color(0xFF7BE5FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          setState(() {
            _selectedIndex = item.index;
          });
          Navigator.pop(context); // Close drawer
        },
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  final Profile? profile;

  const DashboardHome({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome text
                Text(
                  'Welcome back!',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 28 : 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (profile != null)
                  Text(
                    profile!.name,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 36 : 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                SizedBox(height: isTablet ? 32 : 24),

                // Profile stats card
                if (profile != null) _buildStatsCard(isTablet),
                if (profile != null) SizedBox(height: isTablet ? 32 : 24),

                // Quick Actions title
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: isTablet ? 20 : 16),

                // Action cards grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isTablet ? 3 : 3,
                  crossAxisSpacing: isTablet ? 20 : 16,
                  mainAxisSpacing: isTablet ? 20 : 16,
                  childAspectRatio: isTablet ? 1.1 : 1.0,
                  children: [
                    _buildActionCard(
                      'Lessons',
                      Icons.menu_book_rounded,
                      'Continue learning',
                      const Color(0xFFCAF4E9),
                      context,
                      isTablet,
                      () => _navigateToScreen(context, 1),
                    ),
                    _buildActionCard(
                      'Practice',
                      Icons.piano,
                      'Start practicing',
                      const Color(0xFFAEEFE0),
                      context,
                      isTablet,
                      () => _navigateToScreen(context, 2),
                    ),
                    _buildActionCard(
                      'Achievements',
                      Icons.emoji_events_rounded,
                      'View rewards',
                      const Color(0xFF96EBD2),
                      context,
                      isTablet,
                      () => _navigateToScreen(context, 3),
                    ),
                  ],
                ),

                SizedBox(height: isTablet ? 32 : 24),

                // Recent activity or tips
                _buildTipsCard(isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFCAF4E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8CEADF), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Level',
            '${profile?.currentLevel ?? 1}',
            Icons.trending_up,
            isTablet,
          ),
          Container(width: 1, height: 40, color: const Color(0xFF8CEADF)),
          _buildStatItem(
            'XP',
            '${profile?.metadata.xp ?? 0}',
            Icons.stars,
            isTablet,
          ),
          Container(width: 1, height: 40, color: const Color(0xFF8CEADF)),
          _buildStatItem(
            'Next Level',
            '${profile?.xpForNextLevel ?? 1000}',
            Icons.flag,
            isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    bool isTablet,
  ) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00838F), size: isTablet ? 28 : 24),
        SizedBox(height: isTablet ? 8 : 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF00838F),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    String subtitle,
    Color backgroundColor,
    BuildContext context,
    bool isTablet,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8CEADF), width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isTablet ? 44 : 40,
                color: const Color(0xFF00838F),
              ),
              SizedBox(height: isTablet ? 12 : 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 6 : 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 13 : 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFAEEFE0), const Color(0xFFCAF4E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8CEADF), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Color(0xFF00838F),
              size: 28,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice Tip',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00838F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Regular practice is key! Try to practice at least 15 minutes daily to build consistency.',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    // Find the MainDashboard ancestor and update its selected index
    final mainDashboard = context
        .findAncestorStateOfType<_MainDashboardState>();
    if (mainDashboard != null) {
      mainDashboard.navigateToIndex(index);
    }
  }
}

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 400;
        final isTablet = screenWidth > 768;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset(
                  'assets/images/PQ LOGO.png',
                  height: isSmallScreen ? 20.0 : 24.0,
                  width: isSmallScreen ? 20.0 : 24.0,
                ),
                SizedBox(width: isSmallScreen ? 8.0 : 12.0),
                Text(
                  'Lessons',
                  style: TextStyle(fontSize: isSmallScreen ? 16.0 : 18.0),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  size: isSmallScreen ? 20.0 : 24.0,
                ),
                onPressed: () => _showSnackbar(context, 'Filter'),
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
            child: isSmallScreen
                ? _buildMobileLayout(
                    isSmallScreen,
                    context,
                  ) // Single column for small screens
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left sidebar - Lesson categories
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16.0 : 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                            Expanded(
                              child: ListView(
                                children: [
                                  _buildCategoryCard(
                                    'Basics',
                                    8,
                                    12,
                                    Icons.music_note,
                                    true,
                                    isSmallScreen,
                                  ),
                                  _buildCategoryCard(
                                    'Scales',
                                    5,
                                    10,
                                    Icons.trending_up,
                                    false,
                                    isSmallScreen,
                                  ),
                                  _buildCategoryCard(
                                    'Chords',
                                    3,
                                    15,
                                    Icons.piano,
                                    false,
                                    isSmallScreen,
                                  ),
                                  _buildCategoryCard(
                                    'Songs',
                                    2,
                                    20,
                                    Icons.audiotrack,
                                    false,
                                    isSmallScreen,
                                  ),
                                  _buildCategoryCard(
                                    'Advanced',
                                    0,
                                    8,
                                    Icons.star,
                                    false,
                                    isSmallScreen,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: isSmallScreen ? 12.0 : 24.0),

                      // Right side - Lesson details
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Basics Lessons',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18.0 : 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 8.0 : 12.0,
                                    vertical: isSmallScreen ? 4.0 : 6.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '8/12 Complete',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isSmallScreen ? 10.0 : 12.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 12.0 : 20.0),

                            // Lessons grid
                            Expanded(
                              child: GridView.count(
                                crossAxisCount: isTablet ? 3 : 2,
                                crossAxisSpacing: isSmallScreen ? 8.0 : 16.0,
                                mainAxisSpacing: isSmallScreen ? 8.0 : 16.0,
                                childAspectRatio: 1.4,
                                children: [
                                  _buildLessonCard(
                                    'Note Reading',
                                    'Learn to read musical notes',
                                    'Completed',
                                    true,
                                    Icons.visibility,
                                    context,
                                    isSmallScreen,
                                  ),
                                  _buildLessonCard(
                                    'Finger Position',
                                    'Proper hand positioning',
                                    'Completed',
                                    true,
                                    Icons.back_hand,
                                    context,
                                    isSmallScreen,
                                  ),
                                  _buildLessonCard(
                                    'Basic Rhythm',
                                    'Understanding beats and timing',
                                    'Completed',
                                    true,
                                    Icons.av_timer,
                                    context,
                                    isSmallScreen,
                                  ),
                                  _buildLessonCard(
                                    'C Major Scale',
                                    'Play your first scale',
                                    'In Progress',
                                    true,
                                    Icons.piano,
                                    context,
                                    isSmallScreen,
                                  ),
                                  _buildLessonCard(
                                    'Simple Melodies',
                                    'Play easy songs',
                                    'Locked',
                                    false,
                                    Icons.lock,
                                    context,
                                    isSmallScreen,
                                  ),
                                  _buildLessonCard(
                                    'Practice Exercises',
                                    'Daily finger exercises',
                                    'Locked',
                                    false,
                                    Icons.fitness_center,
                                    context,
                                    isSmallScreen,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(bool isSmallScreen, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories section
          Text(
            'Categories',
            style: TextStyle(
              fontSize: isSmallScreen ? 16.0 : 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12.0 : 16.0),
          SizedBox(
            height: 200, // Fixed height for horizontal scroll
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryCard(
                  'Basics',
                  8,
                  12,
                  Icons.music_note,
                  true,
                  isSmallScreen,
                ),
                SizedBox(width: 8),
                _buildCategoryCard(
                  'Scales',
                  5,
                  10,
                  Icons.trending_up,
                  false,
                  isSmallScreen,
                ),
                SizedBox(width: 8),
                _buildCategoryCard(
                  'Chords',
                  3,
                  15,
                  Icons.piano,
                  false,
                  isSmallScreen,
                ),
                SizedBox(width: 8),
                _buildCategoryCard(
                  'Songs',
                  2,
                  20,
                  Icons.audiotrack,
                  false,
                  isSmallScreen,
                ),
                SizedBox(width: 8),
                _buildCategoryCard(
                  'Advanced',
                  0,
                  8,
                  Icons.star,
                  false,
                  isSmallScreen,
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 20.0 : 24.0),

          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Basics Lessons',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18.0 : 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8.0 : 12.0,
                  vertical: isSmallScreen ? 4.0 : 6.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '8/12 Complete',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 10.0 : 12.0,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 12.0 : 20.0),

          // Lessons grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: isSmallScreen ? 8.0 : 16.0,
            mainAxisSpacing: isSmallScreen ? 8.0 : 16.0,
            childAspectRatio: 1.4,
            children: [
              _buildLessonCard(
                'Note Reading',
                'Learn to read musical notes',
                'Completed',
                true,
                Icons.visibility,
                context,
                isSmallScreen,
              ),
              _buildLessonCard(
                'Finger Position',
                'Proper hand positioning',
                'Completed',
                true,
                Icons.back_hand,
                context,
                isSmallScreen,
              ),
              _buildLessonCard(
                'Basic Rhythm',
                'Understanding beats and timing',
                'Completed',
                true,
                Icons.av_timer,
                context,
                isSmallScreen,
              ),
              _buildLessonCard(
                'C Major Scale',
                'Play your first scale',
                'In Progress',
                true,
                Icons.piano,
                context,
                isSmallScreen,
              ),
              _buildLessonCard(
                'Simple Melodies',
                'Play easy songs',
                'Locked',
                false,
                Icons.lock,
                context,
                isSmallScreen,
              ),
              _buildLessonCard(
                'Practice Exercises',
                'Daily finger exercises',
                'Locked',
                false,
                Icons.fitness_center,
                context,
                isSmallScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    int completed,
    int total,
    IconData icon,
    bool isSelected,
    bool isSmallScreen,
  ) {
    return Container(
      width: isSmallScreen
          ? 140.0
          : null, // Fixed width for mobile horizontal scroll
      margin: EdgeInsets.only(bottom: isSmallScreen ? 0 : 8.0),
      child: Card(
        color: isSelected ? const Color(0xFF7BE5FF) : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF00838F),
                size: isSmallScreen ? 16.0 : 20.0,
              ),
              SizedBox(width: isSmallScreen ? 8.0 : 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: isSmallScreen ? 12.0 : 14.0,
                      ),
                    ),
                    Text(
                      '$completed/$total lessons',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10.0 : 12.0,
                        color: isSelected ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: isSmallScreen ? 30.0 : 40.0,
                height: isSmallScreen ? 2.0 : 4.0,
                child: LinearProgressIndicator(
                  value: completed / total,
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

  Widget _buildLessonCard(
    String title,
    String description,
    String status,
    bool isUnlocked,
    IconData icon,
    BuildContext context,
    bool isSmallScreen,
  ) {
    Color statusColor;
    switch (status) {
      case 'Completed':
        statusColor = Colors.green;
        break;
      case 'In Progress':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      color: isUnlocked ? Colors.white : Colors.grey.shade100,
      child: InkWell(
        onTap: isUnlocked ? () => _showSnackbar(context, title) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    color: isUnlocked ? Colors.black : Colors.grey,
                    size: isSmallScreen ? 20.0 : 24.0,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6.0 : 8.0,
                      vertical: isSmallScreen ? 2.0 : 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 8.0 : 10.0,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 8.0 : 12.0),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 12.0 : 14.0,
                  color: isUnlocked ? Colors.black : Colors.grey,
                ),
              ),
              SizedBox(height: isSmallScreen ? 2.0 : 4.0),
              Text(
                description,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10.0 : 12.0,
                  color: isUnlocked ? Colors.grey.shade700 : Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message feature coming soon! 🚀'),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.black),
            SizedBox(height: 16),
            Text(
              'Achievements Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Coming Soon!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.black),
            SizedBox(height: 16),
            Text(
              'Progress Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Coming Soon!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class ImmediatePracticeScreen extends StatelessWidget {
  final PitchDetectionService pitchDetectionService;

  const ImmediatePracticeScreen({
    super.key,
    required this.pitchDetectionService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: ImmediateNoteDetector(
                  pitchDetectionService: pitchDetectionService,
                  onNoteDetected: (note) {
                    debugPrint('Note detected in UI: ${note.noteWithOctave}');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
