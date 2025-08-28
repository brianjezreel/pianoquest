import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load user data from Firestore
  Future<void> loadUserData() async {
    try {
      _setLoading(true);
      _clearError();
      
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        _setLoading(false);
        return;
      }

      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        _currentUser = UserModel.fromFirestore(userDoc);
      } else {
        // Create new user document if it doesn't exist
        await _createUserDocument(firebaseUser);
      }
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load user data');
    }
  }

  // Create new user document in Firestore
  Future<void> _createUserDocument(User firebaseUser) async {
    final UserModel newUser = UserModel(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Piano Student',
      email: firebaseUser.email ?? '',
      level: 1,
      xp: 0,
      achievements: [],
      settings: {
        'sound': true,
        'difficulty': 'easy',
        'notifications': true,
      },
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(newUser.toFirestore());
    
    _currentUser = newUser;
  }

  // Update user XP and level
  Future<void> addXP(int xpToAdd) async {
    if (_currentUser == null) return;

    try {
      final int newXP = _currentUser!.xp + xpToAdd;
      final int newLevel = _calculateLevel(newXP);
      
      _currentUser = _currentUser!.copyWith(
        xp: newXP,
        level: newLevel,
        lastActive: DateTime.now(),
      );

      await _updateUserInFirestore();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update XP');
    }
  }

  // Add achievement to user
  Future<void> addAchievement(String achievementId) async {
    if (_currentUser == null) return;

    try {
      if (!_currentUser!.achievements.contains(achievementId)) {
        final List<String> newAchievements = [
          ..._currentUser!.achievements,
          achievementId,
        ];
        
        _currentUser = _currentUser!.copyWith(
          achievements: newAchievements,
          lastActive: DateTime.now(),
        );

        await _updateUserInFirestore();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to add achievement');
    }
  }

  // Update user settings
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    if (_currentUser == null) return;

    try {
      final Map<String, dynamic> updatedSettings = {
        ..._currentUser!.settings,
        ...newSettings,
      };
      
      _currentUser = _currentUser!.copyWith(
        settings: updatedSettings,
        lastActive: DateTime.now(),
      );

      await _updateUserInFirestore();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update settings');
    }
  }

  // Update user name
  Future<void> updateUserName(String newName) async {
    if (_currentUser == null) return;

    try {
      _currentUser = _currentUser!.copyWith(
        name: newName,
        lastActive: DateTime.now(),
      );

      await _updateUserInFirestore();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update name');
    }
  }

  // Update last active timestamp
  Future<void> updateLastActive() async {
    if (_currentUser == null) return;

    try {
      _currentUser = _currentUser!.copyWith(
        lastActive: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'lastActive': Timestamp.fromDate(_currentUser!.lastActive)});
    } catch (e) {
      // Silently fail for this operation
    }
  }

  // Update user document in Firestore
  Future<void> _updateUserInFirestore() async {
    if (_currentUser == null) return;
    
    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .update(_currentUser!.toFirestore());
  }

  // Calculate level based on XP
  int _calculateLevel(int xp) {
    // Simple level calculation: every 1000 XP = 1 level
    // You can adjust this formula as needed
    return (xp / 1000).floor() + 1;
  }

  // Calculate XP needed for next level
  int getXPForNextLevel() {
    if (_currentUser == null) return 1000;
    return _currentUser!.level * 1000;
  }

  // Calculate XP progress for current level
  double getLevelProgress() {
    if (_currentUser == null) return 0.0;
    
    final int currentLevelXP = (_currentUser!.level - 1) * 1000;
    final int nextLevelXP = _currentUser!.level * 1000;
    final int progressXP = _currentUser!.xp - currentLevelXP;
    
    return progressXP / (nextLevelXP - currentLevelXP);
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Clear user data on logout
  void clearUserData() {
    _currentUser = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
} 