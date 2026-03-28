// lib/features/feed/repositories/feed_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feed_profile.dart';

class FeedRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Батч = 12 профилей (3 строки по 4 в сетке 2 колонки)
  static const int _pageSize = 12;

  Future<List<FeedProfile>> fetchProfiles({
    DocumentSnapshot? lastDoc,
    String? filterCity,
    int? filterAgeMin,
    int? filterAgeMax,
    List<String>? filterInterests,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return [];

    // Получаем uid-ы уже отправленных запросов — чтобы не показывать их снова
    final sentSnap = await _db
        .collection('requests')
        .where('fromUid', isEqualTo: currentUid)
        .get();
    final excludeUids = sentSnap.docs.map((d) => d['toUid'] as String).toSet()
      ..add(currentUid); // себя тоже исключаем

    Query query = _db
        .collection('users')
        .where('isProfileComplete', isEqualTo: true)
        .where('isVisible', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);

    if (filterCity != null && filterCity.isNotEmpty) {
      query = query.where('city', isEqualTo: filterCity);
    }
    if (filterAgeMin != null) {
      query = query.where('age', isGreaterThanOrEqualTo: filterAgeMin);
    }
    if (filterAgeMax != null) {
      query = query.where('age', isLessThanOrEqualTo: filterAgeMax);
    }
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snap = await query.get();

    return snap.docs
        .where((doc) => !excludeUids.contains(doc.id))
        .map(
          (doc) => FeedProfile.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  // Нужен для cursor pagination — храним сам DocumentSnapshot
  Future<QuerySnapshot> fetchProfilesRaw({
    DocumentSnapshot? lastDoc,
    String? filterCity,
  }) async {
    final currentUid = _auth.currentUser?.uid ?? '';

    Query query = _db
        .collection('users')
        .where('isProfileComplete', isEqualTo: true)
        .where('isVisible', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);

    if (filterCity != null && filterCity.isNotEmpty) {
      query = query.where('city', isEqualTo: filterCity);
    }
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.get();
  }
}
