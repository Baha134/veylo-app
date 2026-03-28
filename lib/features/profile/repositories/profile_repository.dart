import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_profile.dart';

class ProfileRepository {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _db
        .collection('users')
        .doc(profile.uid)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<String> uploadSilhouette(String uid, File silhouetteFile) async {
    final ref = _storage.ref().child('silhouettes/$uid.png');
    final task = await ref.putFile(
      silhouetteFile,
      SettableMetadata(contentType: 'image/png'),
    );
    return await task.ref.getDownloadURL();
  }
}
