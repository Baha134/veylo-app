// lib/features/requests/repositories/request_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/request_model.dart';

class RequestRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _currentUid => _auth.currentUser?.uid ?? '';

  // Отправить запрос
  Future<void> sendRequest(String toUid, {String? message}) async {
    // Проверяем дубликат
    final existing = await _db
        .collection('requests')
        .where('fromUid', isEqualTo: _currentUid)
        .where('toUid', isEqualTo: toUid)
        .get();

    if (existing.docs.isNotEmpty) return;

    await _db
        .collection('requests')
        .add(
          RequestModel(
            id: '',
            fromUid: _currentUid,
            toUid: toUid,
            status: RequestStatus.pending,
            createdAt: DateTime.now(),
            message: message,
          ).toMap(),
        );
  }

  // Входящие запросы (pending)
  Stream<List<RequestModel>> incomingRequests() {
    return _db
        .collection('requests')
        .where('toUid', isEqualTo: _currentUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => RequestModel.fromFirestore(d)).toList(),
        );
  }

  // Принять запрос → создаём match
  Future<void> acceptRequest(RequestModel request) async {
    final batch = _db.batch();

    // Обновляем статус запроса
    batch.update(_db.collection('requests').doc(request.id), {
      'status': 'accepted',
    });

    // Создаём match
    final matchRef = _db.collection('matches').doc();
    batch.set(matchRef, {
      'users': [request.fromUid, request.toUid],
      'createdAt': FieldValue.serverTimestamp(),
      'chatId': matchRef.id, // chatId = matchId (упрощение для Этапа 4)
    });

    await batch.commit();
  }

  // Отклонить запрос
  Future<void> declineRequest(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'declined',
    });
  }
}
