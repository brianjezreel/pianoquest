import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profiles/profile_selection_screen.dart';
import '../models/profile.dart';

class WelcomeScreen extends StatefulWidget {
  final Function(Profile) onProfileSelected;

  const WelcomeScreen({super.key, required this.onProfileSelected});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _startAnimations();
  }

  void _startAnimations() async {
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
        final maxWidth = isTablet ? 800.0 : double.infinity;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFCAF4E9)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    minHeight: screenHeight * 0.8,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      isSmallScreen ? 12.0 : (isTablet ? 48.0 : 24.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo and title section
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _fadeAnimation,
                            _slideAnimation,
                          ]),
                          builder: (context, child) {
                            return SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildHeader(isTablet, isSmallScreen),
                              ),
                            );
                          },
                        ),

                        SizedBox(
                          height: isSmallScreen ? 20.0 : (isTablet ? 60 : 40),
                        ),

                        // Features section
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildFeatures(isTablet, isSmallScreen),
                            );
                          },
                        ),

                        SizedBox(
                          height: isSmallScreen ? 20.0 : (isTablet ? 60 : 40),
                        ),

                        // Action buttons
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildActionButtons(
                                isTablet,
                                isSmallScreen,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isTablet, bool isSmallScreen) {
    return Column(
      children: [
        // Logo container
        Container(
          width: isSmallScreen ? 60.0 : (isTablet ? 160 : 120),

          height: isSmallScreen ? 60.0 : (isTablet ? 160 : 120),
          decoration: BoxDecoration(
            color: const Color(0xFFCAF4E9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF8CEADF), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7BE5FF).withValues(alpha: 0.3),
                blurRadius: isSmallScreen ? 10.0 : 20.0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(
              isSmallScreen ? 12.0 : (isTablet ? 24.0 : 20.0),
            ),
            child: Image.asset(
              'assets/images/PQ LOGO.png',
              fit: BoxFit.contain,
            ),
          ),
        ),

        SizedBox(height: isSmallScreen ? 16.0 : (isTablet ? 32 : 24)),

        // App name
        Text(
          'PianoQuest',

          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 20.0 : (isTablet ? 48 : 36),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF00838F),
            letterSpacing: -1.0,
          ),
        ),

        SizedBox(height: isSmallScreen ? 8.0 : (isTablet ? 16 : 12)),

        // Tagline
        Text(
          'Your AI-Powered Piano Learning Journey',

          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 10.0 : (isTablet ? 20 : 16),
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatures(bool isTablet, bool isSmallScreen) {
    final features = [
      _FeatureItem(
        icon: Icons.school,
        title: 'Interactive Lessons',
        description: 'Step-by-step lessons tailored to your skill level',
        color: const Color(0xFF7BE5FF),
      ),
      _FeatureItem(
        icon: Icons.person,
        title: 'Personalized Learning',
        description: 'AI adapts to your learning style and pace',
        color: const Color(0xFF96EBD2),
      ),
      _FeatureItem(
        icon: Icons.trending_up,
        title: 'Track Progress',
        description: 'See your improvement with detailed analytics',
        color: const Color(0xFFAEEFE0),
      ),
      _FeatureItem(
        icon: Icons.piano,
        title: 'Real-time Feedback',
        description: 'Instant feedback on your piano playing',
        color: const Color(0xFF8CEADF),
      ),
    ];

    if (isTablet) {
      // Grid layout for tablets
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.2,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          return _buildFeatureCard(features[index], isTablet, isSmallScreen);
        },
      );
    } else {
      // Column layout for phones
      return Column(
        children: features
            .map(
              (feature) => Container(
                margin: EdgeInsets.only(bottom: isSmallScreen ? 8.0 : 16.0),
                child: _buildFeatureCard(feature, isTablet, isSmallScreen),
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildFeatureCard(
    _FeatureItem feature,
    bool isTablet,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : (isTablet ? 24 : 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8CEADF), width: 2),
        boxShadow: [
          BoxShadow(
            color: feature.color.withValues(alpha: 0.1),
            blurRadius: isSmallScreen ? 5.0 : 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isSmallScreen ? 32.0 : (isTablet ? 64 : 56),

            height: isSmallScreen ? 32.0 : (isTablet ? 64 : 56),
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              feature.icon,

              color: feature.color,

              size: isSmallScreen ? 16.0 : (isTablet ? 32 : 28),
            ),
          ),
          SizedBox(height: isSmallScreen ? 8.0 : (isTablet ? 16 : 12)),
          Text(
            feature.title,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 14.0 : (isTablet ? 18 : 16),
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 4.0 : (isTablet ? 8 : 6)),
          Text(
            feature.description,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 10.0 : (isTablet ? 14 : 12),
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isTablet, bool isSmallScreen) {
    return Column(
      children: [
        // Get Started button
        SizedBox(
          width: double.infinity,
          height: isSmallScreen ? 40.0 : (isTablet ? 64 : 56),
          child: FilledButton.icon(
            onPressed: _navigateToProfileSelection,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7BE5FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12.0 : 24.0,
              ),
            ),
            icon: Icon(
              Icons.rocket_launch,
              size: isSmallScreen ? 16.0 : (isTablet ? 24 : 20),
            ),
            label: Text(
              'Get Started',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14.0 : (isTablet ? 20 : 18),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        SizedBox(height: isSmallScreen ? 8.0 : (isTablet ? 16 : 12)),

        // Learn More button
        SizedBox(
          width: double.infinity,
          height: isSmallScreen ? 40.0 : (isTablet ? 64 : 56),
          child: OutlinedButton.icon(
            onPressed: _showAboutDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF8CEADF), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12.0 : 24.0,
              ),
            ),
            icon: Icon(
              Icons.info_outline,
              size: isSmallScreen ? 16.0 : (isTablet ? 24 : 20),
              color: const Color(0xFF00838F),
            ),
            label: Text(
              'Learn More',
              style: TextStyle(
                fontSize: isSmallScreen ? 14.0 : (isTablet ? 20 : 18),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00838F),
              ),
            ),
          ),
        ),

        SizedBox(height: isSmallScreen ? 16.0 : (isTablet ? 32 : 24)),

        // Version info
        Text(
          'Version 1.0.0 • Made with ❤️ for piano learners',
          style: TextStyle(
            fontSize: isSmallScreen ? 8.0 : (isTablet ? 12 : 10),
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _navigateToProfileSelection() {
    if (!mounted) return;

    final callback = widget.onProfileSelected;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProfileSelectionScreen(onProfileSelected: callback),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.piano, color: Color(0xFF00838F)),
            SizedBox(width: 8),
            Text('About PianoQuest'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PianoQuest is an innovative piano learning app that combines:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text('🎵 AI-powered pitch detection'),
              SizedBox(height: 6),
              Text('📚 Personalized lesson plans'),
              SizedBox(height: 6),
              Text('🎯 Adaptive difficulty progression'),
              SizedBox(height: 6),
              Text('📊 Comprehensive progress tracking'),
              SizedBox(height: 6),
              Text('🎮 Gamified learning experience'),
              SizedBox(height: 16),
              Text(
                'Perfect for beginners and intermediate players who want to learn piano in a fun, interactive way!',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
