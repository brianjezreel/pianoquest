import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final int level;
  final int xp;
  final List<String> achievements;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime lastActive;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.level,
    required this.xp,
    required this.achievements,
    required this.settings,
    required this.createdAt,
    required this.lastActive,
  });

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      level: data['level'] ?? 1,
      xp: data['xp'] ?? 0,
      achievements: List<String>.from(data['achievements'] ?? []),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'level': level,
      'xp': xp,
      'achievements': achievements,
      'settings': settings,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  // Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    int? level,
    int? xp,
    List<String>? achievements,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      achievements: achievements ?? this.achievements,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  // Calculate XP progress for current level (0.0 to 1.0)
  double getLevelProgress() {
    final int currentLevelXP = (level - 1) * 1000;
    final int nextLevelXP = level * 1000;
    final int progressXP = xp - currentLevelXP;
    
    return progressXP / (nextLevelXP - currentLevelXP);
  }

  // Get XP needed for next level
  int getXPForNextLevel() {
    return level * 1000;
  }

  // Get XP progress in current level
  int getCurrentLevelXP() {
    final int currentLevelXP = (level - 1) * 1000;
    return xp - currentLevelXP;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, level: $level, xp: $xp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is UserModel &&
        other.uid == uid &&
        other.name == name &&
        other.email == email &&
        other.level == level &&
        other.xp == xp;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        name.hashCode ^
        email.hashCode ^
        level.hashCode ^
        xp.hashCode;
  }
} 