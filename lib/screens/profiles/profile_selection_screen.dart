import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/profile.dart';
import '../../repositories/profiles_repository.dart';
import '../../repositories/progress_repository.dart';
import 'profile_creation_screen.dart';

class ProfileSelectionScreen extends StatefulWidget {
  final Function(Profile) onProfileSelected;

  const ProfileSelectionScreen({super.key, required this.onProfileSelected});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  late ProfilesRepository _profilesRepository;
  late ProgressRepository _progressRepository;
  List<Profile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadProfiles();
  }

  Future<void> _initializeAndLoadProfiles() async {
    try {
      _profilesRepository = ProfilesRepository();
      _progressRepository = ProgressRepository();

      await _profilesRepository.initialize();
      await _progressRepository.initialize();

      _loadProfiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profiles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadProfiles() {
    setState(() {
      _profiles = _profilesRepository.getAllProfiles();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 400;
        final isTablet = screenWidth > 768;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              'Select Profile',
              style: TextStyle(fontSize: isSmallScreen ? 16.0 : 20.0),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _navigateToCreateProfile,
                tooltip: 'Create New Profile',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _profiles.isEmpty
              ? _buildEmptyState(isSmallScreen)
              : _buildProfilesList(isSmallScreen, isTablet),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isSmallScreen ? 80.0 : 120.0,
              height: isSmallScreen ? 80.0 : 120.0,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add,
                size: isSmallScreen ? 40.0 : 60.0,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: isSmallScreen ? 16.0 : 24.0),
            Text(
              'No Profiles Yet',
              style: TextStyle(
                fontSize: isSmallScreen ? 20.0 : 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isSmallScreen ? 4.0 : 8.0),
            Text(
              'Create your first profile to start your piano learning journey!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 12.0 : 16.0,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: isSmallScreen ? 24.0 : 32.0),
            SizedBox(
              width: double.infinity,
              height: isSmallScreen ? 40.0 : 48.0,
              child: FilledButton.icon(
                onPressed: _navigateToCreateProfile,
                icon: Icon(Icons.add, size: isSmallScreen ? 16.0 : 24.0),
                label: Text(
                  'Create Profile',
                  style: TextStyle(fontSize: isSmallScreen ? 14.0 : 16.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesList(bool isSmallScreen, bool isTablet) {
    final crossAxisCount = isSmallScreen ? 1 : (isTablet ? 3 : 2);
    final crossAxisSpacing = isSmallScreen ? 8.0 : 16.0;
    final mainAxisSpacing = isSmallScreen ? 8.0 : 16.0;
    final childAspectRatio = isSmallScreen ? 0.9 : (isTablet ? 0.9 : 0.85);

    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Profile',
            style: TextStyle(
              fontSize: isSmallScreen ? 20.0 : 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4.0 : 8.0),
          Text(
            'Select a profile to continue your piano journey',
            style: TextStyle(
              fontSize: isSmallScreen ? 12.0 : 16.0,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12.0 : 24.0),
          Expanded(
            child: LayoutBuilder(
              builder: (context, gridConstraints) {
                // Ensure minimum card size with better responsive calculation
                final minCardWidth = isSmallScreen ? 140.0 : 180.0;
                final availableWidth =
                    gridConstraints.maxWidth -
                    (crossAxisSpacing * (crossAxisCount - 1));
                final cardWidth = availableWidth / crossAxisCount;

                // Adjust cross axis count if cards would be too small
                final adjustedCrossAxisCount = cardWidth < minCardWidth
                    ? 1
                    : crossAxisCount;
                final adjustedAspectRatio = isSmallScreen
                    ? 0.9
                    : childAspectRatio;

                return GridView.builder(
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 8.0 : 16.0,
                    horizontal: isSmallScreen ? 4.0 : 8.0,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: adjustedCrossAxisCount,
                    crossAxisSpacing: crossAxisSpacing,
                    mainAxisSpacing: mainAxisSpacing,
                    childAspectRatio: adjustedAspectRatio,
                  ),
                  itemCount: _profiles.length + 1, // +1 for the "Add New" card
                  itemBuilder: (context, index) {
                    if (index == _profiles.length) {
                      return _buildAddNewProfileCard(isSmallScreen);
                    }

                    return _buildProfileCard(_profiles[index], isSmallScreen);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Profile profile, bool isSmallScreen) {
    final progressStats = _progressRepository.getProgressStats(
      profile.profileId!,
    );
    final completedLessons = progressStats['totalLessonsCompleted'] as int;
    final lastActivity = progressStats['lastActivity'] as DateTime?;

    return Card(
      elevation: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Main tap area
            InkWell(
              onTap: () => _selectProfile(profile),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: isSmallScreen ? 40.0 : 50.0,
                          height: isSmallScreen ? 40.0 : 50.0,
                          decoration: BoxDecoration(
                            color: _getAvatarColor(profile.profileId!),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              profile.name.isNotEmpty
                                  ? profile.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 16.0 : 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8.0 : 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14.0 : 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _getSkillLevelDisplayName(profile.skillLevel),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10.0 : 12.0,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 4.0 : 8.0),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 8.0 : 16.0),

                    // Stats
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Level ${profile.currentLevel}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 12.0 : 14.0,
                                ),
                              ),
                              Text(
                                '${profile.metadata.xp} XP',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10.0 : 12.0,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 4.0 : 8.0),
                          LinearProgressIndicator(
                            value: (profile.metadata.xp % 1000) / 1000,
                            backgroundColor: const Color(0xFFCAF4E9),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF7BE5FF),
                            ),
                            minHeight: isSmallScreen ? 3.0 : 4.0,
                          ),
                          SizedBox(height: isSmallScreen ? 4.0 : 8.0),
                          Row(
                            children: [
                              Icon(
                                Icons.school,
                                size: isSmallScreen ? 12.0 : 14.0,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: isSmallScreen ? 2.0 : 4.0),
                              Text(
                                '$completedLessons lessons',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10.0 : 12.0,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6.0 : 12.0),

                    // Last Activity
                    if (lastActivity != null)
                      Text(
                        'Last active: ${_formatLastActivity(lastActivity)}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8.0 : 11.0,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Positioned menu button
            Positioned(
              top: isSmallScreen ? 4.0 : 8.0,
              right: isSmallScreen ? 4.0 : 8.0,
              child: PopupMenuButton<String>(
                onSelected: (value) => _handleProfileAction(value, profile),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: isSmallScreen ? 12.0 : 16.0),
                        SizedBox(width: isSmallScreen ? 4.0 : 8.0),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10.0 : 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: isSmallScreen ? 12.0 : 16.0,
                          color: Colors.red,
                        ),
                        SizedBox(width: isSmallScreen ? 4.0 : 8.0),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: isSmallScreen ? 10.0 : 12.0,
                          ),
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

  Widget _buildAddNewProfileCard(bool isSmallScreen) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _navigateToCreateProfile,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFCAF4E9),
            border: Border.all(
              color: const Color(0xFF8CEADF),
              style: BorderStyle.solid,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isSmallScreen ? 40.0 : 60.0,
                height: isSmallScreen ? 40.0 : 60.0,
                decoration: const BoxDecoration(
                  color: Color(0xFFAEEFE0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  size: isSmallScreen ? 24.0 : 32.0,
                  color: const Color(0xFF7BE5FF),
                ),
              ),
              SizedBox(height: isSmallScreen ? 8.0 : 16.0),
              Text(
                'Create New Profile',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12.0 : 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 2.0 : 4.0),
              Text(
                'Start a new learning journey',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10.0 : 12.0,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectProfile(Profile profile) {
    debugPrint(
      '_selectProfile called with: ${profile.name} (ID: ${profile.profileId})',
    );

    // Check if still mounted before proceeding

    if (!mounted) return;

    // Store the callback locally to avoid accessing widget after disposal

    final callback = widget.onProfileSelected;

    // Use Future.microtask to defer the callback to avoid gesture conflicts

    Future.microtask(() {
      // Double-check mounted state before calling navigation

      if (mounted) {
        try {
          callback(profile);
        } catch (e) {
          debugPrint('Error in profile selection callback: $e');
        }
      }
    });
  }

  void _navigateToCreateProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileCreationScreen(
          onProfileCreated: () {
            _loadProfiles(); // Refresh the list
          },
        ),
      ),
    );
  }

  void _handleProfileAction(String action, Profile profile) {
    switch (action) {
      case 'edit':
        _editProfile(profile);
        break;
      case 'delete':
        _confirmDeleteProfile(profile);
        break;
    }
  }

  void _editProfile(Profile profile) {
    // TODO: Implement profile editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile editing coming soon! 🚀'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _confirmDeleteProfile(Profile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
          'Are you sure you want to delete "${profile.name}"? This action cannot be undone and will delete all progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProfile(profile);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProfile(Profile profile) async {
    try {
      await _profilesRepository.deleteProfile(profile.profileId!);
      await _progressRepository.deleteProfileProgress(profile.profileId!);

      _loadProfiles(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile "${profile.name}" deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  String _formatLastActivity(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _profilesRepository.close();
    _progressRepository.close();
    super.dispose();
  }
}
