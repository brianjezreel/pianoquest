import 'package:hive/hive.dart';
import '../models/profile.dart';

class ProfilesRepository {
  static const String _boxName = 'profiles';
  static Box<Profile>? _sharedBox;
  late Box<Profile> _profilesBox;

  // Initialize the repository
  Future<void> initialize() async {
    // Use shared box if already open, otherwise open it
    if (_sharedBox == null || !_sharedBox!.isOpen) {
      _sharedBox = await Hive.openBox<Profile>(_boxName);
    }
    _profilesBox = _sharedBox!;
  }

  // Create a new profile
  Future<Profile> createProfile(Profile profile) async {
    // Generate a new ID (use the length as the next ID)
    final newId = _profilesBox.length;
    
    final profileWithId = profile.copyWith(
      profileId: newId,
      metadata: profile.metadata.copyWith(
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
    );
    
    await _profilesBox.put(newId, profileWithId);
    return profileWithId;
  }

  // Get all profiles
  List<Profile> getAllProfiles() {
    return _profilesBox.values.toList();
  }

  // Get a profile by ID
  Profile? getProfileById(int profileId) {
    return _profilesBox.get(profileId);
  }

  // Update a profile
  Future<void> updateProfile(Profile profile) async {
    if (profile.profileId != null) {
      final updatedProfile = profile.copyWith(
        metadata: profile.metadata.copyWith(
          lastActive: DateTime.now(),
        ),
      );
      await _profilesBox.put(profile.profileId!, updatedProfile);
    }
  }

  // Delete a profile
  Future<void> deleteProfile(int profileId) async {
    await _profilesBox.delete(profileId);
  }

  // Update profile XP and level
  Future<void> addXP(int profileId, int xpToAdd) async {
    final profile = getProfileById(profileId);
    if (profile != null) {
      final newXP = profile.metadata.xp + xpToAdd;
      final newLevel = (newXP / 1000).floor() + 1;
      
      final updatedProfile = profile.copyWith(
        metadata: profile.metadata.copyWith(
          xp: newXP,
          level: newLevel,
          lastActive: DateTime.now(),
        ),
      );
      
      await updateProfile(updatedProfile);
    }
  }

  // Get the most recently active profile
  Profile? getMostRecentProfile() {
    final profiles = getAllProfiles();
    if (profiles.isEmpty) return null;
    
    profiles.sort((a, b) => b.metadata.lastActive.compareTo(a.metadata.lastActive));
    return profiles.first;
  }

  // Check if any profiles exist
  bool hasProfiles() {
    return _profilesBox.isNotEmpty;
  }

  // Close the repository
  Future<void> close() async {
    // Don't close the shared box - it will be closed when the app terminates
    // This prevents "box already closed" errors when multiple repositories exist
  }

  // Close the shared box - call this when app terminates
  static Future<void> closeSharedBox() async {
    if (_sharedBox != null && _sharedBox!.isOpen) {
      await _sharedBox!.close();
      _sharedBox = null;
    }
  }
} 