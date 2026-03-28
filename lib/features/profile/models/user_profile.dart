import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String nickname;
  final int age;
  final String city;
  final List<String> interests;
  final String? avatarUrl;
  final bool isProfileComplete;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime lastSeen;

  const UserProfile({
    required this.uid,
    required this.nickname,
    required this.age,
    required this.city,
    required this.interests,
    this.avatarUrl,
    required this.isProfileComplete,
    required this.isVisible,
    required this.createdAt,
    required this.lastSeen,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: data['uid'] as String,
      nickname: data['nickname'] as String,
      age: data['age'] as int,
      city: data['city'] as String,
      interests: List<String>.from(data['interests'] ?? []),
      avatarUrl: data['avatarUrl'] as String?,
      isProfileComplete: data['isProfileComplete'] as bool? ?? false,
      isVisible: data['isVisible'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'nickname': nickname,
    'age': age,
    'city': city,
    'interests': interests,
    'avatarUrl': avatarUrl,
    'isProfileComplete': isProfileComplete,
    'isVisible': isVisible,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastSeen': Timestamp.fromDate(lastSeen),
  };
}
