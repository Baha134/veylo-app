// lib/features/feed/models/feed_profile.dart

class FeedProfile {
  final String uid;
  final String nickname;
  final int age;
  final String city;
  final List<String> interests;
  final String? avatarUrl;

  const FeedProfile({
    required this.uid,
    required this.nickname,
    required this.age,
    required this.city,
    required this.interests,
    this.avatarUrl,
  });

  factory FeedProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return FeedProfile(
      uid: uid,
      nickname: data['nickname'] ?? '',
      age: (data['age'] ?? 18).toInt(),
      city: data['city'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      avatarUrl: data['avatarUrl'],
    );
  }
}
