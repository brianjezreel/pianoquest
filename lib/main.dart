import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'dart:async'; // Added for Timer

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force landscape orientation for piano app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const PianoQuestApp());
}

class PianoQuestApp extends StatelessWidget {
  const PianoQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'PianoQuest',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: Colors.black,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
            surfaceVariant: Color(0xFFF5F5F5),
            onSurfaceVariant: Color(0xFF424242),
            primaryContainer: Color(0xFFF0F0F0),
            onPrimaryContainer: Colors.black,
          ),
          textTheme: GoogleFonts.interTextTheme(),
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
            shadowColor: Colors.black.withOpacity(0.1),
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
        home: const SplashScreen(), // Start with splash screen
      ),
    );
  }
}

// Splash Screen with Animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start scale animation first
    _scaleController.forward();
    
    // Start fade animation slightly delayed
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    // Navigate to main dashboard after animations complete
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainDashboard(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            AnimatedBuilder(
              animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
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
                  ),
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // Animated app name
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: const Column(
                    children: [
                      Text(
                        'PianoQuest',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Learn piano with AI-powered feedback',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 50),
            
            // Loading indicator
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const LessonsScreen(),
    const PracticeScreen(),
    const AchievementsScreen(),
    const ProgressScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Clean white navigation rail
          Container(
            width: 120,
            color: const Color(0xFFFAFAFA),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo at top
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/images/PQ LOGO.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Navigation buttons
                Expanded(
                  child: ListView(
                    children: [
                      _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                      _buildNavItem(1, Icons.school, 'Lessons'),
                      _buildNavItem(2, Icons.piano, 'Practice'),
                      _buildNavItem(3, Icons.emoji_events, 'Awards'),
                      _buildNavItem(4, Icons.trending_up, 'Progress'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/PQ LOGO.png',
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 12),
            const Text('PianoQuest Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSnackbar(context, 'Settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left panel - User profile
            Expanded(
              flex: 1,
              child: SingleChildScrollView( // Allow scrolling if needed
                child: Column(
                  children: [
                    // User profile card - more compact
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0), // Reduced from 24
                        child: Column(
                          children: [
                            // Profile picture with logo - smaller
                            Container(
                              width: 60, // Reduced from 80
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  'assets/images/PQ LOGO.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12), // Reduced spacing
                            
                            Text(
                              'Welcome back!',
                              style: TextStyle(
                                fontSize: 12, // Smaller font
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            
                            const Text(
                              'Piano Student',
                              style: TextStyle(
                                fontSize: 16, // Reduced from 20
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Level badge - smaller
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Level 3 • 2450 XP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12, // Smaller font
                                ),
                              ),
                            ),
                            const SizedBox(height: 12), // Reduced spacing
                            
                            // Progress section - more compact
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Next Level',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12, // Smaller font
                                      ),
                                    ),
                                    Text(
                                      '550 XP to go',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12, // Smaller font
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: 0.45,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                                  minHeight: 4, // Thinner progress bar
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12), // Reduced spacing
                    
                    // Stats card - more compact
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0), // Further reduced
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Stats',
                              style: TextStyle(
                                fontSize: 14, // Smaller title
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildStatRow('Achievements', '5', Icons.emoji_events),
                            _buildStatRow('Lessons', '12', Icons.school),
                            _buildStatRow('Sessions', '28', Icons.piano),
                            _buildStatRow('Total XP', '2450', Icons.flash_on),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 24),
            
            // Right panel - Quick actions
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0, // Made square to prevent overflow
                      children: [
                        _buildActionCard('Start Lesson', Icons.play_circle, context),
                        _buildActionCard('Free Practice', Icons.piano, context),
                        _buildActionCard('View Progress', Icons.trending_up, context),
                        _buildActionCard('Achievements', Icons.emoji_events, context),
                        _buildActionCard('Settings', Icons.settings, context),
                        _buildActionCard('Help', Icons.help_outline, context),
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
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0), // Further reduced spacing
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.black), // Smaller icon
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))), // Smaller font
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _showSnackbar(context, title),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.black, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackbar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon! 🚀'),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/PQ LOGO.png',
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 12),
            const Text('Lessons'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showSnackbar(context, 'Filter'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left sidebar - Lesson categories
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildCategoryCard('Basics', 8, 12, Icons.music_note, true),
                        _buildCategoryCard('Scales', 5, 10, Icons.trending_up, false),
                        _buildCategoryCard('Chords', 3, 15, Icons.piano, false),
                        _buildCategoryCard('Songs', 2, 20, Icons.audiotrack, false),
                        _buildCategoryCard('Advanced', 0, 8, Icons.star, false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 24),
            
            // Right side - Lesson details
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Basics Lessons',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '8/12 Complete',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Lessons grid
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.4,
                      children: [
                        _buildLessonCard(
                          'Note Reading',
                          'Learn to read musical notes',
                          'Completed',
                          true,
                          Icons.visibility,
                          context,
                        ),
                        _buildLessonCard(
                          'Finger Position',
                          'Proper hand positioning',
                          'Completed',
                          true,
                          Icons.back_hand,
                          context,
                        ),
                        _buildLessonCard(
                          'Basic Rhythm',
                          'Understanding beats and timing',
                          'Completed',
                          true,
                          Icons.av_timer,
                          context,
                        ),
                        _buildLessonCard(
                          'C Major Scale',
                          'Play your first scale',
                          'In Progress',
                          true,
                          Icons.piano,
                          context,
                        ),
                        _buildLessonCard(
                          'Simple Melodies',
                          'Play easy songs',
                          'Locked',
                          false,
                          Icons.lock,
                          context,
                        ),
                        _buildLessonCard(
                          'Practice Exercises',
                          'Daily finger exercises',
                          'Locked',
                          false,
                          Icons.fitness_center,
                          context,
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
  }

  Widget _buildCategoryCard(String title, int completed, int total, IconData icon, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: isSelected ? Colors.black : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$completed/$total lessons',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: completed / total,
                backgroundColor: isSelected ? Colors.white30 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isSelected ? Colors.white : Colors.black,
                ),
                minHeight: 2,
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    color: isUnlocked ? Colors.black : Colors.grey,
                    size: 24,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
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
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isUnlocked ? Colors.black : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
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

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  bool _isListening = false;
  String _detectedNote = 'C';
  int _detectedOctave = 4;
  double _confidence = 0.0;
  List<String> _recentNotes = [];

  // Mock data for demonstration
  final List<String> _notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  int _currentNoteIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        _mockDetectNote();
      });
    } else {
      _timer?.cancel();
    }
  }

  void _mockDetectNote() {
    if (!mounted) return;
    
    setState(() {
      _detectedNote = _notes[_currentNoteIndex];
      _detectedOctave = 4 + (_currentNoteIndex % 3);
      _confidence = 80 + (_currentNoteIndex % 20);
      
      String noteWithOctave = '$_detectedNote$_detectedOctave';
      _recentNotes.insert(0, noteWithOctave);
      if (_recentNotes.length > 10) {
        _recentNotes.removeAt(_recentNotes.length - 1);
      }
      
      _currentNoteIndex = (_currentNoteIndex + 1) % _notes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/PQ LOGO.png', height: 24, width: 24),
            const SizedBox(width: 12),
            const Text('Practice Mode'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top section - Controls and Detection
            Container(
              height: 200,
              child: Row(
                children: [
                  // Left panel - Controls
                  Expanded(
                    flex: 1,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isListening ? Icons.mic : Icons.mic_off,
                              size: 48,
                              color: _isListening ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isListening ? 'Listening...' : 'Ready to Listen',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _toggleListening,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isListening ? Colors.red : Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(120, 40),
                              ),
                              child: Text(_isListening ? 'Stop' : 'Start'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right panel - Detection Display
                  Expanded(
                    flex: 1,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Detected Note',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$_detectedNote$_detectedOctave',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Confidence: ${_confidence.toInt()}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Bottom section - Recent Notes and Piano
            Expanded(
              child: Row(
                children: [
                  // Recent Notes
                  Expanded(
                    flex: 1,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recent Notes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _recentNotes.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No notes detected yet.\nStart practicing!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _recentNotes.length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 4),
                                      itemBuilder: (context, index) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _recentNotes[index],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Virtual Piano
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Virtual Piano',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    // White keys
                                    Row(
                                      children: List.generate(7, (index) {
                                        List<String> whiteKeys = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
                                        bool isPressed = _detectedNote == whiteKeys[index];
                                        return Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 1),
                                            decoration: BoxDecoration(
                                              color: isPressed ? Colors.blue.shade200 : Colors.white,
                                              border: Border.all(color: Colors.black, width: 1),
                                              borderRadius: const BorderRadius.only(
                                                bottomLeft: Radius.circular(4),
                                                bottomRight: Radius.circular(4),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                whiteKeys[index],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isPressed ? Colors.blue.shade800 : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                    // Black keys
                                    ...List.generate(5, (index) {
                                      List<String> blackKeys = ['C#', 'D#', 'F#', 'G#', 'A#'];
                                      List<double> positions = [0.7, 1.7, 3.7, 4.7, 5.7];
                                      bool isPressed = _detectedNote == blackKeys[index];
                                      
                                      return Positioned(
                                        left: positions[index] * (MediaQuery.of(context).size.width * 0.3) / 7,
                                        top: 0,
                                        child: Container(
                                          width: 30,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: isPressed ? Colors.blue.shade400 : Colors.black,
                                            borderRadius: const BorderRadius.only(
                                              bottomLeft: Radius.circular(4),
                                              bottomRight: Radius.circular(4),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              blackKeys[index],
                                              style: TextStyle(
                                                color: isPressed ? Colors.white : Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            Text('Achievements Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
            Text('Progress Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Coming Soon!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
